import SwiftUI

struct VehicleSelectionView: View {
    @StateObject private var vehicleManager = VehicleManager.shared
    @State private var showingAddVehicle = false
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            List {
                // Selected Vehicle Section
                if let selected = vehicleManager.selectedVehicle {
                    Section("Current Vehicle") {
                        VehicleRow(vehicle: selected, isSelected: true) {
                            // Already selected
                        }
                    }
                }
                
                // Saved Vehicles Section
                if !vehicleManager.savedVehicles.isEmpty {
                    Section("My Vehicles") {
                        ForEach(vehicleManager.savedVehicles) { vehicle in
                            if vehicle.id != vehicleManager.selectedVehicle?.id {
                                VehicleRow(vehicle: vehicle, isSelected: false) {
                                    vehicleManager.selectVehicle(vehicle)
                                    dismiss()
                                }
                            }
                        }
                        .onDelete { indexSet in
                            for index in indexSet {
                                vehicleManager.removeVehicle(vehicleManager.savedVehicles[index])
                            }
                        }
                    }
                }
                
                // Popular Models Section
                Section("Popular Models") {
                    ForEach(Vehicle.popularModels) { vehicle in
                        VehicleRow(vehicle: vehicle, isSelected: vehicle.id == vehicleManager.selectedVehicle?.id) {
                            vehicleManager.selectVehicle(vehicle)
                            dismiss()
                        }
                    }
                }
            }
            .navigationTitle("Select Vehicle")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingAddVehicle = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddVehicle) {
                AddVehicleView()
            }
        }
    }
}

// MARK: - Vehicle Row

struct VehicleRow: View {
    let vehicle: Vehicle
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(vehicle.displayName)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    HStack(spacing: 12) {
                        Label("\(Int(vehicle.batteryCapacity)) kWh", systemImage: "battery.100")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Label("\(Int(vehicle.range)) km", systemImage: "location.circle")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Label("\(Int(vehicle.maxChargingSpeed)) kW", systemImage: "bolt.fill")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .font(.title2)
                }
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Add Vehicle View

struct AddVehicleView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var vehicleManager = VehicleManager.shared
    
    @State private var make = ""
    @State private var model = ""
    @State private var year = Calendar.current.component(.year, from: Date())
    @State private var batteryCapacity = "75"
    @State private var range = "400"
    @State private var efficiency = "15"
    @State private var maxChargingSpeed = "150"
    @State private var selectedConnectors: Set<Connector.ConnectorType> = [.ccs]
    
    var isFormValid: Bool {
        !make.isEmpty &&
        !model.isEmpty &&
        year >= 2010 &&
        (Double(batteryCapacity) ?? 0) > 0 &&
        (Double(range) ?? 0) > 0 &&
        (Double(efficiency) ?? 0) > 0 &&
        (Double(maxChargingSpeed) ?? 0) > 0 &&
        !selectedConnectors.isEmpty
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Vehicle Information") {
                    TextField("Make", text: $make)
                    TextField("Model", text: $model)
                    Stepper("Year: \(year)", value: $year, in: 2010...2030)
                }
                
                Section("Battery & Performance") {
                    HStack {
                        TextField("Battery Capacity", text: $batteryCapacity)
                            .keyboardType(.decimalPad)
                        Text("kWh")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        TextField("Range", text: $range)
                            .keyboardType(.numberPad)
                        Text("km")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        TextField("Efficiency", text: $efficiency)
                            .keyboardType(.decimalPad)
                        Text("kWh/100km")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        TextField("Max Charging Speed", text: $maxChargingSpeed)
                            .keyboardType(.numberPad)
                        Text("kW")
                            .foregroundColor(.secondary)
                    }
                }
                
                Section("Connector Types") {
                    ForEach([Connector.ConnectorType.ccs, .chademo, .type2, .tesla, .j1772], id: \.self) { type in
                        Toggle(type.displayName, isOn: Binding(
                            get: { selectedConnectors.contains(type) },
                            set: { isSelected in
                                if isSelected {
                                    selectedConnectors.insert(type)
                                } else {
                                    selectedConnectors.remove(type)
                                }
                            }
                        ))
                    }
                }
            }
            .navigationTitle("Add Vehicle")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveVehicle()
                    }
                    .disabled(!isFormValid)
                }
            }
        }
    }
    
    private func saveVehicle() {
        vehicleManager.addCustomVehicle(
            make: make,
            model: model,
            year: year,
            batteryCapacity: Double(batteryCapacity) ?? 75,
            range: Double(range) ?? 400,
            efficiency: Double(efficiency) ?? 15,
            connectorTypes: Array(selectedConnectors),
            maxChargingSpeed: Double(maxChargingSpeed) ?? 150
        )
        dismiss()
    }
}

// MARK: - Previews

#Preview("Vehicle Selection") {
    VehicleSelectionView()
}

#Preview("Add Vehicle") {
    AddVehicleView()
}