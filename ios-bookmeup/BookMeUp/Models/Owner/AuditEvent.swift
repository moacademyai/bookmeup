import Foundation

/// Who performed an action. AI and the system are first-class actors on purpose —
/// an owner has to be able to tell an automated change from a human one.
nonisolated enum AuditActorType: String, CaseIterable, Identifiable, Hashable, Codable {
    case client
    case employee
    case owner
    case ai
    case system

    var id: String { rawValue }

    var title: String {
        switch self {
        case .client: "Klientas"
        case .employee: "Darbuotojas"
        case .owner: "Savininkas"
        case .ai: "AI"
        case .system: "Sistema"
        }
    }

    var symbolName: String {
        switch self {
        case .client: "person"
        case .employee: "briefcase"
        case .owner: "crown"
        case .ai: "sparkles"
        case .system: "gearshape"
        }
    }
}

nonisolated enum AuditAction: String, CaseIterable, Identifiable, Hashable, Codable {
    case bookingCreated
    case bookingMoved
    case bookingCancelled
    case bookingApproved
    case paymentTaken
    case refundIssued
    case giftCardIssued
    case permissionChanged
    case pricingChanged
    case scheduleChanged
    case inventoryChanged
    case clientRestricted
    case settingsChanged
    case aiAction

    var id: String { rawValue }

    var title: String {
        switch self {
        case .bookingCreated: "Sukurta rezervacija"
        case .bookingMoved: "Perkelta rezervacija"
        case .bookingCancelled: "Atšaukta rezervacija"
        case .bookingApproved: "Patvirtinta rezervacija"
        case .paymentTaken: "Priimtas mokėjimas"
        case .refundIssued: "Grąžinti pinigai"
        case .giftCardIssued: "Išduota dovanų kortelė"
        case .permissionChanged: "Pakeistos teisės"
        case .pricingChanged: "Pakeistos kainos"
        case .scheduleChanged: "Pakeistas grafikas"
        case .inventoryChanged: "Pakeistos atsargos"
        case .clientRestricted: "Apribotas klientas"
        case .settingsChanged: "Pakeisti nustatymai"
        case .aiAction: "AI veiksmas"
        }
    }
}

/// One line of history.
///
/// Records what happened, never the sensitive content itself: `summary` is written to
/// be safe to read. Entries are append-only by design — nothing in the product edits
/// them, which is the whole point of keeping them.
nonisolated struct AuditEvent: Identifiable, Hashable, Codable {
    let id: UUID
    let date: Date
    let actorName: String
    let actorType: AuditActorType
    let action: AuditAction
    let entityTitle: String
    let locationID: UUID?
    let summary: String

    init(
        id: UUID = UUID(),
        date: Date,
        actorName: String,
        actorType: AuditActorType,
        action: AuditAction,
        entityTitle: String,
        locationID: UUID? = nil,
        summary: String
    ) {
        self.id = id
        self.date = date
        self.actorName = actorName
        self.actorType = actorType
        self.action = action
        self.entityTitle = entityTitle
        self.locationID = locationID
        self.summary = summary
    }
}
