import Foundation

/// A loyalty step. Tiers are data, so a business can rename or add one without a
/// release, and benefits stay owner-defined rather than platform-defined.
nonisolated struct LoyaltyTier: Identifiable, Hashable, Codable {
    let id: UUID
    var name: String
    var pointsRequired: Int
    var benefits: [String]

    init(id: UUID = UUID(), name: String, pointsRequired: Int, benefits: [String] = []) {
        self.id = id
        self.name = name
        self.pointsRequired = pointsRequired
        self.benefits = benefits
    }
}

/// What earns points and how far they travel.
nonisolated struct LoyaltySettings: Hashable, Codable {
    var isEnabled: Bool
    var pointsPerEuroSpent: Double
    var pointsForReview: Int
    var pointsForReferral: Int
    var pointsForQuestionnaire: Int
    /// Whether points earned at one location can be spent at another.
    var isCrossLocation: Bool
    var tiers: [LoyaltyTier]

    static let standard = LoyaltySettings(
        isEnabled: false,
        pointsPerEuroSpent: 1,
        pointsForReview: 25,
        pointsForReferral: 100,
        pointsForQuestionnaire: 50,
        isCrossLocation: true,
        tiers: [
            LoyaltyTier(name: "Bronza", pointsRequired: 0),
            LoyaltyTier(name: "Sidabras", pointsRequired: 500),
            LoyaltyTier(name: "Auksas", pointsRequired: 1500),
            LoyaltyTier(name: "VIP", pointsRequired: 3000)
        ]
    )
}

/// How the owner slices the client base.
///
/// The rules behind each segment are not implemented yet; the vocabulary is fixed
/// first so campaigns, analytics and policies can all speak about the same groups.
nonisolated enum ClientSegment: String, CaseIterable, Identifiable, Hashable, Codable {
    case new
    case loyal
    case vip
    case atRisk
    case lost
    case highSpend
    case frequent
    case lowFrequency
    case productBuyer
    case neverBoughtProduct
    case referralChampion
    case needsRebooking
    case noShowRisk

    var id: String { rawValue }

    var title: String {
        switch self {
        case .new: "Nauji"
        case .loyal: "Lojalūs"
        case .vip: "VIP"
        case .atRisk: "Rizikoje"
        case .lost: "Prarasti"
        case .highSpend: "Daug išleidžiantys"
        case .frequent: "Dažni"
        case .lowFrequency: "Reti"
        case .productBuyer: "Perka prekes"
        case .neverBoughtProduct: "Nepirkę prekių"
        case .referralChampion: "Rekomenduoja"
        case .needsRebooking: "Laikas registruotis"
        case .noShowRisk: "Neatvykimo rizika"
        }
    }

    var symbolName: String {
        switch self {
        case .new: "sparkles"
        case .loyal: "heart"
        case .vip: "crown"
        case .atRisk: "exclamationmark.triangle"
        case .lost: "person.slash"
        case .highSpend: "eurosign.circle"
        case .frequent: "repeat"
        case .lowFrequency: "tortoise"
        case .productBuyer: "bag"
        case .neverBoughtProduct: "bag.badge.questionmark"
        case .referralChampion: "person.2.badge.plus"
        case .needsRebooking: "calendar.badge.clock"
        case .noShowRisk: "person.fill.xmark"
        }
    }
}
