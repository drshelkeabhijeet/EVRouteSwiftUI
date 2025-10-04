import SwiftUI
import MapKit

struct RouteResultsView: View {
    enum ResultsTab: String, CaseIterable { case overview = "Overview", stops = "Stops", alternatives = "Alternatives" }

    let routeResponse: RouteResponse
    @State private var selectedStation: RouteChargingStation?
    @State private var showStationDetail = false
    @State private var selectedStationsState: [RouteChargingStation]
    @State private var originName: String = ""
    @State private var destinationName: String = ""
    @Environment(\.dismiss) private var dismiss
    @State private var activeTab: ResultsTab = .overview
    @State private var scrollTargetID: String?
    @State private var replacingCandidate: RouteChargingStation?
    @State private var showReplaceSheet = false
    
    init(routeResponse: RouteResponse) {
        self.routeResponse = routeResponse
        _selectedStationsState = State(initialValue: routeResponse.chargingPlan.selectedStations)
        print("RouteResultsView initialized with:")
        print("- Selected stations: \(routeResponse.chargingPlan.selectedStations.count)")
        print("- All stations: \(routeResponse.chargingPlan.allStations.count)")
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 12) {
                Picker("Tab", selection: $activeTab) {
                    ForEach(ResultsTab.allCases, id: \.self) { tab in
                        Text(tab.rawValue).tag(tab)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)

                ScrollViewReader { proxy in
                    ScrollView {
                        VStack(spacing: 20) {
                            switch activeTab {
                            case .overview:
                                mapSection
                                tripSummarySection
                                statisticsSection
                            case .stops:
                                if routeResponse.chargingPlan.needed && !routeResponse.chargingPlan.selectedStations.isEmpty {
                                    chargingPlanSection
                                } else if !routeResponse.chargingPlan.allStations.isEmpty {
                                    allStationsSection
                                }
                            case .alternatives:
                                alternativesSection
                            }
                        }
                        .padding(.bottom, 80)
                        .onChange(of: scrollTargetID) { _, newID in
                            guard let id = newID else { return }
                            withAnimation(.easeInOut(duration: 0.25)) {
                                proxy.scrollTo(id, anchor: .center)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Route Plan")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .overlay(alignment: .bottom) {
                // Navigation Buttons
                VStack(spacing: 12) {
                    HStack(spacing: 12) {
                        // Google Maps Button
                        Button {
                            openInGoogleMaps()
                        } label: {
                            Label("Google Maps", systemImage: "map.fill")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(12)
                        }
                        
                        // Apple Maps Button
                        Button {
                            openInAppleMaps()
                        } label: {
                            Label("Apple Maps", systemImage: "map.fill")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.green)
                                .foregroundColor(.white)
                                .cornerRadius(12)
                        }
                    }
                }
                .padding()
                .background(Color(.systemBackground))
            }
        }
        .sheet(isPresented: $showStationDetail) {
            if let station = selectedStation {
                StationDetailSheet(station: station)
            }
        }
        .sheet(isPresented: $showReplaceSheet) {
            if let candidate = replacingCandidate {
                ReplaceStopSheet(
                    candidate: candidate,
                    stops: selectedStationsState,
                    onReplace: { index in
                        guard index >= 0 && index < selectedStationsState.count else { return }
                        selectedStationsState[index] = candidate
                        triggerHaptic(.success)
                        activeTab = .stops
                        scrollTargetID = candidate.id
                    },
                    onAdd: {
                        if !selectedStationsState.contains(where: { $0.id == candidate.id }) {
                            selectedStationsState.append(candidate)
                            triggerHaptic(.success)
                            activeTab = .stops
                            scrollTargetID = candidate.id
                        }
                    }
                )
            }
        }
    }

    private var summaryStrip: some View {
        HStack(spacing: 12) {
            Label("\(formatDuration(routeResponse.route.durationMinutes))", systemImage: "clock")
            Divider()
            Label("\(Int(routeResponse.route.distanceKm)) km", systemImage: "road.lanes")
            Divider()
            Label("\(routeResponse.chargingPlan.selectedStations.count) stops", systemImage: "bolt.fill")
        }
        .font(.subheadline)
        .foregroundColor(.secondary)
        .padding(.vertical, 6)
        .padding(.horizontal)
    }
    
    // MARK: - Map Section
    
    private var mapSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Route Map")
                    .font(.headline)
                if !originDisplayName.isEmpty || !destinationDisplayName.isEmpty {
                    Text("\(originDisplayName) - \(destinationDisplayName)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                Spacer()
                if selectedStationsState.count > 0 {
                    Label("\(selectedStationsState.count) stops", systemImage: "bolt.circle.fill")
                        .font(.caption)
                        .foregroundColor(.orange)
                }
            }
            .padding(.horizontal)
            
            RouteMapView(
                routePolyline: routeResponse.route.polyline,
                selectedStations: selectedStationsState,
                allStations: routeResponse.chargingPlan.allStations,
                onStationTap: { station in
                    selectedStation = station
                    showStationDetail = true
                    activeTab = .stops
                    scrollTargetID = station.id
                },
                onToggleSelection: { station in
                    if let idx = selectedStationsState.firstIndex(where: { $0.id == station.id }) {
                        selectedStationsState.remove(at: idx)
                    } else {
                        selectedStationsState.append(station)
                    }
                }
            )
            .frame(height: 400)
            .background(Color.gray.opacity(0.1))
            .cornerRadius(12)
            .padding(.horizontal)
            .onAppear {
                print("Map section appeared")
                print("- Polyline length: \(routeResponse.route.polyline.count) characters")
                print("- Selected stations: \(selectedStationsState.count)")
                print("- All stations: \(routeResponse.chargingPlan.allStations.count)")
                resolvePlaceNames()
            }
        }
    }
    
    // MARK: - Trip Summary Section
    
    private var tripSummarySection: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Trip Summary")
                    .font(.headline)
                Spacer()
            }
            
