import Foundation

/// One specialist as the client sees them while choosing who will do the work.
///
/// It carries the person and their real availability for the service and day already
/// chosen, so the picker never promises a master who is fully booked, and the time grid
/// below it is drawn from exactly the same slots.
nonisolated struct SpecialistOption: Identifiable, Hashable {
    let member: TeamMember
    /// Free start times on the chosen day, in order.
    let slots: [Date]
    /// The soonest day this person still has room, when the chosen day has none.
    let nextFreeDay: Date?
    /// Appointments already in their day. Used to spread "no preference" bookings
    /// across the floor instead of always naming the same person.
    let load: Int

    var id: String { member.id }

    var isFree: Bool { !slots.isEmpty }

    /// "6 laisvi laikai", "Laisva rytoj", or an honest dead end.
    var availabilityText: String {
        if isFree {
            return "\(slots.count) \(LithuanianPlural.freeSlot(slots.count))"
        }
        if let nextFreeDay {
            return "Laisva \(nextFreeDay.relativeDayText.lowercased())"
        }
        return "Nėra laisvų laikų"
    }
}

nonisolated extension Array where Element == SpecialistOption {
    /// Every free time on the day, whoever performs it — what "no preference" offers.
    var combinedSlots: [Date] {
        let all: [Date] = flatMap { $0.slots }
        return Set(all).sorted()
    }

    /// Who actually takes a slot when the client did not choose a person.
    ///
    /// The least busy free specialist wins, which is how a salon would hand the work
    /// out. Ties break on name so the same tap always produces the same result.
    func assignee(for slot: Date) -> TeamMember? {
        filter { $0.slots.contains(slot) }
            .min {
                $0.load == $1.load
                    ? $0.member.name.localizedStandardCompare($1.member.name) == .orderedAscending
                    : $0.load < $1.load
            }?
            .member
    }

    func option(named name: String) -> SpecialistOption? {
        first { $0.member.name == name }
    }
}
