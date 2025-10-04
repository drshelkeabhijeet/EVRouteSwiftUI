import SwiftUI
import UIKit

// App Icon Generator for EV Route
// This creates a simple EV-themed app icon programmatically
// Run this in a Swift Playground or temporary view to generate the icon

struct AppIconView: View {
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [
                    Color(red: 0.0, green: 0.8, blue: 0.4),  // Electric green
                    Color(red: 0.0, green: 0.6, blue: 0.3)   // Darker green
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            // Main icon content
            ZStack {
                // Road/Route element
                Path { path in
                    path.move(to: CGPoint(x: 200, y: 800))
                    path.addCurve(
                        to: CGPoint(x: 824, y: 224),
                        control1: CGPoint(x: 400, y: 600),
                        control2: CGPoint(x: 624, y: 424)
                    )
                }
                .stroke(Color.white.opacity(0.3), lineWidth: 80)

                // Lightning bolt (charging symbol)
                Image(systemName: "bolt.fill")
                    .font(.system(size: 400, weight: .bold))
                    .foregroundColor(.white)
                    .rotationEffect(.degrees(-15))
                    .offset(x: -50, y: -50)

                // Location pin
                Image(systemName: "mappin.circle.fill")
                    .font(.system(size: 200, weight: .medium))
                    .foregroundColor(.white.opacity(0.9))
                    .offset(x: 250, y: 200)
            }
        }
        .frame(width: 1024, height: 1024)
    }
}

// Helper function to generate PNG data from the view
extension View {
    func snapshot() -> UIImage {
        let controller = UIHostingController(rootView: self.edgesIgnoringSafeArea(.all))
        let view = controller.view

        let targetSize = CGSize(width: 1024, height: 1024)
        view?.bounds = CGRect(origin: .zero, size: targetSize)
        view?.backgroundColor = .clear

        let renderer = UIGraphicsImageRenderer(size: targetSize)
        return renderer.image { _ in
            view?.drawHierarchy(in: controller.view.bounds, afterScreenUpdates: true)
        }
    }
}

// Instructions for generating the app icon:
// 1. Create a new SwiftUI View in your app temporarily
// 2. Add this code to render and save the icon:
/*
struct IconGeneratorView: View {
    var body: some View {
        VStack {
            AppIconView()
                .frame(width: 300, height: 300)
                .cornerRadius(60)

            Button("Save Icon") {
                let image = AppIconView().snapshot()
                UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
                print("Icon saved to Photos")
            }
            .padding()
        }
    }
}
*/

// Alternative: Simple text-based icon for quick generation
struct SimpleAppIconView: View {
    var body: some View {
        ZStack {
            // Background
            LinearGradient(
                colors: [
                    Color(red: 0.1, green: 0.7, blue: 0.4),
                    Color(red: 0.0, green: 0.5, blue: 0.3)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            // EV text with bolt
            VStack(spacing: 0) {
                Image(systemName: "bolt.fill")
                    .font(.system(size: 400, weight: .bold))
                    .foregroundColor(.white)

                Text("EV")
                    .font(.system(size: 300, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
            }
        }
        .frame(width: 1024, height: 1024)
    }
}