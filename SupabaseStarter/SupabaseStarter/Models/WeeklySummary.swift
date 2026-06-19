import Foundation

struct WeeklySummaryPayload: Codable, Sendable, Hashable {
    var headline: String
    var themes: [String]
    var evidenceEntryIds: [UUID]
    var suggestedStatus: String?
    var nextCheckIn: String?

    enum CodingKeys: String, CodingKey {
        case headline
        case themes
        case evidenceEntryIds = "evidence_entry_ids"
        case suggestedStatus = "suggested_status"
        case nextCheckIn = "next_check_in"
    }
}

struct WeeklySummary: Codable, Identifiable, Sendable {
    let id: UUID
    let userId: UUID
    let personId: UUID?
    let isoWeek: String
    var payload: WeeklySummaryPayload
    let createdAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case personId = "person_id"
        case isoWeek = "iso_week"
        case payload
        case createdAt = "created_at"
    }
}

struct WeeklySummaryUpsert: Codable, Sendable {
    let userId: UUID
    let personId: UUID?
    let isoWeek: String
    let payload: WeeklySummaryPayload

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case personId = "person_id"
        case isoWeek = "iso_week"
        case payload
    }
}
