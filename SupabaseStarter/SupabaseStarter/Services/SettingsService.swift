import Foundation

struct SettingsService {

    func get(userId: UUID) async throws -> UserSettings? {
        let rows: [UserSettings] = try await supabase
            .from("user_settings")
            .select()
            .eq("user_id", value: userId.uuidString)
            .limit(1)
            .execute()
            .value
        return rows.first
    }

    func ensure(userId: UUID) async throws -> UserSettings {
        if let existing = try await get(userId: userId) { return existing }
        let upsert = UserSettingsUpsert(
            userId: userId,
            disciplineMode: false,
            disciplineTriggers: [],
            aiServerUrl: nil,
            timezone: TimeZone.current.identifier
        )
        return try await supabase
            .from("user_settings")
            .upsert(upsert, onConflict: "user_id")
            .select()
            .single()
            .execute()
            .value
    }

    func update(userId: UUID, with updates: UserSettingsUpdate) async throws -> UserSettings {
        try await supabase
            .from("user_settings")
            .update(updates)
            .eq("user_id", value: userId.uuidString)
            .select()
            .single()
            .execute()
            .value
    }
}
