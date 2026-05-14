import Foundation
import Observation
import Supabase

@Observable @MainActor
final class AppModel {
    private(set) var client: SupabaseClient?
    private(set) var session: Session?
    private(set) var secretsError: String?
    private(set) var isBootstrapping = true

    init() {
        Task { await bootstrap() }
    }

    func bootstrap() async {
        isBootstrapping = true
        defer { isBootstrapping = false }

        do {
            let secrets = try AppSecrets.load()
            secretsError = nil
            let client = SupabaseClient(supabaseURL: secrets.url, supabaseKey: secrets.anonKey)
            self.client = client
            session = try? await client.auth.session
            observeAuth(client: client)
        } catch let error as LocalizedError {
            secretsError = error.errorDescription ?? String(describing: error)
            client = nil
            session = nil
        } catch {
            secretsError = error.localizedDescription
            client = nil
            session = nil
        }
    }

    private func observeAuth(client: SupabaseClient) {
        Task {
            for await change in await client.auth.authStateChanges {
                await MainActor.run {
                    session = change.session
                }
            }
        }
    }

    func signIn(email: String, password: String) async throws {
        guard let client else { throw AppModelError.noClient }
        try await client.auth.signIn(email: email, password: password)
        session = try await client.auth.session
    }

    func signUp(email: String, password: String) async throws {
        guard let client else { throw AppModelError.noClient }
        try await client.auth.signUp(email: email, password: password)
        session = try? await client.auth.session
    }

    func signOut() async throws {
        guard let client else { throw AppModelError.noClient }
        try await client.auth.signOut()
        session = nil
    }
}

enum AppModelError: LocalizedError {
    case noClient

    var errorDescription: String? {
        switch self {
        case .noClient:
            return "Supabase is not configured."
        }
    }
}
