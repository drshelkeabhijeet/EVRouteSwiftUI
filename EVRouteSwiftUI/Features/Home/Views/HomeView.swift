import SwiftUI
import MapKit

struct HomeView: View {
    @StateObject private var viewModel = HomeViewModel()
    @State private var showingStationDetail = false
    @State private var position = MapCameraPosition.region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
            span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
        )
    )
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Map View
                Map(position: $position) {
                    ForEach(viewModel.nearbyStations) { station in
                        Annotation(station.name, coordinate: station.coordinate) {
                            StationMapPin(station: station) {
                                viewModel.selectedStation = station
                                showingStationDetail = true
                            }
                        }
                    }
                }
                .ignoresSafeArea()
                
                // Search and List Overlay
                VStack {
                    searchBar
                    
                    if viewModel.isLoading {
                        loadingView
                    } else if viewModel.nearbyStations.isEmpty {
                        emptyStateView
                    } else {
                        stationsList
                    }
                    
                    Spacer()
                }
            }
            .navigationTitle("EV Charging")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showingStationDetail) {
                if let station = viewModel.selectedStation {
                    StationDetailView(station: station)
                }
            }
            .task {
                // Disabled to prevent network errors
                // await viewModel.loadNearbyStations()
            }
            .alert("Error", isPresented: .constant(viewModel.error != nil)) {
                Button("OK") {
                    viewModel.error = nil
                }
            } message: {
                Text(viewModel.error?.localizedDescription ?? "An error occurred")
            }
        }
    }
    
    // MARK: - Subviews
    
    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
            
            TextField("Search stations", text: $viewModel.searchText)
                .textFieldStyle(.plain)
            
            if !viewModel.searchText.isEmpty {
                Button {
                    viewModel.searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(.regularMaterial)
        .cornerRadius(10)
        .padding()
    }
    
    private var loadingView: some View {
        ProgressView("Finding charging stations...")
            .padding()
            .background(.regularMaterial)
            .cornerRadius(10)
            .padding()
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "bolt.slash.circle")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            
            Text("No charging stations found")
                .font(.headline)
            
            Text("Try adjusting your search or location")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(.regularMaterial)
        .cornerRadius(10)
        .padding()
    }
    
    private var stationsList: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(viewModel.nearbyStations) { station in
                    StationCard(station: station) {
                        viewModel.selectedStation = station
                        showingStationDetail = true
                    }
                }
            }
            .padding(.horizontal)
        }
    }
}

// MARK: - Station Map Pin

struct StationMapPin: View {
    let station: ChargingStation
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 0) {
                Image(systemName: "bolt.circle.fill")
                    .font(.title2)
                    .foregroundColor(.green)
                    .background(Circle().fill(.white).frame(width: 30, height: 30))
                
                Image(systemName: "triangle.fill")
                    .font(.caption)
                    .foregroundColor(.green)
                    .rotationEffect(.degrees(180))
                    .offset(y: -5)
            }
        }
        .accessibilityLabel("Charging station at \(station.name)")
    }
}

// MARK: - Station Card

struct StationCard: View {
    let station: ChargingStation
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(station.name)
                        .font(.headline)
                        .lineLimit(1)
                    
                    Spacer()
                    
                    if let distance = station.distance {
                        Text("\(Int(distance / 1000))km")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Text(station.address)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                
                HStack {
                    Label("\(station.availability.availableConnectors)/\(station.availability.totalConnectors)",
                          systemImage: "bolt.fill")
                        .font(.caption)
                        .foregroundColor(.green)
                    
                    Spacer()
                    
                    if let price = station.pricePerKwh {
                        Text("$\(price, specifier: "%.2f")/kWh")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding()
            .frame(width: 250)
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Previews

#Preview {
    HomeView()
        .environmentObject(AuthManager.shared)
}