import Foundation
import Combine
import Supabase

enum AuthError: LocalizedError {
    case emailConfirmationRequired
    
    var errorDescription: String? {
        switch self {
        case .emailConfirmationRequired:
            return "Please check your email and click the confirmation link to activate your account."
        }
    }
}

@MainActor
final class AuthManager: ObservableObject {
    static let shared = AuthManager()
    
    @Published private(set) var currentUser: User?
    @Published private(set) var isAuthenticated = false
    @Published private(set) var isLoading = false
    
    private let supabase = SupabaseManager.shared.client
    
    private init() {
        Task {
            await checkAuthState()
        }
    }
    
    func signUp(email: String, password: String, name: String, phone: String, displayName: String) async throws {
        isLoading = true
        defer { isLoading = false }
        
        let response = try await supabase.auth.signUp(
            email: email,
            password: password,
            data: [
                "name": .string(name),
                "phone": .string(phone),
                "display_name": .string(displayName)
            ]
        )
        
        // For email confirmation, we don't automatically authenticate
        // The user needs to confirm their email first
        // We'll throw a custom error to indicate email confirmation is needed
        if response.session == nil {
            throw AuthError.emailConfirmationRequired
        }
        
        if let session = response.session {
            currentUser = User(
                id: session.user.id.uuidString,
                email: session.user.email ?? "",
                name: name,
                phone: phone,
                displayName: displayName,
                profileImageUrl: nil,
                createdAt: Date(),
                updatedAt: Date()
            )
            isAuthenticated = true
        }
    }
    
    func signIn(email: String, password: String) async throws {
        isLoading = true
        defer { isLoading = false }
        
        let response = try await supabase.auth.signIn(
            email: email,
            password: password
        )
        
        let userName = response.user.userMetadata["name"]?.stringValue ?? ""
        let userPhone = response.user.userMetadata["phone"]?.stringValue
        let userDisplayName = response.user.userMetadata["display_name"]?.stringValue
        let profileImageUrl = response.user.userMetadata["profile_image_url"]?.stringValue
        
        currentUser = User(
            id: response.user.id.uuidString,
            email: response.user.email ?? "",
            name: userName,
            phone: userPhone,
            displayName: userDisplayName,
            profileImageUrl: profileImageUrl,
            createdAt: Date(),
            updatedAt: Date()
        )
        isAuthenticated = true
    }
    
    func signOut() async throws {
        try await supabase.auth.signOut()
        currentUser = nil
        isAuthenticated = false
    }
    
    private func checkAuthState() async {
        do {
            let session = try await supabase.auth.session
            let userName = session.user.userMetadata["name"]?.stringValue ?? ""
            let userPhone = session.user.userMetadata["phone"]?.stringValue
            let userDisplayName = session.user.userMetadata["display_name"]?.stringValue
            let profileImageUrl = session.user.userMetadata["profile_image_url"]?.stringValue
            
            currentUser = User(
                id: session.user.id.uuidString,
                email: session.user.email ?? "",
                name: userName,
                phone: userPhone,
                displayName: userDisplayName,
                profileImageUrl: profileImageUrl,
                createdAt: Date(),
                updatedAt: Date()
            )
            isAuthenticated = true
        } catch {
            // No active session
            currentUser = nil
            isAuthenticated = false
        }
    }
}
