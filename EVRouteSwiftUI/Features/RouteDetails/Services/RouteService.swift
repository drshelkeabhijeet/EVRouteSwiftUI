import Foundation
import Combine

// MARK: - N8N Response Models

struct N8NResponse: Codable {
    let origin: String
    let destination: String
    let current_soc: Double
    let battery_capacity_kwh: Double
    let min_soc: Double
    let target_soc: Double
    let amenity_preferences: [String]
    let selected_stations: [N8NChargingStation]?
    let response_data: ResponseData?
    let response: N8NRouteResponse
    
    struct N8NChargingStation: Codable {
        let name: String
        let charging_speed_kw: Double
        let detour_km: Double
        let arrival_soc: Double
        let departure_soc: Double
        let charging_time_minutes: Int
        let energy_added_kwh: Double
        let distance_from_origin_km: Double
        let is_critical: Bool
        let reason: String
    }
    
    struct ResponseData: Codable {
        let distance_km: Double
        let duration_minutes: Int
        let total_charging_time: Int
        let total_detour_km: Double
        let total_energy_added_kwh: Double
        let can_complete_without_charging: Bool
        let stations_selected: Int
    }
    
    struct N8NRouteResponse: Codable {
        let route: N8NRouteInfo
        let charging_plan: N8NChargingPlan
        let summary: N8NTripSummary
        let statistics: N8NRouteStatistics
    }
    
    struct N8NRouteInfo: Codable {
        let polyline: String
        let distance_km: Double
        let duration_minutes: Int
        let origin: String
        let destination: String
    }
    
    struct N8NChargingPlan: Codable {
        let needed: Bool
        let selected_stations: [N8NRouteChargingStation]
        let all_stations: [N8NRouteChargingStation]
        let total_charging_time: Int
        let total_detour_km: Double
        let total_energy_added_kwh: Double
        let can_complete_without_charging: Bool
    }
    
    struct N8NRouteChargingStation: Codable {
        let station_name: String
        let location: N8NStationLocation
        let address: String
        let charging_speed_kw: Double
        let detour_km: Double
        let arrival_SOC: Double
        let departure_SOC: Double
        let charging_time_minutes: Int
        let energy_added_kwh: Double
        let distance_from_origin_km: Double
        let is_critical: Bool
        let reason: String
        let is_selected: Bool
    }
    
    struct N8NStationLocation: Codable {
        let latitude: Double
        let longitude: Double
    }
    
    struct N8NTripSummary: Codable {
        let origin: String
        let destination: String
        let base_duration_minutes: Int
        let charging_time_minutes: Int
        let detour_time_minutes: Int
        let estimated_total_duration: Int
    }
    
    struct N8NRouteStatistics: Codable {
        let total_stations_found: Int
        let on_route_stations: Int
        let stations_selected: Int
        let avg_charging_speed_selected: Double
        let total_energy_required: Double
        let min_soc_reached: Double
    }
}

// MARK: - Route Response Models

struct RouteResponse: Codable {
    let route: RouteInfo
    let chargingPlan: ChargingPlan
    let summary: TripSummary
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

