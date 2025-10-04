import Foundation
import CoreLocation
import Combine

@MainActor
class LocationManager: NSObject, ObservableObject {
    static let shared = LocationManager()
    
    @Published var currentLocation: CLLocation?
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published var isLocationEnabled = false
    
    private var locationManager: CLLocationManager?
    private var cancellables = Set<AnyCancellable>()
    
    override init() {
        super.init()
        setupLocationManager()
    }
    
    private func setupLocationManager() {
        locationManager = CLLocationManager()
        locationManager?.delegate = self
        locationManager?.desiredAccuracy = kCLLocationAccuracyBest
        locationManager?.distanceFilter = 100 // Update every 100 meters
    }
    
    func requestLocationPermission() {
        locationManager?.requestWhenInUseAuthorization()
    }
    
    func startUpdatingLocation() {
        if authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways {
            locationManager?.startUpdatingLocation()
        }
    }
    
    func stopUpdatingLocation() {
        locationManager?.stopUpdatingLocation()
    }
    
    func requestLocation() {
        locationManager?.requestLocation()
    }
}

// MARK: - CLLocationManagerDelegate

extension LocationManager: CLLocationManagerDelegate {
    // Mark delegate callbacks as nonisolated and hop to main actor to mutate state
    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        Task { @MainActor in
            self.currentLocation = location
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Task { @MainActor in
            // Handle location errors gracefully
            if let clError = error as? CLError {
                switch clError.code {
                case .denied:
                    print("Location access denied by user")
                case .locationUnknown:
                    print("Location currently unknown, will retry")
                case .network:
                    print("Network error occurred")
                default:
                    print("Location error: \(error.localizedDescription)")
                }
            } else {
                print("Location error: \(error.localizedDescription)")
            }
        }
    }

    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        Task { @MainActor in
            let status = manager.authorizationStatus
            self.authorizationStatus = status
            // Avoid calling CLLocationManager.locationServicesEnabled() on main thread; infer from status
            self.isLocationEnabled = (status == .authorizedWhenInUse || status == .authorizedAlways)

            switch status {
            case .authorizedWhenInUse, .authorizedAlways:
                self.startUpdatingLocation()
            case .denied, .restricted:
                self.currentLocation = nil
            case .notDetermined:
                break
            @unknown default:
                break
            }
        }
    }
}
