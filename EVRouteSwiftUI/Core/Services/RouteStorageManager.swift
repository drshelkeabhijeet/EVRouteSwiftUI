import Foundation

class RouteStorageManager {
    static let shared = RouteStorageManager()
    private let userDefaults = UserDefaults.standard
    private let savedRoutesKey = "savedRoutes"
    
    private init() {}
    
    func saveRoute(_ route: SavedRoute) {
        var routes = getSavedRoutes()
        routes.insert(route, at: 0) // Add to beginning
        
        // Keep only last 50 routes
        if routes.count > 50 {
            routes = Array(routes.prefix(50))
        }
        
        if let encoded = try? JSONEncoder().encode(routes) {
            userDefaults.set(encoded, forKey: savedRoutesKey)
        }
    }
    
    func getSavedRoutes() -> [SavedRoute] {
        guard let data = userDefaults.data(forKey: savedRoutesKey),
              let routes = try? JSONDecoder().decode([SavedRoute].self, from: data) else {
            return []
        }
        return routes
    }
    
    func deleteRoute(_ route: SavedRoute) {
        var routes = getSavedRoutes()
        routes.removeAll { $0.id == route.id }
        
        if let encoded = try? JSONEncoder().encode(routes) {
            userDefaults.set(encoded, forKey: savedRoutesKey)
        }
    }
    
    func clearAllRoutes() {
        userDefaults.removeObject(forKey: savedRoutesKey)
    }
}