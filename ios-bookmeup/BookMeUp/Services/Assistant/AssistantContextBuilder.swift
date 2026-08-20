import Foundation

/// Collects everything the assistant is allowed to use into one `AssistantContext`.
///
/// Views build the context here rather than assembling it inline, so there is exactly one
/// definition of what the assistant knows — the catalogue, the client's preferences,
/// their favorites, their history, and where they are. When a backend assistant arrives,
/// this is the payload it receives.
enum AssistantContextBuilder {

    static func make(store: BookMeUpStore, location: DiscoveryLocationService) -> AssistantContext {
        AssistantContext(
            providers: store.providers,
            profile: store.signedInExperienceProfile,
            favoriteProviderIDs: store.favoriteProviderIDs,
            history: store.clientVisitHistory,
            // `nil` when the device position is unknown, so the assistant never prints a
            // distance it cannot honestly measure.
            reference: location.distanceReference,
            availability: { provider, service, day in
                store.availableSlots(for: provider, on: day, durationMinutes: service.durationMinutes)
            }
        )
    }
}
