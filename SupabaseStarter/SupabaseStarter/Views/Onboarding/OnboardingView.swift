import SwiftUI
import PhotosUI

struct OnboardingView: View {
    @Environment(AuthViewModel.self) private var authViewModel
    @State private var viewModel = OnboardingViewModel()

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
                    .teal.opacity(0.7), .cyan.opacity(0.5), .blue.opacity(0.6),
                    .cyan.opacity(0.4), .teal.opacity(0.5), .indigo.opacity(0.4),
                    .blue.opacity(0.5), .teal.opacity(0.3), .cyan.opacity(0.5)
                ]
            )
            .ignoresSafeArea()

            VStack(spacing: 32) {
                // Header
                VStack(spacing: 12) {
                    Text("Complete Your Profile")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)

                    Text("Choose a username and avatar")
                        .foregroundStyle(.white.opacity(0.8))
                }
                .padding(.top, 60)

                // Glass card
                VStack(spacing: 28) {
                    // Avatar Picker
                    PhotosPicker(selection: $viewModel.selectedPhoto, matching: .images) {
                        if let avatarImage = viewModel.avatarImage {
                            avatarImage
                                .resizable()
                                .scaledToFill()
                                .frame(width: 120, height: 120)
                                .clipShape(Circle())
                                .overlay(Circle().stroke(.white.opacity(0.5), lineWidth: 3))
                                .shadow(color: .black.opacity(0.2), radius: 12)
                        } else {
                            ZStack {
                                Circle()
                                    .frame(width: 120, height: 120)
                                    .foregroundStyle(.clear)
                                    .glassEffect(.regular, in: .circle)

                                VStack(spacing: 6) {
                                    Image(systemName: "camera.fill")
                                        .font(.title2)
                                    Text("Add Photo")
                                        .font(.caption)
                                }
                                .foregroundStyle(.primary)
                            }
                        }
                    }
                    .onChange(of: viewModel.selectedPhoto) {
                        Task { await viewModel.loadImage() }
                    }

                    // Username field
                    HStack(spacing: 12) {
                        Image(systemName: "at")
                            .foregroundStyle(.secondary)
                            .frame(width: 20)
                        TextField("Username", text: $viewModel.username)
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.never)
                    }
                    .padding()
                    .glassEffect(.regular, in: .rect(cornerRadius: 14))

                    // Error
                    if let error = viewModel.errorMessage {
                        Label(error, systemImage: "exclamationmark.triangle.fill")
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                }
                .padding(28)
                .glassEffect(.regular.interactive, in: .rect(cornerRadius: 28))
                .padding(.horizontal, 20)

                Spacer()

                // Complete Button
                Button {
                    Task {
                        guard let userId = try? await supabase.auth.session.user.id else { return }
                        let success = await viewModel.saveProfile(userId: userId)
                        if success {
                            authViewModel.completeOnboarding()
                        }
                    }
                } label: {
                    HStack(spacing: 8) {
                        if viewModel.isLoading {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Text("Complete Setup")
                                .fontWeight(.semibold)
                            Image(systemName: "arrow.right")
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                }
                .buttonStyle(.borderedProminent)
                .buttonBorderShape(.capsule)
                .tint(.blue)
                .disabled(viewModel.username.isEmpty || viewModel.isLoading)
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
        }
    }
}

#Preview {
    OnboardingView()
        .environment(AuthViewModel())
}
