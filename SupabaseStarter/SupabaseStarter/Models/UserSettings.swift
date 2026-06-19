import Foundation

struct UserSettings: Codable, Sendable {
    let userId: UUID
    var disciplineMode: Bool
    var disciplineTriggers: [String]
    var aiServerUrl: String?
    var timezone: String?
    var updatedAt: Date?

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case disciplineMode = "discipline_mode"
        case disciplineTriggers = "discipline_triggers"
        case aiServerUrl = "ai_server_url"
        case timezone
        case updatedAt = "updated_at"
    }
}

struct UserSettingsUpsert: Codable, Sendable {
    let userId: UUID
    let disciplineMode: Bool
    let disciplineTriggers: [String]
    let aiServerUrl: String?
    let timezone: String?

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case disciplineMode = "discipline_mode"
        case disciplineTriggers = "discipline_triggers"
        case aiServerUrl = "ai_server_url"
        case timezone
    }
}

struct UserSettingsUpdate: Codable, Sendable {
    var disciplineMode: Bool?
    var disciplineTriggers: [String]?
    var aiServerUrl: String?
    var timezone: String?

    enum CodingKeys: String, CodingKey {
        case disciplineMode = "discipline_mode"
        case disciplineTriggers = "discipline_triggers"
        case aiServerUrl = "ai_server_url"
        case timezone
    }
}