            VStack(spacing: 12) {
                // Origin & Destination
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Label(routeResponse.summary.origin, systemImage: "location.circle")
                            .font(.subheadline)
                        Label(routeResponse.summary.destination, systemImage: "mappin.circle.fill")
                            .font(.subheadline)
                    }
                    Spacer()
                }
                
                Divider()
                
                // Distance & Time
                HStack(spacing: 24) {
                    VStack(spacing: 4) {
                        Text("\(Int(routeResponse.route.distanceKm))")
                            .font(.title2)
                            .fontWeight(.semibold)
                        Text("km")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Divider()
                        .frame(height: 40)
                    
                    VStack(spacing: 4) {
                        Text(formatDuration(routeResponse.summary.estimatedTotalDuration))
                            .font(.title2)
                            .fontWeight(.semibold)
                        Text("total time")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    if !selectedStationsState.isEmpty {
                        Divider()
                            .frame(height: 40)
                        
                        VStack(spacing: 4) {
                            Text("\(selectedStationsState.reduce(0) { $0 + $1.chargingTimeMinutes })")
                                .font(.title2)
                                .fontWeight(.semibold)
                            Text("min charging")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Spacer()
                }
            }
            .padding()
            .background(Color(.secondarySystemBackground))
            .cornerRadius(12)
        }
        .padding(.horizontal)
    }
    
    // MARK: - Charging Plan Section
    
    private var chargingPlanSection: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Stops Timeline").font(.headline)
                Spacer()
                Text("\(selectedStationsState.count) stops")
                    .font(.subheadline).foregroundColor(.secondary)
            }
            ForEach(Array(selectedStationsState.enumerated()), id: \.offset) { index, station in
                StopTimelineRow(
                    index: index + 1,
                    isLast: index == selectedStationsState.count - 1,
                    station: station,
                    previousStation: index > 0 ? selectedStationsState[index - 1] : nil,
                    totalRouteDistance: routeResponse.route.distanceKm,
                    onTap: {
                        selectedStation = station
                        showStationDetail = true
                    },
                    isSelected: selectedStation?.id == station.id
                )
                .id(station.id)
            }
        }
        .padding(.horizontal)
    }

    // MARK: - All Stations Fallback Section
    private var allStationsSection: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Charging Stations")
                    .font(.headline)
                Spacer()
                Text("\(routeResponse.chargingPlan.allStations.count) nearby")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            ForEach(routeResponse.chargingPlan.allStations) { station in
                BasicStationCard(station: station) {
                    selectedStation = station
                    showStationDetail = true
                }
            }
        }
        .padding(.horizontal)
    }

    private var alternativesSection: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Alternatives")
                    .font(.headline)
                Spacer()
                Text("Suggestions")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            let selectedIDs = Set(routeResponse.chargingPlan.selectedStations.map { $0.id })
            let candidates = routeResponse.chargingPlan.allStations.filter { !selectedIDs.contains($0.id) }
            if candidates.isEmpty {
                Text("No alternatives available.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                ForEach(Array(candidates.prefix(10)), id: \.id) { station in
                    AlternativeCard(station: station) {
                        // Trigger replace/add flow
                        replacingCandidate = station
                        showReplaceSheet = true
                        triggerImpact(.light)
                    } details: {
                        selectedStation = station
                        showStationDetail = true
                    }
                }
            }
        }
        .padding(.horizontal)
    }
    
    // MARK: - Statistics Section
    
    private var statisticsSection: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Route Statistics")
                    .font(.headline)
                Spacer()
            }
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                StatCard(
                    title: "Energy Required",
                    value: String(format: "%.1f", routeResponse.statistics.totalEnergyRequired),
                    unit: "kWh",
                    icon: "bolt.fill"
                )
                
                StatCard(
                    title: "Min SOC",
                    value: String(format: "%.0f", routeResponse.statistics.minSocReached),
                    unit: "%",
                    icon: "battery.25"
                )
                
                StatCard(
                    title: "Stations Found",
                    value: "\(routeResponse.statistics.totalStationsFound)",
                    unit: "total",
                    icon: "mappin.circle"
                )
                
                StatCard(
                    title: "Avg Charging Speed",
                    value: String(format: "%.0f", routeResponse.statistics.avgChargingSpeedSelected),
                    unit: "kW",
                    icon: "speedometer"
                )
            }
        }
        .padding(.horizontal)
    }
    
    // MARK: - Helpers
    
    private func formatDuration(_ minutes: Int) -> String {
        let hours = minutes / 60
        let mins = minutes % 60
        
        if hours > 0 {
            return "\(hours)h \(mins)m"
        } else {
            return "\(mins)m"
        }
    }
    
    private func openInGoogleMaps() {
        // Get origin and destination from route summary
        let originText = routeResponse.summary.origin
        let destinationText = routeResponse.summary.destination
        
        // Sort charging stations by distance from origin
        let sortedStations = routeResponse.chargingPlan.selectedStations
            .sorted { $0.distanceFromOriginKm < $1.distanceFromOriginKm }
        
        print("Opening Google Maps with:")
        print("Origin: \(originText)")
        print("Destination: \(destinationText)")
        print("Stations: \(sortedStations.count)")
        for station in sortedStations {
            print("- \(station.stationName) at \(station.location.lat),\(station.location.lng)")
        }
        
        // Try Google Maps app first with simple approach
        if sortedStations.isEmpty {
            // No waypoints - simple route
            let urlString = "comgooglemaps://?saddr=\(originText.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")&daddr=\(destinationText.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")&directionsmode=driving"
            
            if let url = URL(string: urlString), UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url)
                return
            }
        }
        
        // Fallback to web version with waypoints
        var components = URLComponents(string: "https://www.google.com/maps/dir/")!
        
        // Build path with all stops
        var pathComponents: [String] = []
        
        // Add origin
        pathComponents.append(originText)
        
        // Add charging stations
        for station in sortedStations {
            // Use coordinates for precision
            pathComponents.append("\(station.location.lat),\(station.location.lng)")
        }
        
        // Add destination
        pathComponents.append(destinationText)
        
        // Create the full path
        let path = pathComponents
            .map { $0.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? $0 }
            .joined(separator: "/")
        
        components.path = "/maps/dir/" + path
        
        if let url = components.url {
            print("Opening Google Maps URL: \(url)")
            UIApplication.shared.open(url)
        }
    }
    
    private func openInAppleMaps() {
        let sortedStations = routeResponse.chargingPlan.selectedStations
            .sorted { $0.distanceFromOriginKm < $1.distanceFromOriginKm }
        
        print("Opening Apple Maps with \(sortedStations.count) stations")
        
        // Build URL for Apple Maps with waypoints
        var urlComponents = URLComponents(string: "https://maps.apple.com/")!
        
        // Start with origin
        var queryItems: [URLQueryItem] = []
        queryItems.append(URLQueryItem(name: "saddr", value: routeResponse.summary.origin))
        
        // Add destination
        queryItems.append(URLQueryItem(name: "daddr", value: routeResponse.summary.destination))
        
        // Add waypoints if any
        if !sortedStations.isEmpty {
            // Apple Maps doesn't support multiple waypoints in URL, so we'll open with just origin and destination
            // and show stations in the UI
            print("Note: Apple Maps URL scheme doesn't support multiple waypoints")
        }
        
        queryItems.append(URLQueryItem(name: "dirflg", value: "d")) // driving directions
        
        urlComponents.queryItems = queryItems
        
        if let url = urlComponents.url {
            print("Opening Apple Maps URL: \(url)")
            UIApplication.shared.open(url)
        }
    }
}

