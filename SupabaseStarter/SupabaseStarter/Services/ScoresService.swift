import Foundation

struct ScoresService {

    func get(personId: UUID) async throws -> ScoreRow? {
        let rows: [ScoreRow] = try await supabase
            .from("scores")
            .select()
            .eq("person_id", value: personId.uuidString)
            .limit(1)
            .execute()
            .value
        return rows.first
    }

    func getMany(personIds: [UUID]) async throws -> [UUID: ScoreRow] {
        guard !personIds.isEmpty else { return [:] }
        let rows: [ScoreRow] = try await supabase
            .from("scores")
            .select()
            .in("person_id", values: personIds.map { $0.uuidString })
            .execute()
            .value
        return Dictionary(uniqueKeysWithValues: rows.map { ($0.personId, $0) })
    }

    func upsert(_ row: ScoreRowUpsert) async throws -> ScoreRow {
        try await supabase
            .from("scores")
            .upsert(row, onConflict: "person_id")
            .select()
            .single()
            .execute()
            .value
    }

    func history(personId: UUID, limit: Int = 500) async throws -> [ScoreHistoryRow] {
        try await supabase
            .from("score_history")
            .select()
            .eq("person_id", value: personId.uuidString)
            .order("created_at", ascending: true)
            .limit(limit)
            .execute()
            .value
    }

    func historyForMany(personIds: [UUID], since: Date) async throws -> [UUID: [ScoreHistoryRow]] {
        guard !personIds.isEmpty else { return [:] }
        let isoFormatter = ISO8601DateFormatter()
        let rows: [ScoreHistoryRow] = try await supabase
            .from("score_history")
            .select()
            .in("person_id", values: personIds.map { $0.uuidString })
            .gte("created_at", value: isoFormatter.string(from: since))
            .order("created_at", ascending: true)
            .execute()
            .value
        return Dictionary(grouping: rows, by: \.personId)
    }

    func appendHistory(_ row: ScoreHistoryInsert) async throws {
        try await supabase
            .from("score_history")
            .insert(row)
            .execute()
    }
}
