import SwiftUI
import PhotosUI

struct ProfileView: View {
    @State private var viewModel = ProfileViewModel()

    var body: some View {
        Form {
            // Avatar section
            Section {
                HStack {
                    Spacer()
                    PhotosPicker(selection: $viewModel.selectedPhoto, matching: .images) {
                        if let avatarImage = viewModel.avatarImage {
                            avatarImage
                                .resizable()
                                .scaledToFill()
                                .frame(width: 100, height: 100)
                                .clipShape(Circle())
                                .overlay(Circle().stroke(.tint, lineWidth: 2))
                        } else if let avatarUrl = viewModel.profile?.avatarUrl,
                                  let url = URL(string: avatarUrl) {
                            AsyncImage(url: url) { image in
                                image
                                    .resizable()
                                    .scaledToFill()
                            } placeholder: {
                                ProgressView()
                            }
                            .frame(width: 100, height: 100)
                            .clipShape(Circle())
                            .overlay(Circle().stroke(.tint, lineWidth: 2))
                        } else {
                            Image(systemName: "person.circle.fill")
                                .font(.system(size: 80))
                                .foregroundStyle(.secondary)
                        }
                    }
                    Spacer()
                }
                .listRowBackground(Color.clear)
            }
            .onChange(of: viewModel.selectedPhoto) {
                Task { await viewModel.loadImage() }
            }

            // Username section
            Section("Username") {
                TextField("Username", text: $viewModel.username)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
            }

            // Error
            if let error = viewModel.errorMessage {
                Section {
                    Label(error, systemImage: "exclamationmark.triangle.fill")
                        .foregroundStyle(.red)
                        .font(.caption)
                }
            }

            // Save
            Section {
                Button {
                    Task {
                        guard let userId = try? await supabase.auth.session.user.id else { return }
                        await viewModel.updateProfile(userId: userId)
                    }
                } label: {
                    HStack {
                        Spacer()
                        if viewModel.isSaving {
                            ProgressView()
                        } else {
                            Text("Save Changes")
                                .fontWeight(.semibold)
                        }
                        Spacer()
                    }
                }
                .disabled(viewModel.isSaving || viewModel.username.isEmpty)
            }
        }
        .navigationTitle("Profile")
        .overlay {
            if viewModel.isLoading {
                LoadingView(message: "Loading profile...")
            }
        }
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