// MARK: - UI Components

private struct StopTimelineRow: View {
    let index: Int
    let isLast: Bool
    let station: RouteChargingStation
    let previousStation: RouteChargingStation?
    let totalRouteDistance: Double
    let onTap: () -> Void
    var isSelected: Bool = false

    private var distanceFromPreviousStop: Double {
        if let previous = previousStation {
            return station.distanceFromOriginKm - previous.distanceFromOriginKm
        }
        return station.distanceFromOriginKm
    }

    private var distanceToDestination: Double {
        return totalRouteDistance - station.distanceFromOriginKm
    }

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(spacing: 0) {
                // Node
                ZStack {
                    Circle().fill(isSelected ? Color.orange : Color.blue).frame(width: 10, height: 10)
                    Text("\(index)").font(.system(size: 9, weight: .bold)).foregroundColor(.white)
                }
                // Rail
                if !isLast {
                    Rectangle().fill(Color.blue.opacity(0.3)).frame(width: 2).frame(maxHeight: .infinity)
                } else {
                    Spacer(minLength: 0)
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .firstTextBaseline) {
                    Text(station.stationName).font(.headline)
                    Spacer()
                    Label("\(Int(station.chargingSpeedKw)) kW", systemImage: "bolt.fill").font(.caption).foregroundColor(.secondary)
                }

                // Distance Information
                HStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("From Origin").font(.caption2).foregroundColor(.secondary)
                        Text("\(Int(station.distanceFromOriginKm)) km").font(.caption).fontWeight(.medium)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text("From Last Stop").font(.caption2).foregroundColor(.secondary)
                        Text("\(Int(distanceFromPreviousStop)) km").font(.caption).fontWeight(.medium)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text("To Destination").font(.caption2).foregroundColor(.secondary)
                        Text("\(Int(distanceToDestination)) km").font(.caption).fontWeight(.medium)
                    }
                }
                .padding(.vertical, 4)
                .padding(.horizontal, 8)
                .background(Color(.systemGray6))
                .cornerRadius(8)

                SOCBar(arrival: station.arrivalSOC, departure: station.departureSOC)
                HStack(spacing: 12) {
                    Label("\(station.chargingTimeMinutes) min", systemImage: "clock").font(.caption)
                    Label(String(format: "%.1f km detour", station.detourKm), systemImage: "arrow.triangle.branch").font(.caption)
                }
                .foregroundColor(.secondary)

                HStack(spacing: 6) {
                    ForEach(amenityChips(for: station), id: \.self) { chip in
                        Text(chip).font(.caption2).padding(.horizontal, 8).padding(.vertical, 4).background(Color(.systemGray6)).clipShape(Capsule())
                    }
                }

                HStack(spacing: 12) {
                    Button("Details", action: onTap)
                    Button("Remove") { /* hook up remove if needed */ }
                }
                .font(.caption.weight(.semibold))
            }
        }
        .padding(12)
        .background(isSelected ? Color.orange.opacity(0.08) : Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    private func amenityChips(for station: RouteChargingStation) -> [String] {
        var chips: [String] = []
        if let types = station.connectorTypes, let first = types.first { chips.append(first.replacingOccurrences(of: "EV_CONNECTOR_TYPE_", with: "")) }
        if let rating = station.rating { chips.append(String(format: "⭐️ %.1f", rating)) }
        if station.onRoute == true { chips.append("On route") }
        return chips
    }
}

