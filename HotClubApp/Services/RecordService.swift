import Foundation
import Supabase

struct RecordService: Sendable {
    let client: SupabaseClient

    func fetchCatalogRecords() async throws -> [CatalogRecordRow] {
        try await client
            .from("records")
            .select("id, created_at, updated_at, record_sides(id, record_id, side, song_title, artist, composer, label, year, image_storage_path)")
            .order("created_at", ascending: false)
            .execute()
            .value
    }

    func insertRecord() async throws -> UUID {
        let rows: [RecordRow] = try await client
            .from("records")
            .insert(NewRecordInsert())
            .select("id, user_id, created_at, updated_at")
            .execute()
            .value
        guard let id = rows.first?.id else {
            throw RecordServiceError.missingInsertedId
        }
        return id
    }

    func insertSides(_ sides: [RecordSideInsert]) async throws {
        try await client
            .from("record_sides")
            .insert(sides)
            .execute()
    }

    func deleteRecord(id: UUID) async throws {
        try await client
            .from("records")
            .delete()
            .eq("id", value: id.uuidString)
            .execute()
    }
}

enum RecordServiceError: Error {
    case missingInsertedId
}
