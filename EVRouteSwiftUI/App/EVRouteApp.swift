import SwiftUI

@main
struct EVRouteApp: App {
    @StateObject private var authManager = AuthManager.shared
    
    var body: some Scene {
        WindowGroup {
            if authManager.isAuthenticated {
                MainTabView()
            } else {
                LandingView()
            }
        }
        .environmentObject(authManager)
    }
}