import Foundation

struct Entry: Codable, Identifiable, Sendable, Hashable {
    let id: UUID
    let userId: UUID
    let personId: UUID?
    var rawText: String
    var occurredAt: Date
    let createdAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case personId = "person_id"
        case rawText = "raw_text"
        case occurredAt = "occurred_at"
        case createdAt = "created_at"
    }
}

struct EntryInsert: Codable, Sendable {
    let userId: UUID
    let personId: UUID?
    let rawText: String
    let occurredAt: Date

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case personId = "person_id"
        case rawText = "raw_text"
        case occurredAt = "occurred_at"
    }
}
