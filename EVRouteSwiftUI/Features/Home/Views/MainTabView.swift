import SwiftUI

struct MainTabView: View {
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            RouteView()
                .tabItem {
                    Label("Route", systemImage: "map.fill")
                }
                .tag(0)
            
            NearbyView()
                .tabItem {
                    Label("Nearby", systemImage: "bolt.circle.fill")
                }
                .tag(1)
            
            SavedView()
                .tabItem {
                    Label("Saved", systemImage: "bookmark.fill")
                }
                .tag(2)
            
            ProfileView()
                .tabItem {
                    Label("Profile", systemImage: "person.circle.fill")
                }
                .tag(3)
        }
        .accentColor(.green)
    }
}

// Placeholder Views
struct RouteView: View {
    var body: some View {
        RoutePlanningView()
    }
}

struct SavedView: View {
    var body: some View {
        RouteHistoryView()
    }
}

struct ProfileView: View {
    @StateObject private var vehicleManager = VehicleManager.shared
    
    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack {
                        Image(systemName: "person.circle.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        
                        VStack(alignment: .leading) {
                            Text("Demo User")
                                .font(.headline)
                            Text("demo@evroute.app")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.vertical, 8)
                }
                
                Section("Vehicle") {
                    NavigationLink {
                        VehicleSelectionView()
                    } label: {
                        HStack {
                            Label("My Vehicles", systemImage: "car.fill")
                            Spacer()
                            if let vehicle = VehicleManager.shared.selectedVehicle {
                                Text(vehicle.displayName)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
                
                Section("Settings") {
                    NavigationLink {
                        Text("Preferences")
                    } label: {
                        Label("Preferences", systemImage: "gear")
                    }
                    
                    NavigationLink {
                        Text("Notifications")
                    } label: {
                        Label("Notifications", systemImage: "bell")
                    }
                }
                
                Section {
                    Button {
                        // No-op for demo
                    } label: {
                        Label("Demo Mode", systemImage: "person.badge.shield.checkmark")
                            .foregroundColor(.blue)
                    }
                    .disabled(true)
                }
            }
            .navigationTitle("Profile")
        }
    }
}

// MARK: - Preview

struct MainTabView_Previews: PreviewProvider {
    static var previews: some View {
        MainTabView()
    }
}
