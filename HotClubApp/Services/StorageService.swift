import Foundation
import Supabase

struct StorageService: Sendable {
    static let bucketId = "record-images"

    let client: SupabaseClient

    func uploadJPEG(path: String, data: Data) async throws {
        try await client.storage
            .from(Self.bucketId)
            .upload(
                path,
                data: data,
                options: FileOptions(cacheControl: "3600", contentType: "image/jpeg", upsert: true)
            )
    }

    func signedURL(path: String, expiresIn: Int = 3600) async throws -> URL {
        try await client.storage
            .from(Self.bucketId)
            .createSignedURL(path: path, expiresIn: expiresIn)
    }
}