    init(
        needed: Bool,
        selectedStations: [RouteChargingStation],
        allStations: [RouteChargingStation],
        totalChargingTime: Int,
        totalDetourKm: Double,
        totalEnergyAddedKwh: Double,
        canCompleteWithoutCharging: Bool
    ) {
        self.needed = needed
        self.selectedStations = selectedStations
        self.allStations = allStations
        self.totalChargingTime = totalChargingTime
        self.totalDetourKm = totalDetourKm
        self.totalEnergyAddedKwh = totalEnergyAddedKwh
        self.canCompleteWithoutCharging = canCompleteWithoutCharging
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let needed = (try? c.decode(Bool.self, forKey: .needed)) ?? true
        let selected = (try? c.decode([RouteChargingStation].self, forKey: .selectedStations)) ?? []
        let all = (try? c.decode([RouteChargingStation].self, forKey: .allStations)) ?? []
        let totalCharge = (try? c.decode(Int.self, forKey: .totalChargingTime)) ?? selected.reduce(0) { $0 + $1.chargingTimeMinutes }
        let totalDetour = (try? c.decode(Double.self, forKey: .totalDetourKm)) ?? (selected + all).reduce(0.0) { $0 + $1.detourKm }
        let totalEnergy = (try? c.decode(Double.self, forKey: .totalEnergyAddedKwh)) ?? selected.reduce(0.0) { $0 + $1.energyAddedKwh }
        let canComplete = (try? c.decode(Bool.self, forKey: .canCompleteWithoutCharging)) ?? !needed

        self.needed = needed
        self.selectedStations = selected
        self.allStations = all
        self.totalChargingTime = totalCharge
        self.totalDetourKm = totalDetour
        self.totalEnergyAddedKwh = totalEnergy
        self.canCompleteWithoutCharging = canComplete
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(needed, forKey: .needed)
        try c.encode(selectedStations, forKey: .selectedStations)
        try c.encode(allStations, forKey: .allStations)
        try c.encode(totalChargingTime, forKey: .totalChargingTime)
        try c.encode(totalDetourKm, forKey: .totalDetourKm)
        try c.encode(totalEnergyAddedKwh, forKey: .totalEnergyAddedKwh)
        try c.encode(canCompleteWithoutCharging, forKey: .canCompleteWithoutCharging)
    }
}

struct RouteChargingStation: Codable, Identifiable {
    var id: String {
        "\(stationName)_\(location.lat)_\(location.lng)"
    }
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
    // Optional extra fields from backend we may show in UI
    let rating: Double?
    let userRatingCount: Int?
    let connectorTypes: [String]?
    let websiteURI: String?
    let phoneNumber: String?
    let businessStatus: String?
    let onRoute: Bool?
    let timeImpactMinutes: Int?

    enum CodingKeys: String, CodingKey {
        case stationName = "station_name"
        case name
        case location
        case address
        case chargingSpeedKw = "charging_speed_kw"
        case detourKm = "detour_km"
        case arrivalSOC = "arrival_SOC"
        case departureSOC = "departure_SOC"
        case chargingTimeMinutes = "charging_time_minutes"
        case chargingDurationMinutes = "charging_duration_minutes"
        case energyAddedKwh = "energy_added_kwh"
        case distanceFromOriginKm = "distance_from_origin_km"
        case isCritical = "is_critical"
        case reason
        case isSelected = "is_selected"
        case rating
        case userRatingCount = "user_rating_count"
        case connectorTypes = "connector_types"
        case websiteURI = "website_uri"
        case phoneNumber = "phone_number"
        case businessStatus = "business_status"
        case onRoute = "on_route"
        case timeImpactMinutes = "time_impact_minutes"
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)

        if let s = try? c.decode(String.self, forKey: .stationName) {
            stationName = s
        } else if let s = try? c.decode(String.self, forKey: .name) {
            stationName = s
        } else {
            stationName = ""
        }

        location = try c.decode(StationLocation.self, forKey: .location)
        address = (try? c.decode(String.self, forKey: .address)) ?? ""
        chargingSpeedKw = (try? c.decode(Double.self, forKey: .chargingSpeedKw)) ?? 0
        detourKm = (try? c.decode(Double.self, forKey: .detourKm)) ?? 0
        arrivalSOC = (try? c.decode(Double.self, forKey: .arrivalSOC)) ?? 0
        departureSOC = (try? c.decode(Double.self, forKey: .departureSOC)) ?? 0

        if let ct = try? c.decode(Int.self, forKey: .chargingTimeMinutes) {
            chargingTimeMinutes = ct
        } else if let ct2 = try? c.decode(Int.self, forKey: .chargingDurationMinutes) {
            chargingTimeMinutes = ct2
        } else {
            chargingTimeMinutes = 0
        }

