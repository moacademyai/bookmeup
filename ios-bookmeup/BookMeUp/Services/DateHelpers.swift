import Foundation

nonisolated enum AppDate {
    static let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = Locale(identifier: "lt_LT")
        calendar.firstWeekday = 2
        return calendar
    }()

    /// A date at `hour:minute`, offset by whole days from today.
    static func time(_ hour: Int, _ minute: Int = 0, dayOffset: Int = 0) -> Date {
        let base = calendar.date(byAdding: .day, value: dayOffset, to: Date()) ?? Date()
        return calendar.date(bySettingHour: hour, minute: minute, second: 0, of: base) ?? base
    }

    static func startOfDay(_ date: Date) -> Date { calendar.startOfDay(for: date) }

    /// 1 = Monday … 7 = Sunday, matching how working hours and shifts are stored.
    static func isoWeekday(of date: Date) -> Int {
        let weekday = calendar.component(.weekday, from: date)
        return weekday == 1 ? 7 : weekday - 1
    }

    static func isSameDay(_ lhs: Date, _ rhs: Date) -> Bool {
        calendar.isDate(lhs, inSameDayAs: rhs)
    }

    /// Minutes since midnight — how time windows are compared.
    static func minuteOfDay(_ date: Date) -> Int {
        let parts = calendar.dateComponents([.hour, .minute], from: date)
        return (parts.hour ?? 0) * 60 + (parts.minute ?? 0)
    }

    /// "15:30" from minutes since midnight.
    static func timeText(minuteOfDay minute: Int) -> String {
        String(format: "%02d:%02d", minute / 60, minute % 60)
    }
}

nonisolated extension Date {
    private static let ltLocale = Locale(identifier: "lt_LT")

    /// "10:30"
    var timeText: String {
        let formatter = DateFormatter()
        formatter.locale = Self.ltLocale
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: self)
    }

    /// "Rugsėjo 4 d."
    var dayText: String {
        let formatter = DateFormatter()
        formatter.locale = Self.ltLocale
        formatter.dateFormat = "LLLL d 'd.'"
        return formatter.string(from: self).capitalizedFirst
    }

    /// "Antradienis, rugsėjo 3 d."
    var weekdayLongText: String {
        let formatter = DateFormatter()
        formatter.locale = Self.ltLocale
        formatter.dateFormat = "EEEE, LLLL d 'd.'"
        return formatter.string(from: self).capitalizedFirst
    }

    /// "Antr."
    var weekdayShortText: String {
        let formatter = DateFormatter()
        formatter.locale = Self.ltLocale
        formatter.dateFormat = "EEE"
        return formatter.string(from: self).capitalizedFirst
    }

    var dayNumberText: String {
        let formatter = DateFormatter()
        formatter.locale = Self.ltLocale
        formatter.dateFormat = "d"
        return formatter.string(from: self)
    }

    /// Relative, human phrasing: "Šiandien, 16:15", "Rytoj, 10:30", "Rugsėjo 4 d., 11:00".
    var relativeDayTimeText: String {
        if AppDate.calendar.isDateInToday(self) { return "Šiandien, \(timeText)" }
        if AppDate.calendar.isDateInTomorrow(self) { return "Rytoj, \(timeText)" }
        return "\(dayText), \(timeText)"
    }

    var relativeDayText: String {
        if AppDate.calendar.isDateInToday(self) { return "Šiandien" }
        if AppDate.calendar.isDateInTomorrow(self) { return "Rytoj" }
        return dayText
    }

    /// "Rugpjūtis" — the month standing on its own.
    var monthText: String {
        let formatter = DateFormatter()
        formatter.locale = Self.ltLocale
        formatter.dateFormat = "LLLL"
        return formatter.string(from: self).capitalizedFirst
    }

    /// "Rugp." — fits under a chart column.
    var monthShortText: String {
        let formatter = DateFormatter()
        formatter.locale = Self.ltLocale
        formatter.dateFormat = "LLL"
        return formatter.string(from: self).capitalizedFirst
    }

    /// "liepos" — the form used inside a sentence, as in "nuo liepos".
    var monthGenitiveText: String {
        let formatter = DateFormatter()
        formatter.locale = Self.ltLocale
        formatter.dateFormat = "MMMM"
        return formatter.string(from: self).lowercased()
    }

    /// "20 rugp." — compact date for dense history rows.
    var shortDayMonthText: String {
        let formatter = DateFormatter()
        formatter.locale = Self.ltLocale
        formatter.dateFormat = "d MMM"
        return formatter.string(from: self)
    }

    /// Whole days between this date and now, always positive.
    var daysAgo: Int {
        let from = AppDate.startOfDay(self)
        let to = AppDate.startOfDay(Date())
        return abs(AppDate.calendar.dateComponents([.day], from: from, to: to).day ?? 0)
    }

    /// "Šiandien", "Vakar", "Prieš 23 d." — recency the specialist can act on,
    /// with the exact date left for the details.
    var recencyText: String {
        if AppDate.calendar.isDateInToday(self) { return "Šiandien" }
        if AppDate.calendar.isDateInYesterday(self) { return "Vakar" }
        let days = daysAgo
        if days < 31 { return "Prieš \(days) d." }
        let months = max(days / 30, 1)
        return "Prieš \(months) \(LithuanianPlural.month(months))"
    }

    /// Days remaining until this date, counted in calendar days.
    var daysFromNow: Int {
        let from = AppDate.startOfDay(Date())
        let to = AppDate.startOfDay(self)
        return AppDate.calendar.dateComponents([.day], from: from, to: to).day ?? 0
    }
}

nonisolated extension String {
    var capitalizedFirst: String {
        guard let first else { return self }
        return first.uppercased() + dropFirst()
    }
}
