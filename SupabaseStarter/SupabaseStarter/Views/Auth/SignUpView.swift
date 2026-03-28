import SwiftUI

struct SignUpView: View {
    @Environment(AuthViewModel.self) private var authViewModel
    @Environment(Router.self) private var router

    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""

    private var passwordsMatch: Bool {
        !confirmPassword.isEmpty && password == confirmPassword
    }

    private var canSubmit: Bool {
        !email.isEmpty && !password.isEmpty && passwordsMatch && !authViewModel.isLoading
    }

    var body: some View {
        ZStack {
            MeshGradient(
                width: 3, height: 3,
                points: [
                    [0, 0], [0.5, 0], [1, 0],
                    [0, 0.5], [0.5, 0.5], [1, 0.5],
                    [0, 1], [0.5, 1], [1, 1]
                ],
                colors: [
                    .purple.opacity(0.8), .indigo.opacity(0.6), .blue.opacity(0.7),
                    .indigo.opacity(0.5), .purple.opacity(0.4), .blue.opacity(0.5),
                    .blue.opacity(0.6), .indigo.opacity(0.4), .purple.opacity(0.6)
                ]
            )
            .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 28) {
                    // Header
                    VStack(spacing: 12) {
                        Text("Create Account")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundStyle(.white)

                        Text("Sign up to get started")
                            .foregroundStyle(.white.opacity(0.8))
                    }
                    .padding(.top, 40)

                    // Glass card
                    VStack(spacing: 20) {
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
                                    .textContentType(.newPassword)
                            }
                            .padding()
                            .glassEffect(.regular, in: .rect(cornerRadius: 14))

                            HStack(spacing: 12) {
                                Image(systemName: "lock.shield.fill")
                                    .foregroundStyle(.secondary)
                                    .frame(width: 20)
                                SecureField("Confirm Password", text: $confirmPassword)
                                    .textContentType(.newPassword)
                            }
                            .padding()
                            .glassEffect(.regular, in: .rect(cornerRadius: 14))

                            if !confirmPassword.isEmpty && !passwordsMatch {
                                Label("Passwords do not match", systemImage: "exclamationmark.triangle.fill")
                                    .font(.caption)
                                    .foregroundStyle(.red)
                            }
                        }

                        // Error
                        if let error = authViewModel.errorMessage {
                            Text(error)
                                .font(.caption)
                                .foregroundStyle(.red)
                                .multilineTextAlignment(.center)
                        }

                        // Sign Up Button
                        Button {
                            Task { await authViewModel.signUp(email: email, password: password) }
                        } label: {
                            Group {
                                if authViewModel.isLoading {
                                    ProgressView()
                                        .tint(.white)
                                } else {
                                    Text("Create Account")
                                        .fontWeight(.semibold)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                        }
                        .buttonStyle(.borderedProminent)
                        .buttonBorderShape(.roundedRectangle(radius: 14))
                        .tint(.purple)
                        .disabled(!canSubmit)
                    }
                    .padding(24)
                    .glassEffect(.regular.interactive, in: .rect(cornerRadius: 28))
                    .padding(.horizontal, 20)

                    // Back to Login
                    HStack(spacing: 4) {
                        Text("Already have an account?")
                            .foregroundStyle(.white.opacity(0.8))
                        Button("Sign In") {
                            router.pop()
                        }
                        .foregroundStyle(.white)
                        .fontWeight(.semibold)
                    }
                    .font(.subheadline)
                    .padding(.bottom, 32)
                }
            }
        }
        .navigationBarBackButtonHidden(false)
    }
}

#Preview {
    NavigationStack {
        SignUpView()
            .environment(AuthViewModel())
            .environment(Router())
    }
}