        energyAddedKwh = (try? c.decode(Double.self, forKey: .energyAddedKwh)) ?? 0
        distanceFromOriginKm = (try? c.decode(Double.self, forKey: .distanceFromOriginKm)) ?? 0
        isCritical = (try? c.decode(Bool.self, forKey: .isCritical)) ?? false
        reason = (try? c.decode(String.self, forKey: .reason)) ?? ""
        isSelected = (try? c.decode(Bool.self, forKey: .isSelected)) ?? false
        // Optional extras
        rating = try? c.decode(Double.self, forKey: .rating)
        userRatingCount = try? c.decode(Int.self, forKey: .userRatingCount)
        connectorTypes = try? c.decode([String].self, forKey: .connectorTypes)
        websiteURI = try? c.decode(String.self, forKey: .websiteURI)
        phoneNumber = try? c.decode(String.self, forKey: .phoneNumber)
        businessStatus = try? c.decode(String.self, forKey: .businessStatus)
        onRoute = try? c.decode(Bool.self, forKey: .onRoute)
        timeImpactMinutes = try? c.decode(Int.self, forKey: .timeImpactMinutes)
    }

    // Provide explicit memberwise initializer for use in mapping code
    init(
        stationName: String,
        location: StationLocation,
        address: String,
        chargingSpeedKw: Double,
        detourKm: Double,
        arrivalSOC: Double,
        departureSOC: Double,
        chargingTimeMinutes: Int,
        energyAddedKwh: Double,
        distanceFromOriginKm: Double,
        isCritical: Bool,
        reason: String,
        isSelected: Bool
    ) {
        self.stationName = stationName
        self.location = location
        self.address = address
        self.chargingSpeedKw = chargingSpeedKw
        self.detourKm = detourKm
        self.arrivalSOC = arrivalSOC
        self.departureSOC = departureSOC
        self.chargingTimeMinutes = chargingTimeMinutes
        self.energyAddedKwh = energyAddedKwh
        self.distanceFromOriginKm = distanceFromOriginKm
        self.isCritical = isCritical
        self.reason = reason
        self.isSelected = isSelected
        self.rating = nil
        self.userRatingCount = nil
        self.connectorTypes = nil
        self.websiteURI = nil
        self.phoneNumber = nil
        self.businessStatus = nil
        self.onRoute = nil
        self.timeImpactMinutes = nil
    }

    // Custom encoder to satisfy Encodable despite extra CodingKeys used for decoding only
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(stationName, forKey: .stationName)
        try container.encode(location, forKey: .location)
        try container.encode(address, forKey: .address)
        try container.encode(chargingSpeedKw, forKey: .chargingSpeedKw)
        try container.encode(detourKm, forKey: .detourKm)
        try container.encode(arrivalSOC, forKey: .arrivalSOC)
        try container.encode(departureSOC, forKey: .departureSOC)
        try container.encode(chargingTimeMinutes, forKey: .chargingTimeMinutes)
        try container.encode(energyAddedKwh, forKey: .energyAddedKwh)
        try container.encode(distanceFromOriginKm, forKey: .distanceFromOriginKm)
        try container.encode(isCritical, forKey: .isCritical)
        try container.encode(reason, forKey: .reason)
        try container.encode(isSelected, forKey: .isSelected)
        // Encode extras if present
        if let rating = rating { try container.encode(rating, forKey: .rating) }
        if let userRatingCount = userRatingCount { try container.encode(userRatingCount, forKey: .userRatingCount) }
        if let connectorTypes = connectorTypes { try container.encode(connectorTypes, forKey: .connectorTypes) }
        if let websiteURI = websiteURI { try container.encode(websiteURI, forKey: .websiteURI) }
        if let phoneNumber = phoneNumber { try container.encode(phoneNumber, forKey: .phoneNumber) }
        if let businessStatus = businessStatus { try container.encode(businessStatus, forKey: .businessStatus) }
    }
}

struct StationLocation: Codable {
    let lat: Double
    let lng: Double
    
    init(lat: Double, lng: Double) {
        self.lat = lat
        self.lng = lng
    }
    
