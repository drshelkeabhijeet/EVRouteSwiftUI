import Foundation
import Security
import Combine

@MainActor
final class AuthManager: ObservableObject {
    static let shared = AuthManager()
    
    @Published private(set) var currentUser: User?
    @Published private(set) var isAuthenticated = false
    
    private let keychain = KeychainService()
    private let userDefaults = UserDefaults.standard
    
    private let tokenKey = "auth_token"
    private let userKey = "current_user"
    
    private init() {
        Task {
            await loadStoredAuth()
        }
    }
    
    func login(email: String, password: String) async throws {
        // TODO: Switch to real API when ready
        // let endpoint = AuthEndpoint.login(email: email, password: password)
        // let response: AuthResponse = try await NetworkService.shared.request(endpoint)
        
        // Using mock service for now
        let response = try await MockAuthService.shared.login(email: email, password: password)
        
        try keychain.save(response.token, forKey: tokenKey)
        currentUser = response.user
        isAuthenticated = true
        
        // Save user to UserDefaults
        if let userData = try? JSONEncoder().encode(response.user) {
            userDefaults.set(userData, forKey: userKey)
        }
    }
    
    func signup(email: String, password: String, name: String) async throws {
        // TODO: Switch to real API when ready
        // let endpoint = AuthEndpoint.signup(email: email, password: password, name: name)
        // let response: AuthResponse = try await NetworkService.shared.request(endpoint)
        
        // Using mock service for now
        let response = try await MockAuthService.shared.signup(email: email, password: password, name: name)
        
        try keychain.save(response.token, forKey: tokenKey)
        currentUser = response.user
        isAuthenticated = true
        
        // Save user to UserDefaults
        if let userData = try? JSONEncoder().encode(response.user) {
            userDefaults.set(userData, forKey: userKey)
        }
    }
    
    func logout() {
        try? keychain.delete(forKey: tokenKey)
        userDefaults.removeObject(forKey: userKey)
        currentUser = nil
        isAuthenticated = false
    }
    
    func getToken() async -> String? {
        try? keychain.load(forKey: tokenKey)
    }
    
    private func loadStoredAuth() async {
        // Load token
        if let token = try? keychain.load(forKey: tokenKey),
           !token.isEmpty {
            // Load user
            if let userData = userDefaults.data(forKey: userKey),
               let user = try? JSONDecoder().decode(User.self, from: userData) {
                currentUser = user
                isAuthenticated = true
            }
        }
    }
}

// Keychain Service
final class KeychainService {
    enum KeychainError: Error {
        case duplicateItem
        case itemNotFound
        case unexpectedData
        case unhandledError(status: OSStatus)
    }
    
    func save(_ string: String, forKey key: String) throws {
        guard let data = string.data(using: .utf8) else {
            throw KeychainError.unexpectedData
        }
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecValueData as String: data
        ]
        
        // Try to delete existing item first
        SecItemDelete(query as CFDictionary)
        
        let status = SecItemAdd(query as CFDictionary, nil)
        
        guard status == errSecSuccess else {
            throw KeychainError.unhandledError(status: status)
        }
    }
    
    func load(forKey key: String) throws -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var dataTypeRef: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &dataTypeRef)
        
        switch status {
        case errSecSuccess:
            guard let data = dataTypeRef as? Data,
                  let string = String(data: data, encoding: .utf8) else {
                throw KeychainError.unexpectedData
            }
            return string
        case errSecItemNotFound:
            return nil
        default:
            throw KeychainError.unhandledError(status: status)
        }
    }
    
    func delete(forKey key: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.unhandledError(status: status)
        }
    }
}