import XCTest
@testable import EVRouteSwiftUI
import CoreLocation

final class ModelTests: XCTestCase {
    
    // MARK: - User Tests
    
    func testUserDecoding() throws {
        // Given
        let json = """
        {
            "id": "123",
            "email": "test@example.com",
            "name": "Test User",
            "created_at": "2025-01-01T00:00:00Z"
        }
        """
        
        // When
        let user = try JSONDecoder().decode(User.self, from: Data(json.utf8))
        
        // Then
        XCTAssertEqual(user.id, "123")
        XCTAssertEqual(user.email, "test@example.com")
        XCTAssertEqual(user.name, "Test User")
        XCTAssertNotNil(user.createdAt)
    }
    
    // MARK: - ChargingStation Tests
    
    func testChargingStationDecoding() throws {
        // Given
        let json = """
        {
            "id": "station-1",
            "name": "Test Station",
            "address": "123 Test St",
            "latitude": 37.7749,
            "longitude": -122.4194,
            "connectors": [
                {
                    "id": "conn-1",
                    "type": "CCS",
                    "power": 150,
                    "status": "available"
                }
            ],
            "availability": {
                "total_connectors": 4,
                "available_connectors": 2,
                "last_updated": "2025-01-01T00:00:00Z"
            },
            "amenities": ["WiFi", "Restroom"],
            "price_per_kwh": 0.32,
            "rating": 4.5,
            "distance": 2500
        }
        """
        
        // When
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let station = try decoder.decode(ChargingStation.self, from: Data(json.utf8))
        
        // Then
        XCTAssertEqual(station.id, "station-1")
        XCTAssertEqual(station.name, "Test Station")
        XCTAssertEqual(station.connectors.count, 1)
        XCTAssertEqual(station.connectors.first?.type, .ccs)
        XCTAssertEqual(station.availability.percentage, 50.0)
        XCTAssertEqual(station.amenities.count, 2)
        XCTAssertEqual(station.pricePerKwh, 0.32)
        XCTAssertEqual(station.distance, 2500)
    }
    
    func testChargingStationCoordinate() {
        // Given
        let station = ChargingStation(
            id: "1",
            name: "Test",
            address: "Test Address",
            latitude: 37.7749,
            longitude: -122.4194,
            connectors: [],
            availability: Availability(totalConnectors: 1, availableConnectors: 1, lastUpdated: nil),
            amenities: [],
            pricePerKwh: nil,
            rating: nil,
            distance: nil
        )
        
        // When
        let coordinate = station.coordinate
        
        // Then
        XCTAssertEqual(coordinate.latitude, 37.7749)
        XCTAssertEqual(coordinate.longitude, -122.4194)
    }
    
    // MARK: - Connector Tests
    
    func testConnectorTypeDisplayNames() {
        XCTAssertEqual(Connector.ConnectorType.ccs.displayName, "CCS")
        XCTAssertEqual(Connector.ConnectorType.chademo.displayName, "CHAdeMO")
        XCTAssertEqual(Connector.ConnectorType.type2.displayName, "Type 2")
        XCTAssertEqual(Connector.ConnectorType.tesla.displayName, "Tesla")
        XCTAssertEqual(Connector.ConnectorType.j1772.displayName, "J1772")
    }
    
    func testConnectorStatusDisplayColors() {
        XCTAssertEqual(Connector.ConnectorStatus.available.displayColor, "green")
        XCTAssertEqual(Connector.ConnectorStatus.occupied.displayColor, "orange")
        XCTAssertEqual(Connector.ConnectorStatus.maintenance.displayColor, "red")
        XCTAssertEqual(Connector.ConnectorStatus.unknown.displayColor, "gray")
    }
    
    // MARK: - Route Tests
    
    func testRouteFormattedDistance() {
        // Given
        let route = Route(
            id: "1",
            startLocation: Location(address: "Start", latitude: 0, longitude: 0),
            endLocation: Location(address: "End", latitude: 0, longitude: 0),
            distance: 15500, // 15.5 km
            duration: 0,
            energyRequired: 0,
            chargingStops: [],
            polyline: "",
            totalChargingTime: 0,
            totalCost: nil
        )
        
        // Then
        XCTAssertEqual(route.formattedDistance, "15.5 km")
    }
    
    func testRouteFormattedDuration() {
        // Test hours and minutes
        let route1 = Route(
            id: "1",
            startLocation: Location(address: "Start", latitude: 0, longitude: 0),
            endLocation: Location(address: "End", latitude: 0, longitude: 0),
            distance: 0,
            duration: 7890, // 2h 11m 30s
            energyRequired: 0,
            chargingStops: [],
            polyline: "",
            totalChargingTime: 0,
            totalCost: nil
        )
        XCTAssertEqual(route1.formattedDuration, "2h 11m")
        
        // Test minutes only
        let route2 = Route(
            id: "2",
            startLocation: Location(address: "Start", latitude: 0, longitude: 0),
            endLocation: Location(address: "End", latitude: 0, longitude: 0),
            distance: 0,
            duration: 2400, // 40m
            energyRequired: 0,
            chargingStops: [],
            polyline: "",
            totalChargingTime: 0,
            totalCost: nil
        )
        XCTAssertEqual(route2.formattedDuration, "40m")
    }
    
    // MARK: - Vehicle Tests
    
    func testVehicleDisplayName() {
        let vehicle = Vehicle(
            id: "1",
            make: "Tesla",
            model: "Model 3",
            year: 2024,
            batteryCapacity: 75,
            range: 500,
            efficiency: 15,
            connectorTypes: [.tesla],
            maxChargingSpeed: 250
        )
        
        XCTAssertEqual(vehicle.displayName, "2024 Tesla Model 3")
    }
    
    func testPopularVehicleModels() {
        XCTAssertFalse(Vehicle.popularModels.isEmpty)
        XCTAssertTrue(Vehicle.popularModels.contains { $0.make == "Tesla" })
        XCTAssertTrue(Vehicle.popularModels.contains { $0.make == "Nissan" })
    }
}
