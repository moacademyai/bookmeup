import Foundation
import CoreLocation

/// Turns a registered business address into map coordinates.
///
/// This is the missing half of "an owner types an address and the business appears on the
/// map". It resolves through Core Location, caches every result so the same address is
/// never geocoded twice, and — when the device is offline or the geocoder rate-limits —
/// falls back to the city centre, flagged as approximate rather than silently presented
/// as exact.
///
/// When business data moves to a backend, geocoding moves with it: this type is then only
/// a client-side cache in front of coordinates the server already stored.
actor AddressGeocoder {
    static let shared = AddressGeocoder()

    private let geocoder = CLGeocoder()
    private var cache: [String: BusinessAddress] = [:]
    private let defaults = UserDefaults.standard
    private let cacheKey = "bookmeup.geocode.v1"

    private init() {
        if let data = defaults.data(forKey: cacheKey),
           let stored = try? JSONDecoder().decode([String: BusinessAddress].self, from: data) {
            cache = stored
        }
    }

    /// Resolves an address, using the cache whenever possible.
    func resolve(_ location: BusinessAddress) async -> BusinessAddress {
        if location.isResolved { return location }

        let key = location.geocodingQuery
        if let cached = cache[key] { return cached }

        if let placemark = try? await geocoder.geocodeAddressString(key).first,
           let coordinate = placemark.location?.coordinate {
            let resolved = location.resolved(to: coordinate, isApproximate: false)
            remember(resolved, for: key)
            return resolved
        }

        guard let centre = CityGazetteer.centre(of: location.city) else { return location }
        let approximate = location.resolved(to: centre, isApproximate: true)
        remember(approximate, for: key)
        return approximate
    }

    private func remember(_ location: BusinessAddress, for key: String) {
        cache[key] = location
        guard let data = try? JSONEncoder().encode(cache) else { return }
        defaults.set(data, forKey: cacheKey)
    }
}

/// City centres used only when the geocoder cannot be reached.
///
/// Deliberately a coarse development fallback, not a location database: it exists so a
/// business registered in a city still lands in the right part of the country when the
/// simulator has no network, and every coordinate it produces is flagged approximate.
nonisolated enum CityGazetteer {
    private static let centres: [String: CLLocationCoordinate2D] = [
        "vilnius": CLLocationCoordinate2D(latitude: 54.6872, longitude: 25.2797),
        "kaunas": CLLocationCoordinate2D(latitude: 54.8985, longitude: 23.9036),
        "klaipėda": CLLocationCoordinate2D(latitude: 55.7033, longitude: 21.1443),
        "šiauliai": CLLocationCoordinate2D(latitude: 55.9333, longitude: 23.3167),
        "panevėžys": CLLocationCoordinate2D(latitude: 55.7333, longitude: 24.35),
        "alytus": CLLocationCoordinate2D(latitude: 54.3963, longitude: 24.0458),
        "marijampolė": CLLocationCoordinate2D(latitude: 54.5591, longitude: 23.3543)
    ]

    static func centre(of city: String) -> CLLocationCoordinate2D? {
        centres[city.folding(options: .caseInsensitive, locale: nil).lowercased()]
    }
}
