import Foundation
import CoreLocation

// MARK: - Models

struct NearbyStation: Decodable, Identifiable, Equatable {
    var id: String { "\(name)_\(latitude)_\(longitude)" }
    let name: String
    let address: String?
    let latitude: Double
    let longitude: Double
    let chargingSpeedKw: Double?
    let isSelected: Bool

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    private enum CodingKeys: String, CodingKey {
        case name
        case stationName = "station_name"
        case address
        case location
        case latitude
        case longitude
        case lat
        case lng
        case chargingSpeedKw = "charging_speed_kw"
        case isSelected = "is_selected"
        case selected
        case best
        case isBest = "is_best"
    }

    struct LocationObj: Codable {
        let latitude: Double?
        let longitude: Double?
        let lat: Double?
        let lng: Double?
    }

    init(name: String, address: String?, latitude: Double, longitude: Double, chargingSpeedKw: Double?, isSelected: Bool) {
        self.name = name
        self.address = address
        self.latitude = latitude
        self.longitude = longitude
        self.chargingSpeedKw = chargingSpeedKw
        self.isSelected = isSelected
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)

        // Name with multiple fallbacks
        if let n = try? c.decode(String.self, forKey: .stationName) {
            name = n
        } else if let n = try? c.decode(String.self, forKey: .name) {
            name = n
        } else {
            name = ""
        }

        address = try? c.decode(String.self, forKey: .address)

        // Coordinates from nested location or flat keys
        var latVal: Double? = try? c.decode(Double.self, forKey: .latitude)
        var lngVal: Double? = try? c.decode(Double.self, forKey: .longitude)
        if latVal == nil || lngVal == nil {
            let loc = try? c.decode(LocationObj.self, forKey: .location)
            latVal = latVal ?? loc?.latitude ?? loc?.lat
            lngVal = lngVal ?? loc?.longitude ?? loc?.lng
        }
        if latVal == nil { latVal = try? c.decode(Double.self, forKey: .lat) }
        if lngVal == nil { lngVal = try? c.decode(Double.self, forKey: .lng) }

        latitude = latVal ?? 0
        longitude = lngVal ?? 0

        chargingSpeedKw = try? c.decode(Double.self, forKey: .chargingSpeedKw)

        // Selection flag with multiple possible keys
        let selected1 = (try? c.decode(Bool.self, forKey: .isSelected)) ?? false
        let selected2 = (try? c.decode(Bool.self, forKey: .selected)) ?? false
        let selected3 = (try? c.decode(Bool.self, forKey: .best)) ?? false
        let selected4 = (try? c.decode(Bool.self, forKey: .isBest)) ?? false
        isSelected = selected1 || selected2 || selected3 || selected4
    }
}

// MARK: - Service

@MainActor
final class NearbyStationsService {
    static let shared = NearbyStationsService()

    // Dedicated webhook for Nearby Stations (not the route planning one)
    private let webhookURL = "https://abhijeetshelke.app.n8n.cloud/webhook/545c8277-554b-460d-89c5-5785fb99c782"

    private init() {}

    struct NearbyRequest: Encodable {
        let latitude: Double
        let longitude: Double
        let radius_km: Double
        let location: String // "lat,lng" convenience for flows expecting string
    }

