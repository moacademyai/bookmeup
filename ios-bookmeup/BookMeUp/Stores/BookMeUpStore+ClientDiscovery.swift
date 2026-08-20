import Foundation
import CoreLocation
import MapKit

/// Client-side reads used by the assistant, the map and the visits screen.
///
/// Kept apart from the core store so the booking engine stays exactly as it was: nothing
/// here mutates anything, it only asks the existing records different questions.
extension BookMeUpStore {

    /// The signed-in client's visits, newest first, excluding cancellations.
    ///
    /// This is the history the assistant reasons over — "ten, kur paskutinį kartą
    /// lankiausi" has to mean a visit that actually happened.
    var clientVisitHistory: [Booking] {
        clientBookings
            .filter { $0.status != .cancelled }
            .sorted { $0.start > $1.start }
    }

    /// Visits already behind the client, newest first.
    var pastClientVisits: [Booking] {
        clientVisitHistory.filter { $0.end <= Date() }
    }

    /// Visits the client called off. Kept visible rather than hidden — a client looking
    /// for "what happened to that booking" should find it.
    var cancelledClientBookings: [Booking] {
        clientBookings
            .filter { $0.status == .cancelled }
            .sorted { $0.start > $1.start }
    }

    /// Places the client has been, most recent first, without repeats.
    func recentProviders(limit: Int = 3) -> [Provider] {
        var seen: [UUID] = []
        for booking in pastClientVisits where !seen.contains(booking.providerID) {
            seen.append(booking.providerID)
        }
        return seen.prefix(limit).compactMap { provider(with: $0) }
    }

    /// "Paskutinį kartą rugsėjo 4 d." — the line under a place the client already knows.
    func lastVisitText(with provider: Provider) -> String? {
        guard let last = pastClientVisits.first(where: { $0.providerID == provider.id }) else { return nil }
        return "Paskutinį kartą \(last.start.dayText)"
    }

    /// The client's most recent visit to a place, used to repeat a booking.
    func lastVisit(with provider: Provider) -> Booking? {
        pastClientVisits.first { $0.providerID == provider.id }
    }

    /// The client's loyalty standing, derived from their own completed visits.
    var loyaltyAccount: LoyaltyAccount {
        LoyaltyProgram.account(from: clientBookings)
    }

    /// Past visits the client has not reviewed yet — the only ones a review can be
    /// offered for.
    var reviewableVisits: [Booking] {
        pastClientVisits.filter { canReview($0) }
    }

    /// Providers matching a free-text search and an optional category, ranked for this
    /// client. Ranking personalises the order; the filter never hides an industry the
    /// client explicitly asked for.
    func discover(
        filter: DiscoveryFilter,
        query: String,
        profile: ClientExperienceProfile?,
        reference: CLLocationCoordinate2D?
    ) -> [Provider] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        let matches = providers
            .filter { provider in
                guard let category = filter.category else { return true }
                return provider.category == category
            }
            .filter { provider in
                guard !trimmed.isEmpty else { return true }
                let haystack = [
                    provider.name,
                    provider.specialistName,
                    provider.craft,
                    provider.district,
                    provider.address,
                    provider.category.title,
                    provider.services.map(\.name).joined(separator: " ")
                ].joined(separator: " ")
                return haystack.localizedStandardContains(trimmed)
            }

        return ClientPersonalization.rank(
            matches,
            profile: profile,
            favorites: favoriteProviderIDs,
            history: clientVisitHistory,
            reference: reference
        )
    }

    /// Businesses for a discovery surface, in the order the client asked for.
    ///
    /// The category is a filter; the sort is an order. Neither ever removes an industry
    /// the client did not choose — "Tau" is a ranking, not a cage.
    func businesses(
        category: ServiceCategory?,
        sort: DiscoverySort,
        profile: ClientExperienceProfile?,
        reference: CLLocationCoordinate2D?
    ) -> [Provider] {
        let matches = providers.filter { category == nil || $0.category == category }
        return DiscoveryRanking.sorted(
            matches,
            by: sort,
            reference: reference,
            profile: profile,
            favorites: favoriteProviderIDs,
            history: clientVisitHistory
        )
    }

    /// The businesses inside the part of the map the client is currently looking at.
    ///
    /// The map asks for a region rather than for everything, so the same call works
    /// unchanged when this becomes a server query: today it filters an in-memory list,
    /// tomorrow it sends the same bounding box to the backend. Nothing in the UI assumes
    /// the whole marketplace is loaded.
    func businesses(
        in region: MKCoordinateRegion,
        category: ServiceCategory?,
        limit: Int = 60
    ) -> [Provider] {
        let latitudeSpan = region.span.latitudeDelta / 2
        let longitudeSpan = region.span.longitudeDelta / 2

        let inside = providers.filter { provider in
            guard category == nil || provider.category == category else { return false }
            guard let coordinate = provider.coordinate else { return false }
            return abs(coordinate.latitude - region.center.latitude) <= latitudeSpan
                && abs(coordinate.longitude - region.center.longitude) <= longitudeSpan
        }

        // Closest to the middle of the view first, so a capped result set is the part of
        // the region the client is actually looking at.
        let centre = CLLocation(latitude: region.center.latitude, longitude: region.center.longitude)
        return inside
            .sorted { lhs, rhs in
                let left = lhs.coordinate.map { centre.distance(from: CLLocation(latitude: $0.latitude, longitude: $0.longitude)) } ?? .greatestFiniteMagnitude
                let right = rhs.coordinate.map { centre.distance(from: CLLocation(latitude: $0.latitude, longitude: $0.longitude)) } ?? .greatestFiniteMagnitude
                return left < right
            }
            .prefix(limit)
            .map { $0 }
    }
}
