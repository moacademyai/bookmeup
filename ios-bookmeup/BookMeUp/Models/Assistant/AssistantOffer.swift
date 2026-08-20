import Foundation

/// One bookable option the assistant found: a place, a service and real free times.
///
/// The times are not decoration — they come from the same availability logic the booking
/// sheet uses, so tapping one books that exact slot. If nothing is free in the window the
/// client asked for, the offer is not created at all rather than shown with invented times.
nonisolated struct AssistantOffer: Identifiable, Hashable {
    let id: UUID
    let provider: Provider
    let service: ServiceOffering
    /// Free times inside the requested window, soonest first.
    let slots: [Date]
    /// Metres from the client's reference location, when one is known.
    let distanceMetres: Double?
    /// Why this option is at the top — one short, honest reason.
    let reason: String?

    init(
        id: UUID = UUID(),
        provider: Provider,
        service: ServiceOffering,
        slots: [Date],
        distanceMetres: Double? = nil,
        reason: String? = nil
    ) {
        self.id = id
        self.provider = provider
        self.service = service
        self.slots = slots
        self.distanceMetres = distanceMetres
        self.reason = reason
    }

    /// The slot the primary action books — the earliest one that fits.
    var recommendedSlot: Date? { slots.first }

    var distanceText: String? {
        guard let distanceMetres else { return nil }
        return DistanceText.short(distanceMetres)
    }
}

/// Formats distances the way a person says them.
nonisolated enum DistanceText {
    static func short(_ metres: Double) -> String {
        if metres < 950 {
            return "\(Int((metres / 50).rounded() * 50)) m"
        }
        return "\(NumberText.oneDecimal(metres / 1000)) km"
    }
}
