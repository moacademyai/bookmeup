import Foundation

/// Opening hours of one weekday. Minutes from midnight keep the model free of
/// time-zone assumptions — the location's own zone turns them into a real time.
nonisolated struct DayHours: Identifiable, Hashable, Codable {
    /// 1 = Monday … 7 = Sunday.
    let weekday: Int
    var isOpen: Bool
    var opensMinutes: Int
    var closesMinutes: Int

    var id: Int { weekday }

    var openMinutes: Int { isOpen ? max(closesMinutes - opensMinutes, 0) : 0 }

    var weekdayTitle: String {
        let names = ["Pirmadienis", "Antradienis", "Trečiadienis", "Ketvirtadienis",
                     "Penktadienis", "Šeštadienis", "Sekmadienis"]
        let index = min(max(weekday - 1, 0), names.count - 1)
        return names[index]
    }

    var weekdayShortTitle: String { String(weekdayTitle.prefix(2)) }

    var rangeText: String {
        guard isOpen else { return "Nedirbama" }
        return "\(Self.timeText(opensMinutes))–\(Self.timeText(closesMinutes))"
    }

    static func timeText(_ minutes: Int) -> String {
        String(format: "%02d:%02d", minutes / 60, minutes % 60)
    }
}

/// A week of opening hours. Special days, holidays and temporary closures are
/// exceptions layered on top of this — the regular week stays the baseline.
nonisolated struct OperatingHours: Hashable, Codable {
    var days: [DayHours]

    static func standard(opens: Int = 9 * 60, closes: Int = 19 * 60, closedWeekdays: Set<Int> = [7]) -> OperatingHours {
        OperatingHours(days: (1...7).map { weekday in
            DayHours(
                weekday: weekday,
                isOpen: !closedWeekdays.contains(weekday),
                opensMinutes: opens,
                closesMinutes: closes
            )
        })
    }

    func day(_ weekday: Int) -> DayHours? {
        days.first { $0.weekday == weekday }
    }

    /// Minutes the location is open on this date — the denominator of occupancy.
    func openMinutes(on date: Date) -> Int {
        let weekday = AppDate.isoWeekday(of: date)
        return day(weekday)?.openMinutes ?? 0
    }

    var summaryText: String {
        let open = days.filter(\.isOpen)
        guard let first = open.first else { return "Darbo laikas nenustatytas" }
        let sameEveryDay = open.allSatisfy {
            $0.opensMinutes == first.opensMinutes && $0.closesMinutes == first.closesMinutes
        }
        return sameEveryDay
            ? "\(open.count) d. per savaitę · \(first.rangeText)"
            : "\(open.count) d. per savaitę · kintantis grafikas"
    }
}

/// A physical place of work. Multi-location from day one: every operational record
/// points at the location it belongs to, so a second address needs no migration.
nonisolated struct BusinessLocation: Identifiable, Hashable, Codable {
    let id: UUID
    let businessID: UUID
    var name: String
    var address: String
    var city: String
    var countryCode: String
    var currencyCode: String
    var language: String
    var timeZoneIdentifier: String
    var phone: String
    var hours: OperatingHours
    var isActive: Bool

    init(
        id: UUID = UUID(),
        businessID: UUID,
        name: String,
        address: String,
        city: String,
        countryCode: String = "LT",
        currencyCode: String = "EUR",
        language: String = "lt",
        timeZoneIdentifier: String = "Europe/Vilnius",
        phone: String = "",
        hours: OperatingHours = .standard(),
        isActive: Bool = true
    ) {
        self.id = id
        self.businessID = businessID
        self.name = name
        self.address = address
        self.city = city
        self.countryCode = countryCode
        self.currencyCode = currencyCode
        self.language = language
        self.timeZoneIdentifier = timeZoneIdentifier
        self.phone = phone
        self.hours = hours
        self.isActive = isActive
    }

    var timeZone: TimeZone { TimeZone(identifier: timeZoneIdentifier) ?? .current }

    var addressText: String { "\(address), \(city)" }
}
