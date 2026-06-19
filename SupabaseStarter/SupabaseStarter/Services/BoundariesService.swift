import Foundation

struct BoundariesService {

    func list(userId: UUID) async throws -> [Boundary] {
        try await supabase
            .from("boundaries")
            .select()
            .eq("user_id", value: userId.uuidString)
            .order("sort_order", ascending: true)
            .execute()
            .value
    }

    func create(_ insert: BoundaryInsert) async throws -> Boundary {
        try await supabase
            .from("boundaries")
            .insert(insert)
            .select()
            .single()
            .execute()
            .value
    }

    func update(_ id: UUID, with updates: BoundaryUpdate) async throws -> Boundary {
        try await supabase
            .from("boundaries")
            .update(updates)
            .eq("id", value: id.uuidString)
            .select()
            .single()
            .execute()
            .value
    }

    func delete(_ id: UUID) async throws {
        try await supabase
            .from("boundaries")
            .delete()
            .eq("id", value: id.uuidString)
            .execute()
    }
}
