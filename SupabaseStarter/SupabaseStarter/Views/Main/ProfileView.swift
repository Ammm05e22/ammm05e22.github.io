import SwiftUI
import PhotosUI

struct ProfileView: View {
    @State private var viewModel = ProfileViewModel()

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                if viewModel.isLoading {
                    ProgressView()
                        .padding(.top, 60)
                } else {
                    // Avatar
                    PhotosPicker(selection: $viewModel.selectedPhoto, matching: .images) {
                        if let avatarImage = viewModel.avatarImage {
                            avatarImage
                                .resizable()
                                .scaledToFill()
                                .frame(width: 120, height: 120)
                                .clipShape(Circle())
                                .overlay(Circle().stroke(.blue, lineWidth: 3))
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
                            .overlay(Circle().stroke(.blue, lineWidth: 3))
                        } else {
                            Image(systemName: "person.circle.fill")
                                .font(.system(size: 100))
                                .foregroundStyle(.blue.opacity(0.5))
                        }
                    }
                    .onChange(of: viewModel.selectedPhoto) {
                        Task { await viewModel.loadImage() }
                    }
                    .padding(.top, 20)

                    // Username
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Username")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)

                        TextField("Username", text: $viewModel.username)
                            .textFieldStyle(.roundedBorder)
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.never)
                    }
                    .padding(.horizontal, 24)

                    // Error
                    if let error = viewModel.errorMessage {
                        Text(error)
                            .font(.caption)
                            .foregroundStyle(.red)
                            .padding(.horizontal, 24)
                    }

                    // Save Button
                    Button {
                        Task {
                            guard let userId = try? await supabase.auth.session.user.id else { return }
                            await viewModel.updateProfile(userId: userId)
                        }
                    } label: {
                        Group {
                            if viewModel.isSaving {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                Text("Save Changes")
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(.blue)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .disabled(viewModel.isSaving)
                    .padding(.horizontal, 24)
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
