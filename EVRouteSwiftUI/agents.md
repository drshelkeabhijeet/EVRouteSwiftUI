# EVRouteSwiftUI – Agents Guide

This document equips contributors and AI agents with the minimum, accurate context needed to build, test, and extend the EVRouteSwiftUI app efficiently and safely.

## Quick Start
- Open `EVRouteSwiftUI.xcodeproj` in Xcode (target: `EVRouteSwiftUI`).
- Build & run on iOS simulator (iOS 17+ recommended).
- Location permissions: App requests When-In-Use on first launch (strings are in `Info.plist`).
- Tests: Run the `EVRouteSwiftUITests` target for unit tests.

## High-Level Architecture
- App entry: `App/EVRouteApp.swift` loads `MainTabView` directly (auth gating currently bypassed).
- Features
  - Route Planning: `Features/RouteDetails` (views, view model, service, map UI).
  - Charging (Home): `Features/Home` (map of stations, search, station detail).
  - Saved History: `RouteHistoryView` with `RouteStorageManager` for persistence.
  - Profile: Vehicle management (`VehicleSelectionView`, `VehicleManager`).
- Core
  - Networking: `Core/Services/NetworkService.swift`, `Endpoints.swift`.
  - Auth: `AuthManager` with Keychain-backed token storage; currently uses `MockAuthService`.
  - Models: User, Vehicle, ChargingStation, Route, SavedRoute.
  - Utilities: `PolylineDecoder` for Google-encoded polylines.

## Networking & Configuration
- Base API URL: hardcoded in `NetworkService.Endpoint.baseURL` → `https://abhijeetshelke.app.n8n.cloud`.
- Route planning webhook: `RouteService.webhookURL` (POST JSON) in `Features/RouteDetails/Services/RouteService.swift`.
- Authorization header: `NetworkService` automatically injects `Bearer <token>` if present via `AuthManager`.
- Station endpoints exist in `Endpoints.swift` but Home auto-fetch is currently disabled to avoid network errors.

### Offline / Mock Options
- Authentication: `MockAuthService` returns a demo user and token (used by `AuthManager`).
- Route planning: Use `RouteService.planRouteMock(...)` for deterministic responses when the webhook is offline.
- Saved routes: `SavedRoute.mockRoutes` populates history when none exist.

## Building Blocks
- `RoutePlanningViewModel` builds a `RoutePlanRequest` from inputs (origin/destination/SOC/vehicle prefs), calls `RouteService`, saves `SavedRoute`, and toggles `RouteResultsView`.
- `RouteService` decoding strategy:
  1) Try direct `RouteResponse` decoding (newer webhook format).
  2) Fallback to an array payload (older n8n format) and map to internal models.
- `RouteMapView` (UIKit-backed) renders the decoded polyline and station markers (selected vs other).

## Known Duplications & Intentional Choices
- Route domain duplication:
  - `Features/RouteDetails/Services/RouteService.swift` defines `RouteResponse`, `RouteInfo`, `ChargingPlan`, etc. These are the ACTIVE models referenced by the target.
  - `Core/Models/RouteResponse.swift` contains similarly named types that are NOT part of the build target (to avoid conflicts). Do not cross-import both; consolidate later if desired.
- Amenity model exists in two places (Home/RouteDetails) with different fields; each is scoped to its feature.
- A sample sub-app exists under `Features/Home/Views/MYAPP/` and is not used by this target.

## Common Workflows
1) Add or adjust route planning UI/logic
   - Update `RoutePlanningView` and `RoutePlanningViewModel`.
   - If the webhook contract changes, update models in `RouteService.swift` first (the ones used by the target).
   - Use `RouteService.planRouteMock` during local development if external network is flaky.

2) Enable Home’s nearby stations fetch
   - `HomeViewModel`: re-enable the commented-out bindings in `setupBindings()` and the `.task { await loadNearbyStations() }` in `HomeView`.
   - Ensure your stations API is reachable and matches `StationEndpoint` expectations.

3) Switch to auth-gated entry flow
   - `App/EVRouteApp.swift.backup` shows a ContentView that gates on `AuthManager.isAuthenticated` and uses `SimpleAuthenticationView` for demo login.
   - To enable it, replace the current `EVRouteApp.swift` body with the backup’s content (or wire a top-level environment object and conditional navigation).

## Coding Conventions
- Swift 5.9+, SwiftUI-first, UIKit only when required (e.g., MapKit polyline rendering).
- Keep changes minimal and localized; prefer feature-scoped models and services unless refactoring is intentional.
- Avoid adding new third-party dependencies without discussion.
- Do not add license headers unless requested.
- Prefer `@MainActor` for view models that mutate view state.

## Testing
- Unit tests live under `Tests/*` and include:
  - Models decoding and helpers (`ModelTests`).
  - Network service with `MockURLSession` (`NetworkServiceTests`).
  - Home view model behavior (`HomeViewModelTests`).
- Add targeted tests where there are existing patterns. Avoid adding net-new frameworks.

## Security & Secrets
- Tokens are stored in Keychain via `KeychainService`.
- No API keys are checked in; the webhook/base URL is public. Do not commit secrets.
- Be mindful of PII in logs; current debug prints should be sanitized before production.

## Troubleshooting
- Polyline not rendering: verify the route polyline string and ensure `PolylineDecoder` outputs non-empty coordinates.
- Map annotations missing: check that `RouteMapView` clears prior annotations and that station arrays are not empty; selected vs non-selected markers are rendered with different identifiers.
- Decoding failures: `RouteService` logs decoding errors with context; update `CodingKeys` or fallback mapping as needed.
- Nearby stations empty: Home’s auto-fetch is intentionally disabled; re-enable and ensure location permissions are granted.

## Backlog / Cleanup Suggestions
- Consolidate duplicate route/amenity models into a single shared module to reduce confusion.
- Introduce environment-based configuration for `baseURL` and `webhookURL` (e.g., build settings or plist/config structs) instead of hardcoding.
- Consider extracting Map UI to a unified component with MapKit SwiftUI (when polyline support is sufficient) to reduce UIKit bridging.
- Prune or archive the `Features/Home/Views/MYAPP/` sample app folder if not needed.

## Points of Contact
- Primary owner: repository maintainer(s).
- If you need more context or want changes to scope/config, open a PR with a brief proposal.

