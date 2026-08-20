import Foundation

/// The stretch of history the Growth tab is looking at.
nonisolated enum GrowthPeriod: String, CaseIterable, Identifiable, Hashable {
    case thisMonth
    case lastMonth
    case threeMonths
    case sixMonths
    case twelveMonths

    var id: String { rawValue }

    var shortTitle: String {
        switch self {
        case .thisMonth: "Šis mėn."
        case .lastMonth: "Praėjęs"
        case .threeMonths: "3 mėn."
        case .sixMonths: "6 mėn."
        case .twelveMonths: "12 mėn."
        }
    }

    /// How many months of trend to draw next to the headline number.
    var trendMonths: Int {
        switch self {
        case .thisMonth, .lastMonth: 4
        case .threeMonths: 3
        case .sixMonths: 6
        case .twelveMonths: 12
        }
    }

    /// The window itself, plus the equally long window before it that every
    /// comparison is measured against.
    func range(now: Date = Date()) -> DateInterval {
        let calendar = AppDate.calendar
        switch self {
        case .thisMonth:
            let start = calendar.date(from: calendar.dateComponents([.year, .month], from: now)) ?? now
            return DateInterval(start: start, end: now)
        case .lastMonth:
            let thisStart = calendar.date(from: calendar.dateComponents([.year, .month], from: now)) ?? now
            let start = calendar.date(byAdding: .month, value: -1, to: thisStart) ?? thisStart
            return DateInterval(start: start, end: thisStart)
        case .threeMonths, .sixMonths, .twelveMonths:
            let months = self == .threeMonths ? 3 : (self == .sixMonths ? 6 : 12)
            let start = calendar.date(byAdding: .month, value: -months, to: now) ?? now
            return DateInterval(start: start, end: now)
        }
    }

    /// The same length of time, immediately before the current window.
    func previousRange(now: Date = Date()) -> DateInterval {
        let current = range(now: now)
        let length = current.duration
        let start = current.start.addingTimeInterval(-length)
        return DateInterval(start: start, end: current.start)
    }

    /// What the headline number is labelled with: "Rugpjūtis", "3 mėn." …
    func title(now: Date = Date()) -> String {
        switch self {
        case .thisMonth:
            return now.monthText
        case .lastMonth:
            let previous = AppDate.calendar.date(byAdding: .month, value: -1, to: now) ?? now
            return previous.monthText
        case .threeMonths: return "Paskutiniai 3 mėn."
        case .sixMonths: return "Paskutiniai 6 mėn."
        case .twelveMonths: return "Paskutiniai 12 mėn."
        }
    }
}

/// Whether a rising number is a better number. Cancellations and no-shows are the
/// reason this exists: an arrow pointing up is not automatically green.
nonisolated enum MetricDirection {
    case higherIsBetter
    case lowerIsBetter

    func improved(current: Double, previous: Double) -> Bool {
        switch self {
        case .higherIsBetter: current >= previous
        case .lowerIsBetter: current <= previous
        }
    }
}

/// One historical number with its own comparison against the previous period.
nonisolated struct GrowthMetric: Identifiable, Hashable {
    let key: String
    let title: String
    let value: String
    let current: Double
    let previous: Double?
    let direction: MetricDirection

    var id: String { key }

    /// Relative change, `nil` when there is nothing to compare against.
    var change: Double? {
        guard let previous, previous > 0 else { return nil }
        return (current - previous) / previous
    }

    /// "↑ 8 %". Absent when the movement is not worth a line of type.
    var changeText: String? {
        guard let change, abs(change) >= 0.01 else { return nil }
        let arrow = change > 0 ? "↑" : "↓"
        return "\(arrow) \(Int((abs(change) * 100).rounded())) %"
    }

    /// Did the specialist do better, whichever way the arrow points.
    var isImprovement: Bool? {
        guard let previous, previous > 0, change != nil else { return nil }
        return direction.improved(current: current, previous: previous)
    }
}

/// One column of the revenue trend.
nonisolated struct MonthlyRevenuePoint: Identifiable, Hashable {
    let month: Date
    let revenue: Double

    var id: Date { month }

    /// "Rugp."
    var shortLabel: String { month.monthShortText }
}

/// A personal best. Records are the specialist against their own history — never
/// against a colleague.
nonisolated struct PersonalRecord: Identifiable, Hashable {
    let key: String
    let title: String
    let value: String
    let detail: String?

    var id: String { key }
}

/// Everything the Growth tab shows for one period, computed in one pass.
nonisolated struct EmployeeGrowthReport: Hashable {
    let period: GrowthPeriod
    let revenue: Double
    let previousRevenue: Double
    let visits: Int
    let metrics: [GrowthMetric]
    let trend: [MonthlyRevenuePoint]
    let services: [ServiceCount]
    let records: [PersonalRecord]
    let hasEnoughData: Bool

    static func empty(_ period: GrowthPeriod) -> EmployeeGrowthReport {
        EmployeeGrowthReport(
            period: period,
            revenue: 0,
            previousRevenue: 0,
            visits: 0,
            metrics: [],
            trend: [],
            services: [],
            records: [],
            hasEnoughData: false
        )
    }

    /// The headline comparison: "↑ 14 % nuo liepos".
    var revenueChange: Double? {
        guard previousRevenue > 0 else { return nil }
        return (revenue - previousRevenue) / previousRevenue
    }

    func revenueChangeText(now: Date = Date()) -> String? {
        guard let change = revenueChange, abs(change) >= 0.01 else { return nil }
        let arrow = change > 0 ? "↑" : "↓"
        let percent = Int((abs(change) * 100).rounded())
        switch period {
        case .thisMonth, .lastMonth:
            let offset = period == .thisMonth ? -1 : -2
            let previousMonth = AppDate.calendar.date(byAdding: .month, value: offset, to: now) ?? now
            return "\(arrow) \(percent) % nuo \(previousMonth.monthGenitiveText)"
        default:
            return "\(arrow) \(percent) % nuo praėjusio laikotarpio"
        }
    }
}
