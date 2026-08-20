import Foundation
import CoreLocation

/// Everything the assistant is allowed to know when answering.
///
/// Passed in rather than reached for, so the matching logic has no idea where a store,
/// a network call or a cache lives. A future server-side assistant receives the same
/// facts and returns the same reply type.
struct AssistantContext {
    let providers: [Provider]
    /// Personalisation signals. Preferences never filter anything out — they only move
    /// results up, which is why they live here next to history rather than in the query.
    let profile: ClientExperienceProfile?
    let favoriteProviderIDs: Set<UUID>
    /// The client's own past and upcoming visits, newest first.
    let history: [Booking]
    /// Where distances are measured from, when a location is known.
    let reference: CLLocationCoordinate2D?
    /// Real availability for a provider and service on one day.
    let availability: (Provider, ServiceOffering, Date) -> [Date]
}

/// Anything that can answer a client's request with bookable options.
///
/// The protocol is the seam between the app and whatever produces answers. Today that is
/// on-device matching over the bundled catalogue; tomorrow it is the BookMeUp booking
/// service. The UI only ever talks to this.
protocol AssistantService {
    func reply(to query: AssistantQuery, context: AssistantContext) async -> AssistantReply
}

/// On-device assistant used while the booking backend is not connected.
///
/// It does real work — it parses constraints, searches the real catalogue and reads real
/// availability — but only over the demo data bundled with the app, and it says so in
/// every reply through `AssistantDataSource.demoCatalogue`. No availability, price or
/// rating shown here is invented.
struct LocalAssistantService: AssistantService {

    func reply(to query: AssistantQuery, context: AssistantContext) async -> AssistantReply {
        let offers = search(query, context: context)
        return AssistantReply(
            text: message(for: query, offers: offers, context: context),
            query: query,
            offers: offers,
            refinements: refinements(for: query, offers: offers),
            source: .demoCatalogue
        )
    }

    // MARK: - Search

    private func search(_ query: AssistantQuery, context: AssistantContext) -> [AssistantOffer] {
        let days = candidateDays(for: query)

        let candidates: [AssistantOffer] = context.providers.compactMap { provider in
            guard matchesHardConstraints(provider, query: query) else { return nil }
            guard let service = service(of: provider, for: query) else { return nil }
            let slots = freeSlots(provider: provider, service: service, days: days, query: query, context: context)
            guard !slots.isEmpty else { return nil }
            return AssistantOffer(
                provider: provider,
                service: service,
                slots: Array(slots.prefix(3)),
                distanceMetres: distance(to: provider, from: context.reference),
                reason: nil
            )
        }

        let ranked = candidates
            .map { (offer: $0, score: score($0, query: query, context: context)) }
            .sorted { $0.score > $1.score }
            .prefix(query.limit)

        // The reason is written after ranking, because it explains the position.
        return ranked.map { annotate($0.offer, query: query, context: context) }
    }

    /// Hard constraints are the ones a client would consider broken if ignored: the
    /// industry, the price ceiling and the rating floor.
    private func matchesHardConstraints(_ provider: Provider, query: AssistantQuery) -> Bool {
        if let category = query.category, provider.category != category { return false }
        if let minRating = query.minRating, provider.rating < minRating { return false }
        if let maxPrice = query.maxPrice {
            guard provider.services.contains(where: { $0.price <= maxPrice }) else { return false }
        }
        if query.category == nil, let term = query.serviceTerm {
            let matchesService = provider.services.contains { $0.name.lowercased().contains(term.prefix(5)) }
            if !matchesService { return false }
        }
        return true
    }

    /// The cheapest service that satisfies the request, so a price ceiling is honoured
    /// by picking a service the client can actually afford rather than by hiding the place.
    private func service(of provider: Provider, for query: AssistantQuery) -> ServiceOffering? {
        var options = provider.services
        if let term = query.serviceTerm {
            let named = options.filter { $0.name.lowercased().contains(term.prefix(5)) }
            if !named.isEmpty { options = named }
        }
        if let maxPrice = query.maxPrice {
            options = options.filter { $0.price <= maxPrice }
        }
        return options.min { $0.price < $1.price }
    }

    /// The days to look at: the one the client named, or the next week.
    private func candidateDays(for query: AssistantQuery) -> [Date] {
        if let window = query.window {
            return [window.day]
        }
        return (0..<7).map { AppDate.time(9, 0, dayOffset: $0) }
    }

