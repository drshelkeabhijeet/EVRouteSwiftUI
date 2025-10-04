import SwiftUI
import MapKit

struct RoutePlanningView: View {
    @StateObject private var viewModel = RoutePlanningViewModel()
    @StateObject private var locationManager = LocationManager.shared
    @StateObject private var vehicleManager = VehicleManager.shared
    @State private var showVehiclePicker = false
    @State private var showPrefsSheet = false
    @State private var showSocSheet = false
    @State private var mapPosition: MapCameraPosition = .region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
            span: MKCoordinateSpan(latitudeDelta: 0.09, longitudeDelta: 0.09)
        )
    )
    @FocusState private var focusedField: Field?
    
    enum Field {
        case origin, destination
    }
    
    private var canPlanRoute: Bool {
        viewModel.originCoordinates != nil &&
        viewModel.destinationCoordinates != nil &&
        vehicleManager.selectedVehicle != nil
    }
    
    var body: some View {
        ZStack {
            // Full-screen map background
            Map(position: $mapPosition) {
                UserAnnotation()
            }
            .mapStyle(.standard)
            .ignoresSafeArea()
            .onAppear {
                locationManager.requestLocationPermission()
                locationManager.startUpdatingLocation()
            }
            .onReceive(locationManager.$currentLocation) { location in
                if let location = location {
                    withAnimation {
                        mapPosition = .region(
                            MKCoordinateRegion(
                                center: location.coordinate,
                                span: MKCoordinateSpan(latitudeDelta: 0.09, longitudeDelta: 0.09)
                            )
                        )
                    }
                }
            }
            
            // Content overlay with proper layering
            VStack {
                // Top content - input fields
                VStack(spacing: 0) {
                    // Top safe area spacing
                    Spacer()
                        .frame(height: 20)
                    
                    // Route Details Card
                    VStack(spacing: 8) {
                        Text("Plan Your Route")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                        
                        // Origin field with z-index layering
                        LocationSearchField(
                            placeholder: "Starting point or current location",
                            text: $viewModel.originText,
                            coordinates: $viewModel.originCoordinates
                        )
                        .focused($focusedField, equals: .origin)
                        .zIndex(focusedField == .origin ? 10 : 1)
                        
                        // Destination field
                        LocationSearchField(
                            placeholder: "Destination",
                            text: $viewModel.destinationText,
                            coordinates: $viewModel.destinationCoordinates
                        )
                        .focused($focusedField, equals: .destination)
                        .zIndex(focusedField == .destination ? 10 : 0)
                        .offset(y: focusedField == .origin ? 80 : 0) // Push down when origin is focused
                        .animation(.easeInOut(duration: 0.2), value: focusedField)

                        // Compact controls row (Vehicle, SOC, Prefs)
                        HStack(spacing: 6) {
                            // Vehicle chip
                            Button {
                                showVehiclePicker = true
                            } label: {
                                Chip(icon: "car.fill", label: vehicleManager.selectedVehicle?.displayName ?? "Select Vehicle")
                            }
                            .buttonStyle(.plain)

                            // SOC chip (tappable to adjust)
                            Button { showSocSheet = true } label: {
                                Chip(icon: "battery.100", label: "\(Int(viewModel.currentSOC))%")
                            }
                            .buttonStyle(.plain)

                            // Prefs chip
                            Button { showPrefsSheet = true } label: {
                                if viewModel.selectedAmenities.isEmpty {
                                    Chip(icon: "slider.horizontal.3", label: "Prefs")
                                } else {
                                    Chip(icon: "slider.horizontal.3", label: "Prefs (\(viewModel.selectedAmenities.count))")
                                }
                            }
                            .buttonStyle(.plain)
                        }
                        .scaleEffect(0.9)
                    }
                    .padding(8)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(.ultraThinMaterial)
                            .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
                    )
                    .padding(.horizontal, 12)
                    .scaleEffect(0.8) // Reduce size ~20%
                    .offset(y: -10) // Nudge slightly up
                    .zIndex(100) // Ensure the entire card is above other elements
                    
                    // Add space for dropdown when destination is focused
                    if focusedField == .destination {
                        Spacer()
                            .frame(height: 200) // Space for destination dropdown
                    }
                }
                
                Spacer()
            }
            
            // Bottom content as overlay that stays in place
            VStack {
                Spacer()
                
                // Bottom content (plan button only) — reduced height ~30%
                VStack(spacing: 10) {
                    // Plan Route Button
                    Button {
                        planRoute()
                    } label: {
                        ZStack {
                            if viewModel.isLoading {
                                VStack(spacing: 8) {
                                    EVLoadingScene()
                                    PlanningStatusTicker()
                                }
                                .transition(.opacity)
                            } else {
                                HStack {
                                    Image(systemName: "map")
                                    Text("Plan Route")
                                        .fontWeight(.semibold)
                                }
                                .transition(.opacity)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(canPlanRoute ? Color.blue : Color.gray)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                    .disabled(!canPlanRoute || viewModel.isLoading)
                }
                .padding(8)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(.ultraThinMaterial)
                        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
                )
                .padding(.horizontal, 12)
                .padding(.bottom, 8)
            }
            .ignoresSafeArea(.keyboard) // Bottom content ignores keyboard
            
            // Keyboard Done button
            if focusedField != nil {
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button("Done") {
                            focusedField = nil
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                        .padding()
                    }
                }
                .transition(.move(edge: .bottom))
                .animation(.easeInOut(duration: 0.25), value: focusedField)
            }
        }
        .alert("Error", isPresented: $viewModel.showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(viewModel.errorMessage)
        }
        .sheet(isPresented: $viewModel.showResults) {
            if let routeResponse = viewModel.routeResponse {
                RouteResultsView(routeResponse: routeResponse)
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        // Vehicle picker sheet
        .sheet(isPresented: $showVehiclePicker) {
            NavigationStack { VehicleSelectionView() }
        }
        // Preferences sheet
        .sheet(isPresented: $showPrefsSheet) {
            PreferencesSheet(
                selected: $viewModel.selectedAmenities,
                selectedConnectors: $viewModel.preferredConnectors
            )
        }
        // SOC quick adjust sheet
        .sheet(isPresented: $showSocSheet) {
            NavigationStack {
                VStack(spacing: 20) {
                    Text("Battery Level")
                        .font(.headline)
                    BatterySlider(currentSOC: $viewModel.currentSOC)
                        .padding(.horizontal)
                    HStack(spacing: 16) {
                        Button("-5%") { viewModel.currentSOC = max(0, viewModel.currentSOC - 5) }
                            .buttonStyle(.bordered)
                        Button("+5%") { viewModel.currentSOC = min(100, viewModel.currentSOC + 5) }
                            .buttonStyle(.bordered)
                    }
                    .padding(.top, 8)
                    Spacer()
                }
                .padding()
                .toolbar { ToolbarItem(placement: .navigationBarTrailing) { Button("Done") { showSocSheet = false } } }
            }
        }
        .onAppear {
            // Select a default vehicle if none is selected
            if vehicleManager.selectedVehicle == nil {
                if let firstPopularVehicle = Vehicle.popularModels.first {
                    vehicleManager.selectVehicle(firstPopularVehicle)
                }
            }
        }
    }
    
    private func planRoute() {
        Task {
            await viewModel.planRoute()
        }
    }
}

// MARK: - Preview

#Preview {
    RoutePlanningView()
}

