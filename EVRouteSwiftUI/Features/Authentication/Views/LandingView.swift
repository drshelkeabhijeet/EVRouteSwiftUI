import SwiftUI

struct LandingView: View {
    @State private var showingSignUp = false
    @State private var showingSignIn = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background gradient
                LinearGradient(
                    colors: [.green.opacity(0.1), .blue.opacity(0.1)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack(spacing: 40) {
                    Spacer()
                    
                    // Logo and branding
                    VStack(spacing: 16) {
                        Image(systemName: "bolt.car.circle.fill")
                            .font(.system(size: 100))
                            .foregroundColor(.green)
                        
                        Text("EV Route")
                            .font(.system(size: 48, weight: .bold))
                            .foregroundColor(.primary)
                        
                        Text("Plan your electric journey with confidence")
                            .font(.title3)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    
                    Spacer()
                    
                    // Feature highlights
                    VStack(spacing: 20) {
                        FeatureRow(icon: "bolt.circle.fill", title: "Find Charging Stations", description: "Discover nearby EV charging points")
                        FeatureRow(icon: "map.fill", title: "Plan Routes", description: "Get optimal routes with charging stops")
                        FeatureRow(icon: "clock.fill", title: "Real-time Updates", description: "Live availability and pricing")
                    }
                    .padding(.horizontal)
                    
                    Spacer()
                    
                    // Action buttons
                    VStack(spacing: 16) {
                        Button {
                            showingSignUp = true
                        } label: {
                            Text("Get Started")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 56)
                                .background(Color.green)
                                .cornerRadius(16)
                        }
                        
                        Button {
                            showingSignIn = true
                        } label: {
                            Text("Sign In")
                                .font(.headline)
                                .foregroundColor(.green)
                                .frame(maxWidth: .infinity)
                                .frame(height: 56)
                                .background(Color.green.opacity(0.1))
                                .cornerRadius(16)
                        }
                    }
                    .padding(.horizontal, 32)
                    .padding(.bottom, 50)
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showingSignUp) {
                SignUpView()
            }
            .sheet(isPresented: $showingSignIn) {
                SignInView()
            }
        }
    }
}

struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.green)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
    }
}
