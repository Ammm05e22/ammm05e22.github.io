import Foundation

// AI server contract — mirrors web app/api/aiServer.js.
//
// POST /analyze-entry
//   Headers: Authorization: Bearer <supabase access_token>
//   Body: AnalyzeEntryRequest
//   Returns: AnalyzeEntryResponse
//
// POST /weekly-summary
//   Headers: Authorization: Bearer <supabase access_token>
//   Body: WeeklySummaryRequest
//   Returns: WeeklySummaryResponse
//
// The server verifies the JWT against the Supabase project JWKS, calls
// OpenAI with response_format=json_object, and shapes the response.

enum AIServerError: LocalizedError {
    case invalidURL
    case noSession
    case http(Int, String)
    case decode(String)

    var errorDescription: String? {
        switch self {
        case .invalidURL: "Invalid AI server URL."
        case .noSession: "No active Supabase session."
        case .http(let code, let msg): "AI server returned \(code): \(msg)"
        case .decode(let msg): "Failed to decode AI response: \(msg)"
        }
    }
}

struct AnalyzeEntryRequest: Codable, Sendable {
    struct PersonRef: Codable, Sendable {
        let id: UUID
        let displayName: String
        let relationshipType: String?
        let currentScores: AxisVector

        enum CodingKeys: String, CodingKey {
            case id
            case displayName = "display_name"
            case relationshipType = "relationship_type"
            case currentScores = "current_scores"
        }
    }

    struct RecentEntry: Codable, Sendable {
        let occurredAt: Date
        let rawText: String

        enum CodingKeys: String, CodingKey {
            case occurredAt = "occurred_at"
            case rawText = "raw_text"
        }
    }

    let entryId: UUID
    let person: PersonRef
    let rawText: String
    let occurredAt: Date
    let recentEntries: [RecentEntry]
    let boundaries: [String]

    enum CodingKeys: String, CodingKey {
        case entryId = "entry_id"
        case person
        case rawText = "raw_text"
        case occurredAt = "occurred_at"
        case recentEntries = "recent_entries"
        case boundaries
    }
}

struct AnalyzeEntryResponse: Codable, Sendable {
    let model: String?
    let analysis: AnalysisPayload
}

struct WeeklySummaryRequest: Codable, Sendable {
    struct EntryWithAnalysis: Codable, Sendable {
        let occurredAt: Date
        let rawText: String
        let analysis: AnalysisPayload?

        enum CodingKeys: String, CodingKey {
            case occurredAt = "occurred_at"
            case rawText = "raw_text"
            case analysis
        }
    }

    struct HistoryPoint: Codable, Sendable {
        let createdAt: Date
        let composite: Double
        let axes: AxisVector

        enum CodingKeys: String, CodingKey {
            case createdAt = "created_at"
            case composite
            case axes
        }
    }

    struct PersonRef: Codable, Sendable {
        let displayName: String
        let relationshipType: String?

        enum CodingKeys: String, CodingKey {
            case displayName = "display_name"
            case relationshipType = "relationship_type"
        }
    }

    let personId: UUID
    let isoWeek: String
    let person: PersonRef
    let entries: [EntryWithAnalysis]
    let scoreHistory: [HistoryPoint]

    enum CodingKeys: String, CodingKey {
        case personId = "person_id"
        case isoWeek = "iso_week"
        case person
        case entries
        case scoreHistory = "score_history"
    }
}

struct WeeklySummaryResponse: Codable, Sendable {
    let model: String?
    let summary: WeeklySummaryPayload
}

struct AIServerService {

    var overrideBaseURL: URL?

    private var baseURL: URL { overrideBaseURL ?? AIServerConfig.baseURL }

    private var jsonEncoder: JSONEncoder {
        let e = JSONEncoder()
        e.dateEncodingStrategy = .iso8601
        return e
    }

    private var jsonDecoder: JSONDecoder {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .iso8601
        return d
    }

    private func authToken() async throws -> String {
        do {
            return try await supabase.auth.session.accessToken
        } catch {
            throw AIServerError.noSession
        }
    }

    func analyzeEntry(_ req: AnalyzeEntryRequest) async throws -> AnalyzeEntryResponse {
        try await post(path: "/analyze-entry", body: req, as: AnalyzeEntryResponse.self)
    }

    func weeklySummary(_ req: WeeklySummaryRequest) async throws -> WeeklySummaryResponse {
        try await post(path: "/weekly-summary", body: req, as: WeeklySummaryResponse.self)
    }

    private func post<Body: Encodable, Out: Decodable>(path: String, body: Body, as: Out.Type) async throws -> Out {
        let token = try await authToken()
        guard let url = URL(string: path, relativeTo: baseURL) else {
            throw AIServerError.invalidURL
        }
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        req.httpBody = try jsonEncoder.encode(body)

        let (data, response) = try await URLSession.shared.data(for: req)
        guard let http = response as? HTTPURLResponse else {
            throw AIServerError.http(0, "No HTTP response")
        }
        guard (200..<300).contains(http.statusCode) else {
            let msg = String(data: data, encoding: .utf8) ?? "Server error"
            throw AIServerError.http(http.statusCode, msg)
        }
        do {
            return try jsonDecoder.decode(Out.self, from: data)
        } catch {
            throw AIServerError.decode(error.localizedDescription)
        }
    }
}
