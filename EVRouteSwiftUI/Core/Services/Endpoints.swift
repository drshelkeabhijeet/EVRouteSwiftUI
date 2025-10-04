import Foundation

// Auth Endpoints
enum AuthEndpoint: Endpoint {
    case login(email: String, password: String)
    case signup(email: String, password: String, name: String)
    
    var path: String {
        switch self {
        case .login:
            return "/auth/login"
        case .signup:
            return "/auth/signup"
        }
    }
    
    var method: HTTPMethod {
        switch self {
        case .login, .signup:
            return .post
        }
    }
    
    var body: Encodable? {
        switch self {
        case .login(let email, let password):
            return LoginRequest(email: email, password: password)
        case .signup(let email, let password, let name):
            return SignupRequest(email: email, password: password, name: name)
        }
    }
}

// Charging Station Endpoints
enum StationEndpoint: Endpoint {
    case nearbyStations(latitude: Double, longitude: Double, radius: Double)
    case stationDetails(id: String)
    
    var path: String {
        switch self {
        case .nearbyStations:
            // Route stations nearby queries through the n8n webhook
            return "/webhook/5c5cf1c2-edab-404e-8637-8e3c4a572f9d"
        case .stationDetails(let id):
            return "/stations/\(id)"
        }
    }
    
    var method: HTTPMethod {
        .get
    }
    
    var queryItems: [URLQueryItem]? {
        switch self {
        case .nearbyStations(let lat, let lng, let radius):
            return [
                URLQueryItem(name: "lat", value: String(lat)),
                URLQueryItem(name: "lng", value: String(lng)),
                URLQueryItem(name: "radius", value: String(radius))
            ]
        default:
            return nil
        }
    }
}

// Route Planning Endpoints
enum RouteEndpoint: Endpoint {
    case planRoute(request: RoutePlanRequest)
    case routeDetails(id: String)
    
    var path: String {
        switch self {
        case .planRoute:
            // Point planRoute to the provided n8n webhook
            return "/webhook/5c5cf1c2-edab-404e-8637-8e3c4a572f9d"
        case .routeDetails(let id):
            return "/route/\(id)"
        }
    }
    
    var method: HTTPMethod {
        switch self {
        case .planRoute:
            return .post
        case .routeDetails:
            return .get
        }
    }
    
    var body: Encodable? {
        switch self {
        case .planRoute(let request):
            return request
        default:
            return nil
        }
    }
}
