import SwiftUI

struct SimpleAuthenticationView: View {
    @EnvironmentObject var authManager: AuthManager
    @State private var email = "test@example.com"
    @State private var password = "password123"
    @State private var isLoading = false
    
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            
            // Logo
            Image(systemName: "bolt.car.circle.fill")
                .font(.system(size: 80))
                .foregroundColor(.green)
            
            Text("EV Route")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("Plan your electric journey")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Spacer()
            
            // Demo Login Button
            Button {
                Task {
                    await demoLogin()
                }
            } label: {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                } else {
                    Text("Demo Login")
                        .fontWeight(.semibold)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(Color.green)
            .foregroundColor(.white)
            .cornerRadius(10)
            .padding(.horizontal, 40)
            .disabled(isLoading)
            
            Text("Tap to continue with demo account")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Spacer()
        }
    }
    
    private func demoLogin() async {
        isLoading = true
        
        do {
            try await authManager.signIn(email: email, password: password)
        } catch {
            print("Demo login error: \(error)")
            // Silently fail and retry
            try? await Task.sleep(nanoseconds: 500_000_000)
            try? await authManager.signIn(email: email, password: password)
        }
        
        isLoading = false
    }
}