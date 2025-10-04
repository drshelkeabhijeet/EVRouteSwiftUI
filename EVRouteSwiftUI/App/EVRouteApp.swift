import SwiftUI

@main
struct EVRouteApp: App {
    var body: some Scene {
        WindowGroup {
            MainTabView()
                .preferredColorScheme(.none)
        }
    }
}