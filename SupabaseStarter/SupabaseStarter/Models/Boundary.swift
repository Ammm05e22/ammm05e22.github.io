import Foundation

struct Boundary: Codable, Identifiable, Sendable, Hashable {
    let id: UUID
    let userId: UUID
    var text: String
    var sortOrder: Int
    let createdAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case text
        case sortOrder = "sort_order"
        case createdAt = "created_at"
    }
}

struct BoundaryInsert: Codable, Sendable {
    let userId: UUID
    let text: String
    let sortOrder: Int

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case text
        case sortOrder = "sort_order"
    }
}

struct BoundaryUpdate: Codable, Sendable {
    var text: String?
    var sortOrder: Int?

    enum CodingKeys: String, CodingKey {
        case text
        case sortOrder = "sort_order"
    }
}