// MARK: - Replace Stop Sheet
private struct ReplaceStopSheet: View {
    let candidate: RouteChargingStation
    let stops: [RouteChargingStation]
    let onReplace: (Int) -> Void
    let onAdd: () -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                if stops.isEmpty {
                    Section("No existing stops") {
                        Button("Add as first stop") { onAdd(); dismiss() }
                    }
                } else {
                    Section("Replace a stop") {
                        ForEach(Array(stops.enumerated()), id: \.offset) { index, stop in
                            Button {
                                onReplace(index)
                                dismiss()
                            } label: {
                                HStack {
                                    Text("Stop \(index + 1)")
                                    Text(stop.stationName).foregroundColor(.secondary)
                                }
                            }
                        }
                    }
                    Section {
                        Button("Add as extra stop") { onAdd(); dismiss() }
                    }
                }
            }
            .navigationTitle("Use Alternative")
            .toolbar { ToolbarItem(placement: .navigationBarTrailing) { Button("Done") { dismiss() } } }
        }
    }
}

// MARK: - Haptics
private func triggerHaptic(_ type: UINotificationFeedbackGenerator.FeedbackType) {
    let gen = UINotificationFeedbackGenerator(); gen.notificationOccurred(type)
}

private func triggerImpact(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
    let gen = UIImpactFeedbackGenerator(style: style); gen.impactOccurred()
}

