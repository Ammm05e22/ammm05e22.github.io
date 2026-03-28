import Foundation
import SwiftUI
import PhotosUI

@Observable
@MainActor
final class OnboardingViewModel {
    var username = ""
    var selectedPhoto: PhotosPickerItem?
    var avatarImage: Image?
    var isLoading = false
    var errorMessage: String?

    private var avatarData: Data?
    private let profileService = ProfileService()

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

    func saveProfile(userId: UUID) async -> Bool {
        guard !username.trimmingCharacters(in: .whitespaces).isEmpty else {
            errorMessage = "Username is required."
            return false
        }

        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            var avatarUrl: String?

            if let avatarData {
                avatarUrl = try await profileService.uploadAvatar(userId: userId, imageData: avatarData)
            }

            let profile = ProfileInsert(
                id: userId,
                username: username.trimmingCharacters(in: .whitespaces),
                avatarUrl: avatarUrl
            )
            try await profileService.createProfile(profile)
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }
}
