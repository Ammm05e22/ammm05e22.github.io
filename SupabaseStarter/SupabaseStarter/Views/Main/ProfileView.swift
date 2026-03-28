import SwiftUI
import PhotosUI

struct ProfileView: View {
    @State private var viewModel = ProfileViewModel()

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
                    .indigo.opacity(0.3), .blue.opacity(0.2), .purple.opacity(0.3),
                    .blue.opacity(0.2), .indigo.opacity(0.15), .blue.opacity(0.2),
                    .purple.opacity(0.2), .indigo.opacity(0.2), .blue.opacity(0.25)
                ]
            )
            .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 28) {
                    if viewModel.isLoading {
                        LoadingView(message: "Loading profile...")
                            .padding(.top, 60)
                    } else {
                        // Avatar card
                        VStack(spacing: 20) {
                            PhotosPicker(selection: $viewModel.selectedPhoto, matching: .images) {
                                if let avatarImage = viewModel.avatarImage {
                                    avatarImage
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 120, height: 120)
                                        .clipShape(Circle())
                                        .overlay(Circle().stroke(.white.opacity(0.4), lineWidth: 3))
                                        .shadow(color: .black.opacity(0.15), radius: 10)
                                } else if let avatarUrl = viewModel.profile?.avatarUrl,
                                          let url = URL(string: avatarUrl) {
                                    AsyncImage(url: url) { image in
                                        image
                                            .resizable()
                                            .scaledToFill()
                                    } placeholder: {
                                        ProgressView()
                                    }
                                    .frame(width: 120, height: 120)
                                    .clipShape(Circle())
                                    .overlay(Circle().stroke(.white.opacity(0.4), lineWidth: 3))
                                } else {
                                    ZStack {
                                        Circle()
                                            .frame(width: 120, height: 120)
                                            .foregroundStyle(.clear)
                                            .glassEffect(.regular, in: .circle)

                                        Image(systemName: "person.circle.fill")
                                            .font(.system(size: 50))
                                            .foregroundStyle(.secondary)
                                    }
                                }
                            }
                            .onChange(of: viewModel.selectedPhoto) {
                                Task { await viewModel.loadImage() }
                            }

                            Text("Tap to change photo")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.top, 20)

                        // Profile form card
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Username")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundStyle(.secondary)

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
                        .padding(24)
                        .glassEffect(.regular.interactive, in: .rect(cornerRadius: 24))
                        .padding(.horizontal, 20)

                        // Save Button
                        Button {
                            Task {
                                guard let userId = try? await supabase.auth.session.user.id else { return }
                                await viewModel.updateProfile(userId: userId)
                            }
                        } label: {
                            HStack(spacing: 8) {
                                if viewModel.isSaving {
                                    ProgressView()
                                        .tint(.white)
                                } else {
                                    Image(systemName: "checkmark.circle.fill")
                                    Text("Save Changes")
                                        .fontWeight(.semibold)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                        }
                        .buttonStyle(.borderedProminent)
                        .buttonBorderShape(.capsule)
                        .tint(.blue)
                        .disabled(viewModel.isSaving)
                        .padding(.horizontal, 24)
                        .padding(.bottom, 32)
                    }
                }
            }
        }
        .navigationTitle("Profile")
        .task {
            guard let userId = try? await supabase.auth.session.user.id else { return }
            await viewModel.loadProfile(userId: userId)
        }
    }
}

#Preview {
    NavigationStack {
        ProfileView()
    }
}