private struct SOCBar: View {
    let arrival: Double
    let departure: Double
    var body: some View {
        GeometryReader { geo in
            let width = geo.size.width
            let from = max(0, min(100, arrival)) / 100
            let to = max(from, min(100, departure)) / 100
            ZStack(alignment: .leading) {
                Capsule().fill(Color.gray.opacity(0.2))
                Capsule().fill(LinearGradient(colors: [.orange, .green], startPoint: .leading, endPoint: .trailing))
                    .frame(width: max(2, width * (to - 0)))
            }
        }
        .frame(height: 8)
        .clipShape(Capsule())
    }
}

private struct AlternativeCard: View {
    let station: RouteChargingStation
    let onTry: () -> Void
    let details: () -> Void
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(station.stationName).font(.subheadline).fontWeight(.semibold)
                Spacer()
                Label("\(Int(station.chargingSpeedKw)) kW", systemImage: "bolt.fill").font(.caption).foregroundColor(.secondary)
            }
            HStack(spacing: 12) {
                Label(String(format: "Detour %.1f km", station.detourKm), systemImage: "arrow.left.and.right").font(.caption)
                if station.timeImpactMinutes != nil {
                    Label("\(station.timeImpactMinutes!) min", systemImage: "clock").font(.caption)
                }
            }
            .foregroundColor(.secondary)
            HStack(spacing: 12) {
                Button("Try this", action: onTry)
                Button("Details", action: details)
            }
            .font(.caption.weight(.semibold))
        }
        .padding(12)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Reverse Geocoding Helpers
extension RouteResultsView {
    private var originDisplayName: String {
        if !originName.isEmpty { return originName }
        return routeResponse.summary.origin
    }
    private var destinationDisplayName: String {
        if !destinationName.isEmpty { return destinationName }
        return routeResponse.summary.destination
    }
    private func resolvePlaceNames() {
        let coords = [(routeResponse.summary.origin, true), (routeResponse.summary.destination, false)]
        for (text, isOrigin) in coords {
            let parts = text.split(separator: ",")
            if parts.count == 2, let lat = Double(parts[0]), let lng = Double(parts[1]) {
                let loc = CLLocation(latitude: lat, longitude: lng)
                CLGeocoder().reverseGeocodeLocation(loc) { placemarks, _ in
                    guard let placemark = placemarks?.first else { return }
                    let city = placemark.locality ?? placemark.subLocality ?? placemark.name ?? ""
                    if isOrigin { originName = city } else { destinationName = city }
                }
            }
        }
    }
}

// MARK: - Supporting Views