    private func freeSlots(
        provider: Provider,
        service: ServiceOffering,
        days: [Date],
        query: AssistantQuery,
        context: AssistantContext
    ) -> [Date] {
        days
            .flatMap { context.availability(provider, service, $0) }
            .filter { query.window?.contains($0) ?? true }
            .sorted()
    }

    // MARK: - Ranking

    /// Ranking is a weighted sum rather than a sort chain, so a slightly farther place
    /// with a much better rating can still win — which is what "geriausias variantas" means.
    private func score(_ offer: AssistantOffer, query: AssistantQuery, context: AssistantContext) -> Double {
        var score = 0.0

        score += (offer.provider.rating - 4.0) * (query.prefersTopRated ? 40 : 12)

        if let distance = offer.distanceMetres {
            let kilometres = distance / 1000
            score -= kilometres * (query.prefersNearby ? 12 : 4)
        }

        if query.prefersCheapest {
            score -= offer.service.price * 0.9
        } else {
            score -= offer.service.price * 0.15
        }

        // Sooner is better when someone asked for today.
        if let slot = offer.recommendedSlot {
            let hours = slot.timeIntervalSinceNow / 3600
            score -= max(hours, 0) * 0.3
        }

        // Personalisation: signals that lift, never filters that exclude.
        if context.favoriteProviderIDs.contains(offer.provider.id) {
            score += query.prefersKnownProviders ? 45 : 10
        }
        if context.history.contains(where: { $0.providerID == offer.provider.id }) {
            score += query.prefersKnownProviders ? 35 : 6
        }
        if let profile = context.profile, profile.interestedCategories.contains(offer.provider.category) {
            score += 8
        }
        if query.prefersNovelty, context.history.contains(where: { $0.providerID == offer.provider.id }) {
            score -= 25
        }

        return score
    }

    /// One short reason, and only when it is actually true of this result.
    private func annotate(_ offer: AssistantOffer, query: AssistantQuery, context: AssistantContext) -> AssistantOffer {
        var reason: String?
        if context.favoriteProviderIDs.contains(offer.provider.id) {
            reason = "Jūsų mėgstamiausias"
        } else if context.history.contains(where: { $0.providerID == offer.provider.id }) {
            reason = "Čia jau lankėtės"
        } else if query.prefersCheapest {
            reason = "Pigiausias variantas"
        } else if offer.provider.rating >= 4.9 {
            reason = "Vienas geriausiai vertinamų"
        } else if let distance = offer.distanceMetres, distance < 1200 {
            reason = "Visai netoli"
        }
        return AssistantOffer(
            id: offer.id,
            provider: offer.provider,
            service: offer.service,
            slots: offer.slots,
            distanceMetres: offer.distanceMetres,
            reason: reason
        )
    }

    private func distance(to provider: Provider, from reference: CLLocationCoordinate2D?) -> Double? {
        guard let reference, let coordinate = provider.coordinate else { return nil }
        let from = CLLocation(latitude: reference.latitude, longitude: reference.longitude)
        let to = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        return from.distance(from: to)
    }

    // MARK: - Wording

    private func message(for query: AssistantQuery, offers: [AssistantOffer], context: AssistantContext) -> String {
        guard !offers.isEmpty else {
            if query.window != nil {
                return "Šiam laikui laisvų vietų neradau. Pabandykime kitą dieną arba platesnį laiką."
            }
            if query.maxPrice != nil {
                return "Pagal šią kainą nieko neradau. Galiu paieškoti šiek tiek brangiau?"
            }
            return "Kol kas nieko tinkamo neradau. Pabandykite pasakyti kitaip — pavyzdžiui, paslaugą ir laiką."
        }

        if offers.count == 1 {
            return "Radau vieną tinkamą variantą."
        }
        return "Radau \(offers.count) \(LithuanianPlural.result(offers.count)). Geriausias — pirmas."
    }

    /// Only offer follow-ups that would actually change this result set.
    private func refinements(for query: AssistantQuery, offers: [AssistantOffer]) -> [AssistantRefinement] {
        guard !offers.isEmpty else { return [] }
        var options: [AssistantRefinement] = []
        if offers.contains(where: { $0.distanceMetres != nil }), !query.prefersNearby {
            options.append(.closer)
        }
        if offers.count > 1 || query.maxPrice == nil {
            options.append(.cheaper)
        }
        if offers.contains(where: { $0.provider.rating < 4.8 }) {
            options.append(.betterRated)
        }
        options.append(.more)
        return options
    }
}