    enum CodingKeys: String, CodingKey {
        case lat = "latitude"
        case lng = "longitude"
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // Try to decode with latitude/longitude first (n8n format)
        if let latitude = try? container.decode(Double.self, forKey: .lat),
           let longitude = try? container.decode(Double.self, forKey: .lng) {
            self.lat = latitude
            self.lng = longitude
        } else {
            // Fall back to lat/lng format
            let values = try decoder.singleValueContainer()
            let dict = try values.decode([String: Double].self)
            if let lat = dict["lat"], let lng = dict["lng"] {
                self.lat = lat
                self.lng = lng
            } else {
                throw DecodingError.keyNotFound(CodingKeys.lat, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Neither latitude/longitude nor lat/lng found"))
            }
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(lat, forKey: .lat)
        try container.encode(lng, forKey: .lng)
    }
}

struct TripSummary: Codable {
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
    let avgChargingSpeedSelected: Double
    let totalEnergyRequired: Double
    let minSocReached: Double
    
    enum CodingKeys: String, CodingKey {
        case totalStationsFound = "total_stations_found"
        case onRouteStations = "on_route_stations"
        case stationsSelected = "stations_selected"
        case avgChargingSpeedSelected = "avg_charging_speed_selected"
        case totalEnergyRequired = "total_energy_required"
        case minSocReached = "min_soc_reached"
    }
}

// MARK: - New Webhook (array) Response Models

// Supports the provided n8n sample: an array of one object with `route` and `charging_plan`.
struct WebhookV2TopLevel: Decodable {
    let route: WebhookV2Route
    let charging_plan: WebhookV2ChargingPlan
}

struct WebhookV2Route: Decodable {
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
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        polyline = try container.decode(String.self, forKey: .polyline)
        // Accept number or string for distance_km
        if let d = try? container.decode(Double.self, forKey: .distanceKm) {
            distanceKm = d
        } else if let s = try? container.decode(String.self, forKey: .distanceKm), let d = Double(s) {
            distanceKm = d
        } else {
            throw DecodingError.typeMismatch(Double.self, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "distance_km not Double or numeric String"))
        }
        durationMinutes = try container.decode(Int.self, forKey: .durationMinutes)
        origin = try container.decode(String.self, forKey: .origin)
        destination = try container.decode(String.self, forKey: .destination)
    }
}

struct WebhookV2ChargingPlan: Decodable {
    let needed: Bool
    let selected_stations: [WebhookV2Station]
    let all_stations: [WebhookV2Station]
    let from_cache: Bool?
}

struct WebhookV2Station: Decodable {
    let stationName: String
    let location: N8NResponse.N8NStationLocation
    let address: String
    let chargingSpeedKw: Double
    let detourKm: Double
    let arrivalSOC: Double?
    let departureSOC: Double?
    let chargingTimeMinutes: Int?
    let energyAddedKwh: Double?
    let distanceFromOriginKm: Double?
    let isCritical: Bool?
    let reason: String?
    let onRoute: Bool?
    let timeImpactMinutes: Int?
    
    enum CodingKeys: String, CodingKey {
        case station_name
        case name
        case location
        case address
        case charging_speed_kw
        case detour_km
        case arrival_SOC
        case departure_SOC
        case charging_time_minutes
        case charging_duration_minutes
        case energy_added_kwh
        case distance_from_origin_km
        case is_critical
        case reason
        case on_route
        case time_impact_minutes
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        if let s = try? container.decode(String.self, forKey: .station_name) {
            stationName = s
        } else if let s = try? container.decode(String.self, forKey: .name) {
            stationName = s
        } else {
            stationName = ""
        }
        location = try container.decode(N8NResponse.N8NStationLocation.self, forKey: .location)
        address = (try? container.decode(String.self, forKey: .address)) ?? ""
        chargingSpeedKw = (try? container.decode(Double.self, forKey: .charging_speed_kw)) ?? 0
        detourKm = (try? container.decode(Double.self, forKey: .detour_km)) ?? 0
        arrivalSOC = try? container.decode(Double.self, forKey: .arrival_SOC)
        departureSOC = try? container.decode(Double.self, forKey: .departure_SOC)
        if let ct = try? container.decode(Int.self, forKey: .charging_time_minutes) {
            chargingTimeMinutes = ct
        } else if let ct2 = try? container.decode(Int.self, forKey: .charging_duration_minutes) {
            chargingTimeMinutes = ct2
        } else {
            chargingTimeMinutes = nil
        }
        energyAddedKwh = try? container.decode(Double.self, forKey: .energy_added_kwh)
        distanceFromOriginKm = try? container.decode(Double.self, forKey: .distance_from_origin_km)
        isCritical = try? container.decode(Bool.self, forKey: .is_critical)
        reason = try? container.decode(String.self, forKey: .reason)
        onRoute = try? container.decode(Bool.self, forKey: .on_route)
        timeImpactMinutes = try? container.decode(Int.self, forKey: .time_impact_minutes)
    }
}

