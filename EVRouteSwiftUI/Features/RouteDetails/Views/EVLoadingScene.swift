import SwiftUI

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
                    .frame(width: 90, height: 38)
                    .offset(x: lerp(-28, 28, travel), y: -1)
                    .shadow(color: .black.opacity(0.18), radius: 6, x: 0, y: 2)
            }
            .animation(.linear(duration: 0.001), value: timeline.date)
            .accessibilityLabel("Planning route…")
        }
        .frame(height: 48)
    }

    private func lerp(_ a: CGFloat, _ b: CGFloat, _ t: CGFloat) -> CGFloat {
        a + (b - a) * t
    }
}

private struct RoadLayer: View {
    var phase: CGFloat
    var body: some View {
        ZStack(alignment: .leading) {
            Capsule().fill(.white.opacity(0.22))
            Canvas { ctx, size in
                let dashW: CGFloat = 10
                let gap: CGFloat = 8
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
            let w = geo.size.width
            ZStack {
                hillPath(width: w, height: geo.size.height, amp: 6, phase: phase * 1.0)
                    .fill(Color.blue.opacity(0.18))
                hillPath(width: w, height: geo.size.height, amp: 4, phase: phase * 1.6)
                    .fill(Color.blue.opacity(0.12))
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
            CarBody()
                .fill(LinearGradient(colors: [Color.white.opacity(0.95), Color.white.opacity(0.78)], startPoint: .topLeading, endPoint: .bottomTrailing))
                .overlay(CarBody().stroke(Color.white.opacity(0.55), lineWidth: 1))
                .offset(y: bob)

            RoundedRectangle(cornerRadius: 3)
                .fill(Color.blue.opacity(0.25))
                .frame(width: 28, height: 12)
                .offset(x: 6, y: -8)

            Circle()
                .fill(RadialGradient(colors: [Color.yellow.opacity(0.7), .clear], center: .center, startRadius: 1, endRadius: 14))
                .frame(width: 16, height: 16)
                .offset(x: -36, y: -2)

            Wheel(angle: wheelAngle).frame(width: 14, height: 14).offset(x: -22, y: 8)
            Wheel(angle: wheelAngle).frame(width: 14, height: 14).offset(x:  22, y: 8)
        }
        .drawingGroup()
    }
}

private struct CarBody: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path()
        let w = r.width, h = r.height
        let hoodH = h * 0.55, roofH = h * 0.38, trunkH = h * 0.5
        p.move(to: CGPoint(x: r.minX + w*0.05, y: r.minY + hoodH))
        p.addQuadCurve(to: CGPoint(x: r.minX + w*0.22, y: r.minY + roofH), control: CGPoint(x: r.minX + w*0.12, y: r.minY + hoodH - 6))
        p.addLine(to: CGPoint(x: r.minX + w*0.64, y: r.minY + roofH))
        p.addQuadCurve(to: CGPoint(x: r.minX + w*0.78, y: r.minY + trunkH), control: CGPoint(x: r.minX + w*0.70, y: r.minY + roofH - 4))
        p.addLine(to: CGPoint(x: r.minX + w*0.92, y: r.minY + trunkH))
        p.addQuadCurve(to: CGPoint(x: r.minX + w*0.95, y: r.minY + trunkH + 8), control: CGPoint(x: r.minX + w*0.97, y: r.minY + trunkH + 2))
        p.addLine(to: CGPoint(x: r.minX + w*0.90, y: r.minY + h*0.88))
        p.addLine(to: CGPoint(x: r.minX + w*0.12, y: r.minY + h*0.88))
        p.addLine(to: CGPoint(x: r.minX + w*0.07, y: r.minY + trunkH + 8))
        p.addQuadCurve(to: CGPoint(x: r.minX + w*0.05, y: r.minY + hoodH), control: CGPoint(x: r.minX + w*0.03, y: r.minY + hoodH + 2))
        return p
    }
}

private struct Wheel: View {
    var angle: Double
    var body: some View {
        ZStack {
            Circle().fill(Color.black.opacity(0.25))
            Circle().stroke(Color.white.opacity(0.85), lineWidth: 1.5)
            ForEach(0..<6, id: \.self) { i in
                Capsule()
                    .fill(Color.white.opacity(0.9))
                    .frame(width: 1.5, height: 6)
                    .offset(y: -5)
                    .rotationEffect(.degrees(Double(i) * 60 + angle))
            }
            Circle().fill(Color.white.opacity(0.95)).frame(width: 3, height: 3)
        }
    }
}