// (Old inline loading view removed; replaced by EVLoadingScene + PlanningStatusTicker)

// MARK: - Premium Loading Animation (inline)

struct EVLoadingScene: View {
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        TimelineView(.animation) { timeline in
            let t = timeline.date.timeIntervalSinceReferenceDate
            let travel = CGFloat((t.truncatingRemainder(dividingBy: 1.8)) / 1.8)
            let spin = (t * 2).truncatingRemainder(dividingBy: 1.0) * 360
            let bob = sin(t * 3.2) * 1.5

            ZStack {
                RoadLayer(phase: travel)
                    .frame(height: 6)
                    .offset(y: 18)

                ParallaxHills(phase: travel)
                    .frame(height: 24)
                    .offset(y: -2)
                    .opacity(scheme == .dark ? 0.20 : 0.30)

                EVCar(wheelAngle: spin, bob: bob)
                    .frame(width: 110, height: 42)
                    .offset(x: lerp(-28, 28, travel), y: -1)
                    .shadow(color: .black.opacity(0.18), radius: 6, x: 0, y: 2)
            }
            .animation(.linear(duration: 0.001), value: timeline.date)
            .accessibilityLabel("Planning route…")
        }
        .frame(height: 48)
    }

    private func lerp(_ a: CGFloat, _ b: CGFloat, _ t: CGFloat) -> CGFloat { a + (b - a) * t }
}

private struct RoadLayer: View {
    var phase: CGFloat
    var body: some View {
        ZStack(alignment: .leading) {
            Capsule().fill(.white.opacity(0.22))
            Canvas { ctx, size in
                let dashW: CGFloat = 10, gap: CGFloat = 8
                let total = dashW + gap
                let offset = -((phase.truncatingRemainder(dividingBy: 1)) * total)
                var x = offset
                while x < size.width {
                    let r = CGRect(x: x, y: (size.height-2)/2, width: dashW, height: 2)
                    ctx.fill(Path(r), with: .color(.white.opacity(0.7)))
                    x += total
                }
            }
        }
    }
}