// MARK: - Route Service

@MainActor
final class RouteService: ObservableObject {
    static let shared = RouteService()
    
    private let networkService = NetworkService.shared
    private let webhookURL = "https://abhijeetshelke.app.n8n.cloud/webhook/5c5cf1c2-edab-404e-8637-8e3c4a572f9d"
    
    private init() {}
    
    func planRoute(request: RoutePlanRequest) async throws -> RouteResponse {
        // Create URL
        guard let url = URL(string: webhookURL) else {
            throw NetworkError.invalidURL
        }
        
        // Create request
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Encode request body
        let encoder = JSONEncoder()
        urlRequest.httpBody = try encoder.encode(request)
        
        // Log request for debugging
        if let bodyData = urlRequest.httpBody,
           let bodyString = String(data: bodyData, encoding: .utf8) {
            print("Sending route request to n8n:")
            print(bodyString)
        }
        
        // Make request
        let (data, response) = try await URLSession.shared.data(for: urlRequest)
        
        // Check response
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.serverError("Invalid response")
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            if let errorData = String(data: data, encoding: .utf8) {
                print("Server error: \(errorData)")
            }
            throw NetworkError.serverError("Server returned status code \(httpResponse.statusCode)")
        }
        
        // Log response for debugging
        if let responseString = String(data: data, encoding: .utf8) {
            print("Received route response:")
            print(responseString)
        }
        
