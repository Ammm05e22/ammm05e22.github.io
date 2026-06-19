import Foundation

struct AxisVector: Codable, Sendable, Hashable {
    var emotionalSafety: Double
    var consistency: Double
    var reciprocity: Double
    var growthAlignment: Double
    var integrity: Double
    var attraction: Double

    static let neutral = AxisVector(
        emotionalSafety: 50, consistency: 50, reciprocity: 50,
        growthAlignment: 50, integrity: 50, attraction: 50
    )

    enum CodingKeys: String, CodingKey {
        case emotionalSafety = "emotionalSafety"
        case consistency
        case reciprocity
        case growthAlignment = "growthAlignment"
        case integrity
        case attraction
    }
}

enum PortfolioStatus: String, Codable, Sendable, CaseIterable {
    case buy = "Buy"
    case hold = "Hold"
    case reduce = "Reduce"
    case freeze = "Freeze"
    case exit = "Exit"
    case watchlist = "Watchlist"
}

struct ScoreRow: Codable, Identifiable, Sendable {
    let personId: UUID
    let userId: UUID
    var emotionalSafety: Double
    var consistency: Double
    var reciprocity: Double
    var growthAlignment: Double
    var integrity: Double
    var attraction: Double
    var composite: Double
    var status: String
    var lastUpdated: Date?

    var id: UUID { personId }

    var axes: AxisVector {
        AxisVector(
            emotionalSafety: emotionalSafety,
            consistency: consistency,
            reciprocity: reciprocity,
            growthAlignment: growthAlignment,
            integrity: integrity,
            attraction: attraction
        )
    }

    enum CodingKeys: String, CodingKey {
        case personId = "person_id"
        case userId = "user_id"
        case emotionalSafety = "emotional_safety"
        case consistency
        case reciprocity
        case growthAlignment = "growth_alignment"
        case integrity
        case attraction
        case composite
        case status
        case lastUpdated = "last_updated"
    }
}

struct ScoreRowUpsert: Codable, Sendable {
    let personId: UUID
    let userId: UUID
    let emotionalSafety: Double
    let consistency: Double
    let reciprocity: Double
    let growthAlignment: Double
    let integrity: Double
    let attraction: Double
    let composite: Double
    let status: String
    let lastUpdated: Date

    enum CodingKeys: String, CodingKey {
        case personId = "person_id"
        case userId = "user_id"
        case emotionalSafety = "emotional_safety"
        case consistency
        case reciprocity
        case growthAlignment = "growth_alignment"
        case integrity
        case attraction
        case composite
        case status
        case lastUpdated = "last_updated"
    }
}

struct ScoreHistoryRow: Codable, Identifiable, Sendable, Hashable {
    let id: UUID
    let personId: UUID
    let userId: UUID
    let composite: Double
    let axes: AxisVector
    let entryId: UUID?
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case personId = "person_id"
        case userId = "user_id"
        case composite
        case axes
        case entryId = "entry_id"
        case createdAt = "created_at"
    }
}

struct ScoreHistoryInsert: Codable, Sendable {
    let personId: UUID
    let userId: UUID
    let composite: Double
    let axes: AxisVector
    let entryId: UUID?

    enum CodingKeys: String, CodingKey {
        case personId = "person_id"
        case userId = "user_id"
        case composite
        case axes
        case entryId = "entry_id"
    }
}
