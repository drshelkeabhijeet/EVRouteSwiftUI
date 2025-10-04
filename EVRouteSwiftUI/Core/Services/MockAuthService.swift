import Foundation

// Mock service for testing without backend
final class MockAuthService {
    static let shared = MockAuthService()
    
    private init() {}
    
    func login(email: String, password: String) async throws -> AuthResponse {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
        
        // Create mock user
        let user = User(
            id: UUID().uuidString,
            email: email,
            name: "Test User",
            createdAt: Date()
        )
        
        return AuthResponse(user: user, token: "mock-token-123")
    }
    
    func signup(email: String, password: String, name: String) async throws -> AuthResponse {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
        
        // Create mock user
        let user = User(
            id: UUID().uuidString,
            email: email,
            name: name,
            createdAt: Date()
        )
        
        return AuthResponse(user: user, token: "mock-token-123")
    }
}