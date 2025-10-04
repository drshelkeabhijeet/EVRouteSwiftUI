import SwiftUI
import MapKit
import Combine

struct StationDetailView: View {
    let station: ChargingStation
    @Environment(\.dismiss) private var dismiss
    @State private var selectedConnector: Connector?
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Map Preview
                    mapSection
                    
                    // Station Info
                    stationInfoSection
                    
                    // Availability
                    availabilitySection
                    
                    // Connectors
                    connectorsSection
                    
                    // Amenities
                    if !station.amenities.isEmpty {
                        amenitiesSection
                    }
                    
                    // Actions
                    actionButtons
                }
                .padding()
            }
            .navigationTitle(station.name)
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    // MARK: - Sections
    
    private var mapSection: some View {
        Map(position: .constant(.region(MKCoordinateRegion(
            center: station.coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        )))) {
            Marker(station.name, coordinate: station.coordinate)
                .tint(.green)
        }
        .frame(height: 200)
        .cornerRadius(12)
        .overlay(alignment: .bottomTrailing) {
            Button {
                openInMaps()
            } label: {
                Label("Directions", systemImage: "arrow.triangle.turn.up.right.circle.fill")
                    .labelStyle(.iconOnly)
                    .font(.title2)
                    .foregroundColor(.white)
                    .background(Circle().fill(.blue))
                    .padding(8)
            }
        }
    }
    
    private var stationInfoSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(station.address, systemImage: "location.fill")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            if let distance = station.distance {
                Label("\(Int(distance / 1000)) km away", systemImage: "car.fill")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            if let rating = station.rating {
                HStack {
                    Image(systemName: "star.fill")
                        .foregroundColor(.yellow)
                    Text("\(rating, specifier: "%.1f")")
                    Text("(123 reviews)")
                        .foregroundColor(.secondary)
                }
                .font(.subheadline)
            }
        }
    }
    
    private var availabilitySection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Availability")
                .font(.headline)
            
            HStack {
                ProgressView(value: station.availability.percentage, total: 100)
                    .tint(.green)
                
                Text("\(station.availability.availableConnectors)/\(station.availability.totalConnectors)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            if let lastUpdated = station.availability.lastUpdated {
                Text("Updated \(lastUpdated, style: .relative) ago")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
    
    private var connectorsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Connectors")
                .font(.headline)
            
            ForEach(station.connectors) { connector in
                ConnectorRow(connector: connector, isSelected: selectedConnector?.id == connector.id) {
                    selectedConnector = connector
                }
            }
        }
    }
    
    private var amenitiesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Amenities")
                .font(.headline)
            
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))], spacing: 8) {
                ForEach(station.amenities, id: \.self) { amenity in
                    AmenityChip(name: amenity)
                }
            }
        }
    }
    
    private var actionButtons: some View {
        VStack(spacing: 12) {
            Button {
                // Start charging session
            } label: {
                Label("Start Charging", systemImage: "bolt.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            
            Button {
                // Save station
            } label: {
                Label("Save Station", systemImage: "bookmark")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .controlSize(.large)
        }
        .padding(.top)
    }
    
    // MARK: - Actions
    
    private func openInMaps() {
        let mapItem = MKMapItem(placemark: MKPlacemark(coordinate: station.coordinate))
        mapItem.name = station.name
        mapItem.openInMaps(launchOptions: [
            MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving
        ])
    }
}

// MARK: - Connector Row

struct ConnectorRow: View {
    let connector: Connector
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(connector.type.displayName)
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Text("\(Int(connector.power))kW")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Label(connector.status.rawValue.capitalized,
                      systemImage: "circle.fill")
                    .labelStyle(.titleAndIcon)
                    .font(.caption)
                    .foregroundColor(Color(connector.status.displayColor))
            }
            .padding()
            .background(isSelected ? Color.accentColor.opacity(0.1) : Color(.secondarySystemBackground))
            .cornerRadius(8)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Amenity Chip

struct AmenityChip: View {
    let name: String
    
    private var icon: String {
        switch name.lowercased() {
        case "wifi": return "wifi"
        case "restroom": return "toilet"
        case "food": return "fork.knife"
        case "shopping": return "cart"
        case "parking": return "car"
        default: return "star"
        }
    }
    
    var body: some View {
        Label(name, systemImage: icon)
            .font(.caption)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color(.tertiarySystemBackground))
            .cornerRadius(16)
    }
}

// MARK: - Preview

struct StationDetailView_Previews: PreviewProvider {
    static var previews: some View {
        StationDetailView(station: ChargingStation(
            id: "1",
            name: "Tesla Supercharger - San Francisco",
            address: "123 Market St, San Francisco, CA 94105",
            latitude: 37.7749,
            longitude: -122.4194,
            connectors: [
                Connector(id: "1", type: .tesla, power: 250, status: .available),
                Connector(id: "2", type: .ccs, power: 150, status: .occupied)
            ],
            availability: Availability(totalConnectors: 8, availableConnectors: 5, lastUpdated: Date()),
            amenities: ["WiFi", "Restroom", "Food", "Shopping"],
            pricePerKwh: 0.32,
            rating: 4.5,
            distance: 2500
        ))
    }
}
