import Foundation

protocol RecordRepository: Sendable {
    func fetchCatalogRecords() async throws -> [CatalogRecordRow]
    func fetchCatalogRecord(id: UUID) async throws -> CatalogRecordRow
    func insertRecord() async throws -> UUID
    func insertSides(_ sides: [RecordSideInsert]) async throws
    func updateSide(id: UUID, update: RecordSideUpdate) async throws
    func deleteRecord(id: UUID) async throws
}

protocol ImageStore: Sendable {
    func uploadJPEG(path: String, data: Data) async throws
    func signedURL(path: String, expiresIn: Int) async throws -> URL
    func delete(paths: [String]) async throws
}

extension ImageStore {
    func signedURL(path: String) async throws -> URL {
        try await signedURL(path: path, expiresIn: 3600)
    }
}
