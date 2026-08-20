import Foundation

/// Two appointments of the same specialist that overlap in time.
nonisolated struct ScheduleConflict: Identifiable, Hashable {
    let id: UUID
    let specialistName: String
    let first: Booking
    let second: Booking
}

/// Salon-wide reads for the owner environment.
///
/// The employee views intentionally filter everything to one specialist. The owner
/// needs the whole floor, so those reads are added here instead of changing the
/// existing ones — nothing on the employee side changes behaviour.
extension BookMeUpStore {
    /// Every live appointment of the day, whoever performs it.
    func salonBookings(on date: Date) -> [Booking] {
        bookings
            .filter { $0.status != .cancelled }
            .filter { AppDate.isSameDay($0.start, date) }
            .sorted { $0.start < $1.start }
    }

    func salonCancellations(on date: Date) -> [Booking] {
        bookings
            .filter { $0.status == .cancelled }
            .filter { AppDate.isSameDay($0.start, date) }
    }

    /// No-shows recorded on this date, read from the clients' own attendance history.
    func salonNoShows(on date: Date) -> [ClientAttendanceEvent] {
        attendanceEvents
            .filter { $0.kind == .noShow }
            .filter { AppDate.isSameDay($0.date, date) }
    }

    /// Appointments still waiting for a decision, soonest first.
    var pendingApprovalBookings: [Booking] {
        bookings
            .filter { $0.status == .pending && $0.end > Date() }
            .sorted { $0.start < $1.start }
    }

    /// Specialists with at least one live appointment that day.
    func specialistsBooked(on date: Date) -> [String] {
        Array(Set(salonBookings(on: date).map(\.specialistName))).sorted()
    }

    func salonRevenue(on date: Date) -> Double {
        salonBookings(on: date).reduce(0) { $0 + $1.price }
    }

    /// Double bookings on one specialist's day — a real problem the owner can fix.
    func scheduleConflicts(on date: Date) -> [ScheduleConflict] {
        var conflicts: [ScheduleConflict] = []
        let bySpecialist = Dictionary(grouping: salonBookings(on: date), by: \.specialistName)
        for (specialist, dayBookings) in bySpecialist {
            let ordered = dayBookings.sorted { $0.start < $1.start }
            for index in ordered.indices.dropLast() {
                let current = ordered[index]
                let next = ordered[index + 1]
                guard next.start < current.end else { continue }
                conflicts.append(
                    ScheduleConflict(id: current.id, specialistName: specialist, first: current, second: next)
                )
            }
        }
        return conflicts.sorted { $0.first.start < $1.first.start }
    }

    /// The whole business base, alphabetically. The owner sees every client, not only
    /// the ones one specialist happens to serve.
    var businessClients: [Client] {
        clients.sorted { $0.fullName.localizedStandardCompare($1.fullName) == .orderedAscending }
    }

    /// The business base filtered by the same forgiving search the specialist uses.
    func businessClients(matching query: String) -> [Client] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return businessClients }
        return businessClients.filter { $0.matches(query: trimmed) }
    }

    /// Revenue of the whole salon in the current calendar month.
    var salonMonthlyRevenue: Double {
        let month = AppDate.calendar.dateComponents([.year, .month], from: Date())
        return bookings
            .filter { $0.status != .cancelled }
            .filter { AppDate.calendar.dateComponents([.year, .month], from: $0.start) == month }
            .reduce(0) { $0 + $1.price }
    }

    /// Live appointments of the month, used for month-level owner reads.
    var salonMonthlyBookings: [Booking] {
        let month = AppDate.calendar.dateComponents([.year, .month], from: Date())
        return bookings
            .filter { $0.status != .cancelled }
            .filter { AppDate.calendar.dateComponents([.year, .month], from: $0.start) == month }
    }
}
