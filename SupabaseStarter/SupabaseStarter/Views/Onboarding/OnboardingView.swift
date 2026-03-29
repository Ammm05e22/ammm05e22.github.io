import SwiftUI
import PhotosUI

struct OnboardingView: View {
    @Environment(AuthViewModel.self) private var authViewModel
    @State private var viewModel = OnboardingViewModel()

    var body: some View {
        VStack(spacing: 32) {
            // Header
            VStack(spacing: 8) {
                Text("Complete Your Profile")
                    .font(.title)
                    .fontWeight(.bold)

                Text("Choose a username and avatar")
                    .foregroundStyle(.secondary)
            }
            .padding(.top, 40)

            // Avatar Picker
            PhotosPicker(selection: $viewModel.selectedPhoto, matching: .images) {
                if let avatarImage = viewModel.avatarImage {
                    avatarImage
                        .resizable()
                        .scaledToFill()
                        .frame(width: 120, height: 120)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(.tint, lineWidth: 3))
                } else {
                    ZStack {
                        Circle()
                            .fill(.fill.tertiary)
                            .frame(width: 120, height: 120)

                        VStack(spacing: 4) {
                            Image(systemName: "camera.fill")
                                .font(.title2)
                            Text("Add Photo")
                                .font(.caption)
                        }
                        .foregroundStyle(.tint)
                    }
                }
            }
            .onChange(of: viewModel.selectedPhoto) {
                Task { await viewModel.loadImage() }
            }

            // Username
            TextField("Username", text: $viewModel.username)
                .textFieldStyle(.roundedBorder)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
                .padding(.horizontal, 24)

            // Error
            if let error = viewModel.errorMessage {
                Label(error, systemImage: "exclamationmark.triangle.fill")
                    .font(.caption)
                    .foregroundStyle(.red)
                    .padding(.horizontal, 24)
            }

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
            .disabled(viewModel.username.isEmpty || viewModel.isLoading)
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
        }
        .background(Color(.systemGroupedBackground))
    }
}

#Preview {
    OnboardingView()
        .environment(AuthViewModel())
}
