import Foundation

struct Vehicle: Codable, Identifiable, Equatable {
    let id: String
    let make: String
    let model: String
    let year: Int
    let batteryCapacity: Double // in kWh
    let range: Double // in km
    let efficiency: Double // kWh/100km
    let connectorTypes: [Connector.ConnectorType]
    let maxChargingSpeed: Double // in kW
    
    var displayName: String {
        "\(year) \(make) \(model)"
    }
    
    enum CodingKeys: String, CodingKey {
        case id, make, model, year
        case batteryCapacity = "battery_capacity"
        case range, efficiency
        case connectorTypes = "connector_types"
        case maxChargingSpeed = "max_charging_speed"
    }
}

// Popular EV Models Database
extension Vehicle {
    static let popularModels: [Vehicle] = [
        Vehicle(
            id: "tesla-model-3",
            make: "Tesla",
            model: "Model 3",
            year: 2024,
            batteryCapacity: 75,
            range: 500,
            efficiency: 15,
            connectorTypes: [.tesla, .ccs],
            maxChargingSpeed: 250
        ),
        Vehicle(
            id: "tesla-model-y",
            make: "Tesla",
            model: "Model Y",
            year: 2024,
            batteryCapacity: 75,
            range: 480,
            efficiency: 15.6,
            connectorTypes: [.tesla, .ccs],
            maxChargingSpeed: 250
        ),
        Vehicle(
            id: "nissan-leaf",
            make: "Nissan",
            model: "Leaf",
            year: 2024,
            batteryCapacity: 62,
            range: 360,
            efficiency: 17.2,
            connectorTypes: [.chademo, .type2],
            maxChargingSpeed: 50
        ),
        Vehicle(
            id: "vw-id4",
            make: "Volkswagen",
            model: "ID.4",
            year: 2024,
            batteryCapacity: 82,
            range: 520,
            efficiency: 15.8,
            connectorTypes: [.ccs],
            maxChargingSpeed: 135
        )
    ]
}