    func fetchNearbyStations(latitude: Double, longitude: Double, radiusKm: Double) async throws -> [NearbyStation] {
        guard let url = URL(string: webhookURL) else { throw NetworkError.invalidURL }

        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let payload = NearbyRequest(latitude: latitude, longitude: longitude, radius_km: radiusKm, location: "\(latitude),\(longitude)")
        req.httpBody = try JSONEncoder().encode(payload)

        let (data, response) = try await URLSession.shared.data(for: req)
        guard let http = response as? HTTPURLResponse else {
            throw NetworkError.serverError("Nearby stations request failed: invalid response")
        }
        if !(200...299).contains(http.statusCode) {
            let body = String(data: data, encoding: .utf8) ?? "<no body>"
            let msg = "Nearby stations request failed (status: \(http.statusCode)) body: \(body)"
            print(msg)
            throw NetworkError.serverError(msg)
        }

        // Flexible decoding: try raw array, then {stations:[...]}, else numeric keys or first element
        let decoder = JSONDecoder()
        do {
            // Debug log
            if let bodyStr = String(data: data, encoding: .utf8) {
                print("Nearby response: \(bodyStr)")
                // Treat empty/blank body as no results instead of error
                let trimmed = bodyStr.trimmingCharacters(in: .whitespacesAndNewlines)
                if trimmed.isEmpty { return [] }
                // Extract JSON array between first '[' and last ']' if wrappers exist
                if let firstBracket = trimmed.firstIndex(of: "["), let lastBracket = trimmed.lastIndex(of: "]"), firstBracket < lastBracket {
                    let inner = String(trimmed[firstBracket...lastBracket])
                    if let innerData = inner.data(using: .utf8) {
                        if let any = try? JSONSerialization.jsonObject(with: innerData, options: []) as? [[String: Any]] {
                            return any.compactMap { Self.mapLooseStation($0) }
                        }
                        if let arr = try? decoder.decode([NearbyStation].self, from: innerData) { return arr }
                    }
                }
                // Handle bodies wrapped in triple quotes or a single JSON string containing JSON
                // Example: """ [ { ... }, ... ] """
                if trimmed.hasPrefix("\"\"\"") && trimmed.hasSuffix("\"\"\"") {
                    let inner = String(trimmed.dropFirst(3).dropLast(3))
                    if let innerData = inner.data(using: .utf8) {
                        if let arr = try? decoder.decode([NearbyStation].self, from: innerData) { return arr }
                        if let any = try? JSONSerialization.jsonObject(with: innerData, options: []) as? [[String: Any]] {
                            return any.compactMap { Self.mapLooseStation($0) }
                        }
                    }
                }
                // JSON string literal containing JSON
                if trimmed.first == "\"", trimmed.last == "\"" {
                    let inner = String(trimmed.dropFirst().dropLast())
                    if let innerData = inner.data(using: .utf8) {
                        if let arr = try? decoder.decode([NearbyStation].self, from: innerData) { return arr }
                        if let any = try? JSONSerialization.jsonObject(with: innerData, options: []) as? [[String: Any]] {
                            return any.compactMap { Self.mapLooseStation($0) }
                        }
                    }
                }
            } else if data.isEmpty {
                return []
            }
            if let arr = try? decoder.decode([NearbyStation].self, from: data) {
                return arr
            }
            struct Wrapper: Decodable { let stations: [NearbyStation]? }
            if let wrap = try? decoder.decode(Wrapper.self, from: data), let stations = wrap.stations { return stations }

            // Array-of-object where the first item contains stations
            if let any = try? JSONSerialization.jsonObject(with: data, options: []) {
                if let arr = any as? [[String: Any]] {
                    // Empty array -> no results
                    if arr.isEmpty { return [] }
                    // n8n items shape: [{ json: {....}}, ...]
                    if arr.first?["json"] is [String: Any] {
                        let stationDicts = arr.compactMap { $0["json"] as? [String: Any] }
                        return stationDicts.compactMap { Self.mapLooseStation($0) }
                    }
                    // Array where first element has nested 'stations'
                    if let stationsAny = arr.first?["stations"] as? [[String: Any]] {
                        return stationsAny.compactMap { Self.mapLooseStation($0) }
                    }
                    // Direct array of station dicts
                    return arr.compactMap { Self.mapLooseStation($0) }
                } else if let dict = any as? [String: Any] {
                    if let stationsAny = dict["stations"] as? [[String: Any]] {
                        return stationsAny.compactMap { Self.mapLooseStation($0) }
                    }
                    if let one = Self.mapLooseStation(dict) { return [one] }
                }
            }
        }

        throw NetworkError.decodingError
    }

    private static func mapLooseStation(_ st: [String: Any]) -> NearbyStation? {
        func dbl(_ v: Any?) -> Double? {
            if let d = v as? Double { return d }
            if let i = v as? Int { return Double(i) }
            if let s = v as? String, let d = Double(s) { return d }
            return nil
        }
        let name = (st["station_name"] as? String) ?? (st["name"] as? String) ?? ""
        let address = st["address"] as? String
        var lat: Double? = dbl(st["latitude"]) ?? dbl(st["lat"]) 
        var lng: Double? = dbl(st["longitude"]) ?? dbl(st["lng"]) 
        if let loc = st["location"] as? [String: Any] {
            lat = lat ?? dbl(loc["latitude"]) ?? dbl(loc["lat"]) 
            lng = lng ?? dbl(loc["longitude"]) ?? dbl(loc["lng"]) 
        }
        guard let latitude = lat, let longitude = lng else { return nil }
        let speed = dbl(st["charging_speed_kw"]) 
        let isSelected = (st["is_selected"] as? Bool) ?? (st["selected"] as? Bool) ?? (st["best"] as? Bool) ?? (st["is_best"] as? Bool) ?? false
        return NearbyStation(name: name, address: address, latitude: latitude, longitude: longitude, chargingSpeedKw: speed, isSelected: isSelected)
    }
}
