import Foundation
import Observation
import Supabase

@Observable @MainActor
final class AppModel {
    static let mockUserId = UUID(uuidString: "00000000-0000-0000-0000-0000000000FF")!

    private(set) var client: SupabaseClient?
    private(set) var session: Session?
    private(set) var secretsError: String?
    private(set) var isBootstrapping = true
    private(set) var isMockMode = false
    private(set) var recordRepository: RecordRepository?
    private(set) var imageStore: ImageStore?

    var isSignedIn: Bool { isMockMode || session != nil }

    var currentUserId: UUID? { isMockMode ? Self.mockUserId : session?.user.id }

    init() {
        Task { await bootstrap() }
    }

    func bootstrap() async {
        isBootstrapping = true

        if ProcessInfo.processInfo.environment["UITEST_MOCK"] == "1" {
            isMockMode = true
            secretsError = nil
            client = nil
            session = nil
            recordRepository = MockRecordRepository()
            imageStore = MockImageStore()
            isBootstrapping = false
            return
        }

        do {
            let secrets = try AppSecrets.load()
            secretsError = nil
            let client = SupabaseClient(
                supabaseURL: secrets.url,
                supabaseKey: secrets.anonKey,
                options: .init(auth: .init(emitLocalSessionAsInitialSession: true))
            )
            self.client = client
            recordRepository = RecordService(client: client)
            imageStore = StorageService(client: client)

            for await change in await client.auth.authStateChanges {
                applyAuthChange(event: change.event, session: change.session)
            }
        } catch let error as LocalizedError {
            isBootstrapping = false
            secretsError = error.errorDescription ?? String(describing: error)
            client = nil
            session = nil
            recordRepository = nil
            imageStore = nil
        } catch {
            isBootstrapping = false
            secretsError = error.localizedDescription
            client = nil
            session = nil
            recordRepository = nil
            imageStore = nil
        }
    }

    private func applyAuthChange(event: AuthChangeEvent, session: Session?) {
        switch event {
        case .initialSession:
            if let session, !session.isExpired {
                self.session = session
                isBootstrapping = false
            } else if session == nil {
                self.session = nil
                isBootstrapping = false
            }
        case .tokenRefreshed, .signedIn, .userUpdated:
            self.session = session
            isBootstrapping = false
        case .signedOut:
            self.session = nil
            isBootstrapping = false
        default:
            self.session = session
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
