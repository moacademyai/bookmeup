import Foundation

/// The employee environment's window onto the shared store.
///
/// Every read here narrows the one booking list down to a specialist and hands it to
/// `EmployeeAnalytics`. No screen ever filters bookings itself, so "my revenue",
/// "my occupancy" and "my clients" mean exactly the same thing on every tab.
extension BookMeUpStore {

    // MARK: - Team

    /// The specialists on the floor, read from the business rather than hardcoded in a
    /// view. Demo seed data fills it today; a real team endpoint replaces the seed
    /// without any screen changing.
    var team: [TeamMember] { SampleData.team }

    /// The signed-in specialist's own record.
    var currentTeamMember: TeamMember? {
        team.first { $0.isCurrentUser } ?? team.first
    }

    func teamMember(named name: String) -> TeamMember? {
        team.first { $0.name == name }
    }

    /// True when this appointment belongs to somebody else — the condition that turns
    /// a quick action into a confirmed one.
    func isColleagues(_ booking: Booking) -> Bool {
        booking.specialistName != specialistName
    }

    // MARK: - Working schedule

    /// The specialist's working week. Comes from the venue they work at, so occupancy
    /// is measured against real opening hours instead of an assumed nine-to-five.
    var specialistHours: [OpeningHours] {
        providers.first { $0.specialistName == specialistName }?.openingHours
            ?? SampleData.studioNoma.openingHours
    }

    // MARK: - Scoped reads

    /// Every appointment of one specialist, whatever its status. The analytics layer
    /// decides which ones count as earned, expected or cancelled.
    func bookings(ofSpecialist name: String) -> [Booking] {
        bookings.filter { $0.specialistName == name }
    }

    func blocks(ofSpecialist name: String) -> [TimeBlock] {
        blocks.filter { $0.specialistName == name }
    }

    /// Appointments and personal time of one specialist on one day, in time order —
    /// the single source both calendar scopes draw their columns from.
    func calendarItems(forSpecialist name: String, on day: Date) -> [CalendarItem] {
        let dayBookings = bookings
            .filter { $0.specialistName == name && $0.status != .cancelled && AppDate.isSameDay($0.start, day) }
            .map { CalendarItem.booking($0) }
        let dayBlocks = blocks
            .filter { $0.specialistName == name && AppDate.isSameDay($0.start, day) }
            .map { CalendarItem.block($0) }
        return (dayBookings + dayBlocks).sorted { $0.start < $1.start }
    }

    func appointmentCount(forSpecialist name: String, on day: Date) -> Int {
        bookings.filter {
            $0.specialistName == name && $0.status != .cancelled && AppDate.isSameDay($0.start, day)
        }.count
    }

    // MARK: - Today tab

    var todayMetrics: EmployeeTodayMetrics {
        EmployeeAnalytics.today(bookings: bookings(ofSpecialist: specialistName), hours: specialistHours)
    }

    var momentum: EmployeeMomentum {
        EmployeeAnalytics.momentum(
            bookings: bookings(ofSpecialist: specialistName),
            blocks: blocks(ofSpecialist: specialistName),
            hours: specialistHours
        )
    }

    var weeklyGoal: EmployeeWeeklyGoal {
        EmployeeAnalytics.weeklyGoal(
            bookings: bookings(ofSpecialist: specialistName),
            storedTarget: storedWeeklyTarget
        )
    }

    /// What kind of work is booked ahead. Loaded only when the specialist asks for it.
    var upcomingServiceBreakdown: [ServiceCount] {
        EmployeeAnalytics.upcomingServices(bookings: bookings(ofSpecialist: specialistName))
    }

    /// Today's appointments in time order, cancellations left out.
    var todayAppointments: [Booking] {
        bookings
            .filter { $0.specialistName == specialistName }
            .filter { $0.status != .cancelled && AppDate.isSameDay($0.start, Date()) }
            .sorted { $0.start < $1.start }
    }

    /// A target the specialist set by hand. Absent until they do.
    private var storedWeeklyTarget: Double? {
        let stored = UserDefaults.standard.double(forKey: "bookmeup.employee.weeklyTarget")
        return stored > 0 ? stored : nil
    }

    // MARK: - Growth tab

    /// The whole Growth screen in one computation. Called when the tab opens and when
    /// the period changes — never on every render.
    func growthReport(for period: GrowthPeriod) -> EmployeeGrowthReport {
        EmployeeAnalytics.growth(
            period: period,
            bookings: bookings(ofSpecialist: specialistName),
            blocks: blocks(ofSpecialist: specialistName),
            hours: specialistHours,
            attendance: attendanceEvents
        )
    }