private struct ParallaxHills: View {
    var phase: CGFloat
    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width, h = geo.size.height
            ZStack {
                hillPath(width: w, height: h, amp: 6, phase: phase * 1.0).fill(Color.blue.opacity(0.18))
                hillPath(width: w, height: h, amp: 4, phase: phase * 1.6).fill(Color.blue.opacity(0.12))
            }
        }
    }
    private func hillPath(width: CGFloat, height: CGFloat, amp: CGFloat, phase: CGFloat) -> Path {
        var p = Path()
        let yBase = height * 0.75
        p.move(to: CGPoint(x: 0, y: yBase))
        var i: CGFloat = 0
        while i <= width {
            let t = (i / width) + phase
            let y = yBase - sin(t * .pi * 2) * amp
            p.addLine(to: CGPoint(x: i, y: y))
            i += 8
        }
        p.addLine(to: CGPoint(x: width, y: height))
        p.addLine(to: CGPoint(x: 0, y: height))
        return p
    }
}

private struct EVCar: View {
    var wheelAngle: Double
    var bob: CGFloat
    var body: some View {
        ZStack {
            // Underbody shadow
            Ellipse()
                .fill(Color.black.opacity(0.12))
                .frame(width: 90, height: 10)
                .offset(y: 14)

            // Body with metallic finish
            CarBody()
                .fill(LinearGradient(colors: [Color.white.opacity(0.98), Color.white.opacity(0.82)], startPoint: .topLeading, endPoint: .bottomTrailing))
                .overlay(
                    CarBody()
                        .stroke(Color.white.opacity(0.55), lineWidth: 1)
                )
                .offset(y: bob)

            // Green-tinted window
            RoundedRectangle(cornerRadius: 3)
                .fill(Color.cyan.opacity(0.25))
                .frame(width: 36, height: 12)
                .offset(x: 8, y: -10)

            // Side mirror
            Capsule(style: .circular)
                .fill(Color.white.opacity(0.9))
                .frame(width: 8, height: 4)
                .offset(x: -16, y: -6)

            // Headlight glow (subtle)
            Circle()
                .fill(RadialGradient(colors: [Color.yellow.opacity(0.75), .clear], center: .center, startRadius: 1, endRadius: 16))
                .frame(width: 18, height: 18)
                .offset(x: -46, y: -2)

            // Tail light hint
            RoundedRectangle(cornerRadius: 2)
                .fill(Color.red.opacity(0.7))
                .frame(width: 6, height: 4)
                .offset(x: 46, y: -4)

            // Door line + handle
            Rectangle()
                .fill(Color.white.opacity(0.35))
                .frame(width: 1, height: 16)
                .offset(x: 6, y: 2)
            Capsule()
                .fill(Color.white.opacity(0.9))
                .frame(width: 10, height: 3)
                .offset(x: 14, y: 2)

            // Wheels (larger, more realistic)
            Wheel(angle: wheelAngle).frame(width: 16, height: 16).offset(x: -28, y: 10)
            Wheel(angle: wheelAngle).frame(width: 16, height: 16).offset(x:  28, y: 10)
        }
        .drawingGroup()
    }
}

private struct CarBody: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path()
        let w = r.width, h = r.height
        let yBase = h * 0.65
        // Front bumper → hood
        p.move(to: CGPoint(x: r.minX + w*0.02, y: r.minY + yBase))
        p.addQuadCurve(to: CGPoint(x: r.minX + w*0.16, y: r.minY + h*0.40), control: CGPoint(x: r.minX + w*0.06, y: r.minY + h*0.48))
        // Windshield → roof
        p.addQuadCurve(to: CGPoint(x: r.minX + w*0.45, y: r.minY + h*0.28), control: CGPoint(x: r.minX + w*0.28, y: r.minY + h*0.28))
        // Roof → rear glass
        p.addQuadCurve(to: CGPoint(x: r.minX + w*0.78, y: r.minY + h*0.44), control: CGPoint(x: r.minX + w*0.62, y: r.minY + h*0.24))
        // Trunk → rear bumper
        p.addQuadCurve(to: CGPoint(x: r.minX + w*0.95, y: r.minY + yBase), control: CGPoint(x: r.minX + w*0.92, y: r.minY + h*0.54))
        // Sill → front bumper
        p.addLine(to: CGPoint(x: r.minX + w*0.86, y: r.minY + h*0.90))
        p.addLine(to: CGPoint(x: r.minX + w*0.20, y: r.minY + h*0.90))
        p.addLine(to: CGPoint(x: r.minX + w*0.06, y: r.minY + h*0.74))
        p.addQuadCurve(to: CGPoint(x: r.minX + w*0.02, y: r.minY + yBase), control: CGPoint(x: r.minX + w*0.02, y: r.minY + h*0.70))
        return p
    }
}

