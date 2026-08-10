import SwiftUI

struct SideFormState {
    var songTitle = ""
    var artist = ""
    var personnel = ""
    var composer = ""
    var notes = ""
    var croppedPhotoJPEG: Data?
}

@Observable @MainActor
final class RecordFormViewModel {
    enum Mode {
        case create
        case edit(recordId: UUID, sideAId: UUID, sideBId: UUID)
    }

    var mode: Mode = .create
    var sideA = SideFormState()
    var sideB = SideFormState()
    var label = ""
    var yearText = ""
    var keywords = ""
    var matchSideAArtist = true
    var matchSideAPersonnel = true
    var matchSideAComposer = true
    var existingImagePathA: String?
    var existingImagePathB: String?
    var submitError: String?
    var isSubmitting = false

    var isEditing: Bool {
        if case .edit = mode { return true }
        return false
    }

    var canSubmit: Bool {
        !trimmed(sideA.songTitle).isEmpty && !trimmed(sideB.songTitle).isEmpty
    }

    var navigationTitle: String {
        isEditing ? "Edit record" : "New record"
    }

    var saveButtonTitle: String {
        isEditing ? "Save changes" : "Save record"
    }

    func resetForCreate() {
        mode = .create
        sideA = SideFormState()
        sideB = SideFormState()
        label = ""
        yearText = ""
        keywords = ""
        matchSideAArtist = true
        matchSideAPersonnel = true
        matchSideAComposer = true
        existingImagePathA = nil
        existingImagePathB = nil
        submitError = nil
        isSubmitting = false
    }

    func loadForEdit(_ record: CatalogRecordRow) {
        guard let rowA = record.side(.A), let rowB = record.side(.B) else { return }
        mode = .edit(recordId: record.id, sideAId: rowA.id, sideBId: rowB.id)
        sideA = sideFormState(from: rowA)
        sideB = sideFormState(from: rowB)
        label = rowA.label ?? rowB.label ?? ""
        yearText = rowA.year.map(String.init) ?? rowB.year.map(String.init) ?? ""
        keywords = firstNonEmpty(rowA.keywords, rowB.keywords)
        existingImagePathA = rowA.imageStoragePath
        existingImagePathB = rowB.imageStoragePath
        matchSideAArtist = trimmed(rowB.artist ?? "") == trimmed(rowA.artist ?? "")
        matchSideAPersonnel = trimmed(rowB.personnel ?? "") == trimmed(rowA.personnel ?? "")
        matchSideAComposer = trimmed(rowB.composer ?? "") == trimmed(rowA.composer ?? "")
        submitError = nil
        isSubmitting = false
        applyMatchSideAArtist()
        applyMatchSideAPersonnel()
        applyMatchSideAComposer()
    }

    func applyMatchSideAArtist() {
        if matchSideAArtist {
            sideB.artist = sideA.artist
        }
    }

    func applyMatchSideAPersonnel() {
        if matchSideAPersonnel {
            sideB.personnel = sideA.personnel
        }
    }
    
    func applyMatchSideAComposer() {
        if matchSideAComposer {
            sideB.composer = sideA.composer
        }
    }

    private var sideBArtistForSubmit: String {
        matchSideAArtist ? sideA.artist : sideB.artist
    }

    private var sideBComposerForSubmit: String {
        matchSideAComposer ? sideA.composer : sideB.composer
    }

    private var sideBPersonnelForSubmit: String {
        matchSideAPersonnel ? sideA.personnel : sideB.personnel
    }

    func submit(app: AppModel) async -> Bool {
        switch mode {
        case .create:
            return await submitCreate(app: app)
        case let .edit(recordId, sideAId, sideBId):
            return await submitUpdate(app: app, recordId: recordId, sideAId: sideAId, sideBId: sideBId)
        }
    }

    private func submitCreate(app: AppModel) async -> Bool {
        guard let recordService = app.recordRepository, let storage = app.imageStore else {
            submitError = AppModelError.noClient.localizedDescription
            return false
        }
        guard let userId = app.currentUserId else {
            submitError = "Not signed in."
            return false
        }

        submitError = nil
        isSubmitting = true
        defer { isSubmitting = false }

        do {
            try validateRequiredFields()
            let year = try parsedYear(yearText)

            let jpegA = sideA.croppedPhotoJPEG
            let jpegB = sideB.croppedPhotoJPEG

            let recordId = try await recordService.insertRecord()

            var pathA: String?
            var pathB: String?

            do {
                if let jpegA {
                    pathA = imagePath(userId: userId, recordId: recordId, side: .A)
                    try await storage.uploadJPEG(path: pathA!, data: jpegA)
                }
                if let jpegB {
                    pathB = imagePath(userId: userId, recordId: recordId, side: .B)
                    try await storage.uploadJPEG(path: pathB!, data: jpegB)
                }

                let sharedLabel = opt(label)
                let inserts = [
                    RecordSideInsert(
                        recordId: recordId,
                        side: .A,
                        songTitle: requiredTrimmed(sideA.songTitle),
                        artist: opt(sideA.artist),
                        personnel: opt(sideA.personnel),
                        composer: opt(sideA.composer),
                        label: sharedLabel,
                        year: year,
                        keywords: keywords,
                        notes: opt(sideA.notes),
                        imageStoragePath: pathA
                    ),
                    RecordSideInsert(
                        recordId: recordId,
                        side: .B,
                        songTitle: requiredTrimmed(sideB.songTitle),
                        artist: opt(sideBArtistForSubmit),
                        personnel: opt(sideBPersonnelForSubmit),
                        composer: opt(sideBComposerForSubmit),
                        label: sharedLabel,
                        year: year,
                        keywords: keywords,
                        notes: opt(sideB.notes),
                        imageStoragePath: pathB
                    ),
                ]
                try await recordService.insertSides(inserts)
                resetForCreate()
                return true
            } catch {
                try? await recordService.deleteRecord(id: recordId)
                throw error
            }
        } catch {
            submitError = error.localizedDescription
            return false
        }
    }

