import Foundation

struct WeeklySummariesService {

    func latest(personId: UUID) async throws -> WeeklySummary? {
        let rows: [WeeklySummary] = try await supabase
            .from("weekly_summaries")
            .select()
            .eq("person_id", value: personId.uuidString)
            .order("created_at", ascending: false)
            .limit(1)
            .execute()
            .value
        return rows.first
    }

    func upsert(_ row: WeeklySummaryUpsert) async throws -> WeeklySummary {
        try await supabase
            .from("weekly_summaries")
            .upsert(row, onConflict: "person_id,iso_week")
            .select()
            .single()
            .execute()
            .value
    }
}
