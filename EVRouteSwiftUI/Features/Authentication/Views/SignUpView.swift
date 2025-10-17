import SwiftUI

struct SignUpView: View {
    @EnvironmentObject var authManager: AuthManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var name = ""
    @State private var email = ""
    @State private var phone = ""
    @State private var displayName = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var showEmailConfirmation = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 8) {
                    Text("Create Account")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text("Join the EV community")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.top)
                
                // Form
                VStack(spacing: 16) {
                    TextField("Full Name", text: $name)
                        .textFieldStyle(.roundedBorder)
                        .textContentType(.name)
                    
                    TextField("Display Name (Optional)", text: $displayName)
                        .textFieldStyle(.roundedBorder)
                        .textContentType(.name)
                        .onChange(of: displayName) { _, newValue in
                            if newValue.isEmpty {
                                displayName = name
                            }
                        }
                    
                    TextField("Email", text: $email)
                        .textFieldStyle(.roundedBorder)
                        .textContentType(.emailAddress)
                        .autocapitalization(.none)
                        .keyboardType(.emailAddress)
                    
                    TextField("Phone Number", text: $phone)
                        .textFieldStyle(.roundedBorder)
                        .textContentType(.telephoneNumber)
                        .keyboardType(.phonePad)
                    
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
                    RequirementRow(
                        text: "At least 8 characters",
                        isMet: password.count >= 8
                    )
                    RequirementRow(
                        text: "Passwords match",
                        isMet: passwordsMatch
                    )
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)
                
                // Sign up button
                Button {
                    Task {
                        await signUp()
                    }
                } label: {
                    if authManager.isLoading {
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
                .disabled(!isFormValid || authManager.isLoading)
                
                Spacer()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .alert("Error", isPresented: $showError) {
                Button("OK") { }
            } message: {
                Text(errorMessage)
            }
            .alert("Email Confirmation Required", isPresented: $showEmailConfirmation) {
                Button("OK") {
                    dismiss()
                }
            } message: {
                Text("Please check your email and click the confirmation link to activate your account.")
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
        !phone.isEmpty &&
        password.count >= 8 &&
        passwordsMatch
    }
    
    private func signUp() async {
        do {
            try await authManager.signUp(
                email: email, 
                password: password, 
                name: name, 
                phone: phone, 
                displayName: displayName.isEmpty ? name : displayName
            )
            showEmailConfirmation = true
        } catch {
            if let authError = error as? AuthError, authError == .emailConfirmationRequired {
                showEmailConfirmation = true
            } else {
                errorMessage = error.localizedDescription
                showError = true
            }
        }
    }
}

struct RequirementRow: View {
    let text: String
    let isMet: Bool
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: isMet ? "checkmark.circle.fill" : "circle")
                .foregroundColor(isMet ? .green : .secondary)
                .font(.caption)
            
            Text(text)
                .font(.caption)
                .foregroundColor(isMet ? .green : .secondary)
        }
    }
}
