import Foundation

struct EntriesService {

    func listForPerson(_ personId: UUID, limit: Int = 30) async throws -> [Entry] {
        try await supabase
            .from("entries")
            .select()
            .eq("person_id", value: personId.uuidString)
            .order("occurred_at", ascending: false)
            .limit(limit)
            .execute()
            .value
    }

    func create(_ insert: EntryInsert) async throws -> Entry {
        try await supabase
            .from("entries")
            .insert(insert)
            .select()
            .single()
            .execute()
            .value
    }
}
