import Foundation
import Observation

/// Single source of truth for bookings, blocks and favorites.
///
/// The client and the specialist share one booking list, so every client action
/// (booking, rescheduling, cancelling) immediately shows up in the specialist's day.
@Observable
final class BookMeUpStore {
    private(set) var providers: [Provider]
    private(set) var bookings: [Booking]
    private(set) var blocks: [TimeBlock]
    private(set) var favoriteProviderIDs: Set<UUID>
    /// The shared client base. Every screen that shows a client reads it from here.
    private(set) var clients: [Client]
    /// Clients the specialist added by hand. They belong to the base from the first
    /// second, before they have a single appointment.
    private(set) var manualClientIDs: Set<UUID> = []
    private(set) var clientNotes: [ClientNote]
    private(set) var attendanceEvents: [ClientAttendanceEvent]
    /// Beauty Passport records for the whole base — one per documented visit.
    private(set) var passportEntries: [BeautyPassportEntry]
    /// How each client prefers to be served. One record per client, shared by the
    /// client environment that writes it and the specialist environment that reads it.
    private(set) var experienceProfiles: [ClientExperienceProfile]
    /// The authenticated account's link to its client record.
    private(set) var accountLink: ClientAccountLink?
    /// Reviews of businesses. Seeded demo content plus everything clients wrote here.
    private(set) var reviews: [ProviderReview]

    let clientName = SampleData.clientName
    let specialistName = SampleData.specialistName
    let venueName = SampleData.homeVenue

    private let defaults = UserDefaults.standard
    private let bookingsKey = "bookmeup.bookings.v1"
    private let blocksKey = "bookmeup.blocks.v1"
    private let favoritesKey = "bookmeup.favorites.v1"
    private let notesKey = "bookmeup.clientnotes.v1"
    private let passportKey = "bookmeup.passport.v1"
    private let clientsKey = "bookmeup.clients.v1"
    private let experienceKey = "bookmeup.experience.v1"
    private let accountLinkKey = "bookmeup.accountlink.v1"
    private let reviewsKey = "bookmeup.reviews.v1"

    init() {
        providers = SampleData.providers
        bookings = SampleData.bookings
        blocks = SampleData.blocks
        favoriteProviderIDs = SampleData.favoriteProviderIDs
        clients = SampleData.clientDirectory
        clientNotes = []
        attendanceEvents = SampleData.attendanceEvents
        passportEntries = SampleData.passportEntries
        experienceProfiles = SampleData.experienceProfiles
        reviews = SampleData.reviews
        restoreReviews()
        restoreFavorites()
        restoreNotes()
        restoreManualClients()
        restorePassportEntries()
        restoreExperienceProfiles()
        syncClientsWithBookings()
        linkPassportEntriesToBookings()
        linkBookingsToClients()
        restoreAccountLink()
        signIn(SampleData.demoAccount)
    }

    // MARK: - Account and identity

    /// Connects an authenticated account to the client record it belongs to.
    ///
    /// A person who has been visiting the salon for years already exists in the base.
    /// Signing in must find that record — by verified number first, by exact name only
    /// when no number is on file — so their bookings, history and Beauty Passport stay
    /// attached. A new record is created only when nothing matches.
    @discardableResult
    func signIn(_ account: ClientAccount) -> Client {
        // An existing link wins, as long as it still points at a live record.
        if let link = accountLink, link.accountID == account.accountID, let client = client(with: link.clientID) {
            return client
        }

        if let existing = client(matchingPhone: account.phone) {
            fillMissingContact(of: existing, from: account)
            store(link: ClientAccountLink(accountID: account.accountID, clientID: existing.id, method: .verifiedPhone))
            return existing
        }

        if let existing = client(named: account.fullName) {
            fillMissingContact(of: existing, from: account)
            store(link: ClientAccountLink(accountID: account.accountID, clientID: existing.id, method: .name))
            return existing
        }

        let created = Client(
            firstName: account.firstName,
            lastName: account.lastName,
            phone: PhoneFormat.e164(account.phone) ?? account.phone,
            email: account.email
        )
        clients.append(created)
        manualClientIDs.insert(created.id)
        persistManualClients()
        store(link: ClientAccountLink(accountID: account.accountID, clientID: created.id, method: .created))
        return created
    }

