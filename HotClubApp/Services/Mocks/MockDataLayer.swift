import Foundation

actor MockRecordRepository: RecordRepository {
    private var records: [CatalogRecordRow]

    init(records: [CatalogRecordRow] = MockRecordRepository.defaultSeed) {
        self.records = records
    }

    func fetchCatalogRecords() async throws -> [CatalogRecordRow] {
        records.sorted { $0.createdAt > $1.createdAt }
    }

    func fetchCatalogRecord(id: UUID) async throws -> CatalogRecordRow {
        guard let row = records.first(where: { $0.id == id }) else {
            throw RecordServiceError.recordNotFound
        }
        return row
    }

    func insertRecord() async throws -> UUID {
        let id = UUID()
        let now = Date()
        records.append(
            CatalogRecordRow(id: id, createdAt: now, updatedAt: now, recordSides: [])
        )
        return id
    }

    func insertSides(_ sides: [RecordSideInsert]) async throws {
        for insert in sides {
            guard let index = records.firstIndex(where: { $0.id == insert.recordId }) else {
                continue
            }
            let existing = records[index]
            let newSide = RecordSideRow(
                id: UUID(),
                recordId: insert.recordId,
                side: insert.side,
                songTitle: insert.songTitle,
                artist: insert.artist,
                personnel: insert.personnel,
                composer: insert.composer,
                label: insert.label,
                year: insert.year,
                keywords: insert.keywords,
                imageStoragePath: insert.imageStoragePath
            )
            records[index] = CatalogRecordRow(
                id: existing.id,
                createdAt: existing.createdAt,
                updatedAt: Date(),
                recordSides: existing.recordSides + [newSide]
            )
        }
    }

    func updateSide(id: UUID, update: RecordSideUpdate) async throws {
        for (recordIndex, record) in records.enumerated() {
            guard let sideIndex = record.recordSides.firstIndex(where: { $0.id == id }) else {
                continue
            }
            let existingSide = record.recordSides[sideIndex]
            let updatedSide = RecordSideRow(
                id: existingSide.id,
                recordId: existingSide.recordId,
                side: existingSide.side,
                songTitle: update.songTitle,
                artist: update.artist,
                personnel: update.personnel,
                composer: update.composer,
                label: update.label,
                year: update.year,
                keywords: update.keywords,
                imageStoragePath: update.imageStoragePath
            )
            var newSides = record.recordSides
            newSides[sideIndex] = updatedSide
            records[recordIndex] = CatalogRecordRow(
                id: record.id,
                createdAt: record.createdAt,
                updatedAt: Date(),
                recordSides: newSides
            )
            return
        }
    }

    func deleteRecord(id: UUID) async throws {
        records.removeAll { $0.id == id }
    }
}

extension MockRecordRepository {
    static var defaultSeed: [CatalogRecordRow] {
        [
            CatalogRecordRow(
                id: UUID(uuidString: "11111111-1111-1111-1111-111111111111")!,
                createdAt: Date(timeIntervalSince1970: 1_700_000_000),
                updatedAt: Date(timeIntervalSince1970: 1_700_000_000),
                recordSides: [
                    RecordSideRow(
                        id: UUID(uuidString: "1A1A1A1A-1111-1111-1111-111111111111")!,
                        recordId: UUID(uuidString: "11111111-1111-1111-1111-111111111111")!,
                        side: .A,
                        songTitle: "In the Mood",
                        artist: "Glenn Miller",
                        personnel: "Glenn Miller and His Orchestra",
                        composer: "Joe Garland",
                        label: "Bluebird",
                        year: 1939,
                        keywords: "Dance",
                        imageStoragePath: nil
                    ),
                    RecordSideRow(
                        id: UUID(uuidString: "1B1B1B1B-1111-1111-1111-111111111111")!,
                        recordId: UUID(uuidString: "11111111-1111-1111-1111-111111111111")!,
                        side: .B,
                        songTitle: "I Want to Be Happy",
                        artist: "Glenn Miller",
                        personnel: "Glenn Miller and His Orchestra",
                        composer: "Vincent Youmans",
                        label: "Bluebird",
                        year: 1939,
                        keywords: "",
                        imageStoragePath: nil
                    ),
                ]
            ),
            CatalogRecordRow(
                id: UUID(uuidString: "22222222-2222-2222-2222-222222222222")!,
                createdAt: Date(timeIntervalSince1970: 1_700_100_000),
                updatedAt: Date(timeIntervalSince1970: 1_700_100_000),
                recordSides: [
                    RecordSideRow(
                        id: UUID(uuidString: "2A2A2A2A-2222-2222-2222-222222222222")!,
                        recordId: UUID(uuidString: "22222222-2222-2222-2222-222222222222")!,
                        side: .A,
                        songTitle: "Take the A Train",
                        artist: "Duke Ellington",
                        personnel: "Duke Ellington and His Orchestra",
                        composer: "Billy Strayhorn",
                        label: "Victor",
                        year: 1941,
                        keywords: "Cotton Club",
                        imageStoragePath: nil
                    ),
                    RecordSideRow(
                        id: UUID(uuidString: "2B2B2B2B-2222-2222-2222-222222222222")!,
                        recordId: UUID(uuidString: "22222222-2222-2222-2222-222222222222")!,
                        side: .B,
                        songTitle: "Sidewalks of New York",
                        artist: "Duke Ellington",
                        personnel: "Duke Ellington and His Orchestra",
                        composer: "Charles B. Lawlor",
                        label: "Victor",
                        year: 1941,
                        keywords: "Cotton Club",
                        imageStoragePath: nil
                    ),
                ]
            ),
        ]
    }
}

struct MockImageStore: ImageStore {
    func uploadJPEG(path: String, data: Data) async throws {}

    func signedURL(path: String, expiresIn: Int) async throws -> URL {
        URL(string: "https://example.invalid/mock-image.jpg")!
    }

    func delete(paths: [String]) async throws {}
}