struct ChargingStopCard: View {
    let station: RouteChargingStation
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Charging Icon
                ZStack {
                    Circle()
                        .fill(Color.green.opacity(0.2))
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: "bolt.fill")
                        .font(.title3)
                        .foregroundColor(.green)
                }
                
                // Station Info
                VStack(alignment: .leading, spacing: 4) {
                    Text(station.stationName)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
                    HStack(spacing: 8) {
                        Label("\(station.chargingSpeedKw.formatted()) kW", systemImage: "speedometer")
                        Label("\(station.chargingTimeMinutes) min", systemImage: "clock")
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Battery Status
                VStack(alignment: .trailing, spacing: 4) {
                    HStack(spacing: 4) {
                        Text("\(Int(station.arrivalSOC))%")
                            .foregroundColor(.orange)
                        Image(systemName: "arrow.right")
                            .font(.caption)
                        Text("\(Int(station.departureSOC))%")
                            .foregroundColor(.green)
                    }
                    .font(.caption2)
                    
                    Text("+\(Int(station.energyAddedKwh)) kWh")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color(.secondarySystemBackground))
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct BasicStationCard: View {
    let station: RouteChargingStation
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Icon
                ZStack {
                    Circle()
                        .fill(Color.blue.opacity(0.15))
                        .frame(width: 44, height: 44)
                    Image(systemName: "bolt.circle")
                        .foregroundColor(.blue)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(station.stationName)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    Text(station.address)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Label("\(Int(station.chargingSpeedKw)) kW", systemImage: "speedometer")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Label("\(String(format: "%.1f", station.detourKm)) km detour", systemImage: "road.lanes")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            .background(Color(.secondarySystemBackground))
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let unit: String
    let icon: String
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.blue)
            
            Text(value)
                .font(.title3)
                .fontWeight(.semibold)
            
            Text(unit)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text(title)
                .font(.caption2)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
}

struct StationDetailSheet: View {
    let station: RouteChargingStation
    @Environment(\.dismiss) private var dismiss
    @State private var pendingPhone: String? = nil
    @State private var pendingURL: URL? = nil
    @State private var showCallConfirm = false
    @State private var showWebConfirm = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        Text(station.stationName)
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text(station.address)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal)
                    
                    Group {
                        // Charging Details
                        VStack(spacing: 16) {
                            DetailRow(label: "Charging Speed", value: "\(Int(station.chargingSpeedKw)) kW")
                            DetailRow(label: "Charging Time", value: "\(station.chargingTimeMinutes) minutes")
                            DetailRow(label: "Energy to Add", value: "\(Int(station.energyAddedKwh)) kWh")
                            DetailRow(label: "Arrival SOC", value: "\(Int(station.arrivalSOC))%")
                            DetailRow(label: "Departure SOC", value: "\(Int(station.departureSOC))%")
                            DetailRow(label: "Detour Distance", value: "\(String(format: "%.1f", station.detourKm)) km")
                        }

                        // Optional Extras
                        if station.connectorTypes != nil || station.websiteURI != nil || station.phoneNumber != nil || station.rating != nil || station.userRatingCount != nil || station.businessStatus != nil || station.onRoute != nil {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("More Info")
                                    .font(.headline)
                                if let status = station.businessStatus, !status.isEmpty {
                                    DetailRow(label: "Status", value: status)
                                }
                                if let rating = station.rating {
                                    let stars = String(repeating: "★", count: Int((rating).rounded()))
                                    DetailRow(label: "Rating", value: "\(String(format: "%.1f", rating)) \(stars)")
                                }
                                if let count = station.userRatingCount {
                                    DetailRow(label: "Reviews", value: "\(count)")
                                }
                                if let onRoute = station.onRoute {
                                    DetailRow(label: "On Route", value: onRoute ? "Yes" : "No")
                                }
                                if let types = station.connectorTypes, !types.isEmpty {
                                    DetailRow(label: "Connectors", value: types.joined(separator: ", "))
                                }
                                if let phone = station.phoneNumber, !phone.isEmpty {
                                    HStack {
                                        Text("Phone").foregroundColor(.secondary)
                                        Spacer()
                                        Button(phone) { confirmCall(phone) }
                                            .foregroundColor(.blue)
                                    }
                                }
                                if let url = station.websiteURI, !url.isEmpty {
                                    HStack {
                                        Text("Website").foregroundColor(.secondary)
                                        Spacer()
                                        Button(url) { confirmOpen(url) }
                                            .foregroundColor(.blue)
                                    }
                                }
                            }
                        }
                    }
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(12)
                    .padding(.horizontal)
                    
                    if station.isCritical {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.orange)
                            Text("Critical Stop: \(station.reason)")
                                .font(.subheadline)
                        }
                        .padding()
                        .background(Color.orange.opacity(0.1))
                        .cornerRadius(8)
                        .padding(.horizontal)
                    }
                    
                    Spacer(minLength: 20)
                }
            }
            .navigationTitle("Station Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .alert("Call this station?", isPresented: $showCallConfirm) {
                Button("Call", role: .destructive) {
                    if let phone = pendingPhone {
                        let digits = phone.filter { "0123456789+".contains($0) }
                        if let url = URL(string: "tel://\(digits)") {
                            UIApplication.shared.open(url)
                        }
                    }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text(pendingPhone ?? "")
            }
            .alert("Open website?", isPresented: $showWebConfirm) {
                Button("Open") {
                    if let url = pendingURL { UIApplication.shared.open(url) }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text(pendingURL?.absoluteString ?? "")
            }
        }
    }
}

struct DetailRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.medium)
        }
    }
}

// MARK: - Actions
extension StationDetailSheet {
    func confirmCall(_ number: String) {
        pendingPhone = number
        showCallConfirm = true
    }
    func confirmOpen(_ urlString: String) {
        if let url = URL(string: urlString.hasPrefix("http") ? urlString : "https://\(urlString)") {
            pendingURL = url
            showWebConfirm = true
        }
    }
}
