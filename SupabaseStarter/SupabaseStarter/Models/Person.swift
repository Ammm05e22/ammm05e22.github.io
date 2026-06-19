import Foundation

struct Person: Codable, Identifiable, Sendable, Hashable {
    let id: UUID
    let userId: UUID
    var displayName: String
    var relationshipType: String?
    var avatarUrl: String?
    var notes: String?
    var archived: Bool
    var userStance: String?
    var userStanceUpdatedAt: Date?
    let createdAt: Date?
    let updatedAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case displayName = "display_name"
        case relationshipType = "relationship_type"
        case avatarUrl = "avatar_url"
        case notes
        case archived
        case userStance = "user_stance"
        case userStanceUpdatedAt = "user_stance_updated_at"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

struct PersonInsert: Codable, Sendable {
    let userId: UUID
    let displayName: String
    let relationshipType: String?

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case displayName = "display_name"
        case relationshipType = "relationship_type"
    }
}

struct PersonUpdate: Codable, Sendable {
    var displayName: String?
    var relationshipType: String?
    var notes: String?
    var archived: Bool?
    var userStance: String?
    var userStanceUpdatedAt: Date?

    enum CodingKeys: String, CodingKey {
        case displayName = "display_name"
        case relationshipType = "relationship_type"
        case notes
        case archived
        case userStance = "user_stance"
        case userStanceUpdatedAt = "user_stance_updated_at"
    }
}

enum Stance: String, CaseIterable, Sendable {
    case hold = "Hold"
    case buy = "Buy"
    case sell = "Sell"
}
