import SwiftUI

struct BatterySlider: View {
    @Binding var currentSOC: Double
    @State private var isDragging = false
    
    var body: some View {
        VStack(spacing: 16) {
            // Battery Icon and Current Charge
            Text("Current charge: \(Int(currentSOC))%")
                .font(.headline)
                .foregroundColor(.primary)
            
            // Custom Slider
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Track
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.white.opacity(0.2))
                        .frame(height: 12)
                    
                    // Fill
                    RoundedRectangle(cornerRadius: 6)
                        .fill(LinearGradient(
                            gradient: Gradient(colors: [Color.red, Color.orange, Color.green]),
                            startPoint: .leading,
                            endPoint: .trailing
                        ))
                        .frame(width: max(0, geometry.size.width * (currentSOC / 100)), height: 12)
                    
                    // Thumb
                    Circle()
                        .fill(Color.white)
                        .frame(width: 28, height: 28)
                        .shadow(radius: 2)
                        .overlay(
                            Circle()
                                .stroke(batteryColor, lineWidth: 3)
                        )
                        .scaleEffect(isDragging ? 1.2 : 1.0)
                        .offset(x: max(0, min(geometry.size.width - 28, geometry.size.width * (currentSOC / 100) - 14)))
                        .gesture(
                            DragGesture()
                                .onChanged { value in
                                    isDragging = true
                                    let width = max(1, geometry.size.width)
                                    let newValue = (value.location.x / width) * 100
                                    currentSOC = min(100, max(0, newValue))
                                }
                                .onEnded { _ in
                                    withAnimation(.spring()) {
                                        isDragging = false
                                    }
                                }
                        )
                }
                .frame(height: 28)
                .onTapGesture { location in
                    withAnimation(.spring()) {
                        let width = max(1, geometry.size.width)
                        let newValue = (location.x / width) * 100
                        currentSOC = min(100, max(0, newValue))
                    }
                }
            }
            .frame(height: 28)
            
            // Labels
            HStack {
                Text("0%")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text("50%")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text("100%")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
        )
    }
    
    private var batteryIconName: String {
        switch currentSOC {
        case 0..<25:
            return "battery.25"
        case 25..<50:
            return "battery.50"
        case 50..<75:
            return "battery.75"
        default:
            return "battery.100"
        }
    }
    
    private var batteryColor: Color {
        switch currentSOC {
        case 0..<20:
            return .red
        case 20..<50:
            return .orange
        default:
            return .green
        }
    }
}

// MARK: - Preview

#Preview {
    struct PreviewWrapper: View {
        @State var soc = 80.0
        
        var body: some View {
            BatterySlider(currentSOC: $soc)
                .padding()
        }
    }
    
    return PreviewWrapper()
}