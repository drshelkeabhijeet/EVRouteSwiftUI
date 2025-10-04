import Foundation

struct User: Codable, Identifiable, Equatable {
    let id: String
    let email: String
    let name: String
    let createdAt: Date?
    
    enum CodingKeys: String, CodingKey {
        case id
        case email
        case name
        case createdAt = "created_at"
    }
}

struct LoginRequest: Codable {
    let email: String
    let password: String
}

struct SignupRequest: Codable {
    let email: String
    let password: String
    let name: String
}

struct AuthResponse: Codable {
    let user: User
    let token: String
}