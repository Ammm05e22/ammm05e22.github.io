import Foundation

struct AxisDeltas: Codable, Sendable, Hashable {
    var emotionalSafety: Double
    var consistency: Double
    var reciprocity: Double
    var growthAlignment: Double
    var integrity: Double
    var attraction: Double

    static let zero = AxisDeltas(
        emotionalSafety: 0, consistency: 0, reciprocity: 0,
        growthAlignment: 0, integrity: 0, attraction: 0
    )
}

struct AnalysisPayload: Codable, Sendable, Hashable {
    var headline: String?
    var facts: [String]
    var emotions: [String]
    var assumptions: [String]
    var redFlags: [String]
    var greenFlags: [String]
    var recommendation: String?
    var patternsDetected: [String]
    var deltas: AxisDeltas
    var deltaRationale: String?

    enum CodingKeys: String, CodingKey {
        case headline
        case facts
        case emotions
        case assumptions
        case redFlags = "red_flags"
        case greenFlags = "green_flags"
        case recommendation
        case patternsDetected = "patterns_detected"
        case deltas
        case deltaRationale = "delta_rationale"
    }

    static let empty = AnalysisPayload(
        headline: nil,
        facts: [], emotions: [], assumptions: [],
        redFlags: [], greenFlags: [],
        recommendation: nil,
        patternsDetected: [],
        deltas: .zero,
        deltaRationale: nil
    )
}

struct EntryAnalysis: Codable, Identifiable, Sendable {
    let id: UUID
    let entryId: UUID
    let userId: UUID
    var model: String?
    var payload: AnalysisPayload
    let createdAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case entryId = "entry_id"
        case userId = "user_id"
        case model
        case payload
        case createdAt = "created_at"
    }
}

struct EntryAnalysisInsert: Codable, Sendable {
    let entryId: UUID
    let userId: UUID
    let model: String?
    let payload: AnalysisPayload

    enum CodingKeys: String, CodingKey {
        case entryId = "entry_id"
        case userId = "user_id"
        case model
        case payload
    }
}
