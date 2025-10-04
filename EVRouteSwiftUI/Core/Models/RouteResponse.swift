import Foundation
import CoreLocation

// MARK: - Webhook Response Models

struct WebhookResponse: Codable {
    let origin: String
    let destination: String
    let currentSoc: Double
    let batteryCapacityKwh: Double
    let minSoc: Double
    let targetSoc: Double
    let amenityPreferences: [String]
    let selectedStations: [String]
    let responseData: ResponseData
    let response: RouteResponse
    
    enum CodingKeys: String, CodingKey {
        case origin, destination
        case currentSoc = "current_soc"
        case batteryCapacityKwh = "battery_capacity_kwh"
        case minSoc = "min_soc"
        case targetSoc = "target_soc"
        case amenityPreferences = "amenity_preferences"
        case selectedStations = "selected_stations"
        case responseData = "response_data"
        case response
    }
}

struct ResponseData: Codable {
    // Empty for now, can be expanded if needed
}

struct RouteResponse: Codable {
    let route: RouteInfo
    let chargingPlan: ChargingPlan
    let summary: RouteSummary
    let statistics: RouteStatistics
    
    enum CodingKeys: String, CodingKey {
        case route
        case chargingPlan = "charging_plan"
        case summary
        case statistics
    }
}

struct RouteInfo: Codable {
    let polyline: String
    let distanceKm: Double
    let durationMinutes: Int
    let origin: String
    let destination: String
    
    enum CodingKeys: String, CodingKey {
        case polyline
        case distanceKm = "distance_km"
        case durationMinutes = "duration_minutes"
        case origin
        case destination
    }
}

struct ChargingPlan: Codable {
    let needed: Bool
    let selectedStations: [RouteChargingStation]
    let allStations: [RouteChargingStation]
    let totalChargingTime: Int
    let totalDetourKm: Double
    let totalEnergyAddedKwh: Double
    let canCompleteWithoutCharging: Bool
    
    enum CodingKeys: String, CodingKey {
        case needed
        case selectedStations = "selected_stations"
        case allStations = "all_stations"
        case totalChargingTime = "total_charging_time"
        case totalDetourKm = "total_detour_km"
        case totalEnergyAddedKwh = "total_energy_added_kwh"
        case canCompleteWithoutCharging = "can_complete_without_charging"
    }
}

struct RouteChargingStation: Codable, Identifiable {
    let stationName: String
    let location: StationLocation
    let address: String
    let chargingSpeedKw: Double
    let detourKm: Double
    let arrivalSOC: Double
    let departureSOC: Double
    let chargingTimeMinutes: Int
    let energyAddedKwh: Double
    let distanceFromOriginKm: Double
    let isCritical: Bool
    let reason: String
    let isSelected: Bool
    
    var id: String {
        "\(stationName)_\(location.lat)_\(location.lng)"
    }
    
    enum CodingKeys: String, CodingKey {
        case stationName = "station_name"
        case location
        case address
        case chargingSpeedKw = "charging_speed_kw"
        case detourKm = "detour_km"
        case arrivalSOC = "arrival_SOC"
        case departureSOC = "departure_SOC"
        case chargingTimeMinutes = "charging_time_minutes"
        case energyAddedKwh = "energy_added_kwh"
        case distanceFromOriginKm = "distance_from_origin_km"
        case isCritical = "is_critical"
        case reason
        case isSelected = "is_selected"
    }
}

struct StationLocation: Codable {
    let lat: Double
    let lng: Double
    
    enum CodingKeys: String, CodingKey {
        case lat = "latitude"
        case lng = "longitude"
    }
    
    // Handle both formats
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // Try the expected format first
        if let latitude = try? container.decode(Double.self, forKey: .lat),
           let longitude = try? container.decode(Double.self, forKey: .lng) {
            self.lat = latitude
            self.lng = longitude
        } else {
            // If that fails, try direct keys
            let singleContainer = try decoder.singleValueContainer()
            if let dict = try? singleContainer.decode([String: Double].self) {
                self.lat = dict["lat"] ?? 0
                self.lng = dict["lng"] ?? 0
            } else {
                self.lat = 0
                self.lng = 0
            }
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(lat, forKey: .lat)
        try container.encode(lng, forKey: .lng)
    }
}

struct RouteSummary: Codable {
    let origin: String
    let destination: String
    let baseDurationMinutes: Int
    let chargingTimeMinutes: Int
    let detourTimeMinutes: Int
    let estimatedTotalDuration: Int
    
    enum CodingKeys: String, CodingKey {
        case origin
        case destination
        case baseDurationMinutes = "base_duration_minutes"
        case chargingTimeMinutes = "charging_time_minutes"
        case detourTimeMinutes = "detour_time_minutes"
        case estimatedTotalDuration = "estimated_total_duration"
    }
}

struct RouteStatistics: Codable {
    let totalStationsFound: Int
    let onRouteStations: Int
    let stationsSelected: Int
    let avgChargingSpeedSelected: Int
    let totalEnergyRequired: Double
    let minSocReached: Int
    
    enum CodingKeys: String, CodingKey {
        case totalStationsFound = "total_stations_found"
        case onRouteStations = "on_route_stations"
        case stationsSelected = "stations_selected"
        case avgChargingSpeedSelected = "avg_charging_speed_selected"
        case totalEnergyRequired = "total_energy_required"
        case minSocReached = "min_soc_reached"
    }
}

// MARK: - Amenity Model

struct Amenity: Identifiable {
    let id: String
    let name: String
    let icon: String
    
    static let all = [
        Amenity(id: "restaurant", name: "Restaurant", icon: "fork.knife"),
        Amenity(id: "restroom", name: "Restroom", icon: "toilet"),
        Amenity(id: "shopping", name: "Shopping", icon: "cart"),
        Amenity(id: "wifi", name: "WiFi", icon: "wifi"),
        Amenity(id: "lounge", name: "Lounge", icon: "sofa"),
        Amenity(id: "coffee", name: "Coffee", icon: "cup.and.saucer")
    ]
}