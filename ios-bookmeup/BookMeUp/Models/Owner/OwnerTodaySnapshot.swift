import Foundation

/// The salon's day in numbers, all derived from real records.
///
/// Nothing here is stored or invented — every field is computed from bookings,
/// attendance and schedules. When there is nothing to count, the value is zero and
/// the screen says so instead of showing a decorative figure.
nonisolated struct OwnerTodaySnapshot: Hashable {
    var revenue: Double
    var bookings: Int
    /// Booked minutes over available minutes, 0…1.
    var occupancy: Double
    var newClients: Int
    var returningClients: Int
    var cancellations: Int
    var noShows: Int
    var staffWorking: Int
    var staffTotal: Int

    static let empty = OwnerTodaySnapshot(
        revenue: 0,
        bookings: 0,
        occupancy: 0,
        newClients: 0,
        returningClients: 0,
        cancellations: 0,
        noShows: 0,
        staffWorking: 0,
        staffTotal: 0
    )

    var hasActivity: Bool { bookings > 0 || cancellations > 0 || noShows > 0 }

    var occupancyText: String { "\(Int((occupancy * 100).rounded()))%" }

    var staffText: String { "\(staffWorking)/\(staffTotal)" }
}

/// How loudly an item asks for attention.
nonisolated enum ActionSeverity: String, Hashable, Codable {
    case critical
    case attention
    case info
}

/// Something waiting for a decision.
///
/// Only real, checkable situations become items. Signals that need a backend the
/// product does not have yet (failed payouts, low stock, integration errors) have a
/// declared place in the module that will own them, not a fabricated row here.
nonisolated struct ActionRequiredItem: Identifiable, Hashable {
    let id: UUID
    let title: String
    let detail: String
    let symbolName: String
    let severity: ActionSeverity
    /// Where tapping it should go, when the destination already exists.
    let route: OwnerRoute?
    let bookingID: UUID?

    init(
        id: UUID = UUID(),
        title: String,
        detail: String,
        symbolName: String,
        severity: ActionSeverity,
        route: OwnerRoute? = nil,
        bookingID: UUID? = nil
    ) {
        self.id = id
        self.title = title
        self.detail = detail
        self.symbolName = symbolName
        self.severity = severity
        self.route = route
        self.bookingID = bookingID
    }
}

/// A stream of revenue the product recovers that would otherwise be lost.
///
/// This is BookMeUp's own scoreboard — an empty chair costs the owner money, and
/// each of these is a mechanism that fills it. Amounts stay nil until the mechanism
/// actually runs; the list exists so the owner can see what is coming.
nonisolated enum RevenueRecoverySource: String, CaseIterable, Identifiable, Hashable {
    case waitlist
    case fillMyGap
    case afterHours
    case aiFrontDesk
    case retention
    case noShowProtection

    var id: String { rawValue }

    var title: String {
        switch self {
        case .waitlist: "Laukiančiųjų sąrašas"
        case .fillMyGap: "Fill My Gap"
        case .afterHours: "Po darbo valandų"
        case .aiFrontDesk: "AI registratūra"
        case .retention: "Sugrąžinti klientai"
        case .noShowProtection: "Apsauga nuo neatvykimų"
        }
    }

    var detail: String {
        switch self {
        case .waitlist: "Atsilaisvinę laikai, užpildyti laukiančiais klientais."
        case .fillMyGap: "Tarpai dienoje, pasiūlyti tinkamiems klientams."
        case .afterHours: "Vizitai už įprasto grafiko ribų su priedu."
        case .aiFrontDesk: "Rezervacijos, kurias priėmė AI, kai niekas neatsiliepė."
        case .retention: "Klientai, grįžę po priminimo ar win-back."
        case .noShowProtection: "Avansai ir mokesčiai, padengę neatvykimus."
        }
    }

    var symbolName: String {
        switch self {
        case .waitlist: "person.badge.clock"
        case .fillMyGap: "square.split.1x2"
        case .afterHours: "moon.stars"
        case .aiFrontDesk: "sparkles"
        case .retention: "arrow.uturn.backward.circle"
        case .noShowProtection: "shield"
        }
    }
}
