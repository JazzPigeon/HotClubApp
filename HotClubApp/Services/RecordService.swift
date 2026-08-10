import Foundation
import Supabase

struct RecordService: RecordRepository {
    let client: SupabaseClient

    private static let catalogSelect =
        "id, created_at, updated_at, record_sides(id, record_id, side, song_title, artist, personnel, composer, label, year, keywords, notes, image_storage_path)"

    func fetchCatalogRecords() async throws -> [CatalogRecordRow] {
        try await client
            .from("records")
            .select(Self.catalogSelect)
            .order("created_at", ascending: false)
            .execute()
            .value
    }

    func fetchCatalogRecord(id: UUID) async throws -> CatalogRecordRow {
        let rows: [CatalogRecordRow] = try await client
            .from("records")
            .select(Self.catalogSelect)
            .eq("id", value: id.uuidString)
            .limit(1)
            .execute()
            .value
        guard let row = rows.first else {
            throw RecordServiceError.recordNotFound
        }
        return row
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

    func updateSide(id: UUID, update: RecordSideUpdate) async throws {
        try await client
            .from("record_sides")
            .update(update)
            .eq("id", value: id.uuidString)
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
    case recordNotFound
}
