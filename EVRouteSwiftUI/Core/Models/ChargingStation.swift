import Foundation
import CoreLocation

struct ChargingStation: Codable, Identifiable, Equatable {
    let id: String
    let name: String
    let address: String
    let latitude: Double
    let longitude: Double
    let connectors: [Connector]
    let availability: Availability
    let amenities: [String]
    let pricePerKwh: Double?
    let rating: Double?
    let distance: Double? // in meters
    
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
    
    enum CodingKeys: String, CodingKey {
        case id, name, address, latitude, longitude
        case connectors, availability, amenities
        case pricePerKwh = "price_per_kwh"
        case rating, distance
    }
}

struct Connector: Codable, Identifiable, Equatable {
    let id: String
    let type: ConnectorType
    let power: Double // in kW
    let status: ConnectorStatus
    
    enum ConnectorType: String, Codable {
        case ccs = "CCS"
        case chademo = "CHAdeMO"
        case type2 = "Type2"
        case tesla = "Tesla"
        case j1772 = "J1772"
        
        var displayName: String {
            switch self {
            case .ccs: return "CCS"
            case .chademo: return "CHAdeMO"
            case .type2: return "Type 2"
            case .tesla: return "Tesla"
            case .j1772: return "J1772"
            }
        }
    }
    
    enum ConnectorStatus: String, Codable {
        case available
        case occupied
        case maintenance
        case unknown
        
        var displayColor: String {
            switch self {
            case .available: return "green"
            case .occupied: return "orange"
            case .maintenance: return "red"
            case .unknown: return "gray"
            }
        }
    }
}

struct Availability: Codable, Equatable {
    let totalConnectors: Int
    let availableConnectors: Int
    let lastUpdated: Date?
    
    var percentage: Double {
        guard totalConnectors > 0 else { return 0 }
        return Double(availableConnectors) / Double(totalConnectors) * 100
    }
    
    enum CodingKeys: String, CodingKey {
        case totalConnectors = "total_connectors"
        case availableConnectors = "available_connectors"
        case lastUpdated = "last_updated"
    }
}