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
                        .overlay(Circle().stroke(.blue, lineWidth: 3))
                } else {
                    ZStack {
                        Circle()
                            .fill(.blue.opacity(0.1))
                            .frame(width: 120, height: 120)

                        VStack(spacing: 4) {
                            Image(systemName: "camera.fill")
                                .font(.title2)
                            Text("Add Photo")
                                .font(.caption)
                        }
                        .foregroundStyle(.blue)
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
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .multilineTextAlignment(.center)
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
                Group {
                    if viewModel.isLoading {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Text("Complete Setup")
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(viewModel.username.isEmpty ? .gray : .blue)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .disabled(viewModel.username.isEmpty || viewModel.isLoading)
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
        }
    }
}

#Preview {
    OnboardingView()
        .environment(AuthViewModel())
}
