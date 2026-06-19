import Foundation

struct PeopleService {

    func listActive(userId: UUID) async throws -> [Person] {
        try await supabase
            .from("people")
            .select()
            .eq("user_id", value: userId.uuidString)
            .eq("archived", value: false)
            .order("created_at", ascending: false)
            .execute()
            .value
    }

    func get(_ id: UUID) async throws -> Person {
        try await supabase
            .from("people")
            .select()
            .eq("id", value: id.uuidString)
            .single()
            .execute()
            .value
    }

    func create(_ insert: PersonInsert) async throws -> Person {
        try await supabase
            .from("people")
            .insert(insert)
            .select()
            .single()
            .execute()
            .value
    }

    func update(_ id: UUID, with updates: PersonUpdate) async throws -> Person {
        try await supabase
            .from("people")
            .update(updates)
            .eq("id", value: id.uuidString)
            .select()
            .single()
            .execute()
            .value
    }

    func archive(_ id: UUID) async throws {
        try await supabase
            .from("people")
            .update(PersonUpdate(archived: true))
            .eq("id", value: id.uuidString)
            .execute()
    }
}

extension PersonUpdate {
    init(archived: Bool) {
        self.displayName = nil
        self.relationshipType = nil
        self.notes = nil
        self.archived = archived
        self.userStance = nil
        self.userStanceUpdatedAt = nil
    }
}
