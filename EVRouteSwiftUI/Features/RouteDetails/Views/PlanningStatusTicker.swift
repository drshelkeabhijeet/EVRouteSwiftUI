import SwiftUI

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
            Image(systemName: items[index].0)
                .transition(.opacity)
            Text(items[index].1)
                .transition(.opacity)
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

