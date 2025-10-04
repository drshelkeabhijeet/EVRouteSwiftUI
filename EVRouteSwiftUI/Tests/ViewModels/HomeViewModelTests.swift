import XCTest
@testable import EVRouteSwiftUI
import Combine

final class HomeViewModelTests: XCTestCase {
    var viewModel: HomeViewModel!
    var mockNetworkService: MockNetworkService!
    var cancellables: Set<AnyCancellable>!
    
    override func setUp() {
        super.setUp()
        mockNetworkService = MockNetworkService()
        viewModel = HomeViewModel(networkService: mockNetworkService)
        cancellables = []
    }
    
    override func tearDown() {
        viewModel = nil
        mockNetworkService = nil
        cancellables = nil
        super.tearDown()
    }
    
    func testLoadNearbyStationsSuccess() async {
        // Given
        let expectedStations = [
            ChargingStation.mockStation(id: "1", name: "Station 1", distance: 1000),
            ChargingStation.mockStation(id: "2", name: "Station 2", distance: 2000),
            ChargingStation.mockStation(id: "3", name: "Station 3", distance: 500)
        ]
        mockNetworkService.mockResponse = expectedStations
        
        // When
        await viewModel.loadNearbyStations()
        
        // Then
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNil(viewModel.error)
        XCTAssertEqual(viewModel.nearbyStations.count, 3)
        XCTAssertEqual(viewModel.nearbyStations.first?.id, "3") // Should be sorted by distance
    }
    
    func testLoadNearbyStationsFailure() async {
        // Given
        mockNetworkService.shouldFail = true
        mockNetworkService.mockError = NetworkError.noInternet
        
        // When
        await viewModel.loadNearbyStations()
        
        // Then
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNotNil(viewModel.error)
        XCTAssertTrue(viewModel.nearbyStations.isEmpty)
    }
    
    func testSearchStationsFiltersResults() async {
        // Given
        let stations = [
            ChargingStation.mockStation(id: "1", name: "Tesla Supercharger"),
            ChargingStation.mockStation(id: "2", name: "Electrify America"),
            ChargingStation.mockStation(id: "3", name: "Tesla Service Center")
        ]
        mockNetworkService.mockResponse = stations
        await viewModel.loadNearbyStations()
        
        // When
        viewModel.searchText = "Tesla"
        await viewModel.searchStations()
        
        // Then
        XCTAssertEqual(viewModel.nearbyStations.count, 2)
        XCTAssertTrue(viewModel.nearbyStations.allSatisfy { $0.name.contains("Tesla") })
    }
    
    func testSearchTextDebounce() {
        // Given
        let expectation = XCTestExpectation(description: "Debounce search")
        var searchCallCount = 0
        
        viewModel.$searchText
            .dropFirst() // Skip initial value
            .sink { _ in
                searchCallCount += 1
            }
            .store(in: &cancellables)
        
        // When
        viewModel.searchText = "T"
        viewModel.searchText = "Te"
        viewModel.searchText = "Tes"
        viewModel.searchText = "Test"
        
        // Then
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            XCTAssertEqual(searchCallCount, 4) // All changes should be captured
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1.0)
    }
}

// MARK: - Mock Network Service

class MockNetworkService: NetworkServiceProtocol {
    var mockResponse: Any?
    var mockError: Error?
    var shouldFail = false
    
    func request<T>(_ endpoint: Endpoint) async throws -> T where T : Decodable {
        if shouldFail {
            throw mockError ?? NetworkError.serverError("Mock error")
        }
        
        guard let response = mockResponse as? T else {
            throw NetworkError.noData
        }
        
        return response
    }
}

// MARK: - Test Helpers

extension ChargingStation {
    static func mockStation(
        id: String = UUID().uuidString,
        name: String = "Test Station",
        distance: Double? = nil
    ) -> ChargingStation {
        ChargingStation(
            id: id,
            name: name,
            address: "123 Test St",
            latitude: 37.7749,
            longitude: -122.4194,
            connectors: [
                Connector(id: "1", type: .ccs, power: 150, status: .available)
            ],
            availability: Availability(totalConnectors: 4, availableConnectors: 2, lastUpdated: Date()),
            amenities: ["WiFi", "Restroom"],
            pricePerKwh: 0.32,
            rating: 4.5,
            distance: distance
        )
    }
}