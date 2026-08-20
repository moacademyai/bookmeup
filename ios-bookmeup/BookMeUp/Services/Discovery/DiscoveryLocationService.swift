import Foundation
import CoreLocation
import Observation

/// Where "aplink mane" is measured from.
///
/// Distance is only honest when it is measured from somewhere real. For BookMeUp that
/// means one thing: distance is the distance from the client. When the device position is
/// unknown, `distanceReference` is `nil` and every surface simply shows no distance —
/// never a distance from a city centre dressed up as "near you".
///
/// `mapCentre` is a different question: the map has to open somewhere even with no
/// permission, so it falls back to the market centre and lets the client explore from
/// there.
@Observable
final class DiscoveryLocationService: NSObject, CLLocationManagerDelegate {
    /// The coordinate distances are measured from — device position when available.
    private(set) var reference: CLLocationCoordinate2D
    private(set) var authorization: CLAuthorizationStatus
    /// True while `reference` is the city centre rather than the device.
    private(set) var isUsingFallback: Bool = true

    private let manager = CLLocationManager()

    /// The market centre used until the device reports a position. A constant, not a
    /// fabricated user location.
    static let fallbackCoordinate = CLLocationCoordinate2D(latitude: 54.6872, longitude: 25.2797)

    override init() {
        reference = Self.fallbackCoordinate
        authorization = manager.authorizationStatus
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        if authorization == .authorizedWhenInUse || authorization == .authorizedAlways {
            manager.startUpdatingLocation()
        }
    }

    var canAskForPermission: Bool { authorization == .notDetermined }

    var isDenied: Bool { authorization == .denied || authorization == .restricted }

    /// True when the device position is known, which is the only case where a distance
    /// can be shown.
    var hasPreciseLocation: Bool { !isUsingFallback }

    /// The point distances are measured from, or `nil` when there is nothing honest to
    /// measure from. Every "350 m" in the app comes from here.
    var distanceReference: CLLocationCoordinate2D? {
        isUsingFallback ? nil : reference
    }

    /// Where the map opens when it has nothing better to go on.
    var mapCentre: CLLocationCoordinate2D { reference }

    func requestPermission() {
        guard canAskForPermission else { return }
        manager.requestWhenInUseAuthorization()
    }

    /// Asks for a fresh fix. Used by the recenter button, which is the one place a
    /// client explicitly asks to be located.
    func refresh() {
        guard authorization == .authorizedWhenInUse || authorization == .authorizedAlways else { return }
        manager.requestLocation()
    }

    // MARK: - CLLocationManagerDelegate

    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus
        Task { @MainActor in
            self.authorization = status
            if status == .authorizedWhenInUse || status == .authorizedAlways {
                manager.startUpdatingLocation()
            } else {
                self.reference = Self.fallbackCoordinate
                self.isUsingFallback = true
            }
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let coordinate = locations.last?.coordinate else { return }
        Task { @MainActor in
            self.reference = coordinate
            self.isUsingFallback = false
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        // A failed fix is not an error worth showing: the fallback already covers it.
        Task { @MainActor in
            self.isUsingFallback = true
        }
    }
}
