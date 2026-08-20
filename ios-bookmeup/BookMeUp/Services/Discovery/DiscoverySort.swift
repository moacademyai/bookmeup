import Foundation
import CoreLocation

/// How the client wants the list ordered.
///
/// Deliberately two options, not ten. Everything else a client might want — "cheaper",
/// "tonight", "4,8+" — is a question for the assistant, not a control on a browse screen.
nonisolated enum DiscoverySort: String, CaseIterable, Identifiable {
    /// Personalised order: this client's interests, favorites and history first.
    case forYou
    case nearest
    case topRated

    var id: String { rawValue }

    var title: String {
        switch self {
        case .forYou: "Tau"
        case .nearest: "Arčiausiai"
        case .topRated: "Geriausiai įvertinti"
        }
    }

    var symbolName: String {
        switch self {
        case .forYou: "sparkles"
        case .nearest: "location"
        case .topRated: "star"
        }
    }
}

/// Deterministic ordering of businesses. No AI, no randomness — the same input always
/// produces the same list, which is what makes a sort control trustworthy.
nonisolated enum DiscoveryRanking {

    /// Confidence-weighted rating.
    ///
    /// A 5,0 from one review is not better than a 4,9 from eight hundred, so the score
    /// pulls a rating towards the platform average until enough reviews back it up. This
    /// is the standard Bayesian shrinkage: with `confidenceFloor` reviews of weight, a
    /// business with few reviews sits closer to the mean than to its own average.
    static let confidenceFloor = 40.0
    static let platformAverage = 4.6

    static func score(for provider: Provider) -> Double {
        let count = Double(provider.reviewCount ?? provider.visitCount)
        return (count * provider.rating + confidenceFloor * platformAverage) / (count + confidenceFloor)
    }

    /// Applies a sort to an already-filtered set of businesses.
    ///
    /// Businesses with no known position keep their place at the end of a distance sort
    /// rather than being dropped — an unmapped business is still bookable.
    static func sorted(
        _ providers: [Provider],
        by sort: DiscoverySort,
        reference: CLLocationCoordinate2D?,
        profile: ClientExperienceProfile?,
        favorites: Set<UUID>,
        history: [Booking]
    ) -> [Provider] {
        switch sort {
        case .forYou:
            return ClientPersonalization.rank(
                providers,
                profile: profile,
                favorites: favorites,
                history: history,
                reference: reference
            )
        case .nearest:
            return providers.sorted { lhs, rhs in
                let left = ClientPersonalization.distance(to: lhs, from: reference) ?? .greatestFiniteMagnitude
                let right = ClientPersonalization.distance(to: rhs, from: reference) ?? .greatestFiniteMagnitude
                if left == right { return score(for: lhs) > score(for: rhs) }
                return left < right
            }
        case .topRated:
            return providers.sorted { lhs, rhs in
                let left = score(for: lhs)
                let right = score(for: rhs)
                if left == right { return (lhs.reviewCount ?? 0) > (rhs.reviewCount ?? 0) }
                return left > right
            }
        }
    }
}
