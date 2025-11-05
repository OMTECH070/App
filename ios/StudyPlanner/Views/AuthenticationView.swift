import SwiftUI
import GoogleSignIn
import AuthenticationServices

struct AuthenticationView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var email = ""
    @State private var password = ""
    @State private var displayName = ""
    @State private var isSignUpMode = false
    @State private var showingAlert = false

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Logo and Title
                VStack(spacing: 8) {
                    Image(systemName: "brain.head.profile")
                        .font(.system(size: 60))
                        .foregroundColor(.blue)

                    Text("Study Planner")
                        .font(.largeTitle)
                        .fontWeight(.bold)

                    Text("AI-Powered Study Scheduling")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 40)

                // Form
                VStack(spacing: 16) {
                    if isSignUpMode {
                        TextField("Display Name", text: $displayName)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .autocapitalization(.words)
                    }

                    TextField("Email", text: $email)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)

                    SecureField("Password", text: $password)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                .padding(.horizontal)

                // Action Button
                Button(action: {
                    if isSignUpMode {
                        Task {
                            await authViewModel.signUp(email: email, password: password, displayName: displayName)
                        }
                    } else {
                        Task {
                            await authViewModel.signIn(email: email, password: password)
                        }
                    }
                }) {
                    if authViewModel.isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Text(isSignUpMode ? "Sign Up" : "Sign In")
                            .fontWeight(.semibold)
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
                .disabled(authViewModel.isLoading || email.isEmpty || password.isEmpty || (isSignUpMode && displayName.isEmpty))

                // Sign In With Google
                Button(action: {
                    Task {
                        await authViewModel.signInWithGoogle()
                    }
                }) {
                    HStack {
                        Image("google-logo")
                            .resizable()
                            .frame(width: 20, height: 20)
                        Text("Continue with Google")
                            .fontWeight(.medium)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(Color.white)
                    .foregroundColor(.black)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                    )
                }
                .disabled(authViewModel.isLoading)

                // Sign In With Apple
                SignInWithAppleButton(
                    onRequest: { request in
                        request.requestedScopes = [.fullName, .email]
                    },
                    onCompletion: { result in
                        switch result {
                        case .success(let authorization):
                            // Handle Apple Sign In success
                            Task {
                                // await authViewModel.signInWithApple(authorization)
                            }
                        case .failure(let error):
                            print("Apple Sign In failed: \(error)")
                        }
                    }
                )
                .signInWithAppleButtonStyle(.black)
                .frame(height: 50)
                .padding(.horizontal)

                Spacer()

                // Toggle Sign Up/Sign In
                HStack {
                    Text(isSignUpMode ? "Already have an account?" : "Don't have an account?")
                        .foregroundColor(.secondary)

                    Button(action: {
                        withAnimation {
                            isSignUpMode.toggle()
                        }
                    }) {
                        Text(isSignUpMode ? "Sign In" : "Sign Up")
                            .fontWeight(.semibold)
                            .foregroundColor(.blue)
                    }
                }
                .padding(.bottom, 40)
            }
            .navigationBarHidden(true)
            .alert("Authentication Error", isPresented: .constant(authViewModel.errorMessage != nil)) {
                Button("OK") {
                    authViewModel.errorMessage = nil
                }
            } message: {
                Text(authViewModel.errorMessage ?? "")
            }
        }
    }
}

#Preview {
    AuthenticationView()
        .environmentObject(AuthViewModel())
}