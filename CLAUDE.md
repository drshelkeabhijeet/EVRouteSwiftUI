# EV Route SwiftUI - Project Documentation

## Project Overview
A modern iOS application for electric vehicle route planning built with SwiftUI, following MVVM architecture and best practices.

**Tech Stack:**
- SwiftUI (iOS 17+)
- MVVM Architecture
- Combine Framework
- async/await for networking
- Swift Package Manager
- XCTest for unit testing

## Architecture

### MVVM Pattern
```
Views (SwiftUI) <-> ViewModels (ObservableObject) <-> Models/Services
```

### Project Structure
```
EVRouteSwiftUI/
├── App/
│   ├── EVRouteApp.swift
│   └── ContentView.swift
├── Core/
│   ├── Models/
│   ├── Services/
│   ├── Utilities/
│   └── Extensions/
├── Features/
│   ├── Home/
│   │   ├── Views/
│   │   └── ViewModels/
│   ├── RouteDetails/
│   │   ├── Views/
│   │   └── ViewModels/
│   ├── ChargingStations/
│   │   ├── Views/
│   │   └── ViewModels/
│   └── Profile/
│       ├── Views/
│       └── ViewModels/
├── Resources/
└── Tests/
```

## Coding Style

### Swift Style Guide
- Use descriptive variable names
- Follow Swift API Design Guidelines
- Use `private` for implementation details
- Prefer `let` over `var`
- Use trailing closures when appropriate
- Group related functionality with `// MARK: -`

### SwiftUI Best Practices
- Extract reusable views into separate components
- Use `@StateObject` for view-owned ObservableObjects
- Use `@ObservedObject` for injected ObservableObjects
- Implement proper accessibility labels
- Support both light and dark modes
- Use environment values for dependency injection

### Example ViewModel
```swift
@MainActor
final class HomeViewModel: ObservableObject {
    @Published private(set) var isLoading = false
    @Published private(set) var error: Error?
    @Published private(set) var stations: [ChargingStation] = []
    
    private let networkService: NetworkServiceProtocol
    
    init(networkService: NetworkServiceProtocol = NetworkService()) {
        self.networkService = networkService
    }
    
    func loadStations() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            stations = try await networkService.fetchNearbyStations()
        } catch {
            self.error = error
        }
    }
}
```

## API Endpoints
- Base URL: `https://abhijeetshelke.app.n8n.cloud`
- `/auth/login` - User authentication
- `/auth/signup` - User registration  
- `/route/plan` - Route planning with charging stations
- `/stations/nearby` - Get nearby charging stations

**Note**: Currently using `MockAuthService` for authentication. To switch to real API:
1. Open `AuthManager.swift`
2. Uncomment the original network code
3. Comment out the mock service calls

## Dependencies (Swift Package Manager)
- None required initially (using native frameworks)
- Future considerations:
  - Alamofire (if needed for complex networking)
  - SwiftLint (for code quality)

## Testing

### Unit Tests
Run tests with: `cmd+U` in Xcode or `xcodebuild test`

Test coverage targets:
- ViewModels: 90%+
- Services: 90%+
- Models: 100%
- Utilities: 90%+

### Example Test
```swift
final class HomeViewModelTests: XCTestCase {
    func testLoadStationsSuccess() async {
        // Given
        let mockService = MockNetworkService()
        let viewModel = HomeViewModel(networkService: mockService)
        
        // When
        await viewModel.loadStations()
        
        // Then
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNil(viewModel.error)
        XCTAssertEqual(viewModel.stations.count, 3)
    }
}
```

## Build & Run

### Requirements
- Xcode 15+
- iOS 17+ deployment target
- macOS Sonoma or later

### Build Instructions
1. Open `EVRouteSwiftUI.xcodeproj` in Xcode
2. Select target device/simulator
3. Press `Cmd+R` to build and run

### Environment Setup
Create `Config.xcconfig` file (not tracked in git):
```
API_BASE_URL = https://abhijeetshelke.app.n8n.cloud
GOOGLE_MAPS_API_KEY = your_api_key_here
```

## Features

### Implemented
- [x] User authentication (login/signup) - with mock service
- [x] Location-based charging station search
- [x] Route planning UI with EV considerations
- [x] Station details view
- [x] User profile management
- [x] Vehicle management system
- [ ] Offline support for saved routes
- [x] Dark mode support
- [ ] Accessibility support (partial)

### Future Enhancements
- Real-time charging station availability
- Social features (reviews, check-ins)
- Multi-language support
- Apple Watch companion app
- Widget support
- CarPlay integration

## Accessibility
- All interactive elements have accessibility labels
- VoiceOver fully supported
- Dynamic Type supported
- High contrast mode compatible
- Reduced motion respected

## Security
- Keychain for secure token storage
- Certificate pinning for API calls
- No sensitive data in UserDefaults
- Input validation on all forms

## Troubleshooting

### Build Errors
1. **"None of the input catalogs contained AppIcon"**
   - Open Assets.xcassets
   - Right-click → "App Icons & Launch Images" → "New iOS App Icon"

2. **Test files showing errors in main target**
   - Ensure test files are only in EVRouteSwiftUITests target
   - Remove them from main app target in Build Phases

3. **Duplicate file errors**
   - Check for duplicate folders (EVRouteSwiftUI/EVRouteSwiftUI)
   - Use files from root folders only (App, Core, Features, Tests)

### Mock Services
- `MockAuthService` - Provides fake authentication without backend
- Returns success after 1 second delay
- Creates mock user with provided email/name

### Current Status
- ✅ App builds and runs successfully
- ✅ Authentication flow with mock data
- ✅ Tab navigation implemented (Route tab as home screen)
- ✅ Map view with full-screen background centered on user location
- ✅ Dark/Light mode support
- ✅ Vehicle management system (auto-selects first vehicle)
- ✅ Route planning UI with transparent glass morphism design
- ✅ Battery status slider (transparent, no icon/text)
- ✅ Location autocomplete with proper dropdown visibility
- ✅ n8n webhook integration working
- ✅ Route results display
- ⏳ Charging station location data (webhook returns 0,0 coordinates)

### Recent Updates (August 3, 2025)
- **UI Redesign Complete**:
  - Route tab is now the home/first screen
  - Full-screen map background centered on user location (10km radius)
  - Removed vehicle selection and amenity preferences from route planning
  - All UI elements use transparent glass morphism (.ultraThinMaterial)
  - Fixed autocomplete dropdown overlap issues
  - Added proper z-index layering and keyboard handling

- **n8n Webhook Integration**:
  - Fixed response format decoding issues
  - Updated Final Response Builder to ensure no null values
  - Webhook now returns proper RouteResponse format
  - Known issue: Station locations returning as 0,0 (needs webhook fix)

### Technical Fixes Applied
- Fixed LocationManager authorization warnings
- Fixed NaN errors in BatterySlider with bounds checking
- Fixed Plan Route button activation with proper state management
- Fixed autocomplete visibility with overlay positioning
- Fixed origin/destination field overlap with conditional offsets
- Fixed webhook response decoding with null-safe statistics

### Next Steps
- **Phase 4**: Display route results with charging stations on map
- **Phase 5**: Fix station location data in n8n workflow
- **Phase 6**: Polish animations and transitions

### Known Issues
- **Webhook Station Locations**: The n8n workflow returns charging station coordinates as 0,0. The "Final Response Builder" node needs to properly preserve station.location data with lat/lng values.

Last updated: August 3, 2025