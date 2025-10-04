import SwiftUI
import MapKit
import UIKit

struct NearbyView: View {
    @StateObject private var vm = NearbyViewModel()
    @State private var showingDetail = false
    @State private var mapPosition: MapCameraPosition = {
        let coord = SimpleLocationManager.shared.currentLocation?.coordinate
            ?? CLLocationCoordinate2D(latitude: 0, longitude: 0)
        return .region(MKCoordinateRegion(center: coord,
                                          span: MKCoordinateSpan(latitudeDelta: 0.5, longitudeDelta: 0.5)))
    }()

    private let radiusKm: Double = 15

    var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                Map(position: $mapPosition) {
                    UserAnnotation()
                    ForEach(vm.stations) { st in
                        Annotation(st.name, coordinate: st.coordinate) {
                            NearbyPin(isSelected: st.isSelected) {
                                vm.selectedStation = st
                                showingDetail = true
                            }
                        }
                    }
                }
                .ignoresSafeArea()

                HStack {
                    Button(action: { Task { vm.requestLocationAndCenter(); await vm.fetchNearby(radiusKm: radiusKm) } }) {
                        HStack(spacing: 8) {
                            Image(systemName: "bolt.circle.fill")
                            Text("Find Nearby Charging Stations")
                                .fontWeight(.semibold)
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(.ultraThinMaterial)
                        .cornerRadius(10)
                    }
                    .disabled(vm.isLoading)
                    if vm.isLoading {
                        ProgressView().padding(.leading, 4)
                    }
                    Spacer()
                }
                .padding()
            }
            .navigationTitle("Nearby")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                vm.requestLocationAndCenter()
                if let loc = vm.userLocation ?? SimpleLocationManager.shared.currentLocation?.coordinate {
                    centerOnUser(loc)
                }
            }
            .onReceive(SimpleLocationManager.shared.$currentLocation) { loc in
                guard let loc = loc?.coordinate else { return }
                vm.userLocation = loc
                centerOnUser(loc)
            }
            .sheet(isPresented: $showingDetail) {
                if let st = vm.selectedStation {
                    NearbyStationDetailSheet(station: st)
                }
            }
            .alert("Error",
                   isPresented: Binding(
                        get: { vm.error != nil },
                        set: { if !$0 { vm.error = nil } }
                   )
            ) {
                Button("OK") { vm.error = nil }
            } message: { Text(vm.error?.localizedDescription ?? "An error occurred") }
        }
    }

    private func centerOnUser(_ coordinate: CLLocationCoordinate2D) {
        // Roughly 15 km radius -> latDelta ~ 0.27 (diameter)
        let latDelta = 0.27
        let lonDelta = max(0.27 / max(cos(coordinate.latitude * .pi/180), 0.1), 0.27)
        withAnimation {
            mapPosition = .region(MKCoordinateRegion(center: coordinate, span: MKCoordinateSpan(latitudeDelta: latDelta, longitudeDelta: lonDelta)))
        }
    }
}

// MARK: - Pin View
private struct NearbyPin: View {
    let isSelected: Bool
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            VStack(spacing: 0) {
                Image(systemName: "bolt.circle.fill")
                    .font(.title2)
                    .foregroundColor(isSelected ? .orange : .blue)
                    .background(Circle().fill(.white).frame(width: 30, height: 30))

                Image(systemName: "triangle.fill")
                    .font(.caption)
                    .foregroundColor(isSelected ? .orange : .blue)
                    .rotationEffect(.degrees(180))
                    .offset(y: -5)
            }
        }
        .accessibilityLabel(isSelected ? "Best station" : "Station")
    }
}

// MARK: - Detail Sheet
struct NearbyStationDetailSheet: View {
    let station: NearbyStation
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    VStack(alignment: .leading) {
                        Text(station.name)
                            .font(.title3)
                            .fontWeight(.semibold)
                        if let addr = station.address, !addr.isEmpty {
                            Text(addr)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    Spacer()
                    if station.isSelected {
                        Label("Best", systemImage: "star.fill").foregroundColor(.orange)
                    }
                }

                HStack(spacing: 12) {
                    if let kw = station.chargingSpeedKw {
                        Label("\(Int(kw)) kW", systemImage: "speedometer")
                            .foregroundColor(.secondary)
                    }
                    Label("\(String(format: "%.4f", station.latitude)), \(String(format: "%.4f", station.longitude))", systemImage: "mappin.and.ellipse")
                        .foregroundColor(.secondary)
                }

                Spacer()

                Button {
                    openInGoogleMaps()
                } label: {
                    Label("Go To", systemImage: "arrow.triangle.turn.up.right.circle.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            }
            .padding()
            .navigationTitle("Station Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .navigationBarTrailing) { Button("Done") { dismiss() } } }
        }
    }

    private func openInGoogleMaps() {
        let lat = station.latitude
        let lng = station.longitude
        if let url = URL(string: "comgooglemaps://?daddr=\(lat),\(lng)&directionsmode=driving") , UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        } else if let web = URL(string: "https://www.google.com/maps/dir/?api=1&destination=\(lat),\(lng)&travelmode=driving") {
            UIApplication.shared.open(web)
        }
    }
}

// MARK: - Preview
#Preview {
    NearbyView()
}