    // MARK: - Conflicts

    /// Whether a slot is really free for one specialist.
    ///
    /// Checked before every create and every move, because the calendar lets people
    /// press anywhere — the timeline drawing an empty gap is not a promise the gap fits.
    func conflict(
        forSpecialist name: String,
        start: Date,
        durationMinutes: Int,
        ignoring bookingID: UUID? = nil
    ) -> CalendarConflict? {
        let end = start.addingTimeInterval(TimeInterval(durationMinutes * 60))

        if let entry = specialistHours.entry(for: start), entry.isClosed {
            return .outsideWorkingHours
        }

        let overlapping = bookings.first {
            $0.specialistName == name
                && $0.status != .cancelled
                && $0.id != bookingID
                && $0.start < end && start < $0.end
        }
        if let overlapping {
            return .appointment(overlapping)
        }

        if let block = blocks.first(where: { $0.specialistName == name && $0.start < end && start < $0.end }) {
            return .block(block)
        }
        return nil
    }

    // MARK: - Cross-employee mutations

    /// Creates an appointment in a named specialist's calendar.
    ///
    /// Helping a colleague is normal salon work, so this is deliberately not restricted
    /// to the signed-in specialist. What it will not do is create an overlapping
    /// appointment: the conflict is returned instead, and the caller offers another time.
    func createBooking(
        forSpecialist specialistName: String,
        clientName: String,
        service: ServiceOffering,
        at start: Date,
        note: String = ""
    ) -> BookingOutcome {
        if let conflict = conflict(
            forSpecialist: specialistName,
            start: start,
            durationMinutes: service.durationMinutes
        ) {
            return .conflict(conflict)
        }

        let provider = providers.first { $0.specialistName == specialistName } ?? SampleData.studioNoma
        let client = registerClient(named: clientName, phone: SampleData.phone(for: clientName))
        let previous = bookings
            .filter { $0.clientName == clientName && $0.specialistName == specialistName }
            .sorted { $0.start > $1.start }
            .first

        let booking = Booking(
            providerID: provider.id,
            providerName: provider.name,
            specialistName: specialistName,
            address: provider.address,
            imageName: provider.imageName,
            serviceName: service.name,
            start: start,
            durationMinutes: service.durationMinutes,
            price: service.price,
            status: newBookingStatus(clientName: clientName),
            clientName: clientName,
            clientID: client.id,
            clientNote: note,
            visitNumber: (previous?.visitNumber ?? 0) + 1,
            previousVisit: previous?.start
        )
        appendBooking(booking)
        return .created(booking)
    }

    /// Moves an appointment, optionally into a different specialist's column.
    @discardableResult
    func move(
        _ booking: Booking,
        to start: Date,
        specialistName: String? = nil
    ) -> BookingOutcome {
        let target = specialistName ?? booking.specialistName
        if let conflict = conflict(
            forSpecialist: target,
            start: start,
            durationMinutes: booking.durationMinutes,
            ignoring: booking.id
        ) {
            return .conflict(conflict)
        }
        guard var moved = self.booking(with: booking.id) else {
            return .conflict(.outsideWorkingHours)
        }
        moved.start = start
        moved.specialistName = target
        updateBooking(moved)
        return .created(moved)
    }
}

/// Why a slot cannot be used.
nonisolated enum CalendarConflict {
    case appointment(Booking)
    case block(TimeBlock)
    case outsideWorkingHours

    var message: String {
        switch self {
        case .appointment: "Šis laikas jau užimtas."
        case .block: "Šiuo metu rezervuotas asmeninis laikas."
        case .outsideWorkingHours: "Šią dieną nedirbama."
        }
    }

    var detail: String? {
        switch self {
        case .appointment(let booking):
            "\(booking.start.timeText)–\(booking.end.timeText) · \(booking.clientName)"
        case .block(let block):
            "\(block.start.timeText)–\(block.end.timeText) · \(block.title)"
        case .outsideWorkingHours:
            nil
        }
    }
}

/// The result of a booking mutation. Success is never assumed by the caller.
nonisolated enum BookingOutcome {
    case created(Booking)
    case conflict(CalendarConflict)

    var booking: Booking? {
        if case .created(let booking) = self { return booking }
        return nil
    }

    var conflict: CalendarConflict? {
        if case .conflict(let conflict) = self { return conflict }
        return nil
    }
}
