import Foundation

/// Everything the specialist should know about a client in one glance.
///
/// Every value is derived from the client's real booking and attendance records —
/// nothing here is stored or written by a screen.
nonisolated struct ClientOverview: Hashable {
    let totalVisits: Int
    let firstVisit: Date?
    let lastVisit: Date?
    let nextVisit: Date?
    let averageVisitsPerMonth: Double
    /// Mean gap between consecutive past visits; nil until there are at least two.
    let averageDaysBetweenVisits: Double?
    let noShowCount: Int
    let lateCancellationCount: Int

    static let empty = ClientOverview(
        totalVisits: 0,
        firstVisit: nil,
        lastVisit: nil,
        nextVisit: nil,
        averageVisitsPerMonth: 0,
        averageDaysBetweenVisits: nil,
        noShowCount: 0,
        lateCancellationCount: 0
    )

    var totalVisitsText: String { "\(totalVisits)" }

    var averageVisitsPerMonthText: String {
        guard totalVisits > 0 else { return "—" }
        return NumberText.oneDecimal(averageVisitsPerMonth)
    }

    var lastVisitText: String { lastVisit?.dayText ?? "Dar nesilankė" }

    /// Whole days since the last completed visit.
    var daysSinceLastVisit: Int? { lastVisit?.daysAgo }

    /// "23 d." — recency a specialist can act on. The exact date lives in the history.
    var sinceLastVisitText: String {
        guard let days = daysSinceLastVisit else { return "—" }
        return days == 0 ? "Šiandien" : "\(days) d."
    }

    /// When this client would normally be due back, from their own rhythm rather than
    /// one interval applied to everybody.
    ///
    /// Someone who returns every 14 days and someone who returns every 45 must not
    /// share a reminder trigger — this is the value a future re-engagement job reads.
    var expectedReturnDate: Date? {
        guard let lastVisit, let interval = averageDaysBetweenVisits else { return nil }
        return AppDate.calendar.date(byAdding: .day, value: Int(interval.rounded()), to: lastVisit)
    }

    /// True when this client has no visit booked and has passed the point they would
    /// normally have come back.
    ///
    /// Nothing is sent from here: this is the state a reminder feature will read once
    /// there is a backend to send from.
    var isDueToReturn: Bool {
        guard nextVisit == nil, let expected = expectedReturnDate else { return false }
        return expected <= Date()
    }

    var averageGapText: String {
        guard let days = averageDaysBetweenVisits else { return "—" }
        return "\(Int(days.rounded())) d."
    }

    var missedCount: Int { noShowCount + lateCancellationCount }

    /// Short, honest phrasing of the missed visits.
    var attendanceText: String {
        guard noShowCount > 0 else { return "Nėra praleistų vizitų" }
        return "\(noShowCount) \(LithuanianPlural.visit(noShowCount))"
    }

    /// Late cancellations are kept as a separate, softer line.
    var lateCancellationText: String? {
        guard lateCancellationCount > 0 else { return nil }
        return "\(lateCancellationCount) \(LithuanianPlural.lateCancellation(lateCancellationCount))"
    }

    /// Same rule the booking engine uses — read from this client's real history.
    var requiresBookingApproval: Bool {
        BookingApprovalPolicy.requiresApproval(noShowCount: noShowCount)
    }

    /// Explains, without drama, what the missed visits change for this client.
    var approvalNoteText: String? {
        requiresBookingApproval ? "Naujoms rezervacijoms reikalingas patvirtinimas" : nil
    }
}

/// Lithuanian plural forms: 1 → singular, 2–9 → plural, 0 and 10–20 → genitive.
nonisolated enum LithuanianPlural {
    static func visit(_ count: Int) -> String {
        switch form(count) {
        case .one: "praleistas vizitas"
        case .few: "praleisti vizitai"
        case .many: "praleistų vizitų"
        }
    }

    static func lateCancellation(_ count: Int) -> String {
        switch form(count) {
        case .one: "vėlyvas atšaukimas"
        case .few: "vėlyvi atšaukimai"
        case .many: "vėlyvų atšaukimų"
        }
    }

    static func cancelledVisit(_ count: Int) -> String {
        switch form(count) {
        case .one: "atšauktas vizitas"
        case .few: "atšaukti vizitai"
        case .many: "atšauktų vizitų"
        }
    }

    static func visitPlain(_ count: Int) -> String {
        switch form(count) {
        case .one: "vizitas"
        case .few: "vizitai"
        case .many: "vizitų"
        }
    }

    static func month(_ count: Int) -> String {
        switch form(count) {
        case .one: "mėn."
        case .few: "mėn."
        case .many: "mėn."
        }
    }

    static func client(_ count: Int) -> String {
        switch form(count) {
        case .one: "klientas"
        case .few: "klientai"
        case .many: "klientų"
        }
    }

    static func review(_ count: Int) -> String {
        switch form(count) {
        case .one: "atsiliepimas"
        case .few: "atsiliepimai"
        case .many: "atsiliepimų"
        }
    }

    static func year(_ count: Int) -> String {
        switch form(count) {
        case .one: "metai"
        case .few: "metai"
        case .many: "metų"
        }
    }

    static func freeSlot(_ count: Int) -> String {
        switch form(count) {
        case .one: "laisvas laikas"
        case .few: "laisvi laikai"
        case .many: "laisvų laikų"
        }
    }

    static func result(_ count: Int) -> String {
        switch form(count) {
        case .one: "variantas"
        case .few: "variantai"
        case .many: "variantų"
        }
    }

    private enum Form { case one, few, many }

    private static func form(_ count: Int) -> Form {
        let lastTwo = count % 100
        if lastTwo >= 11 && lastTwo <= 19 { return .many }
        switch count % 10 {
        case 1: return .one
        case 0: return .many
        default: return .few
        }
    }
}

/// Number formatting that follows the Lithuanian locale (decimal comma).
nonisolated enum NumberText {
    private static let oneDecimalFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.locale = Locale(identifier: "lt_LT")
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 1
        formatter.maximumFractionDigits = 1
        return formatter
    }()

    static func oneDecimal(_ value: Double) -> String {
        oneDecimalFormatter.string(from: NSNumber(value: value)) ?? "\(value)"
    }
}
