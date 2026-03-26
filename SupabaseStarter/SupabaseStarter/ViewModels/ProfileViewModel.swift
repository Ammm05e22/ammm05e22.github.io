import Foundation
import SwiftUI
import PhotosUI

@Observable
@MainActor
final class ProfileViewModel {
    var profile: Profile?
    var username = ""
    var selectedPhoto: PhotosPickerItem?
    var avatarImage: Image?
    var isLoading = false
    var isSaving = false
    var errorMessage: String?

    private var avatarData: Data?
    private let profileService = ProfileService()

    func loadProfile(userId: UUID) async {
        isLoading = true
        defer { isLoading = false }

        do {
            if let profile = try await profileService.fetchProfile(userId: userId) {
                self.profile = profile
                self.username = profile.username
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func loadImage() async {
        guard let selectedPhoto else { return }
        do {
            if let data = try await selectedPhoto.loadTransferable(type: Data.self) {
                avatarData = data
                if let uiImage = UIImage(data: data) {
                    avatarImage = Image(uiImage: uiImage)
                }
            }
        } catch {
            errorMessage = "Failed to load image."
        }
    }

    func updateProfile(userId: UUID) async {
        guard !username.trimmingCharacters(in: .whitespaces).isEmpty else {
            errorMessage = "Username is required."
            return
        }

        isSaving = true
        errorMessage = nil
        defer { isSaving = false }

        do {
            var avatarUrl: String?

            if let avatarData {
                avatarUrl = try await profileService.uploadAvatar(userId: userId, imageData: avatarData)
            }

            var updates = ProfileUpdate(username: username.trimmingCharacters(in: .whitespaces))
            if let avatarUrl {
                updates.avatarUrl = avatarUrl
            }

            profile = try await profileService.updateProfile(userId: userId, updates: updates)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