    private func submitUpdate(
        app: AppModel,
        recordId: UUID,
        sideAId: UUID,
        sideBId: UUID
    ) async -> Bool {
        guard let recordService = app.recordRepository, let storage = app.imageStore else {
            submitError = AppModelError.noClient.localizedDescription
            return false
        }
        guard let userId = app.currentUserId else {
            submitError = "Not signed in."
            return false
        }

        submitError = nil
        isSubmitting = true
        defer { isSubmitting = false }

        do {
            try validateRequiredFields()
            let year = try parsedYear(yearText)

            let jpegA = sideA.croppedPhotoJPEG
            let jpegB = sideB.croppedPhotoJPEG

            var pathA = existingImagePathA
            var pathB = existingImagePathB

            if let jpegA {
                pathA = imagePath(userId: userId, recordId: recordId, side: .A)
                try await storage.uploadJPEG(path: pathA!, data: jpegA)
            }
            if let jpegB {
                pathB = imagePath(userId: userId, recordId: recordId, side: .B)
                try await storage.uploadJPEG(path: pathB!, data: jpegB)
            }

            let sharedLabel = opt(label)
            let updateA = RecordSideUpdate(
                songTitle: requiredTrimmed(sideA.songTitle),
                artist: opt(sideA.artist),
                personnel: opt(sideA.personnel),
                composer: opt(sideA.composer),
                label: sharedLabel,
                year: year,
                keywords: keywords,
                notes: opt(sideA.notes),
                imageStoragePath: pathA
            )
            let updateB = RecordSideUpdate(
                songTitle: requiredTrimmed(sideB.songTitle),
                artist: opt(sideBArtistForSubmit),
                personnel: opt(sideBPersonnelForSubmit),
                composer: opt(sideBComposerForSubmit),
                label: sharedLabel,
                year: year,
                keywords: keywords,
                notes: opt(sideB.notes),
                imageStoragePath: pathB
            )

            try await recordService.updateSide(id: sideAId, update: updateA)
            try await recordService.updateSide(id: sideBId, update: updateB)
            return true
        } catch {
            submitError = error.localizedDescription
            return false
        }
    }

    private func sideFormState(from row: RecordSideRow) -> SideFormState {
        SideFormState(
            songTitle: row.songTitle ?? "",
            artist: row.artist ?? "",
            personnel: row.personnel ?? "",
            composer: row.composer ?? "",
            notes: row.notes ?? ""
        )
    }

    private func imagePath(userId: UUID, recordId: UUID, side: RecordSideCode) -> String {
        "\(userId.uuidString.lowercased())/\(recordId.uuidString.lowercased())/\(side.rawValue).jpg"
    }

    private func validateRequiredFields() throws {
        if trimmed(sideA.songTitle).isEmpty {
            throw RecordFormValidationError.missingSongTitle(side: .A)
        }
        if trimmed(sideB.songTitle).isEmpty {
            throw RecordFormValidationError.missingSongTitle(side: .B)
        }
    }

    private func trimmed(_ s: String) -> String {
        s.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func requiredTrimmed(_ s: String) -> String {
        trimmed(s)
    }

    private func opt(_ s: String) -> String? {
        let t = trimmed(s)
        return t.isEmpty ? nil : t
    }

    private func parsedYear(_ text: String) throws -> Int? {
        let t = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if t.isEmpty { return nil }
        guard let y = Int(t), (1800 ... 2100).contains(y) else {
            throw RecordFormValidationError.invalidYear
        }
        return y
    }
    
    private func firstNonEmpty(_ values: String?...) -> String {
        values
            .compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }
            .first { !$0.isEmpty } ?? ""
    }
}

enum RecordFormValidationError: LocalizedError {
    case missingSongTitle(side: RecordSideCode)
    case invalidYear

    var errorDescription: String? {
        switch self {
        case let .missingSongTitle(side):
            return "Song title is required for Side \(side.rawValue)."
        case .invalidYear:
            return "Year must be empty or a number between 1800 and 2100."
        }
    }
}

typealias CreateRecordValidationError = RecordFormValidationError