    /// The client record behind the signed-in account.
    var signedInClient: Client? {
        guard let link = accountLink else { return nil }
        return client(with: link.clientID)
    }

    /// Adds contact details the salon never had, without ever overwriting what it has.
    private func fillMissingContact(of client: Client, from account: ClientAccount) {
        guard let index = clients.firstIndex(where: { $0.id == client.id }) else { return }
        if clients[index].phone.isEmpty, let normalized = PhoneFormat.e164(account.phone) {
            clients[index].phone = normalized
        }
        if !clients[index].hasEmail, let email = account.email {
            clients[index].email = email
        }
    }

    private func store(link: ClientAccountLink) {
        accountLink = link
        guard let data = try? JSONEncoder().encode(link) else { return }
        defaults.set(data, forKey: accountLinkKey)
    }

    private func restoreAccountLink() {
        guard let data = defaults.data(forKey: accountLinkKey),
              let stored = try? JSONDecoder().decode(ClientAccountLink.self, from: data) else { return }
        accountLink = stored
    }

    // MARK: - Client Experience Profile

    /// The one place every screen reads a client's preferences from.
    func experienceProfile(for clientID: UUID) -> ClientExperienceProfile? {
        experienceProfiles.first { $0.clientID == clientID }
    }

    func experienceProfile(for client: Client) -> ClientExperienceProfile? {
        experienceProfile(for: client.id)
    }

    /// The preferences of the person this appointment is for, resolved through the
    /// client record rather than through the name written on the booking.
    func experienceProfile(for booking: Booking) -> ClientExperienceProfile? {
        guard let client = client(for: booking) else { return nil }
        return experienceProfile(for: client.id)
    }

    var signedInExperienceProfile: ClientExperienceProfile? {
        guard let client = signedInClient else { return nil }
        return experienceProfile(for: client.id)
    }

    /// True when the signed-in client has not finished the questionnaire yet. This is
    /// the only condition that opens onboarding.
    var needsExperienceOnboarding: Bool {
        guard signedInClient != nil else { return false }
        return signedInExperienceProfile?.onboardingCompleted != true
    }

    /// Saves the questionnaire.
    ///
    /// Empty answers are dropped, so a skipped question never looks answered. Onboarding
    /// is marked complete only when this call is made from the final save — an abandoned
    /// flow leaves the profile unfinished and the questionnaire comes back.
    @discardableResult
    func saveExperienceAnswers(
        _ answers: [String: ExperienceAnswer],
        for clientID: UUID,
        businessID: UUID?,
        completingOnboarding: Bool
    ) -> ClientExperienceProfile {
        let kept = answers.filter { !$0.value.isEmpty }
        var profile = experienceProfile(for: clientID)
            ?? ClientExperienceProfile(clientID: clientID, businessID: businessID)
        profile.answers = kept
        profile.businessID = businessID ?? profile.businessID
        profile.updatedAt = Date()
        if completingOnboarding, !profile.onboardingCompleted {
            profile.onboardingCompleted = true
            profile.onboardingCompletedAt = Date()
        }

        if let index = experienceProfiles.firstIndex(where: { $0.clientID == clientID }) {
            experienceProfiles[index] = profile
        } else {
            experienceProfiles.append(profile)
        }
        persistExperienceProfiles()
        return profile
    }

    private func persistExperienceProfiles() {
        guard let data = try? JSONEncoder().encode(experienceProfiles) else { return }
        defaults.set(data, forKey: experienceKey)
    }

    /// Stored answers win over the demo seed, so a saved profile survives a relaunch.
    private func restoreExperienceProfiles() {
        guard let data = defaults.data(forKey: experienceKey),
              let stored = try? JSONDecoder().decode([ClientExperienceProfile].self, from: data) else { return }
        for profile in stored {
            if let index = experienceProfiles.firstIndex(where: { $0.clientID == profile.clientID }) {
                experienceProfiles[index] = profile
            } else {
                experienceProfiles.append(profile)
            }
        }
    }

    // MARK: - Business locations

    /// Gives every business without coordinates a place on the map.
    ///
    /// Businesses are registered with an address, not a pin, so this resolves the ones
    /// that have never been geocoded and writes the result back. Safe to call repeatedly:
    /// an already-resolved business is skipped, and the geocoder caches everything else.
    func resolveBusinessLocations() async {
        for index in providers.indices where !providers[index].location.isResolved {
            let resolved = await AddressGeocoder.shared.resolve(providers[index].location)
            guard resolved.isResolved else { continue }
            providers[index] = providers[index].withLocation(resolved)
        }
    }