private struct Wheel: View {
    var angle: Double
    var body: some View {
        ZStack {
            // Tire
            Circle().fill(Color.black.opacity(0.6))
            Circle().stroke(Color.black.opacity(0.9), lineWidth: 1.2)
            // Rim
            Circle()
                .inset(by: 2)
                .fill(LinearGradient(colors: [Color.white.opacity(0.95), Color.white.opacity(0.7)], startPoint: .top, endPoint: .bottom))
            // Spokes
            ForEach(0..<6, id: \.self) { i in
                Capsule()
                    .fill(Color.gray.opacity(0.9))
                    .frame(width: 1.6, height: 6.5)
                    .offset(y: -5)
                    .rotationEffect(.degrees(Double(i) * 60 + angle))
            }
            // Hub
            Circle().fill(Color.white.opacity(0.95)).frame(width: 3.5, height: 3.5)
            // Motion blur arcs
            Circle()
                .trim(from: 0.05, to: 0.25)
                .stroke(Color.white.opacity(0.25), lineWidth: 1)
                .rotationEffect(.degrees(angle))
            Circle()
                .trim(from: 0.55, to: 0.75)
                .stroke(Color.white.opacity(0.2), lineWidth: 1)
                .rotationEffect(.degrees(angle + 20))
        }
    }
}

struct PlanningStatusTicker: View {
    @State private var index = 0
    private let items: [(String, String)] = [
        ("map", "Mapping route geometry"),
        ("bolt.car", "Analyzing charging options"),
        ("gauge.with.dots.needle.67percent", "Estimating energy and time"),
        ("wand.and.stars", "Optimizing stops for comfort"),
        ("checkmark.seal", "Finalizing your plan")
    ]
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: items[index].0).transition(.opacity)
            Text(items[index].1).transition(.opacity)
        }
        .foregroundColor(.white.opacity(0.95))
        .font(.subheadline.weight(.semibold))
        .onAppear { tick() }
    }
    private func tick() {
        withAnimation(.easeInOut(duration: 0.25)) {}
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            index = (index + 1) % items.count
            tick()
        }
    }
}

// MARK: - Small Components

private struct Chip: View {
    let icon: String
    let label: String
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
            Text(label)
                .lineLimit(1)
                .truncationMode(.tail)
        }
        .font(.caption.weight(.semibold))
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Color(.systemGray6))
        .foregroundColor(.primary)
        .clipShape(Capsule())
    }
}

private struct PreferencesSheet: View {
    @Binding var selected: Set<String>
    @Binding var selectedConnectors: Set<Connector.ConnectorType>
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Amenities")
                        .font(.headline)
                        .padding(.top)
                    
                    // Using RouteDetails Amenity model
                    let items = Amenity.all
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 120), spacing: 10)], spacing: 10) {
                        ForEach(items) { item in
                            let isOn = selected.contains(item.id)
                            Button {
                                if isOn { selected.remove(item.id) } else { selected.insert(item.id) }
                            } label: {
                                HStack(spacing: 8) {
                                    Image(systemName: item.icon)
                                    Text(item.label)
                                }
                                .font(.subheadline)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 10)
                                .frame(maxWidth: .infinity)
                                .background(isOn ? Color.blue : Color(.systemGray6))
                                .foregroundColor(isOn ? .white : .primary)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    Divider().padding(.vertical, 8)
                    Text("Connector Types")
                        .font(.headline)
                    let types: [Connector.ConnectorType] = [.ccs, .chademo, .type2, .tesla, .j1772]
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 140), spacing: 10)], spacing: 10) {
                        ForEach(types, id: \.self) { type in
                            let isOn = selectedConnectors.contains(type)
                            Button {
                                if isOn { selectedConnectors.remove(type) } else { selectedConnectors.insert(type) }
                            } label: {
                                HStack(spacing: 8) {
                                    Image(systemName: "bolt.fill")
                                    Text(type.displayName)
                                }
                                .font(.subheadline)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 10)
                                .frame(maxWidth: .infinity)
                                .background(isOn ? Color.green : Color(.systemGray6))
                                .foregroundColor(isOn ? .white : .primary)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .accessibilityLabel("\(type.displayName) connector \(isOn ? "selected" : "not selected")")
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Preferences")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}
