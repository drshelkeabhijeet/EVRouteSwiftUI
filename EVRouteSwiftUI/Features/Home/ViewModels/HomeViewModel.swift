import Foundation
import CoreLocation
import Combine
import MapKit

@MainActor
final class HomeViewModel: ObservableObject {
    @Published private(set) var nearbyStations: [ChargingStation] = []
    @Published private(set) var isLoading = false
    @Published var error: Error?
    @Published var searchText = ""
    @Published var selectedStation: ChargingStation?
    
    private let networkService: NetworkServiceProtocol
    private let locationManager = EVLocationManager()
    private var cancellables = Set<AnyCancellable>()
    
    init(networkService: NetworkServiceProtocol = NetworkService.shared) {
        self.networkService = networkService
        setupBindings()
    }
    
    private func setupBindings() {
        // Debounce search text changes - DISABLED to prevent network errors
        // $searchText
        //     .debounce(for: .milliseconds(500), scheduler: RunLoop.main)
        //     .removeDuplicates()
        //     .sink { [weak self] _ in
        //         Task {
        //             await self?.searchStations()
        //         }
        //     }
        //     .store(in: &cancellables)
        
        // Listen to location updates - DISABLED to prevent network errors
        // locationManager.$currentLocation
        //     .compactMap { $0 }
        //     .sink { [weak self] _ in
        //         Task {
        //             await self?.loadNearbyStations()
        //         }
        //     }
        //     .store(in: &cancellables)
    }
    
    func loadNearbyStations() async {
        guard let location = locationManager.currentLocation else {
            error = EVLocationError.locationNotAvailable
            return
        }
        
        isLoading = true
        error = nil
        
        do {
            let endpoint = StationEndpoint.nearbyStations(
                latitude: location.latitude,
                longitude: location.longitude,
                radius: 10000 // 10km radius
            )
            
            let stations: [ChargingStation] = try await networkService.request(endpoint)
            self.nearbyStations = stations.sorted { $0.distance ?? 0 < $1.distance ?? 0 }
        } catch {
            self.error = error
        }
        
        isLoading = false
    }
    
    func searchStations() async {
        // Implement search logic
        if searchText.isEmpty {
            await loadNearbyStations()
        } else {
            // Filter existing stations for now
            let filtered = nearbyStations.filter { station in
                station.name.localizedCaseInsensitiveContains(searchText) ||
                station.address.localizedCaseInsensitiveContains(searchText)
            }
            nearbyStations = filtered
        }
    }
    
    func requestLocationPermission() {
        locationManager.requestPermission()
    }
}

// Location Manager
final class EVLocationManager: NSObject, ObservableObject {
    @Published var currentLocation: CLLocationCoordinate2D?
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    
    private let manager = CLLocationManager()
    
    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
    }
    
    func requestPermission() {
        manager.requestWhenInUseAuthorization()
    }
    
    func startUpdatingLocation() {
        manager.startUpdatingLocation()
    }
    
    func stopUpdatingLocation() {
        manager.stopUpdatingLocation()
    }
}

extension EVLocationManager: CLLocationManagerDelegate {
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus
        
        switch authorizationStatus {
        case .authorizedAlways, .authorizedWhenInUse:
            startUpdatingLocation()
        default:
            break
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        currentLocation = location.coordinate
    }
}

enum EVLocationError: LocalizedError {
    case locationNotAvailable
    case permissionDenied
    
    var errorDescription: String? {
        switch self {
        case .locationNotAvailable:
            return "Location services are not available"
        case .permissionDenied:
            return "Location permission denied"
        }
    }
}