    // MARK: - Reviews

    /// A business's reviews, newest first.
    func reviews(for providerID: UUID) -> [ProviderReview] {
        reviews
            .filter { $0.providerID == providerID }
            .sorted { $0.date > $1.date }
    }

    /// The review a client already left for one visit, if any.
    func review(for booking: Booking) -> ProviderReview? {
        reviews.first { $0.bookingID == booking.id }
    }

    /// A visit can be reviewed once, and only after it happened.
    func canReview(_ booking: Booking) -> Bool {
        booking.status != .cancelled && booking.end <= Date() && review(for: booking) == nil
    }

    /// Records a client's review of a visit they actually had.
    @discardableResult
    func addReview(for booking: Booking, rating: Int, text: String) -> ProviderReview? {
        guard canReview(booking) else { return nil }
        let review = ProviderReview(
            providerID: booking.providerID,
            bookingID: booking.id,
            clientID: booking.clientID,
            authorName: booking.clientName,
            rating: rating,
            text: text.trimmingCharacters(in: .whitespacesAndNewlines),
            date: Date(),
            source: .client
        )
        reviews.append(review)
        persistReviews()
        return review
    }

    private func persistReviews() {
        let written = reviews.filter { $0.source == .client }
        guard let data = try? JSONEncoder().encode(written) else { return }
        defaults.set(data, forKey: reviewsKey)
    }

    /// Brings back reviews clients wrote. Demo seed content is never persisted, so it
    /// can be changed without leaving stale copies behind.
    private func restoreReviews() {
        guard let data = defaults.data(forKey: reviewsKey),
              let stored = try? JSONDecoder().decode([ProviderReview].self, from: data) else { return }
        for review in stored where !reviews.contains(where: { $0.id == review.id }) {
            reviews.append(review)
        }
    }

    // MARK: - Client reads

    /// The signed-in client's own appointments.
    ///
    /// Resolved through the linked client record when there is one, so a person who
    /// signed in and was matched to a record the salon already had sees the visits that
    /// were on file — not an empty list.
    var clientBookings: [Booking] {
        let name = signedInClient?.fullName ?? clientName
        let id = signedInClient?.id
        return bookings
            .filter { booking in
                if let id, let bookingClientID = booking.clientID { return bookingClientID == id }
                return booking.clientName == name
            }
            .sorted { $0.start < $1.start }
    }

    var upcomingClientBookings: [Booking] {
        clientBookings.filter { $0.status.isActive && $0.end > Date() }
    }

    var nextClientBooking: Booking? { upcomingClientBookings.first }

    var laterClientBookings: [Booking] {
        Array(upcomingClientBookings.dropFirst())
    }

    var pastClientBookings: [Booking] {
        clientBookings
            .filter { !$0.status.isActive || $0.end <= Date() }
            .sorted { $0.start > $1.start }
    }

    var favoriteProviders: [Provider] {
        providers.filter { favoriteProviderIDs.contains($0.id) }
    }

    func provider(with id: UUID) -> Provider? {
        providers.first { $0.id == id }
    }

    func isFavorite(_ provider: Provider) -> Bool {
        favoriteProviderIDs.contains(provider.id)
    }

