import SwiftUI

/// Where the Beauty Passport action of this visit leads: back into the editor while
/// the record is a draft, or into the finished record.
private enum BeautyPassportRoute: Hashable, Identifiable {
    case editor(UUID)
    case record(UUID)

    var id: String {
        switch self {
        case .editor(let id): "editor-\(id.uuidString)"
        case .record(let id): "record-\(id.uuidString)"
        }
    }
}

/// Everything the specialist needs between two visits: status, client, details, actions.
struct EmployeeBookingDetailView: View {
    let bookingID: UUID

    @Environment(BookMeUpStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    @State private var bookingFlow: BookingFlow?
    @State private var showCancelDialog = false
    @State private var showMessageSheet = false
    @State private var passportRoute: BeautyPassportRoute?
    @State private var showPassportPrompt = false
    /// Set when the appointment belongs to a colleague, so the change goes through an
    /// explicit confirmation instead of a single tap.
    @State private var colleagueAction: ColleagueAction?

    private var booking: Booking? { store.booking(with: bookingID) }

    /// Somebody else's appointment. Every destructive or rescheduling action below
    /// asks first when this is true.
    private var isColleagues: Bool {
        guard let booking else { return false }
        return store.isColleagues(booking)
    }

    var body: some View {
        ScrollView {
            if let booking {
                VStack(alignment: .leading, spacing: 18) {
                    statusHeader(booking)
                    clientCard(booking)
                    experienceSection(booking)
                    details(booking)
                    notes(booking)
                    passport(booking)
                    actions(booking)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 28)
            } else {
                ContentUnavailableView("Rezervacija nerasta", systemImage: "calendar.badge.exclamationmark")
                    .padding(.top, 60)
            }
        }
        .background(Palette.bone)
        .scrollIndicators(.hidden)
        .navigationTitle("Rezervacijos informacija")
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(item: $passportRoute) { route in
            passportDestination(route)
        }
        .toolbar(.hidden, for: .tabBar)
        .toolbarBackground(Palette.bone, for: .navigationBar)
        .toolbarColorScheme(.light, for: .navigationBar)
        .sheet(item: $bookingFlow) { flow in
            BookingSheet(flow: flow).environment(store)
        }
        .sheet(isPresented: $showMessageSheet) {
            if let booking {
                MessageClientSheet(clientName: booking.clientName, booking: booking)
            }
        }
        .sheet(item: $colleagueAction) { action in
            ColleagueActionSheet(action: action) {
                perform(action)
            }
        }
        .confirmationDialog("Atšaukti rezervaciją?", isPresented: $showCancelDialog, titleVisibility: .visible) {
            Button("Atšaukti rezervaciją", role: .destructive) {
                if let booking { store.cancel(booking) }
                dismiss()
            }
            Button("Palikti", role: .cancel) { }
        } message: {
            Text("Klientas gaus pranešimą, o laikas grįš į laisvų laikų sąrašą.")
        }
        .confirmationDialog(
            "Grožio pasas dar neužbaigtas.",
            isPresented: $showPassportPrompt,
            titleVisibility: .visible
        ) {
            Button("Užbaigti Grožio pasą") {
                if let booking { openPassport(for: booking) }
            }
            Button("Užbaigti vizitą be Grožio paso") {
                if let booking { store.complete(booking) }
            }
            Button("Atšaukti", role: .cancel) { }
        }
    }

    // MARK: - Client Experience

    /// What this client prefers, read in the seconds before the visit starts.
    ///
    /// The profile is resolved through the client record the appointment points at, not
    /// through the name written on it, and it is read live — nothing about the client's
    /// preferences is copied onto the booking, so an edit they make is already correct
    /// here. Compact on purpose: this is a glance, not a second profile screen.
    @ViewBuilder
    private func experienceSection(_ booking: Booking) -> some View {
        if let profile = store.experienceProfile(for: booking), profile.hasSharedPreferences {
            ClientExperienceSummaryView(profile: profile, style: .compact)
        }
    }

    // MARK: - Beauty Passport

    /// One appointment, one passport record — the action always reopens the record
    /// linked to this booking instead of starting a new one.
    @ViewBuilder
    private func passport(_ booking: Booking) -> some View {
        if booking.status != .cancelled {
            let entry = store.passportEntry(for: booking)

            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 12) {
                    Image(systemName: "sparkles")
                        .font(.footnote)
                        .foregroundStyle(Palette.forest)
                        .frame(width: 34, height: 34)
                        .background(Palette.eucalyptus.opacity(0.4), in: .rect(cornerRadius: 10))

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Grožio pasas")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Palette.ink)
                        Text(passportSubtitle(entry))
                            .font(.caption)
                            .foregroundStyle(Palette.inkSoft)
                    }
                    Spacer(minLength: 4)
                }

                Button {
                    openPassport(for: booking)
                } label: {
                    Label(passportActionTitle(entry), systemImage: passportActionSymbol(entry))
                }
                .buttonStyle(QuietButtonStyle(tint: Palette.forest))
            }
            .cardSurface(padding: 16)
        }
    }

    private func passportSubtitle(_ entry: BeautyPassportEntry?) -> String {
        guard let entry else { return "Šis vizitas dar neužfiksuotas" }
        return entry.isDraft ? "Juodraštis · išsaugoma automatiškai" : "Užbaigtas įrašas"
    }

    private func passportActionTitle(_ entry: BeautyPassportEntry?) -> String {
        guard let entry else { return "Pradėti Grožio pasą" }
        return entry.isDraft ? "Tęsti Grožio pasą" : "Peržiūrėti Grožio pasą"
    }

    private func passportActionSymbol(_ entry: BeautyPassportEntry?) -> String {
        guard let entry else { return "plus.circle" }
        return entry.isDraft ? "square.and.pencil" : "eye"
    }

    private func openPassport(for booking: Booking) {
        let entry = store.passportEntry(for: booking) ?? store.startPassportEntry(for: booking)
        passportRoute = entry.isDraft ? .editor(entry.id) : .record(entry.id)
    }

    @ViewBuilder
    private func passportDestination(_ route: BeautyPassportRoute) -> some View {
        switch route {
        case .editor(let id):
            BeautyPassportEditorView(entryID: id)
        case .record(let id):
            if let entry = store.passportEntry(with: id),
               let client = store.client(with: entry.clientID) {
                BeautyPassportDetailView(client: client, entry: entry)
            } else {
                ContentUnavailableView("Įrašas nerastas", systemImage: "doc.badge.ellipsis")
            }
        }
    }

    private func statusHeader(_ booking: Booking) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(booking.status.title, systemImage: booking.status.symbolName)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(booking.status.tint.mix(with: Palette.ink, amount: 0.2))
            Text(booking.start.relativeDayTimeText)
                .font(.title.weight(.bold))
                .monospacedDigit()
                .foregroundStyle(Palette.ink)
            Text("Trukmė · \(booking.durationText)")
                .font(.footnote.monospacedDigit())
                .foregroundStyle(Palette.inkSoft)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background(booking.status.tint.opacity(0.14), in: .rect(cornerRadius: 22))
        .padding(.top, 8)
    }

    private func clientCard(_ booking: Booking) -> some View {
        HStack(alignment: .top, spacing: 14) {
            InitialsAvatar(name: booking.clientName, size: 56)
            VStack(alignment: .leading, spacing: 8) {
                Text(booking.clientName)
                    .font(.headline)
                    .foregroundStyle(Palette.ink)
                // Named only when this is not the signed-in specialist's own visit.
                if isColleagues {
                    Label(booking.specialistName, systemImage: "person")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(Palette.inkSoft)
                }
                Button {
                    showMessageSheet = true
                } label: {
                    Label("Parašyti klientui", systemImage: "bubble.left")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Palette.forest)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 9)
                        .overlay {
                            Capsule().stroke(Palette.forest.opacity(0.4), lineWidth: 1)
                        }
                }
                .buttonStyle(.plain)
                Text("\(booking.visitNumber)-asis apsilankymas")
                    .font(.footnote)
                    .foregroundStyle(Palette.inkSoft)
            }
            Spacer(minLength: 0)
        }
        .cardSurface(padding: 16)
    }

    private func details(_ booking: Booking) -> some View {
        VStack(spacing: 0) {
            detailRow(icon: "scissors", title: "Paslauga", value: booking.serviceName)
            Divider().overlay(Palette.hairline)
            detailRow(icon: "tag", title: "Kaina", value: booking.price.asEuro)
            Divider().overlay(Palette.hairline)
            detailRow(icon: "mappin.and.ellipse", title: "Vieta", value: "\(booking.providerName) · \(booking.address)")
        }
        .cardSurface(padding: 16)
    }

    private func notes(_ booking: Booking) -> some View {
        VStack(spacing: 0) {
            detailRow(
                icon: "note.text",
                title: "Kliento pastabos",
                value: booking.clientNote.isEmpty ? "Pastabų nėra" : booking.clientNote
            )
            if let previous = booking.previousVisit {
                Divider().overlay(Palette.hairline)
                detailRow(
                    icon: "clock.arrow.circlepath",
                    title: "Paskutinis vizitas",
                    value: previous.dayText
                )
            }
        }
        .cardSurface(padding: 16)
    }

    private func actions(_ booking: Booking) -> some View {
        VStack(spacing: 10) {
            if booking.status == .pending {
                approvalReason(booking)

                Button {
                    store.confirm(booking)
                } label: {
                    Label("Patvirtinti rezervaciją", systemImage: "checkmark.circle")
                }
                .buttonStyle(MarigoldButtonStyle())
                .sensoryFeedback(.success, trigger: booking.status)

                Button {
                    store.reject(booking)
                } label: {
                    Label("Atmesti rezervaciją", systemImage: "xmark.circle")
                }
                .buttonStyle(QuietButtonStyle(tint: Palette.terracotta))
            } else if booking.status == .confirmed && booking.start < Date() {
                Button {
                    if store.hasPassportDraft(for: booking) {
                        showPassportPrompt = true
                    } else {
                        store.complete(booking)
                    }
                } label: {
                    Label("Užbaigti vizitą", systemImage: "checkmark.seal")
                }
                .buttonStyle(MarigoldButtonStyle())
            }

            if booking.status.isActive {
                Button {
                    if isColleagues {
                        colleagueAction = .move(booking)
                    } else {
                        openReschedule(booking)
                    }
                } label: {
                    Label("Pakeisti laiką", systemImage: "calendar")
                }
                .buttonStyle(QuietButtonStyle())

                if booking.status != .pending {
                    Button {
                        if isColleagues {
                            colleagueAction = .cancel(booking)
                        } else {
                            showCancelDialog = true
                        }
                    } label: {
                        Label("Atšaukti rezervaciją", systemImage: "xmark.circle")
                    }
                    .buttonStyle(QuietButtonStyle(tint: Palette.terracotta))
                }
            }
        }
        .padding(.top, 4)
    }

    /// Why this one appointment is not confirmed automatically — always the client's
    /// own attendance history, never a manual flag.
    @ViewBuilder
    private func approvalReason(_ booking: Booking) -> some View {
        if let client = store.client(named: booking.clientName) {
            let missed = store.noShowCount(for: client.id)
            if missed > 0 {
                HStack(spacing: 10) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(Palette.terracotta)
                        .frame(width: 30, height: 30)
                        .background(Palette.terracotta.opacity(0.18), in: .circle)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("\(missed) \(LithuanianPlural.visit(missed))")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(Palette.ink)
                        Text("Šiam klientui rezervaciją reikia patvirtinti rankiniu būdu.")
                            .font(.caption)
                            .foregroundStyle(Palette.inkSoft)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    Spacer(minLength: 0)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .cardSurface(padding: 14)
                .padding(.bottom, 2)
            }
        }
    }

    /// Runs a confirmed change to a colleague's appointment.
    private func perform(_ action: ColleagueAction) {
        switch action {
        case .move(let booking):
            openReschedule(booking)
        case .cancel(let booking):
            store.cancel(booking)
            dismiss()
        }
    }

    private func openReschedule(_ booking: Booking) {
        guard let provider = store.provider(with: booking.providerID) else { return }
        bookingFlow = BookingFlow(
            provider: provider,
            rescheduling: booking,
            clientName: booking.clientName
        )
    }

    private func detailRow(icon: String, title: String, value: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.footnote)
                .foregroundStyle(Palette.forest)
                .frame(width: 34, height: 34)
                .background(Palette.eucalyptus.opacity(0.4), in: .rect(cornerRadius: 10))
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundStyle(Palette.inkSoft)
                Text(value)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(Palette.ink)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 4)
        }
        .padding(.vertical, 10)
    }
}

