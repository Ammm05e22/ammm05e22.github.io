import Foundation

struct AnalysisService {

    func latestForEntries(_ entryIds: [UUID]) async throws -> [UUID: EntryAnalysis] {
        guard !entryIds.isEmpty else { return [:] }
        let rows: [EntryAnalysis] = try await supabase
            .from("entry_analysis")
            .select()
            .in("entry_id", values: entryIds.map { $0.uuidString })
            .order("created_at", ascending: false)
            .execute()
            .value

        var byEntry: [UUID: EntryAnalysis] = [:]
        for row in rows where byEntry[row.entryId] == nil {
            byEntry[row.entryId] = row
        }
        return byEntry
    }

    func insert(_ analysis: EntryAnalysisInsert) async throws -> EntryAnalysis {
        try await supabase
            .from("entry_analysis")
            .insert(analysis)
            .select()
            .single()
            .execute()
            .value
    }
}