    /// Providers matching the Discover filters, ordered by the soonest free slot.
    func discoverProviders(category: ServiceCategory?, query: String) -> [Provider] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        return providers
            .filter { category == nil || $0.category == category }
            .filter { provider in
                guard !trimmed.isEmpty else { return true }
                let haystack = [
                    provider.name,
                    provider.specialistName,
                    provider.craft,
                    provider.district,
                    provider.services.map(\.name).joined(separator: " ")
                ].joined(separator: " ")
                return haystack.localizedStandardContains(trimmed)
            }
            .sorted { $0.nextSlot < $1.nextSlot }
    }

    // MARK: - Employee reads

    func schedule(for date: Date) -> [ScheduleEntry] {
        let dayBookings = bookings
            .filter { $0.specialistName == specialistName }
            .filter { $0.status != .cancelled }
            .filter { AppDate.isSameDay($0.start, date) }
            .map { ScheduleEntry.booking($0) }

        let dayBlocks = blocks
            .filter { $0.specialistName == specialistName }
            .filter { AppDate.isSameDay($0.start, date) }
            .map { ScheduleEntry.block($0) }

        let busy = (dayBookings + dayBlocks).sorted { $0.start < $1.start }
        return insertingFreeGaps(into: busy, on: date)
    }

    func dayBookings(for date: Date) -> [Booking] {
        bookings
            .filter { $0.specialistName == specialistName }
            .filter { $0.status != .cancelled }
            .filter { AppDate.isSameDay($0.start, date) }
            .sorted { $0.start < $1.start }
    }

    func pendingCount(for date: Date) -> Int {
        dayBookings(for: date).filter { $0.status == .pending }.count
    }

    func expectedRevenue(for date: Date) -> Double {
        dayBookings(for: date).reduce(0) { $0 + $1.price }
    }

    // MARK: - Client base

    /// Clients this specialist works with: everyone with an appointment plus everyone
    /// added to the base by hand.
    var specialistClients: [Client] {
        let names = Set(
            bookings
                .filter { $0.specialistName == specialistName && $0.status != .cancelled }
                .map(\.clientName)
        )
        return clients
            .filter { names.contains($0.fullName) || manualClientIDs.contains($0.id) }
            .sorted { $0.fullName.localizedStandardCompare($1.fullName) == .orderedAscending }
    }

    /// The specialist's clients filtered by the shared forgiving search.
    func specialistClients(matching query: String) -> [Client] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return specialistClients }
        return specialistClients.filter { $0.matches(query: trimmed) }
    }

    func client(named name: String) -> Client? {
        clients.first { $0.fullName == name }
    }

    func client(with id: UUID) -> Client? {
        clients.first { $0.id == id }
    }

    /// The client record of an appointment.
    ///
    /// Prefers the stored `clientID` and only falls back to the name link, which is how
    /// appointments typed straight into the calendar have always identified a person.
    func client(for booking: Booking) -> Client? {
        if let id = booking.clientID, let match = client(with: id) { return match }
        return client(named: booking.clientName)
    }

    /// The client already holding this number.
    ///
    /// Comparison runs on the normalised E.164 form, so the same person typed as
    /// "+37065539948", "865539948" or "065539948" is found every time.
    func client(matchingPhone phone: String, region: String = PhoneFormat.defaultRegion) -> Client? {
        let key = PhoneFormat.comparisonKey(phone, region: region)
        guard !key.isEmpty else { return nil }
        return clients.first { PhoneFormat.comparisonKey($0.phone, region: region) == key }
    }

    /// Every appointment of this client with this specialist, newest first.
    func visits(for client: Client) -> [Booking] {
        bookings
            .filter { $0.clientName == client.fullName && $0.specialistName == specialistName }
            .sorted { $0.start > $1.start }
    }

    /// Visits that already happened and were not cancelled.
    func pastVisits(for client: Client) -> [Booking] {
        visits(for: client).filter { $0.status != .cancelled && $0.start <= Date() }
    }

    /// Scheduled visits still ahead, soonest first.
    func upcomingVisits(for client: Client) -> [Booking] {
        visits(for: client)
            .filter { $0.status.isActive && $0.end > Date() }
            .sorted { $0.start < $1.start }
    }

    func nextVisit(for client: Client) -> Booking? { upcomingVisits(for: client).first }

    func lastVisit(for client: Client) -> Booking? { pastVisits(for: client).first }

    // MARK: - Booking approval

    /// Recorded no-shows of this client — read from their real attendance history.
    func noShowCount(for clientID: UUID) -> Int {
        attendanceEvents.filter { $0.clientID == clientID && $0.kind == .noShow }.count
    }

    /// Whether this client's new appointments have to be approved by the specialist.
    /// The rule itself lives in `BookingApprovalPolicy`.
    func requiresBookingApproval(clientID: UUID) -> Bool {
        BookingApprovalPolicy.requiresApproval(noShowCount: noShowCount(for: clientID))
    }

    func requiresBookingApproval(clientNamed name: String) -> Bool {
        guard let client = client(named: name) else { return false }
        return requiresBookingApproval(clientID: client.id)
    }

    /// The status every newly created appointment starts with, whoever created it.
    func newBookingStatus(clientName: String) -> BookingStatus {
        requiresBookingApproval(clientNamed: clientName) ? .pending : .confirmed
    }

    func attendance(for client: Client) -> [ClientAttendanceEvent] {
        attendanceEvents
            .filter { $0.clientID == client.id }
            .sorted { $0.date > $1.date }
    }

    /// Derives the client's habits from their real records. Nothing is stored.
    func overview(for client: Client) -> ClientOverview {
        let past = pastVisits(for: client).sorted { $0.start < $1.start }
        let missed = attendance(for: client)
        guard let first = past.first?.start, let last = past.last?.start else {
            return ClientOverview(
                totalVisits: 0,
                firstVisit: nil,
                lastVisit: nil,
                nextVisit: nextVisit(for: client)?.start,
                averageVisitsPerMonth: 0,
                averageDaysBetweenVisits: nil,
                noShowCount: missed.filter { $0.kind == .noShow }.count,
                lateCancellationCount: missed.filter { $0.kind == .lateCancellation }.count
            )
        }

        let daysActive = max(Date().timeIntervalSince(first) / 86_400, 1)
        let monthsActive = max(daysActive / 30.44, 1)
        let span = last.timeIntervalSince(first) / 86_400

        return ClientOverview(
            totalVisits: past.count,
            firstVisit: first,
            lastVisit: last,
            nextVisit: nextVisit(for: client)?.start,
            averageVisitsPerMonth: Double(past.count) / monthsActive,
            averageDaysBetweenVisits: past.count > 1 ? span / Double(past.count - 1) : nil,
            noShowCount: missed.filter { $0.kind == .noShow }.count,
            lateCancellationCount: missed.filter { $0.kind == .lateCancellation }.count
        )
    }

    // MARK: - Beauty Passport

    /// This client's finished passport records, newest first. A draft belongs to the
    /// visit being worked on and only appears here once the specialist finishes it.
    func passportEntries(for client: Client) -> [BeautyPassportEntry] {
        passportEntries
            .filter { $0.clientID == client.id && $0.status == .completed }
            .sorted { $0.date > $1.date }
    }

    /// The most recent documented visit — the card shown on the client profile.
    func latestPassportEntry(for client: Client) -> BeautyPassportEntry? {
        passportEntries(for: client).first
    }

    /// The passport record of one specific appointment, draft or finished.
    /// The `bookingID` link is what guarantees one appointment can only ever have one.
    func passportEntry(for booking: Booking) -> BeautyPassportEntry? {
        passportEntries.first { $0.bookingID == booking.id }
    }

    func passportEntry(with id: UUID) -> BeautyPassportEntry? {
        passportEntries.first { $0.id == id }
    }

    /// True when this appointment has a passport record still being filled in.
    func hasPassportDraft(for booking: Booking) -> Bool {
        passportEntry(for: booking)?.isDraft ?? false
    }

    /// The appointment a passport record documents, when it still exists.
    func booking(for entry: BeautyPassportEntry) -> Booking? {
        guard let bookingID = entry.bookingID else { return nil }
        return bookings.first { $0.id == bookingID }
    }

    // MARK: - Beauty Passport mutations

    /// Returns the record of this appointment, creating the draft only the first time.
    ///
    /// Reopening the editor never produces a second record: an existing entry for the
    /// same `bookingID` always wins.
    @discardableResult
    func startPassportEntry(for booking: Booking) -> BeautyPassportEntry {
        if let existing = passportEntry(for: booking) { return existing }

        let client = registerClient(named: booking.clientName, phone: SampleData.phone(for: booking.clientName))
        let entry = BeautyPassportEntry(
            clientID: client.id,
            bookingID: booking.id,
            date: booking.start,
            serviceName: booking.serviceName,
            specialistName: booking.specialistName,
            category: provider(with: booking.providerID)?.category ?? .beauty,
            status: .draft
        )
        passportEntries.append(entry)
        persistPassportEntries()
        return entry
    }

    /// Autosave hook — every meaningful edit in the editor lands here immediately.
    func savePassportEntry(_ entry: BeautyPassportEntry) {
        if let index = passportEntries.firstIndex(where: { $0.id == entry.id }) {
            passportEntries[index] = entry
        } else {
            passportEntries.append(entry)
        }
        persistPassportEntries()
    }

    /// Turns the draft into a finished record so it appears in the client's passport.
    func completePassportEntry(_ entry: BeautyPassportEntry) {
        guard let index = passportEntries.firstIndex(where: { $0.id == entry.id }) else { return }
        var finished = entry
        finished.status = .completed
        if !finished.hasSummary {
            finished.summary = summaryText(for: finished)
        }
        passportEntries[index] = finished
        persistPassportEntries()
    }

    /// A short human line for the client profile card, built from what was filled in.
    private func summaryText(for entry: BeautyPassportEntry) -> String {
        entry.filledDetails
            .prefix(2)
            .map { "\($0.title): \($0.value)" }
            .joined(separator: " · ")
    }

    func notes(for client: Client) -> [ClientNote] {
        clientNotes
            .filter { $0.clientID == client.id }
            .sorted { $0.createdAt > $1.createdAt }
    }

    var monthlyRevenue: Double {
        let month = AppDate.calendar.dateComponents([.year, .month], from: Date())
        return bookings
            .filter { $0.specialistName == specialistName && $0.status != .cancelled }
            .filter { AppDate.calendar.dateComponents([.year, .month], from: $0.start) == month }
            .reduce(0) { $0 + $1.price }
    }

    // MARK: - Availability

    /// Free times for a provider on a given day, respecting existing bookings and blocks.
    func availableSlots(for provider: Provider, on date: Date, durationMinutes: Int) -> [Date] {
        let opening = 9
        let closing = 19
        var slots: [Date] = []
        var cursor = AppDate.time(opening, 0, dayOffset: date.daysFromNow)
        let dayEnd = AppDate.time(closing, 0, dayOffset: date.daysFromNow)

        let taken = bookings
            .filter { $0.providerID == provider.id && $0.status != .cancelled }
            .filter { AppDate.isSameDay($0.start, date) }
        let takenBlocks = blocks
            .filter { $0.specialistName == provider.specialistName }
            .filter { AppDate.isSameDay($0.start, date) }

        while cursor.addingTimeInterval(TimeInterval(durationMinutes * 60)) <= dayEnd {
            let slotEnd = cursor.addingTimeInterval(TimeInterval(durationMinutes * 60))
            let overlapsBooking = taken.contains { $0.start < slotEnd && cursor < $0.end }
            let overlapsBlock = takenBlocks.contains { $0.start < slotEnd && cursor < $0.end }
            if !overlapsBooking && !overlapsBlock && cursor > Date() {
                slots.append(cursor)
            }
            cursor = cursor.addingTimeInterval(15 * 60)
        }
        return slots
    }

    // MARK: - Mutations

    @discardableResult
    func book(provider: Provider, service: ServiceOffering, at date: Date, clientName: String? = nil) -> Booking {
        let previous = bookings
            .filter { $0.clientName == (clientName ?? self.clientName) && $0.providerID == provider.id }
            .sorted { $0.start > $1.start }
            .first
        let name = clientName ?? self.clientName
        // Resolved before the appointment exists, so it carries the client's real id.
        let client = registerClient(named: name)
        let booking = Booking(
            providerID: provider.id,
            providerName: provider.name,
            specialistName: provider.specialistName,
            address: provider.address,
            imageName: provider.imageName,
            serviceName: service.name,
            start: date,
            durationMinutes: service.durationMinutes,
            price: service.price,
            status: newBookingStatus(clientName: name),
            clientName: name,
            clientID: client.id,
            clientNote: previous?.clientNote ?? "",
            visitNumber: (previous?.visitNumber ?? 0) + 1,
            previousVisit: previous?.start
        )
        bookings.append(booking)
        persistBookings()
        return booking
    }

    // MARK: - Client mutations

    /// Adds a client typed in by the specialist.
    ///
    /// This is the only way a client is created by hand — the client base and a booking
    /// in progress both come here. The number is turned into E.164 first and checked
    /// against the whole base, so the same person can never end up in the list twice.
    func createClient(
        firstName: String,
        lastName: String = "",
        phone: String,
        email: String = "",
        note: String = "",
        region: String = PhoneFormat.defaultRegion
    ) -> ClientCreationOutcome {
        guard let normalizedPhone = PhoneFormat.e164(phone, region: region) else {
            return .invalidPhone
        }
        if let existing = client(matchingPhone: normalizedPhone, region: region) {
            return .duplicate(existing)
        }

        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        let created = Client(
            firstName: firstName.trimmingCharacters(in: .whitespacesAndNewlines),
            lastName: lastName.trimmingCharacters(in: .whitespacesAndNewlines),
            phone: normalizedPhone,
            email: trimmedEmail.isEmpty ? nil : trimmedEmail
        )
        clients.append(created)
        manualClientIDs.insert(created.id)
        persistManualClients()
        addNote(note, for: created)
        return .created(created)
    }

    /// Adds a client to the base if this name is new, and returns the record either way.
    @discardableResult
    func registerClient(named name: String, phone: String = "") -> Client {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        if let existing = client(named: trimmed) {
            if existing.phone.isEmpty, !phone.isEmpty,
               let index = clients.firstIndex(where: { $0.id == existing.id }) {
                clients[index].phone = phone
                return clients[index]
            }
            return existing
        }
        let created = Client.named(trimmed, phone: phone)
        clients.append(created)
        return created
    }

    func updatePhone(_ phone: String, for client: Client) {
        guard let index = clients.firstIndex(where: { $0.id == client.id }) else { return }
        clients[index].phone = phone.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    func addNote(_ text: String, for client: Client) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        clientNotes.append(
            ClientNote(clientID: client.id, text: trimmed, author: specialistName)
        )
        persistNotes()
    }

    func removeNote(_ note: ClientNote) {
        clientNotes.removeAll { $0.id == note.id }
        persistNotes()
    }

    func reschedule(_ booking: Booking, to date: Date) {
        guard let index = bookings.firstIndex(where: { $0.id == booking.id }) else { return }
        bookings[index].start = date
        bookings[index].status = newBookingStatus(clientName: booking.clientName)
        persistBookings()
    }

    func cancel(_ booking: Booking) {
        guard let index = bookings.firstIndex(where: { $0.id == booking.id }) else { return }
        bookings[index].status = .cancelled
        persistBookings()
    }

    func confirm(_ booking: Booking) {
        guard let index = bookings.firstIndex(where: { $0.id == booking.id }) else { return }
        bookings[index].status = .confirmed
        persistBookings()
    }

    /// Turning down an appointment that was waiting for approval.
    func reject(_ booking: Booking) {
        cancel(booking)
    }

    func complete(_ booking: Booking) {
        guard let index = bookings.firstIndex(where: { $0.id == booking.id }) else { return }
        bookings[index].status = .completed
        persistBookings()
    }

    func updateNote(_ note: String, for booking: Booking) {
        guard let index = bookings.firstIndex(where: { $0.id == booking.id }) else { return }
        bookings[index].clientNote = note
        persistBookings()
    }

    /// Reserves personal time. Defaults to the signed-in specialist; the calendar
    /// passes a colleague's name when the block was created in their column.
    func addBlock(title: String, start: Date, minutes: Int, specialistName: String? = nil) {
        blocks.append(
            TimeBlock(
                specialistName: specialistName ?? self.specialistName,
                title: title,
                start: start,
                durationMinutes: minutes
            )
        )
    }

    func removeBlock(_ block: TimeBlock) {
        blocks.removeAll { $0.id == block.id }
    }

    func toggleFavorite(_ provider: Provider) {
        if favoriteProviderIDs.contains(provider.id) {
            favoriteProviderIDs.remove(provider.id)
        } else {
            favoriteProviderIDs.insert(provider.id)
        }
        persistFavorites()
    }

    func booking(with id: UUID) -> Booking? {
        bookings.first { $0.id == id }
    }

    // MARK: - Booking writes

    /// Adds a finished appointment record to the shared list.
    ///
    /// The employee environment builds its own appointments (it can book for a
    /// colleague, which `book(provider:service:at:)` deliberately cannot), but every
    /// route into the booking list still goes through here so persistence stays in
    /// one place.
    func appendBooking(_ booking: Booking) {
        bookings.append(booking)
        persistBookings()
    }

    /// Replaces an appointment with an edited copy of itself.
    func updateBooking(_ booking: Booking) {
        guard let index = bookings.firstIndex(where: { $0.id == booking.id }) else { return }
        bookings[index] = booking
        persistBookings()
    }

    // MARK: - Private

    /// Makes sure every name that appears on a booking also exists in the client base,
    /// so a client created from the calendar is a full record from the first second.
    private func syncClientsWithBookings() {
        for name in Set(bookings.map(\.clientName)) where client(named: name) == nil {
            clients.append(Client.named(name, phone: SampleData.phone(for: name)))
        }
    }

    /// Gives every appointment the id of the client it belongs to.
    ///
    /// Seed and previously stored appointments only carry a name; this resolves that
    /// name once at launch so everything downstream can work with a real client id.
    private func linkBookingsToClients() {
        for index in bookings.indices where bookings[index].clientID == nil {
            bookings[index].clientID = client(named: bookings[index].clientName)?.id
        }
    }

    /// Attaches every passport record to the appointment it documents, by matching the
    /// client and the day. Bookings get fresh ids on each launch, so the link is
    /// resolved here instead of being hardcoded in the seed data.
    private func linkPassportEntriesToBookings() {
        var linked = Set(passportEntries.compactMap(\.bookingID))
        for index in passportEntries.indices {
            let entry = passportEntries[index]
            // Keep a link that still points at a live appointment.
            if let id = entry.bookingID, bookings.contains(where: { $0.id == id }) { continue }
            guard let client = client(with: entry.clientID) else { continue }
            let match = bookings.first {
                $0.clientName == client.fullName
                    && AppDate.isSameDay($0.start, entry.date)
                    && !linked.contains($0.id)
            }
            passportEntries[index].bookingID = match?.id
            if let id = match?.id { linked.insert(id) }
        }
    }

    private func insertingFreeGaps(into entries: [ScheduleEntry], on date: Date) -> [ScheduleEntry] {
        guard !entries.isEmpty else {
            return [.free(id: UUID(), start: AppDate.time(9, 0, dayOffset: date.daysFromNow), minutes: 600)]
        }
        var result: [ScheduleEntry] = []
        for (index, entry) in entries.enumerated() {
            result.append(entry)
            guard index + 1 < entries.count else { continue }
            let currentEnd = entry.start.addingTimeInterval(TimeInterval(entry.minutes * 60))
            let nextStart = entries[index + 1].start
            let gap = Int(nextStart.timeIntervalSince(currentEnd) / 60)
            if gap >= 30 {
                result.append(.free(id: UUID(), start: currentEnd, minutes: gap))
            }
        }
        return result
    }

    private func persistBookings() {
        guard let data = try? JSONEncoder().encode(bookings) else { return }
        defaults.set(data, forKey: bookingsKey)
    }

    private func persistManualClients() {
        let manual = clients.filter { manualClientIDs.contains($0.id) }
        guard let data = try? JSONEncoder().encode(manual) else { return }
        defaults.set(data, forKey: clientsKey)
    }

    /// Brings back clients added by hand, so they stay in the base after a relaunch.
    private func restoreManualClients() {
        guard let data = defaults.data(forKey: clientsKey),
              let stored = try? JSONDecoder().decode([Client].self, from: data) else { return }
        for client in stored {
            manualClientIDs.insert(client.id)
            if let index = clients.firstIndex(where: { $0.id == client.id }) {
                clients[index] = client
            } else {
                clients.append(client)
            }
        }
    }

    private func persistNotes() {
        guard let data = try? JSONEncoder().encode(clientNotes) else { return }
        defaults.set(data, forKey: notesKey)
    }

    private func restoreNotes() {
        guard let data = defaults.data(forKey: notesKey),
              let stored = try? JSONDecoder().decode([ClientNote].self, from: data) else { return }
        clientNotes = stored
    }

    private func persistPassportEntries() {
        guard let data = try? JSONEncoder().encode(passportEntries) else { return }
        defaults.set(data, forKey: passportKey)
    }

    /// Restores stored records over the demo seed, so a draft survives leaving the
    /// screen, switching tabs or relaunching the app.
    private func restorePassportEntries() {
        guard let data = defaults.data(forKey: passportKey),
              let stored = try? JSONDecoder().decode([BeautyPassportEntry].self, from: data) else { return }
        for entry in stored {
            if let index = passportEntries.firstIndex(where: { $0.id == entry.id }) {
                passportEntries[index] = entry
            } else {
                passportEntries.append(entry)
            }
        }
    }

    private func persistFavorites() {
        defaults.set(favoriteProviderIDs.map(\.uuidString), forKey: favoritesKey)
    }

    private func restoreFavorites() {
        guard let stored = defaults.stringArray(forKey: favoritesKey) else { return }
        let ids = stored.compactMap { UUID(uuidString: $0) }
        favoriteProviderIDs = Set(ids)
    }
}

