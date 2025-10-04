import Foundation
import CoreLocation

struct Route: Codable, Identifiable, Equatable {
    let id: String
    let startLocation: Location
    let endLocation: Location
    let distance: Double // in meters
    let duration: Double // in seconds
    let energyRequired: Double // in kWh
    let chargingStops: [ChargingStop]
    let polyline: String
    let totalChargingTime: Double // in seconds
    let totalCost: Double?
    
    var formattedDistance: String {
        let km = distance / 1000
        return String(format: "%.1f km", km)
    }
    
    var formattedDuration: String {
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        }
        return "\(minutes)m"
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case startLocation = "start_location"
        case endLocation = "end_location"
        case distance, duration
        case energyRequired = "energy_required"
        case chargingStops = "charging_stops"
        case polyline
        case totalChargingTime = "total_charging_time"
        case totalCost = "total_cost"
    }
}

struct Location: Codable, Equatable {
    let address: String
    let latitude: Double
    let longitude: Double
    
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}

struct ChargingStop: Codable, Identifiable, Equatable {
    let id: String
    let station: ChargingStation
    let arrivalCharge: Double // percentage
    let targetCharge: Double // percentage
    let chargingTime: Double // in seconds
    let cost: Double?
    
    var formattedChargingTime: String {
        let minutes = Int(chargingTime) / 60
        return "\(minutes) min"
    }
    
    enum CodingKeys: String, CodingKey {
        case id, station
        case arrivalCharge = "arrival_charge"
        case targetCharge = "target_charge"
        case chargingTime = "charging_time"
        case cost
    }
}

struct RoutePlanRequest: Codable {
    let origin: String // "latitude,longitude"
    let destination: String // "latitude,longitude"
    let currentSOC: Double
    let batteryCapacityKWh: Double
    let minSOC: Double
    let targetSOC: Double
    let amenityPreferences: [String]
    let userEmail: String?
    
    enum CodingKeys: String, CodingKey {
        case origin
        case destination
        case currentSOC = "current_soc"
        case batteryCapacityKWh = "battery_capacity_kwh"
        case minSOC = "min_soc"
        case targetSOC = "target_soc"
        case amenityPreferences = "amenity_preferences"
        case userEmail = "user_email"
    }
}