        // Decode response
        let decoder = JSONDecoder()
        do {
            // Unwrap array-of-one for direct decoding
            var dataForDirectDecode = data
            if let top = try? JSONSerialization.jsonObject(with: data, options: []),
               let arr = top as? [Any], let first = arr.first,
               JSONSerialization.isValidJSONObject(first),
               let normalized = try? JSONSerialization.data(withJSONObject: first, options: []) {
                dataForDirectDecode = normalized
            }
            // Try direct RouteResponse decoding first (webhook now returns this format)
            do {
                print("Trying direct RouteResponse decoding")
                let routeResponse = try decoder.decode(RouteResponse.self, from: dataForDirectDecode)
                print("Successfully decoded RouteResponse directly")
                return routeResponse
            } catch {
                print("Direct RouteResponse decoding failed: \(error)")

                // Try new webhook V2 array format
                if let v2Array = try? decoder.decode([WebhookV2TopLevel].self, from: data), let v2 = v2Array.first {
                    print("Decoded webhook V2 array with \(v2Array.count) items; converting")
                    let route = RouteInfo(
                        polyline: v2.route.polyline,
                        distanceKm: v2.route.distanceKm,
                        durationMinutes: v2.route.durationMinutes,
                        origin: v2.route.origin,
                        destination: v2.route.destination
                    )
                    
                    let selectedStations = v2.charging_plan.selected_stations.map { s in
                        RouteChargingStation(
                            stationName: s.stationName,
                            location: StationLocation(lat: s.location.latitude, lng: s.location.longitude),
                            address: s.address,
                            chargingSpeedKw: s.chargingSpeedKw,
                            detourKm: s.detourKm,
                            arrivalSOC: s.arrivalSOC ?? 0,
                            departureSOC: s.departureSOC ?? 0,
                            chargingTimeMinutes: s.chargingTimeMinutes ?? 0,
                            energyAddedKwh: s.energyAddedKwh ?? 0,
                            distanceFromOriginKm: s.distanceFromOriginKm ?? 0,
                            isCritical: s.isCritical ?? false,
                            reason: s.reason ?? "",
                            isSelected: true
                        )
                    }
                    
                    let allStations = v2.charging_plan.all_stations.map { s in
                        RouteChargingStation(
                            stationName: s.stationName,
                            location: StationLocation(lat: s.location.latitude, lng: s.location.longitude),
                            address: s.address,
                            chargingSpeedKw: s.chargingSpeedKw,
                            detourKm: s.detourKm,
                            arrivalSOC: s.arrivalSOC ?? 0,
                            departureSOC: s.departureSOC ?? 0,
                            chargingTimeMinutes: s.chargingTimeMinutes ?? 0,
                            energyAddedKwh: s.energyAddedKwh ?? 0,
                            distanceFromOriginKm: s.distanceFromOriginKm ?? 0,
                            isCritical: s.isCritical ?? false,
                            reason: s.reason ?? "",
                            isSelected: false
                        )
                    }
                    
                    let chargingPlan = ChargingPlan(
                        needed: v2.charging_plan.needed,
                        selectedStations: selectedStations,
                        allStations: allStations,
                        totalChargingTime: selectedStations.reduce(0) { $0 + $1.chargingTimeMinutes },
                        totalDetourKm: (selectedStations + allStations).reduce(0.0) { $0 + $1.detourKm },
                        totalEnergyAddedKwh: selectedStations.reduce(0.0) { $0 + $1.energyAddedKwh },
                        canCompleteWithoutCharging: !v2.charging_plan.needed
                    )
                    
                    let detourTime = v2.charging_plan.selected_stations.compactMap { $0.timeImpactMinutes }.filter { $0 > 0 }.reduce(0, +)
                    let summary = TripSummary(
                        origin: route.origin,
                        destination: route.destination,
                        baseDurationMinutes: route.durationMinutes,
                        chargingTimeMinutes: chargingPlan.totalChargingTime,
                        detourTimeMinutes: detourTime,
                        estimatedTotalDuration: route.durationMinutes + chargingPlan.totalChargingTime + detourTime
                    )
                    
                    let selectedSpeeds = selectedStations.map { $0.chargingSpeedKw }
                    let avgSpeed = selectedSpeeds.isEmpty ? 0 : selectedSpeeds.reduce(0.0, +) / Double(selectedSpeeds.count)
                    let minArrival = selectedStations.map { $0.arrivalSOC }.min() ?? 0
                    let onRoute = v2.charging_plan.all_stations.filter { $0.onRoute == true }.count
                    let statistics = RouteStatistics(
                        totalStationsFound: v2.charging_plan.all_stations.count,
                        onRouteStations: onRoute,
                        stationsSelected: selectedStations.count,
                        avgChargingSpeedSelected: avgSpeed,
                        totalEnergyRequired: chargingPlan.totalEnergyAddedKwh,
                        minSocReached: minArrival
                    )
                    
                    return RouteResponse(route: route, chargingPlan: chargingPlan, summary: summary, statistics: statistics)
                }

                // Fall back to older n8n array format with nested `response`
                if let responseArray = try? decoder.decode([N8NResponse].self, from: data), let firstResponse = responseArray.first {
                    print("Successfully decoded legacy n8n array; converting")
                    let routeData = firstResponse.response
                    let route = RouteInfo(
                        polyline: routeData.route.polyline,
                        distanceKm: routeData.route.distance_km,
                        durationMinutes: routeData.route.duration_minutes,
                        origin: routeData.route.origin,
                        destination: routeData.route.destination
                    )
                    let selectedStations = routeData.charging_plan.selected_stations.map { n in
                        RouteChargingStation(
                            stationName: n.station_name,
                            location: StationLocation(lat: n.location.latitude, lng: n.location.longitude),
                            address: n.address,
                            chargingSpeedKw: n.charging_speed_kw,
                            detourKm: n.detour_km,
                            arrivalSOC: n.arrival_SOC,
                            departureSOC: n.departure_SOC,
                            chargingTimeMinutes: n.charging_time_minutes,
                            energyAddedKwh: n.energy_added_kwh,
                            distanceFromOriginKm: n.distance_from_origin_km,
                            isCritical: n.is_critical,
                            reason: n.reason,
                            isSelected: n.is_selected
                        )
                    }
                    let allStations = routeData.charging_plan.all_stations.map { n in
                        RouteChargingStation(
                            stationName: n.station_name,
                            location: StationLocation(lat: n.location.latitude, lng: n.location.longitude),
                            address: n.address,
                            chargingSpeedKw: n.charging_speed_kw,
                            detourKm: n.detour_km,
                            arrivalSOC: n.arrival_SOC,
                            departureSOC: n.departure_SOC,
                            chargingTimeMinutes: n.charging_time_minutes,
                            energyAddedKwh: n.energy_added_kwh,
                            distanceFromOriginKm: n.distance_from_origin_km,
                            isCritical: n.is_critical,
                            reason: n.reason,
                            isSelected: n.is_selected
                        )
                    }
                    let chargingPlan = ChargingPlan(
                        needed: routeData.charging_plan.needed,
                        selectedStations: selectedStations,
                        allStations: allStations,
                        totalChargingTime: routeData.charging_plan.total_charging_time,
                        totalDetourKm: routeData.charging_plan.total_detour_km,
                        totalEnergyAddedKwh: routeData.charging_plan.total_energy_added_kwh,
                        canCompleteWithoutCharging: routeData.charging_plan.can_complete_without_charging
                    )
                    let summary = TripSummary(
                        origin: routeData.summary.origin,
                        destination: routeData.summary.destination,
                        baseDurationMinutes: routeData.summary.base_duration_minutes,
                        chargingTimeMinutes: routeData.summary.charging_time_minutes,
                        detourTimeMinutes: routeData.summary.detour_time_minutes,
                        estimatedTotalDuration: routeData.summary.estimated_total_duration
                    )
                    let statistics = RouteStatistics(
                        totalStationsFound: routeData.statistics.total_stations_found,
                        onRouteStations: routeData.statistics.on_route_stations,
                        stationsSelected: routeData.statistics.stations_selected,
                        avgChargingSpeedSelected: routeData.statistics.avg_charging_speed_selected,
                        totalEnergyRequired: routeData.statistics.total_energy_required,
                        minSocReached: routeData.statistics.min_soc_reached
                    )
                    return RouteResponse(route: route, chargingPlan: chargingPlan, summary: summary, statistics: statistics)
                }

                // Last-resort: permissive JSON mapping for array-of-object format
                if let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [[String: Any]], let first = json.first,
                   let routeDict = first["route"] as? [String: Any], let plan = first["charging_plan"] as? [String: Any] {
                    func dbl(_ any: Any?) -> Double { if let d = any as? Double { return d }; if let s = any as? String, let d = Double(s) { return d }; if let i = any as? Int { return Double(i) }; return 0 }
                    func int(_ any: Any?) -> Int { if let i = any as? Int { return i }; if let s = any as? String, let i = Int(s) { return i }; if let d = any as? Double { return Int(d) }; return 0 }
                    let route = RouteInfo(
                        polyline: routeDict["polyline"] as? String ?? "",
                        distanceKm: dbl(routeDict["distance_km"]),
                        durationMinutes: int(routeDict["duration_minutes"]),
                        origin: routeDict["origin"] as? String ?? "",
                        destination: routeDict["destination"] as? String ?? ""
                    )
                    func mapStations(_ arr: Any?, selected: Bool) -> [RouteChargingStation] {
                        guard let a = arr as? [[String: Any]] else { return [] }
                        return a.map { st in
                            let loc = st["location"] as? [String: Any]
                            let lat = dbl(loc?["latitude"])
                            let lng = dbl(loc?["longitude"])
                            return RouteChargingStation(
                                stationName: (st["station_name"] as? String) ?? (st["name"] as? String) ?? "",
                                location: StationLocation(lat: lat, lng: lng),
                                address: st["address"] as? String ?? "",
                                chargingSpeedKw: dbl(st["charging_speed_kw"]),
                                detourKm: dbl(st["detour_km"]),
                                arrivalSOC: dbl(st["arrival_SOC"]),
                                departureSOC: dbl(st["departure_SOC"]),
                                chargingTimeMinutes: int(st["charging_time_minutes"] ?? st["charging_duration_minutes"]),
                                energyAddedKwh: dbl(st["energy_added_kwh"]),
                                distanceFromOriginKm: dbl(st["distance_from_origin_km"]),
                                isCritical: (st["is_critical"] as? Bool) ?? false,
                                reason: st["reason"] as? String ?? "",
                                isSelected: selected
                            )
                        }
                    }
                    let selectedStations = mapStations(plan["selected_stations"], selected: true)
                    let allStations = mapStations(plan["all_stations"], selected: false)
                    let totalCharging = selectedStations.reduce(0) { $0 + $1.chargingTimeMinutes }
                    let totalDetour = (selectedStations + allStations).reduce(0.0) { $0 + $1.detourKm }
                    let totalEnergy = selectedStations.reduce(0.0) { $0 + $1.energyAddedKwh }
                    let detourTime = int((plan["selected_stations"] as? [[String: Any]])?.map { int($0["time_impact_minutes"]) }.filter { $0 > 0 }.reduce(0, +))
                    let chargingPlan = ChargingPlan(
                        needed: (plan["needed"] as? Bool) ?? true,
                        selectedStations: selectedStations,
                        allStations: allStations,
                        totalChargingTime: totalCharging,
                        totalDetourKm: totalDetour,
                        totalEnergyAddedKwh: totalEnergy,
                        canCompleteWithoutCharging: !((plan["needed"] as? Bool) ?? true)
                    )
                    let summary = TripSummary(
                        origin: route.origin,
                        destination: route.destination,
                        baseDurationMinutes: route.durationMinutes,
                        chargingTimeMinutes: totalCharging,
                        detourTimeMinutes: detourTime,
                        estimatedTotalDuration: route.durationMinutes + totalCharging + detourTime
                    )
                    let speeds = selectedStations.map { $0.chargingSpeedKw }
                    let avgSpeed = speeds.isEmpty ? 0 : speeds.reduce(0.0, +) / Double(speeds.count)
                    let minArrival = selectedStations.map { $0.arrivalSOC }.min() ?? 0
                    let onRoute = (plan["all_stations"] as? [[String: Any]])?.filter { ($0["on_route"] as? Bool) == true }.count ?? 0
                    let statistics = RouteStatistics(
                        totalStationsFound: allStations.count,
                        onRouteStations: onRoute,
                        stationsSelected: selectedStations.count,
                        avgChargingSpeedSelected: avgSpeed,
                        totalEnergyRequired: totalEnergy,
                        minSocReached: minArrival
                    )
                    return RouteResponse(route: route, chargingPlan: chargingPlan, summary: summary, statistics: statistics)
                }
                // If none of the decoding strategies returned, throw to outer catch
                throw NetworkError.decodingError
            }
        } catch {
            print("Decoding error: \(error)")
            if let decodingError = error as? DecodingError {
                switch decodingError {
                case .keyNotFound(let key, let context):
                    print("Key '\(key.stringValue)' not found: \(context.debugDescription)")
                    print("Coding path: \(context.codingPath)")
                case .typeMismatch(let type, let context):
                    print("Type mismatch for type '\(type)': \(context.debugDescription)")
                    print("Coding path: \(context.codingPath)")
                case .valueNotFound(let type, let context):
                    print("Value not found for type '\(type)': \(context.debugDescription)")
                    print("Coding path: \(context.codingPath)")
                case .dataCorrupted(let context):
                    print("Data corrupted: \(context.debugDescription)")
                    print("Coding path: \(context.codingPath)")
                @unknown default:
                    print("Unknown decoding error")
                }
            }
            // Create a more descriptive error message
            let errorMessage = "Failed to decode response: \(error.localizedDescription)"
            throw NetworkError.serverError(errorMessage)
        }
    }
}
