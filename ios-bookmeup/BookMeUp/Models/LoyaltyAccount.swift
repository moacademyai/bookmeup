import Foundation

/// Where the loyalty balance came from.
///
/// Until the loyalty backend exists, points are derived on the device from real completed
/// visits. That is a demonstration, not a production balance, and the UI has to say so —
/// a client must never be told they own something the platform cannot honour.
nonisolated enum LoyaltyDataSource: String, Codable, Hashable {
    case demoProgram
    case live

    var notice: String? {
        switch self {
        case .demoProgram: "Demonstracinė programa. Taškai apskaičiuoti iš Jūsų vizitų šiame įrenginyje."
        case .live: nil
        }
    }
}

/// A loyalty tier and what it takes to reach it.
nonisolated struct ClientLoyaltyTier: Identifiable, Hashable {
    let id: String
    let title: String
    /// Points needed to enter this tier.
    let threshold: Int
    let perk: String

    static let all: [ClientLoyaltyTier] = [
        ClientLoyaltyTier(id: "bronze", title: "Pradžia", threshold: 0, perk: "Taškai už kiekvieną vizitą"),
        ClientLoyaltyTier(id: "silver", title: "Sidabras", threshold: 500, perk: "Ankstyvos registracijos į populiarius laikus"),
        ClientLoyaltyTier(id: "gold", title: "Auksas", threshold: 1500, perk: "Gimtadienio dovana ir prioritetinė eilė")
    ]
}

/// One way to spend points.
nonisolated struct LoyaltyReward: Identifiable, Hashable {
    let id: String
    let title: String
    let detail: String
    let cost: Int
    let symbolName: String
}

/// A single points movement.
nonisolated struct LoyaltyEntry: Identifiable, Hashable {
    let id: UUID
    let title: String
    let detail: String
    let points: Int
    let date: Date
}

/// The client's standing in the loyalty program.
nonisolated struct LoyaltyAccount: Hashable {
    let points: Int
    let lifetimePoints: Int
    let history: [LoyaltyEntry]
    let source: LoyaltyDataSource

    var tier: ClientLoyaltyTier {
        ClientLoyaltyTier.all.last { lifetimePoints >= $0.threshold } ?? ClientLoyaltyTier.all[0]
    }

    var nextTier: ClientLoyaltyTier? {
        ClientLoyaltyTier.all.first { $0.threshold > lifetimePoints }
    }

    var pointsToNextTier: Int? {
        guard let nextTier else { return nil }
        return max(nextTier.threshold - lifetimePoints, 0)
    }

    /// 0…1 progress towards the next tier, or a full bar at the top tier.
    var tierProgress: Double {
        guard let nextTier else { return 1 }
        let floor = tier.threshold
        let span = Double(nextTier.threshold - floor)
        guard span > 0 else { return 1 }
        return min(max(Double(lifetimePoints - floor) / span, 0), 1)
    }

    /// "1 240" — grouped for readability, which is how a balance should be read.
    var pointsText: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = " "
        formatter.locale = Locale(identifier: "lt_LT")
        return formatter.string(from: NSNumber(value: points)) ?? "\(points)"
    }

    static let empty = LoyaltyAccount(points: 0, lifetimePoints: 0, history: [], source: .demoProgram)
}
