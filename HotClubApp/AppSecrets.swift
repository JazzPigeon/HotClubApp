import Foundation

enum AppSecretsError: LocalizedError {
    case missingPlist
    case missingKeys
    case invalidProjectURL

    var errorDescription: String? {
        switch self {
        case .missingPlist:
            return "Copy Secrets.example.plist to Secrets.plist and add your Supabase URL and anon key."
        case .missingKeys:
            return "Secrets.plist must contain SUPABASE_URL and SUPABASE_ANON_KEY."
        case .invalidProjectURL:
            return """
            SUPABASE_URL must be the project root only, for example https://abcd1234.supabase.co
            (from Dashboard → Settings → API → Project URL). Do not include /rest/v1, /auth/v1, or a trailing path.
            """
        }
    }
}

struct AppSecrets: Sendable {
    let url: URL
    let anonKey: String

    static func load(bundle: Bundle = .main) throws -> AppSecrets {
        guard let url = bundle.url(forResource: "Secrets", withExtension: "plist") else {
            throw AppSecretsError.missingPlist
        }
        let data = try Data(contentsOf: url)
        let dict = try PropertyListSerialization.propertyList(from: data, options: [], format: nil) as? [String: Any]
        guard
            let urlString = dict?["SUPABASE_URL"] as? String,
            let anonRaw = dict?["SUPABASE_ANON_KEY"] as? String
        else {
            throw AppSecretsError.missingKeys
        }
        let anon = anonRaw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !anon.isEmpty else {
            throw AppSecretsError.missingKeys
        }
        let supabaseURL = try normalizedSupabaseProjectURL(from: urlString)
        return AppSecrets(url: supabaseURL, anonKey: anon)
    }

    /// Supabase Swift builds service URLs by appending `/auth/v1`, `/rest/v1`, etc. If the configured URL already
    /// contains a path (e.g. `.../rest/v1`), those requests point at the wrong host path and can fail with errors like
    /// "Invalid path specified in request URL".
    private static func normalizedSupabaseProjectURL(from raw: String) throws -> URL {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard var components = URLComponents(string: trimmed),
              let scheme = components.scheme?.lowercased(),
              scheme == "https" || scheme == "http",
              let host = components.host,
              !host.isEmpty
        else {
            throw AppSecretsError.invalidProjectURL
        }
        components.scheme = scheme
        components.path = ""
        components.query = nil
        components.fragment = nil
        guard let url = components.url else {
            throw AppSecretsError.invalidProjectURL
        }
        return url
    }
}
