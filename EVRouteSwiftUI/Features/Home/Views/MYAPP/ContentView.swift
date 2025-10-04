import SwiftUI

/// The primary view of the application.
///
/// ``ContentView`` displays a simple welcome screen with a navigation
/// link to ``DetailView``. Feel free to customize this view by adding
/// additional UI elements, modifying the layout, or replacing the
/// navigation link with your project's actual features.
struct ContentView: View {
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                Text("Welcome to MyProjectApp")
                    .font(.largeTitle)
                    .multilineTextAlignment(.center)
                    .padding(.top, 40)

                Text("This is a placeholder front‑end for your project.")
                    .font(.headline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

                NavigationLink(destination: DetailView()) {
                    Label("Get Started", systemImage: "arrow.forward.circle.fill")
                        .font(.title2)
                        .padding()
                        .background(Color.blue.opacity(0.8))
                        .foregroundColor(.white)
                        .clipShape(Capsule())
                }

                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(UIColor.systemBackground))
            .navigationTitle("Home")
        }
    }
}

// Preview provider for development previews in Xcode.
#if DEBUG
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
#endif