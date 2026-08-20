import Foundation

/// When a business is open on one weekday.
///
/// Stored as minutes since midnight rather than dates, because opening hours are a rule
/// that repeats — not an event on a particular day. `weekday` is ISO (1 = Monday), the
/// same convention the rest of the app already uses for shifts.
nonisolated struct OpeningHours: Codable, Hashable, Identifiable {
    let weekday: Int
    /// Minutes since midnight. `nil` on both means the business is closed that day.
    let opensMinute: Int?
    let closesMinute: Int?

    var id: Int { weekday }

    init(weekday: Int, opensMinute: Int?, closesMinute: Int?) {
        self.weekday = weekday
        self.opensMinute = opensMinute
        self.closesMinute = closesMinute
    }

    /// Convenience for whole-hour schedules: `OpeningHours(weekday: 1, from: 9, to: 19)`.
    init(weekday: Int, from openHour: Int, to closeHour: Int) {
        self.init(weekday: weekday, opensMinute: openHour * 60, closesMinute: closeHour * 60)
    }

    static func closed(weekday: Int) -> OpeningHours {
        OpeningHours(weekday: weekday, opensMinute: nil, closesMinute: nil)
    }

    var isClosed: Bool { opensMinute == nil || closesMinute == nil }

    /// "Pirmadienis"
    var weekdayText: String {
        switch weekday {
        case 1: "Pirmadienis"
        case 2: "Antradienis"
        case 3: "Trečiadienis"
        case 4: "Ketvirtadienis"
        case 5: "Penktadienis"
        case 6: "Šeštadienis"
        default: "Sekmadienis"
        }
    }

    /// "09:00–19:00" or "Nedirba".
    var rangeText: String {
        guard let opensMinute, let closesMinute else { return "Nedirba" }
        return "\(AppDate.timeText(minuteOfDay: opensMinute))–\(AppDate.timeText(minuteOfDay: closesMinute))"
    }

    func contains(minuteOfDay minute: Int) -> Bool {
        guard let opensMinute, let closesMinute else { return false }
        return minute >= opensMinute && minute < closesMinute
    }
}

nonisolated extension Array where Element == OpeningHours {
    /// The rule that applies to a given day.
    func entry(for date: Date) -> OpeningHours? {
        let weekday = AppDate.isoWeekday(of: date)
        return first { $0.weekday == weekday }
    }

    /// "Atidaryta iki 19:00", "Šiandien nedirba", or `nil` when there is no schedule.
    func statusText(at date: Date = Date()) -> String? {
        guard !isEmpty, let today = entry(for: date) else { return nil }
        guard let closesMinute = today.closesMinute, let opensMinute = today.opensMinute else {
            return "Šiandien nedirba"
        }
        let minute = AppDate.minuteOfDay(date)
        if minute < opensMinute {
            return "Atsidaro \(AppDate.timeText(minuteOfDay: opensMinute))"
        }
        if minute < closesMinute {
            return "Atidaryta iki \(AppDate.timeText(minuteOfDay: closesMinute))"
        }
        return "Šiandien jau uždaryta"
    }

    var isOpenNow: Bool {
        guard let today = entry(for: Date()) else { return false }
        return today.contains(minuteOfDay: AppDate.minuteOfDay(Date()))
    }
}
