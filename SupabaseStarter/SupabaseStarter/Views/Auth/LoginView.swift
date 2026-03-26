import SwiftUI

struct LoginView: View {
    @Environment(AuthViewModel.self) private var authViewModel
    @Environment(Router.self) private var router

    @State private var email = ""
    @State private var password = ""

    var body: some View {
        @Bindable var authVM = authViewModel

        ScrollView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 8) {
                    Image(systemName: "bolt.shield.fill")
                        .font(.system(size: 60))
                        .foregroundStyle(.blue)

                    Text("Welcome Back")
                        .font(.title)
                        .fontWeight(.bold)

                    Text("Sign in to continue")
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 40)

                // Email & Password
                VStack(spacing: 16) {
                    TextField("Email", text: $email)
                        .textFieldStyle(.roundedBorder)
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)

                    SecureField("Password", text: $password)
                        .textFieldStyle(.roundedBorder)
                        .textContentType(.password)
                }

                // Error
                if let error = authViewModel.errorMessage {
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.red)
                        .multilineTextAlignment(.center)
                }

                // Sign In Button
                Button {
                    Task { await authViewModel.signIn(email: email, password: password) }
                } label: {
                    Group {
                        if authViewModel.isLoading {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Text("Sign In")
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(.blue)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .disabled(email.isEmpty || password.isEmpty || authViewModel.isLoading)

                // Divider
                HStack {
                    Rectangle().frame(height: 1).foregroundStyle(.secondary.opacity(0.3))
                    Text("OR")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Rectangle().frame(height: 1).foregroundStyle(.secondary.opacity(0.3))
                }

                // OAuth Buttons
                VStack(spacing: 12) {
                    OAuthButton(provider: .apple) {
                        Task { await authViewModel.signInWithApple() }
                    }

                    OAuthButton(provider: .google) {
                        Task { await authViewModel.signInWithGoogle() }
                    }
                }

                // Sign Up Link
                HStack {
                    Text("Don't have an account?")
                        .foregroundStyle(.secondary)
                    Button("Sign Up") {
                        router.navigate(to: .signUp)
                    }
                }
                .font(.subheadline)
            }
            .padding(.horizontal, 24)
        }
    }
}

#Preview {
    NavigationStack {
        LoginView()
            .environment(AuthViewModel())
            .environment(Router())
    }
}
