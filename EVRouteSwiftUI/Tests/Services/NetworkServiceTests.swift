import XCTest
@testable import EVRouteSwiftUI

final class NetworkServiceTests: XCTestCase {
    var networkService: NetworkService!
    var mockURLSession: MockURLSession!
    
    override func setUp() {
        super.setUp()
        mockURLSession = MockURLSession()
        networkService = NetworkService(session: mockURLSession)
    }
    
    override func tearDown() {
        networkService = nil
        mockURLSession = nil
        super.tearDown()
    }
    
    func testSuccessfulRequest() async throws {
        // Given
        let expectedUser = User(id: "123", email: "test@example.com", name: "Test User", createdAt: Date())
        let responseData = try JSONEncoder().encode(AuthResponse(user: expectedUser, token: "test-token"))
        mockURLSession.mockData = responseData
        mockURLSession.mockResponse = HTTPURLResponse(
            url: URL(string: "https://example.com")!,
            statusCode: 200,
            httpVersion: nil,
            headerFields: nil
        )
        
        // When
        let endpoint = MockEndpoint()
        let response: AuthResponse = try await networkService.request(endpoint)
        
        // Then
        XCTAssertEqual(response.user.id, expectedUser.id)
        XCTAssertEqual(response.user.email, expectedUser.email)
        XCTAssertEqual(response.token, "test-token")
    }
    
    func testUnauthorizedError() async {
        // Given
        mockURLSession.mockData = Data()
        mockURLSession.mockResponse = HTTPURLResponse(
            url: URL(string: "https://example.com")!,
            statusCode: 401,
            httpVersion: nil,
            headerFields: nil
        )
        
        // When/Then
        let endpoint = MockEndpoint()
        do {
            let _: AuthResponse = try await networkService.request(endpoint)
            XCTFail("Expected unauthorized error")
        } catch {
            XCTAssertEqual(error as? NetworkError, NetworkError.unauthorized)
        }
    }
    
    func testDecodingError() async {
        // Given
        mockURLSession.mockData = Data("invalid json".utf8)
        mockURLSession.mockResponse = HTTPURLResponse(
            url: URL(string: "https://example.com")!,
            statusCode: 200,
            httpVersion: nil,
            headerFields: nil
        )
        
        // When/Then
        let endpoint = MockEndpoint()
        do {
            let _: AuthResponse = try await networkService.request(endpoint)
            XCTFail("Expected decoding error")
        } catch {
            XCTAssertEqual(error as? NetworkError, NetworkError.decodingError)
        }
    }
    
    func testServerError() async {
        // Given
        let errorResponse = ErrorResponse(message: "Server error occurred", code: "SERVER_ERROR")
        let errorData = try! JSONEncoder().encode(errorResponse)
        mockURLSession.mockData = errorData
        mockURLSession.mockResponse = HTTPURLResponse(
            url: URL(string: "https://example.com")!,
            statusCode: 500,
            httpVersion: nil,
            headerFields: nil
        )
        
        // When/Then
        let endpoint = MockEndpoint()
        do {
            let _: AuthResponse = try await networkService.request(endpoint)
            XCTFail("Expected server error")
        } catch {
            if case NetworkError.serverError(let message) = error {
                XCTAssertEqual(message, "Server error occurred")
            } else {
                XCTFail("Wrong error type")
            }
        }
    }
}

// MARK: - Mock URL Session

class MockURLSession: URLSession {
    var mockData: Data?
    var mockResponse: URLResponse?
    var mockError: Error?
    
    override func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        if let error = mockError {
            throw error
        }
        
        let data = mockData ?? Data()
        let response = mockResponse ?? URLResponse()
        
        return (data, response)
    }
}

// MARK: - Mock Endpoint

struct MockEndpoint: Endpoint {
    var path: String = "/test"
    var method: HTTPMethod = .get
}