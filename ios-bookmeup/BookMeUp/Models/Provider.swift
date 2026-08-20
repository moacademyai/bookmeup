import Foundation
import CoreLocation

/// A business on BookMeUp, together with the specialist a client books with.
///
/// This is the record discovery is built on: it carries everything the map, the profile,
/// the reviews and the booking flow need, so no screen has to invent data or be told
/// where to draw a pin. Its position comes from `location`, which is derived from the
/// registered address — a business becomes discoverable because it has a real address,
/// not because someone placed a marker for it.
nonisolated struct Provider: Identifiable, Codable, Hashable {
    let id: UUID
    let name: String
    let specialistName: String
    let craft: String
    let category: ServiceCategory
    /// The neighbourhood, used as a human label when no distance is available.
    let district: String
    /// The registered address and, once geocoded, its coordinates.
    var location: BusinessAddress
    let rating: Double
    let visitCount: Int
    /// The card image, and the first photo of the gallery when none are provided.
    let imageName: String
    let about: String
    let services: [ServiceOffering]
    let nextSlot: Date
    /// Published reviews. `nil` means "no review data", which is different from zero and
    /// is why the UI hides the count instead of printing 0.
    let reviewCount: Int?
    /// Business phone, when the business shared one.
    let phone: String?
    /// Gallery photos, in the order the business wants them shown.
    let photoNames: [String]
    /// Weekly opening hours. Empty means the business has not published a schedule.
    let openingHours: [OpeningHours]

    init(
        id: UUID = UUID(),
        name: String,
        specialistName: String,
        craft: String,
        category: ServiceCategory,
        district: String,
        location: BusinessAddress,
        rating: Double,
        visitCount: Int,
        imageName: String,
        about: String,
        services: [ServiceOffering],
        nextSlot: Date,
        reviewCount: Int? = nil,
        phone: String? = nil,
        photoNames: [String] = [],
        openingHours: [OpeningHours] = []
    ) {
        self.id = id
        self.name = name
        self.specialistName = specialistName
        self.craft = craft
        self.category = category
        self.district = district
        self.location = location
        self.rating = rating
        self.visitCount = visitCount
        self.imageName = imageName
        self.about = about
        self.services = services
        self.nextSlot = nextSlot
        self.reviewCount = reviewCount
        self.phone = phone
        self.photoNames = photoNames
        self.openingHours = openingHours
    }

    /// "Respublikos g. 1, Panevėžys"
    var address: String { location.formatted }

    var coordinate: CLLocationCoordinate2D? { location.coordinate }

    /// Photos for the profile gallery, never empty so the header always has something.
    var gallery: [String] {
        photoNames.isEmpty ? [imageName] : photoNames
    }

    var ratingText: String {
        String(format: "%.1f", rating).replacingOccurrences(of: ".", with: ",")
    }

    var trustLine: String { "\(ratingText) · \(visitCount) apsilankymai" }

    /// "4,9 · 312 atsiliepimų", or just the rating when there is no review data.
    var reviewLine: String {
        guard let reviewCount else { return ratingText }
        return "\(ratingText) · \(reviewCount) \(LithuanianPlural.review(reviewCount))"
    }

    /// "312 atsiliepimų", or `nil` when the business has no review data yet.
    var reviewCountText: String? {
        guard let reviewCount else { return nil }
        return "\(reviewCount) \(LithuanianPlural.review(reviewCount))"
    }

    var cheapestService: ServiceOffering? {
        services.min { $0.price < $1.price }
    }

    /// The price band shown on cards. Derived from the real catalogue rather than
    /// stored, so it can never drift away from what the services actually cost.
    var priceLevel: Int {
        guard !services.isEmpty else { return 2 }
        let average = services.reduce(0) { $0 + $1.price } / Double(services.count)
        return switch average {
        case ..<40: 1
        case ..<80: 2
        default: 3
        }
    }

    var priceLevelText: String {
        String(repeating: "€", count: priceLevel)
    }

    /// The cheapest service matching a spoken service name, or the cheapest overall.
    func service(matching text: String) -> ServiceOffering? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return cheapestService }
        return services.first { $0.name.localizedStandardContains(trimmed) } ?? cheapestService
    }

    /// A copy that knows where it is. Used after the address has been geocoded.
    func withLocation(_ resolved: BusinessAddress) -> Provider {
        var copy = self
        copy.location = resolved
        return copy
    }
}
