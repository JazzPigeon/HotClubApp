import Foundation

enum RecordSideCode: String, Codable, Sendable, CaseIterable {
    case A
    case B
}

struct NewRecordInsert: Encodable, Sendable {
    init() {}
}

struct RecordRow: Decodable, Sendable, Identifiable {
    let id: UUID
    let userId: UUID
    let createdAt: Date
    let updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

struct RecordSideRow: Decodable, Sendable, Identifiable {
    let id: UUID
    let recordId: UUID
    let side: RecordSideCode
    let songTitle: String?
    let artist: String?
    let personnel: String?
    let composer: String?
    let label: String?
    let year: Int?
    let keywords: String?
    let imageStoragePath: String?

    enum CodingKeys: String, CodingKey {
        case id
        case recordId = "record_id"
        case side
        case songTitle = "song_title"
        case artist
        case personnel
        case composer
        case label
        case year
        case keywords
        case imageStoragePath = "image_storage_path"
    }
}

struct CatalogRecordRow: Decodable, Sendable, Identifiable, Hashable {
    let id: UUID
    let createdAt: Date
    let updatedAt: Date
    let recordSides: [RecordSideRow]

    enum CodingKeys: String, CodingKey {
        case id
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case recordSides = "record_sides"
    }

    func side(_ code: RecordSideCode) -> RecordSideRow? {
        recordSides.first { $0.side == code }
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: CatalogRecordRow, rhs: CatalogRecordRow) -> Bool {
        lhs.id == rhs.id
    }
}

struct RecordSideInsert: Encodable, Sendable {
    let recordId: UUID
    let side: RecordSideCode
    let songTitle: String?
    let artist: String?
    let personnel: String?
    let composer: String?
    let label: String?
    let year: Int?
    let keywords: String?
    let imageStoragePath: String?

    enum CodingKeys: String, CodingKey {
        case recordId = "record_id"
        case side
        case songTitle = "song_title"
        case artist
        case personnel
        case composer
        case label
        case year
        case keywords
        case imageStoragePath = "image_storage_path"
    }
}

struct RecordSideUpdate: Encodable, Sendable {
    let songTitle: String?
    let artist: String?
    let personnel: String?
    let composer: String?
    let label: String?
    let year: Int?
    let keywords: String?
    let imageStoragePath: String?

    enum CodingKeys: String, CodingKey {
        case songTitle = "song_title"
        case artist
        case personnel
        case composer
        case label
        case year
        case keywords
        case imageStoragePath = "image_storage_path"
    }
}
