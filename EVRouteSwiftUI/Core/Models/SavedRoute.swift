import Foundation

struct SavedRoute: Identifiable, Codable {
    let id: UUID
    let date: Date
    let origin: String
    let destination: String
    let distance: Double
    let duration: Int
    let chargingStops: Int
    let vehicle: String?
    let routeResponse: RouteResponse?
    
    init(id: UUID = UUID(), date: Date, origin: String, destination: String, distance: Double, duration: Int, chargingStops: Int, vehicle: String?, routeResponse: RouteResponse?) {
        self.id = id
        self.date = date
        self.origin = origin
        self.destination = destination
        self.distance = distance
        self.duration = duration
        self.chargingStops = chargingStops
        self.vehicle = vehicle
        self.routeResponse = routeResponse
    }
    
    static let mockRoutes = [
        SavedRoute(
            date: Date().addingTimeInterval(-86400),
            origin: "San Francisco",
            destination: "Los Angeles",
            distance: 615,
            duration: 420,
            chargingStops: 2,
            vehicle: "Tesla Model 3",
            routeResponse: nil
        ),
        SavedRoute(
            date: Date().addingTimeInterval(-172800),
            origin: "San Jose",
            destination: "Sacramento",
            distance: 195,
            duration: 120,
            chargingStops: 0,
            vehicle: "Nissan Leaf",
            routeResponse: nil
        )
    ]
}