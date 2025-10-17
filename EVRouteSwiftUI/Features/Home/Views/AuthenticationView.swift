import SwiftUI

struct AuthenticationView: View {
    @State private var isShowingSignup = false
    
    var body: some View {
        if isShowingSignup {
            SignupView(isShowingSignup: $isShowingSignup)
        } else {
            LoginView(isShowingSignup: $isShowingSignup)
        }
    }
}

struct LoginView: View {
    @EnvironmentObject var authManager: AuthManager
    @Binding var isShowingSignup: Bool
    
    @State private var email = ""
    @State private var password = ""
    @State private var isLoading = false
    @State private var showError = false
    @State private var errorMessage = ""
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // Logo
                Image(systemName: "bolt.car.circle.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.green)
                    .padding(.top, 60)
                
                Text("EV Route")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Plan your electric journey")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                // Form
                VStack(spacing: 16) {
                    TextField("Email", text: $email)
                        .textFieldStyle(.roundedBorder)
                        .textContentType(.emailAddress)
                        .autocapitalization(.none)
                        .keyboardType(.emailAddress)
                    
                    SecureField("Password", text: $password)
                        .textFieldStyle(.roundedBorder)
                        .textContentType(.password)
                }
                .padding(.horizontal)
                
                // Login Button
                Button {
                    Task {
                        await login()
                    }
                } label: {
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Text("Sign In")
                            .fontWeight(.semibold)
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(isFormValid ? Color.green : Color.gray)
                .foregroundColor(.white)
                .cornerRadius(10)
                .padding(.horizontal)
                .disabled(!isFormValid || isLoading)
                
                // Signup Link
                HStack {
                    Text("Don't have an account?")
                        .foregroundColor(.secondary)
                    
                    Button("Sign Up") {
                        isShowingSignup = true
                    }
                    .foregroundColor(.green)
                    .fontWeight(.medium)
                }
                
                Spacer()
            }
            .navigationBarHidden(true)
            .alert("Error", isPresented: $showError) {
                Button("OK") { }
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    private var isFormValid: Bool {
        !email.isEmpty && !password.isEmpty && email.contains("@")
    }
    
    private func login() async {
        isLoading = true
        
        do {
            try await authManager.signIn(email: email, password: password)
        } catch {
            print("Login error: \(error)")
            errorMessage = "Login failed. Please try again."
            showError = true
        }
        
        isLoading = false
    }
}

struct SignupView: View {
    @EnvironmentObject var authManager: AuthManager
    @Binding var isShowingSignup: Bool
    
    @State private var name = ""
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var isLoading = false
    @State private var showError = false
    @State private var errorMessage = ""
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // Header
                HStack {
                    Button {
                        isShowingSignup = false
                    } label: {
                        Image(systemName: "arrow.left")
                            .font(.title2)
                            .foregroundColor(.primary)
                    }
                    
                    Spacer()
                }
                .padding()
                
                Text("Create Account")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Join the EV community")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                // Form
                VStack(spacing: 16) {
                    TextField("Full Name", text: $name)
                        .textFieldStyle(.roundedBorder)
                        .textContentType(.name)
                    
                    TextField("Email", text: $email)
                        .textFieldStyle(.roundedBorder)
                        .textContentType(.emailAddress)
                        .autocapitalization(.none)
                        .keyboardType(.emailAddress)
                    
                    SecureField("Password", text: $password)
                        .textFieldStyle(.roundedBorder)
                        .textContentType(.newPassword)
                    
                    SecureField("Confirm Password", text: $confirmPassword)
                        .textFieldStyle(.roundedBorder)
                        .textContentType(.newPassword)
                }
                .padding(.horizontal)
                
                // Password requirements
                VStack(alignment: .leading, spacing: 4) {
                    Label("At least 8 characters", systemImage: password.count >= 8 ? "checkmark.circle.fill" : "circle")
                        .font(.caption)
                        .foregroundColor(password.count >= 8 ? .green : .secondary)
                    
                    Label("Passwords match", systemImage: passwordsMatch ? "checkmark.circle.fill" : "circle")
                        .font(.caption)
                        .foregroundColor(passwordsMatch ? .green : .secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)
                
                // Signup Button
                Button {
                    Task {
                        await signup()
                    }
                } label: {
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Text("Create Account")
                            .fontWeight(.semibold)
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(isFormValid ? Color.green : Color.gray)
                .foregroundColor(.white)
                .cornerRadius(10)
                .padding(.horizontal)
                .disabled(!isFormValid || isLoading)
                
                Spacer()
            }
            .navigationBarHidden(true)
            .alert("Error", isPresented: $showError) {
                Button("OK") { }
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    private var passwordsMatch: Bool {
        !password.isEmpty && password == confirmPassword
    }
    
    private var isFormValid: Bool {
        !name.isEmpty &&
        !email.isEmpty &&
        email.contains("@") &&
        password.count >= 8 &&
        passwordsMatch
    }
    
    private func signup() async {
        isLoading = true
        
        do {
            try await authManager.signUp(email: email, password: password, name: name)
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
        
        isLoading = false
    }
}

// MARK: - Previews

struct AuthenticationView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            AuthenticationView()
                .environmentObject(AuthManager.shared)
            
            AuthenticationView()
                .environmentObject(AuthManager.shared)
                .preferredColorScheme(.dark)
        }
    }
}