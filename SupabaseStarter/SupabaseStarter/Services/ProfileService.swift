import Foundation

struct ProfileService {

    func fetchProfile(userId: UUID) async throws -> Profile? {
        try await supabase
            .from("profiles")
            .select()
            .eq("id", value: userId.uuidString)
            .single()
            .execute()
            .value
    }

    func createProfile(_ profile: ProfileInsert) async throws {
        try await supabase
            .from("profiles")
            .insert(profile)
            .execute()
    }

    func updateProfile(userId: UUID, updates: ProfileUpdate) async throws -> Profile {
        try await supabase
            .from("profiles")
            .update(updates)
            .eq("id", value: userId.uuidString)
            .single()
            .execute()
            .value
    }

    func uploadAvatar(userId: UUID, imageData: Data) async throws -> String {
        let filePath = "\(userId.uuidString)/avatar.jpg"

        try await supabase.storage
            .from("avatars")
            .upload(
                filePath,
                data: imageData,
                options: .init(contentType: "image/jpeg", upsert: true)
            )

        let publicURL = try supabase.storage
            .from("avatars")
            .getPublicURL(path: filePath)

        return publicURL.absoluteString
    }
}
