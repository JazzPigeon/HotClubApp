import Auth
import PhotosUI
import Supabase
import SwiftUI

struct SideFormState {
    var songTitle = ""
    var artist = ""
    var composer = ""
    var label = ""
    var yearText = ""
    var photoItem: PhotosPickerItem?
}

@Observable @MainActor
final class CreateRecordViewModel {
    var sideA = SideFormState()
    var sideB = SideFormState()
    var submitError: String?
    var isSubmitting = false

    func reset() {
        sideA = SideFormState()
        sideB = SideFormState()
        submitError = nil
        isSubmitting = false
    }

    func submit(app: AppModel) async -> Bool {
        guard let client = app.client else {
            submitError = AppModelError.noClient.localizedDescription
            return false
        }
        guard app.session != nil else {
            submitError = "Not signed in."
            return false
        }

        submitError = nil
        isSubmitting = true
        defer { isSubmitting = false }

        do {
            let yearA = try parsedYear(sideA.yearText)
            let yearB = try parsedYear(sideB.yearText)

            let jpegA = try await jpeg(from: sideA.photoItem)
            let jpegB = try await jpeg(from: sideB.photoItem)

            let recordService = RecordService(client: client)
            let storage = StorageService(client: client)
            let userId = app.session!.user.id
            let recordId = try await recordService.insertRecord()

            var pathA: String?
            var pathB: String?

            do {
                if let jpegA {
                    pathA = "\(userId.uuidString.lowercased())/\(recordId.uuidString.lowercased())/A.jpg"
                    try await storage.uploadJPEG(path: pathA!, data: jpegA)
                }
                if let jpegB {
                    pathB = "\(userId.uuidString.lowercased())/\(recordId.uuidString.lowercased())/B.jpg"
                    try await storage.uploadJPEG(path: pathB!, data: jpegB)
                }

                let inserts = [
                    RecordSideInsert(
                        recordId: recordId,
                        side: .A,
                        songTitle: opt(sideA.songTitle),
                        artist: opt(sideA.artist),
                        composer: opt(sideA.composer),
                        label: opt(sideA.label),
                        year: yearA,
                        imageStoragePath: pathA
                    ),
                    RecordSideInsert(
                        recordId: recordId,
                        side: .B,
                        songTitle: opt(sideB.songTitle),
                        artist: opt(sideB.artist),
                        composer: opt(sideB.composer),
                        label: opt(sideB.label),
                        year: yearB,
                        imageStoragePath: pathB
                    ),
                ]
                try await recordService.insertSides(inserts)
                reset()
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

    private func opt(_ s: String) -> String? {
        let t = s.trimmingCharacters(in: .whitespacesAndNewlines)
        return t.isEmpty ? nil : t
    }

    private func parsedYear(_ text: String) throws -> Int? {
        let t = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if t.isEmpty { return nil }
        guard let y = Int(t), (1800 ... 2100).contains(y) else {
            throw CreateRecordValidationError.invalidYear
        }
        return y
    }

    private func jpeg(from item: PhotosPickerItem?) async throws -> Data? {
        guard let item else { return nil }
        guard let raw = try await item.loadTransferable(type: Data.self) else { return nil }
        return try ImageProcessor.jpegDataResized(raw)
    }
}

enum CreateRecordValidationError: LocalizedError {
    case invalidYear

    var errorDescription: String? {
        switch self {
        case .invalidYear:
            return "Year must be empty or a number between 1800 and 2100."
        }
    }
}
