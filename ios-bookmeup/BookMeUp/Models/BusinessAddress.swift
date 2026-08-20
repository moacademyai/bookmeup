import Foundation
import CoreLocation

/// A business address and, once it has been resolved, where it actually is.
///
/// This is the piece that lets the map stop being a set of hand-placed pins. A business
/// is registered with a street and a city — the only thing an owner can reasonably be
/// asked to type — and the coordinate is *derived* from that address by the geocoder and
/// cached. Nothing in the discovery layer ever asks a human to position a marker.
///
/// `isApproximate` is what keeps that honest: a coordinate that came from a real geocode
/// is precise, while a coordinate derived from the city alone is explicitly marked so the
/// UI never claims a doorstep-accurate distance it does not have.
nonisolated struct BusinessAddress: Codable, Hashable {
    /// "Respublikos g. 1"
    let street: String
    /// "Panevėžys"
    let city: String
    let countryCode: String

    /// Resolved position. `nil` until the address has been geocoded.
    var latitude: Double?
    var longitude: Double?
    /// True when the position came from the city rather than the exact street.
    var isApproximate: Bool

    init(
        street: String,
        city: String,
        countryCode: String = "LT",
        latitude: Double? = nil,
        longitude: Double? = nil,
        isApproximate: Bool = false
    ) {
        self.street = street
        self.city = city
        self.countryCode = countryCode
        self.latitude = latitude
        self.longitude = longitude
        self.isApproximate = isApproximate
    }

    /// "Respublikos g. 1, Panevėžys"
    var formatted: String {
        [street, city].filter { !$0.isEmpty }.joined(separator: ", ")
    }

    /// What the geocoder is asked to resolve.
    var geocodingQuery: String {
        [street, city, countryName].filter { !$0.isEmpty }.joined(separator: ", ")
    }

    private var countryName: String {
        Locale(identifier: "en_US").localizedString(forRegionCode: countryCode) ?? ""
    }

    var coordinate: CLLocationCoordinate2D? {
        guard let latitude, let longitude else { return nil }
        return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    var isResolved: Bool { coordinate != nil }

    /// A copy carrying a resolved position.
    func resolved(to coordinate: CLLocationCoordinate2D, isApproximate: Bool) -> BusinessAddress {
        BusinessAddress(
            street: street,
            city: city,
            countryCode: countryCode,
            latitude: coordinate.latitude,
            longitude: coordinate.longitude,
            isApproximate: isApproximate
        )
    }
}
