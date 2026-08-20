import Foundation

/// Choosing who does the work.
///
/// A business is not one person: the client picks a service, then the master, then the
/// time — and the time offered has to belong to that master alone. Every read here is
/// scoped to one specialist's own day, so two colleagues in the same salon can be booked
/// for the same hour, and a master who is already busy simply stops being offered.
extension BookMeUpStore {

    // MARK: - Roster

    /// The specialists a client can choose from at a business.
    ///
    /// Falls back to the person the business is registered under, so a one-chair studio
    /// that never published a team still behaves exactly as it did before.
    func specialists(at provider: Provider) -> [TeamMember] {
        let roster = team.filter { $0.providerID == provider.id }
        guard roster.isEmpty else { return roster }
        return [
            TeamMember(
                name: provider.specialistName,
                craft: provider.craft,
                providerID: provider.id,
                rating: provider.rating,
                reviewCount: provider.reviewCount
            )
        ]
    }

    /// The specialists qualified for one service. Never empty: when nobody declared the
    /// service, the business owner keeps it rather than the client losing the booking.
    func specialists(at provider: Provider, performing service: ServiceOffering) -> [TeamMember] {
        let roster = specialists(at: provider)
        let eligible = roster.filter { $0.canPerform(service) }
        if !eligible.isEmpty { return eligible }
        return roster.filter { $0.name == provider.specialistName }.isEmpty
            ? Array(roster.prefix(1))
            : roster.filter { $0.name == provider.specialistName }
    }

    /// True when the business has a real choice to offer.
    func hasSpecialistChoice(at provider: Provider) -> Bool {
        specialists(at: provider).count > 1
    }

    /// The master this client has been going to at this business.
    ///
    /// Loyalty in this trade is to a person, not to an address, so a returning client
    /// opens the booking sheet on the person who cut their hair last time.
    func usualSpecialistName(at provider: Provider) -> String? {
        clientBookings
            .filter { $0.providerID == provider.id && $0.status != .cancelled }
            .max { $0.start < $1.start }?
            .specialistName
    }

    // MARK: - Availability

    /// Free start times of one specialist on one day.
    ///
    /// Their whole workload counts, not just this business's bookings: a barber busy on
    /// the salon floor is busy, whichever record the appointment was created from.
    func availableSlots(
        for provider: Provider,
        specialistName: String,
        on date: Date,
        durationMinutes: Int
    ) -> [Date] {
        let opening = 9
        let closing = 19
        var slots: [Date] = []
        var cursor = AppDate.time(opening, 0, dayOffset: date.daysFromNow)
        let dayEnd = AppDate.time(closing, 0, dayOffset: date.daysFromNow)

        let taken = bookings.filter {
            $0.specialistName == specialistName
                && $0.status != .cancelled
                && AppDate.isSameDay($0.start, date)
        }
        let takenBlocks = blocks.filter {
            $0.specialistName == specialistName && AppDate.isSameDay($0.start, date)
        }

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

    /// Everyone who can perform this service, with their real availability for one day.
    ///
    /// Computed in one place and handed to the picker and the time grid together, so the
    /// count on a specialist's card and the times underneath can never disagree.
    func specialistOptions(
        at provider: Provider,
        service: ServiceOffering,
        on day: Date,
        searchDays: Int = 14
    ) -> [SpecialistOption] {
        specialists(at: provider, performing: service).map { member in
            let slots = availableSlots(
                for: provider,
                specialistName: member.name,
                on: day,
                durationMinutes: service.durationMinutes
            )
            return SpecialistOption(
                member: member,
                slots: slots,
                nextFreeDay: slots.isEmpty
                    ? nextFreeDay(for: member, at: provider, service: service, after: day, within: searchDays)
                    : nil,
                load: appointmentCount(forSpecialist: member.name, on: day)
            )
        }
    }

    /// The soonest day this specialist still has room for the service.
    private func nextFreeDay(
        for member: TeamMember,
        at provider: Provider,
        service: ServiceOffering,
        after day: Date,
        within searchDays: Int
    ) -> Date? {
        let start = day.daysFromNow
        for offset in 1...max(searchDays, 1) {
            let candidate = AppDate.time(9, 0, dayOffset: start + offset)
            let slots = availableSlots(
                for: provider,
                specialistName: member.name,
                on: candidate,
                durationMinutes: service.durationMinutes
            )
            if !slots.isEmpty { return candidate }
        }
        return nil
    }
}
