import Foundation
import Combine

@MainActor
final class VehicleManager: ObservableObject {
    static let shared = VehicleManager()
    
    @Published private(set) var selectedVehicle: Vehicle?
    @Published private(set) var savedVehicles: [Vehicle] = []
    
    private let userDefaults = UserDefaults.standard
    private let selectedVehicleKey = "selected_vehicle_id"
    private let savedVehiclesKey = "saved_vehicles"
    
    private init() {
        loadSavedVehicles()
        loadSelectedVehicle()
    }
    
    // MARK: - Public Methods
    
    func selectVehicle(_ vehicle: Vehicle) {
        selectedVehicle = vehicle
        userDefaults.set(vehicle.id, forKey: selectedVehicleKey)
        
        // Add to saved vehicles if not already there
        if !savedVehicles.contains(where: { $0.id == vehicle.id }) {
            savedVehicles.append(vehicle)
            saveSavedVehicles()
        }
    }
    
    func addCustomVehicle(make: String, model: String, year: Int, batteryCapacity: Double, 
                         range: Double, efficiency: Double, connectorTypes: [Connector.ConnectorType], 
                         maxChargingSpeed: Double) {
        let vehicle = Vehicle(
            id: UUID().uuidString,
            make: make,
            model: model,
            year: year,
            batteryCapacity: batteryCapacity,
            range: range,
            efficiency: efficiency,
            connectorTypes: connectorTypes,
            maxChargingSpeed: maxChargingSpeed
        )
        
        savedVehicles.append(vehicle)
        saveSavedVehicles()
        selectVehicle(vehicle)
    }
    
    func removeVehicle(_ vehicle: Vehicle) {
        savedVehicles.removeAll { $0.id == vehicle.id }
        saveSavedVehicles()
        
        // If this was the selected vehicle, clear selection
        if selectedVehicle?.id == vehicle.id {
            selectedVehicle = nil
            userDefaults.removeObject(forKey: selectedVehicleKey)
        }
    }
    
    func clearSelection() {
        selectedVehicle = nil
        userDefaults.removeObject(forKey: selectedVehicleKey)
    }
    
    // MARK: - Private Methods
    
    private func loadSavedVehicles() {
        if let data = userDefaults.data(forKey: savedVehiclesKey),
           let vehicles = try? JSONDecoder().decode([Vehicle].self, from: data) {
            savedVehicles = vehicles
        }
    }
    
    private func saveSavedVehicles() {
        if let data = try? JSONEncoder().encode(savedVehicles) {
            userDefaults.set(data, forKey: savedVehiclesKey)
        }
    }
    
    private func loadSelectedVehicle() {
        guard let selectedId = userDefaults.string(forKey: selectedVehicleKey) else { return }
        
        // First check saved vehicles
        if let vehicle = savedVehicles.first(where: { $0.id == selectedId }) {
            selectedVehicle = vehicle
            return
        }
        
        // Then check popular models
        if let vehicle = Vehicle.popularModels.first(where: { $0.id == selectedId }) {
            selectedVehicle = vehicle
        }
    }
}

// MARK: - Vehicle Extensions for Route Planning

extension Vehicle {
    var preferredMinSOC: Double {
        return 20.0 // Default 20% minimum
    }
    
    var targetChargingSOC: Double {
        return 80.0 // Default 80% target for optimal charging speed
    }
}