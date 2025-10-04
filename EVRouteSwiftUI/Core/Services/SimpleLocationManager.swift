import Foundation
import CoreLocation
import Combine

class SimpleLocationManager: NSObject, ObservableObject {
    static let shared = SimpleLocationManager()
    
    @Published var currentLocation: CLLocation?
    
    private var locationManager: CLLocationManager?
    private let defaults = UserDefaults.standard
    private let lastLatKey = "last_known_latitude"
    private let lastLngKey = "last_known_longitude"
    
    private override init() {
        super.init()
        // Bootstrap with last known location so maps can center immediately
        if let lat = defaults.object(forKey: lastLatKey) as? Double,
           let lng = defaults.object(forKey: lastLngKey) as? Double {
            currentLocation = CLLocation(latitude: lat, longitude: lng)
        }
    }
    
    func requestLocationIfNeeded() {
        // Only create CLLocationManager when actually needed
        if locationManager == nil {
            locationManager = CLLocationManager()
            locationManager?.delegate = self
            locationManager?.desiredAccuracy = kCLLocationAccuracyBest
        }
        
        // Request permission if needed
        let status = locationManager?.authorizationStatus ?? .notDetermined
        if status == .notDetermined {
            locationManager?.requestWhenInUseAuthorization()
        } else if status == .authorizedWhenInUse || status == .authorizedAlways {
            locationManager?.requestLocation()
        }
    }
}

extension SimpleLocationManager: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let loc = locations.last {
            currentLocation = loc
            // Persist last known coordinate for fast startup centering
            defaults.set(loc.coordinate.latitude, forKey: lastLatKey)
            defaults.set(loc.coordinate.longitude, forKey: lastLngKey)
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location error: \(error.localizedDescription)")
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        if manager.authorizationStatus == .authorizedWhenInUse || 
           manager.authorizationStatus == .authorizedAlways {
            manager.requestLocation()
        }
    }
}
