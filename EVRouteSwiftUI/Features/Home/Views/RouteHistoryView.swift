import SwiftUI

struct RouteHistoryView: View {
    @State private var savedRoutes: [SavedRoute] = []
    @State private var selectedRoute: SavedRoute?
    @State private var showRouteDetails = false
    
    var body: some View {
        NavigationStack {
            Group {
                if savedRoutes.isEmpty {
                    emptyStateView
                } else {
                    routeListView
                }
            }
            .navigationTitle("Route History")
            .navigationBarTitleDisplayMode(.large)
            .onAppear {
                loadSavedRoutes()
            }
            .sheet(item: $selectedRoute) { route in
                if let routeResponse = route.routeResponse {
                    RouteResultsView(routeResponse: routeResponse)
                }
            }
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "map.circle")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            Text("No Saved Routes")
                .font(.title2)
                .fontWeight(.medium)
            
            Text("Your planned routes will appear here")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var routeListView: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(savedRoutes) { route in
                    RouteHistoryCard(route: route) {
                        selectedRoute = route
                    }
                }
            }
            .padding()
        }
    }
    
    private func loadSavedRoutes() {
        savedRoutes = RouteStorageManager.shared.getSavedRoutes()
        
        // If no saved routes, show mock data for demo
        if savedRoutes.isEmpty {
            savedRoutes = SavedRoute.mockRoutes
        }
    }
}

struct RouteHistoryCard: View {
    let route: SavedRoute
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(route.origin)
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.down")
                                .font(.caption)
                            Text(route.destination)
                                .font(.subheadline)
                                .fontWeight(.medium)
                        }
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        Text(route.date.formatted(date: .abbreviated, time: .omitted))
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        if let vehicle = route.vehicle {
                            Text(vehicle)
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                Divider()
                
                HStack(spacing: 16) {
                    Label("\(Int(route.distance)) km", systemImage: "location")
                    Label(formatDuration(route.duration), systemImage: "clock")
                    if route.chargingStops > 0 {
                        Label("\(route.chargingStops) stops", systemImage: "bolt.fill")
                    }
                }
                .font(.caption)
                .foregroundColor(.secondary)
            }
            .padding()
            .background(Color(.secondarySystemBackground))
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func formatDuration(_ minutes: Int) -> String {
        let hours = minutes / 60
        let mins = minutes % 60
        return hours > 0 ? "\(hours)h \(mins)m" : "\(mins)m"
    }
}

