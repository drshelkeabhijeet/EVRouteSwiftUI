import Foundation
import SwiftUI
import MapKit
import Combine

@MainActor
final class RoutePlanningViewModel: ObservableObject {
    @Published var originText = ""
    @Published var originCoordinates: CLLocationCoordinate2D? {
        didSet {
            objectWillChange.send()
        }
    }
    @Published var destinationText = ""
    @Published var destinationCoordinates: CLLocationCoordinate2D? {
        didSet {
            objectWillChange.send()
        }
    }
    @Published var currentSOC: Double = 80.0
    @Published var selectedAmenities: Set<String> = []
    @Published var preferredConnectors: Set<Connector.ConnectorType> = []
    @Published var isLoading = false
    @Published var showError = false
    @Published var errorMessage = ""
    @Published var routeResponse: RouteResponse?
    @Published var showResults = false
    
    private let vehicleManager = VehicleManager.shared
    private let routeService = RouteService.shared
    private var cancellables = Set<AnyCancellable>()
    
    var selectedVehicle: Vehicle? {
        vehicleManager.selectedVehicle
    }
    
    var canPlanRoute: Bool {
        originCoordinates != nil &&
        destinationCoordinates != nil &&
        selectedVehicle != nil
    }
    
    init() {
        // Observe vehicle changes
        vehicleManager.$selectedVehicle
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)
    }
    
    func toggleAmenity(_ amenityId: String) {
        if selectedAmenities.contains(amenityId) {
            selectedAmenities.remove(amenityId)
        } else {
            selectedAmenities.insert(amenityId)
        }
    }
    
    func planRoute() async {
        guard let origin = originCoordinates,
              let destination = destinationCoordinates,
              let vehicle = selectedVehicle else {
            showError(message: "Please fill in all required fields")
            return
        }
        
        isLoading = true
        errorMessage = ""
        
        // Create route request
        let request = RoutePlanRequest(
            origin: "\(origin.latitude),\(origin.longitude)",
            destination: "\(destination.latitude),\(destination.longitude)",
            currentSOC: currentSOC,
            batteryCapacityKWh: vehicle.batteryCapacity,
            minSOC: vehicle.preferredMinSOC,
            targetSOC: vehicle.targetChargingSOC,
            amenityPreferences: Array(selectedAmenities),
            userEmail: nil
        )
        
        do {
            // Make API call to n8n webhook
            let routeResponse = try await routeService.planRoute(request: request)
            
            isLoading = false
            
            // Store response and show results
            self.routeResponse = routeResponse
            self.showResults = true
            
            // Save route to history
            let savedRoute = SavedRoute(
                date: Date(),
                origin: originText,
                destination: destinationText,
                distance: routeResponse.route.distanceKm,
                duration: routeResponse.route.durationMinutes,
                chargingStops: routeResponse.chargingPlan.selectedStations.count,
                vehicle: vehicle.displayName,
                routeResponse: routeResponse
            )
            RouteStorageManager.shared.saveRoute(savedRoute)
            
        } catch {
            isLoading = false
            
            print("Route planning error: \(error)")
            if let networkError = error as? NetworkError {
                showError(message: networkError.localizedDescription)
            } else {
                showError(message: "Error loading route: \(error.localizedDescription)")
            }
        }
    }
    
    private func showError(message: String) {
        errorMessage = message
        showError = true
    }
}
