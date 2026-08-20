import Foundation

/// How full one day is for one specialist.
///
/// `openMinutes` comes from the working schedule, personal blocks are removed from it,
/// and only the remaining sellable time is the denominator of occupancy — a day spent
/// half on a training course is not a half-empty day.
nonisolated struct DayLoad: Identifiable, Hashable {
    let date: Date
    /// Minutes the specialist is scheduled to work. Zero on a day off.
    let openMinutes: Int
    /// Minutes taken by personal blocks.
    let blockedMinutes: Int
    /// Minutes taken by active appointments.
    let bookedMinutes: Int
    let appointments: Int
    let revenue: Double

    var id: Date { date }

    var isWorkingDay: Bool { openMinutes > 0 }

    /// Time that could still be sold.
    var sellableMinutes: Int { max(openMinutes - blockedMinutes, 0) }

    var occupancy: Double {
        guard sellableMinutes > 0 else { return 0 }
        return min(Double(bookedMinutes) / Double(sellableMinutes), 1)
    }
}

/// The specialist's own day, as it stands right now.
nonisolated struct EmployeeTodayMetrics: Hashable {
    let expectedRevenue: Double
    let appointments: Int
    /// Mean revenue of a worked day, from real finished days. `nil` until there is
    /// enough history for the comparison to mean anything.
    let dailyAverage: Double?

    static let empty = EmployeeTodayMetrics(expectedRevenue: 0, appointments: 0, dailyAverage: nil)

    /// How today compares with an ordinary day, as a fraction (`0.12` = 12 % above).
    var changeVersusAverage: Double? {
        guard let dailyAverage, dailyAverage > 0, expectedRevenue > 0 else { return nil }
        return (expectedRevenue - dailyAverage) / dailyAverage
    }

    /// "↑ 12 % nuo tavo dienos vidurkio". Silent when the difference is noise.
    var comparisonText: String? {
        guard let change = changeVersusAverage, abs(change) >= 0.05 else { return nil }
        let arrow = change > 0 ? "↑" : "↓"
        return "\(arrow) \(Int((abs(change) * 100).rounded())) % nuo tavo dienos vidurkio"
    }

    var isAboveAverage: Bool { (changeVersusAverage ?? 0) > 0 }
}

/// How strong the schedule ahead looks. This is the part of the screen the specialist
/// is meant to want to improve.
nonisolated struct EmployeeMomentum: Hashable {
    let upcomingAppointments: Int
    /// Share of sellable time already sold over the next seven days.
    let weekOccupancy: Double
    /// Future working days already at or above the "this day is full" threshold.
    let strongDaysAhead: Int
    /// Appointments ahead that were cancelled — the only change metric the booking
    /// records can prove today.
    let cancelledAhead: Int
    let upcomingRevenue: Double

    static let empty = EmployeeMomentum(
        upcomingAppointments: 0,
        weekOccupancy: 0,
        strongDaysAhead: 0,
        cancelledAhead: 0,
        upcomingRevenue: 0
    )

    var weekOccupancyText: String { "\(Int((weekOccupancy * 100).rounded())) %" }

    /// Only ever shown when there is something real to report.
    var changeText: String? {
        guard cancelledAhead > 0 else { return nil }
        return "\(cancelledAhead) \(LithuanianPlural.cancelledVisit(cancelledAhead)) artimiausiu metu"
    }
}

/// How many of each service is booked ahead. Revealed after tapping the upcoming
/// visits metric rather than living permanently on the screen.
nonisolated struct ServiceCount: Identifiable, Hashable {
    let name: String
    let count: Int
    let revenue: Double

    var id: String { name }
}

/// A quiet weekly target: money already earned this week against what this specialist
/// normally earns in a week.
nonisolated struct EmployeeWeeklyGoal: Hashable {
    let earned: Double
    let target: Double
    /// True when the target was derived from the specialist's own history rather than
    /// chosen by hand.
    let isDerived: Bool

    var progress: Double {
        guard target > 0 else { return 0 }
        return min(earned / target, 1)
    }

    var percentText: String { "\(Int((progress * 100).rounded())) %" }

    var isReached: Bool { earned >= target && target > 0 }

    var remaining: Double { max(target - earned, 0) }
}