/// Quick pre-written messages a specialist can send.
///
/// Opened from a booking it can reference that visit; opened from the client
/// profile there may be no upcoming visit to mention.
struct MessageClientSheet: View {
    let clientName: String
    let booking: Booking?

    @Environment(\.dismiss) private var dismiss
    @State private var text: String = ""
    @State private var sent = false

    private var templates: [String] {
        guard let booking else {
            return [
                "Sveiki, turime laisvų laikų šią savaitę. Ar norėtumėte užsirašyti?",
                "Sveiki, seniai matėmės — priminti artimiausius laisvus laikus?",
                "Sveiki, ačiū už vizitą! Jei kils klausimų dėl priežiūros, rašykite."
            ]
        }
        return [
            "Sveiki, primenu apie vizitą \(booking.start.relativeDayTimeText). Laukiu!",
            "Sveiki, prieš kirpimą išsiplaukite galvą maždaug 1 val. prieš vizitą.",
            "Sveiki, ar galėtume vizitą perkelti 15 min. vėliau?"
        ]
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    Text("Žinutė klientui \(clientName)")
                        .font(.headline)
                        .foregroundStyle(Palette.ink)

                    VStack(alignment: .leading, spacing: 10) {
                        ForEach(templates, id: \.self) { template in
                            Button {
                                text = template
                            } label: {
                                Text(template)
                                    .font(.subheadline)
                                    .foregroundStyle(Palette.ink)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .cardSurface(padding: 14, cornerRadius: 16)
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    TextField("Žinutė", text: $text, axis: .vertical)
                        .lineLimit(3...6)
                        .padding(14)
                        .background(Palette.surface, in: .rect(cornerRadius: 16))
                        .overlay {
                            RoundedRectangle(cornerRadius: 16).stroke(Palette.hairline, lineWidth: 1)
                        }

                    Button {
                        sent = true
                        dismiss()
                    } label: {
                        Text("Siųsti žinutę")
                    }
                    .buttonStyle(MarigoldButtonStyle(isDisabled: text.isEmpty))
                    .disabled(text.isEmpty)
                    .sensoryFeedback(.success, trigger: sent)
                }
                .padding(20)
            }
            .background(Palette.bone)
            .navigationTitle("Parašyti klientui")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Uždaryti") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationContentInteraction(.scrolls)
    }
}
