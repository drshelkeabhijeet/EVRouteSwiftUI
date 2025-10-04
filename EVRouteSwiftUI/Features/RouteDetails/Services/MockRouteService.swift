import Foundation

// Mock service for testing when webhook isn't available
extension RouteService {
    func planRouteMock(request: RoutePlanRequest) async throws -> RouteResponse {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 1_500_000_000) // 1.5 seconds
        
        // Create mock response
        let mockResponse = RouteResponse(
            route: RouteInfo(
                polyline: "u{~vFvyys@fS]", // Sample polyline
                distanceKm: 285.5,
                durationMinutes: 180,
                origin: request.origin,
                destination: request.destination
            ),
            chargingPlan: ChargingPlan(
                needed: true,
                selectedStations: [
                    RouteChargingStation(
                        stationName: "Tesla Supercharger - Gilroy",
                        location: StationLocation(lat: 37.0058, lng: -121.5683),
                        address: "681 Leavesley Rd, Gilroy, CA 95020",
                        chargingSpeedKw: 250,
                        detourKm: 2.3,
                        arrivalSOC: 25,
                        departureSOC: 80,
                        chargingTimeMinutes: 22,
                        energyAddedKwh: 41.25,
                        distanceFromOriginKm: 120,
                        isCritical: true,
                        reason: "Required to reach destination",
                        isSelected: true
                    )
                ],
                allStations: [],
                totalChargingTime: 22,
                totalDetourKm: 2.3,
                totalEnergyAddedKwh: 41.25,
                canCompleteWithoutCharging: false
            ),
            summary: TripSummary(
                origin: "San Francisco, CA",
                destination: "Los Angeles, CA",
                baseDurationMinutes: 180,
                chargingTimeMinutes: 22,
                detourTimeMinutes: 5,
                estimatedTotalDuration: 207
            ),
            statistics: RouteStatistics(
                totalStationsFound: 15,
                onRouteStations: 8,
                stationsSelected: 1,
                avgChargingSpeedSelected: 250,
                totalEnergyRequired: 85.5,
                minSocReached: 15
            )
        )
        
        return mockResponse
    }
}