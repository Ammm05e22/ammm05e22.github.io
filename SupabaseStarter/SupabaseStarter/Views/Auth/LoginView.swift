import SwiftUI

struct LoginView: View {
    @Environment(AuthViewModel.self) private var authViewModel
    @Environment(Router.self) private var router

    @State private var email = ""
    @State private var password = ""

    var body: some View {
        ZStack {
            // Animated gradient background
            MeshGradient(
                width: 3, height: 3,
                points: [
                    [0, 0], [0.5, 0], [1, 0],
                    [0, 0.5], [0.5, 0.5], [1, 0.5],
                    [0, 1], [0.5, 1], [1, 1]
                ],
                colors: [
                    .blue.opacity(0.8), .indigo.opacity(0.6), .purple.opacity(0.7),
                    .cyan.opacity(0.5), .blue.opacity(0.4), .indigo.opacity(0.5),
                    .teal.opacity(0.6), .cyan.opacity(0.4), .blue.opacity(0.6)
                ]
            )
            .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 28) {
                    // Header
                    VStack(spacing: 12) {
                        Image(systemName: "bolt.shield.fill")
                            .font(.system(size: 56))
                            .foregroundStyle(.white)
                            .symbolEffect(.breathe)

                        Text("Welcome Back")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundStyle(.white)

                        Text("Sign in to continue")
                            .foregroundStyle(.white.opacity(0.8))
                    }
                    .padding(.top, 60)

                    // Glass card with form
                    VStack(spacing: 20) {
                        // Email & Password
                        VStack(spacing: 14) {
                            HStack(spacing: 12) {
                                Image(systemName: "envelope.fill")
                                    .foregroundStyle(.secondary)
                                    .frame(width: 20)
                                TextField("Email", text: $email)
                                    .textContentType(.emailAddress)
                                    .keyboardType(.emailAddress)
                                    .autocorrectionDisabled()
                                    .textInputAutocapitalization(.never)
                            }
                            .padding()
                            .glassEffect(.regular, in: .rect(cornerRadius: 14))

                            HStack(spacing: 12) {
                                Image(systemName: "lock.fill")
                                    .foregroundStyle(.secondary)
                                    .frame(width: 20)
                                SecureField("Password", text: $password)
                                    .textContentType(.password)
                            }
                            .padding()
                            .glassEffect(.regular, in: .rect(cornerRadius: 14))
                        }

                        // Error
                        if let error = authViewModel.errorMessage {
                            Text(error)
                                .font(.caption)
                                .foregroundStyle(.red)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
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
                                        .fontWeight(.semibold)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                        }
                        .buttonStyle(.borderedProminent)
                        .buttonBorderShape(.roundedRectangle(radius: 14))
                        .tint(.blue)
                        .disabled(email.isEmpty || password.isEmpty || authViewModel.isLoading)

                        // Divider
                        HStack(spacing: 12) {
                            Rectangle().frame(height: 0.5).foregroundStyle(.white.opacity(0.3))
                            Text("OR")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Rectangle().frame(height: 0.5).foregroundStyle(.white.opacity(0.3))
                        }

                        // OAuth Buttons
                        VStack(spacing: 10) {
                            OAuthButton(provider: .apple) {
                                Task { await authViewModel.signInWithApple() }
                            }

                            OAuthButton(provider: .google) {
                                Task { await authViewModel.signInWithGoogle() }
                            }
                        }
                    }
                    .padding(24)
                    .glassEffect(.regular.interactive, in: .rect(cornerRadius: 28))
                    .padding(.horizontal, 20)

                    // Sign Up Link
                    HStack(spacing: 4) {
                        Text("Don't have an account?")
                            .foregroundStyle(.white.opacity(0.8))
                        Button("Sign Up") {
                            router.navigate(to: .signUp)
                        }
                        .foregroundStyle(.white)
                        .fontWeight(.semibold)
                    }
                    .font(.subheadline)
                    .padding(.bottom, 32)
                }
            }
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
