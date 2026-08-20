import Foundation
import CoreLocation

/// Orders what a client sees, using what the app already knows about them.
///
/// The whole product principle lives in this file: preferences are **signals, not
/// restrictions**. Everything here re-orders lists — nothing removes a category, a
/// provider or an industry. A client whose profile says "hair" must still be able to
/// find a dentist, so the only thing their profile changes is what appears first.
nonisolated enum ClientPersonalization {

    /// Categories in the order this client should meet them.
    ///
    /// Interests first, then the industries the client has actually visited, then the
    /// rest of the platform — never a shortened list.
    static func categoryOrder(
        profile: ClientExperienceProfile?,
        history: [Booking],
        providers: [Provider]
    ) -> [ServiceCategory] {
        let interests = profile?.interestedCategories ?? []
        let visited = visitedCategories(history: history, providers: providers)

        var ordered: [ServiceCategory] = []
        for category in interests where !ordered.contains(category) { ordered.append(category) }
        for category in visited where !ordered.contains(category) { ordered.append(category) }
        for category in ServiceCategory.allCases where !ordered.contains(category) { ordered.append(category) }
        return ordered
    }

    /// The categories a client has actually booked in, most recent first.
    static func visitedCategories(history: [Booking], providers: [Provider]) -> [ServiceCategory] {
        var seen: [ServiceCategory] = []
        for booking in history {
            guard let category = providers.first(where: { $0.id == booking.providerID })?.category else { continue }
            if !seen.contains(category) { seen.append(category) }
        }
        return seen
    }

    /// Providers ranked for this client.
    ///
    /// Every provider passed in comes back out — only the order changes.
    static func rank(
        _ providers: [Provider],
        profile: ClientExperienceProfile?,
        favorites: Set<UUID>,
        history: [Booking],
        reference: CLLocationCoordinate2D?
    ) -> [Provider] {
        let interests = Set(profile?.interestedCategories ?? [])
        let visitedIDs = Set(history.map(\.providerID))

        return providers
            .map { provider -> (Provider, Double) in
                var score = 0.0
                if interests.contains(provider.category) { score += 30 }
                if favorites.contains(provider.id) { score += 25 }
                if visitedIDs.contains(provider.id) { score += 15 }
                score += (provider.rating - 4.0) * 10
                if let distance = distance(to: provider, from: reference) {
                    score -= (distance / 1000) * 6
                }
                return (provider, score)
            }
            .sorted { $0.1 > $1.1 }
            .map(\.0)
    }

    /// Places worth suggesting on the home screen.
    ///
    /// Deliberately excludes what the client already has in favorites and what they
    /// visited most recently, because those already have their own sections — a
    /// recommendation that repeats them is not a recommendation.
    static func recommendations(
        from providers: [Provider],
        profile: ClientExperienceProfile?,
        favorites: Set<UUID>,
        history: [Booking],
        reference: CLLocationCoordinate2D?,
        limit: Int = 4
    ) -> [Provider] {
        let recentIDs = Set(history.prefix(3).map(\.providerID))
        let pool = providers.filter { !favorites.contains($0.id) && !recentIDs.contains($0.id) }
        return Array(
            rank(pool, profile: profile, favorites: favorites, history: history, reference: reference)
                .prefix(limit)
        )
    }

    /// A short, honest explanation of why something is being recommended, or `nil` when
    /// there is no real reason beyond it being well rated.
    static func reason(for provider: Provider, profile: ClientExperienceProfile?) -> String? {
        if let profile, profile.interestedCategories.contains(provider.category) {
            return "Pagal Jūsų pasirinkimus · \(provider.category.title)"
        }
        if provider.rating >= 4.9 { return "Vienas geriausiai vertinamų" }
        return nil
    }

    static func distance(to provider: Provider, from reference: CLLocationCoordinate2D?) -> Double? {
        guard let reference, let coordinate = provider.coordinate else { return nil }
        let from = CLLocation(latitude: reference.latitude, longitude: reference.longitude)
        let to = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        return from.distance(from: to)
    }
}
