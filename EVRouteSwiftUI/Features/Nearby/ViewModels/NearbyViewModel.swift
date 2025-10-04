import Foundation
import CoreLocation
import MapKit
import Combine

@MainActor
final class NearbyViewModel: ObservableObject {
    @Published var isLoading = false
    @Published var error: Error?
    @Published var stations: [NearbyStation] = []
    @Published var selectedStation: NearbyStation?
    @Published var userLocation: CLLocationCoordinate2D?

    private let locationManager = SimpleLocationManager.shared

    func requestLocationAndCenter() {
        locationManager.requestLocationIfNeeded()
        // Snapshot current location if available; caller can observe via KVO if needed
        if let loc = locationManager.currentLocation?.coordinate {
            userLocation = loc
        } else {
            // No immediate location; keep nil, UI can default region
        }
    }

    func fetchNearby(radiusKm: Double) async {
        error = nil
        var resolved: CLLocationCoordinate2D? = locationManager.currentLocation?.coordinate ?? userLocation
        if resolved == nil {
            // Try to obtain a fresh fix quickly
            locationManager.requestLocationIfNeeded()
            for _ in 0..<10 {
                try? await Task.sleep(nanoseconds: 150_000_000) // 150ms, total ~1.5s
                if let c = locationManager.currentLocation?.coordinate {
                    resolved = c
                    break
                }
            }
        }
        guard let loc = resolved else { error = EVLocationError.locationNotAvailable; return }

        isLoading = true
        defer { isLoading = false }

        do {
            let results = try await NearbyStationsService.shared.fetchNearbyStations(latitude: loc.latitude, longitude: loc.longitude, radiusKm: radiusKm)
            // Sort: higher kW first, fallback lexicographically by name
            let sorted = results.sorted { (a, b) in
                let ak = a.chargingSpeedKw ?? 0
                let bk = b.chargingSpeedKw ?? 0
                if ak != bk { return ak > bk }
                return a.name < b.name
            }
            self.stations = sorted
        } catch {
            self.error = error
        }
    }
}
