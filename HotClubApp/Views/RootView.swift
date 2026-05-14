import SwiftUI

struct RootView: View {
    @Environment(AppModel.self) private var app
    @AppStorage("selectedAppTheme") private var themeRaw = AppTheme.system.rawValue

    private var theme: AppTheme {
        AppTheme(rawValue: themeRaw) ?? .system
    }

    var body: some View {
        Group {
            if app.isBootstrapping {
                ProgressView("Loading…")
            } else if app.secretsError != nil {
                MissingSecretsView(message: app.secretsError ?? "Missing configuration.")
            } else if app.session == nil {
                LoginView()
            } else {
                MainTabView()
            }
        }
        .environment(\.appTheme, theme)
        .tint(theme.accent)
        .preferredColorScheme(theme.preferredColorScheme)
    }
}

struct MissingSecretsView: View {
    let message: String

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Text(message)
                        .font(.body)
                } header: {
                    Text("Supabase")
                }
                Section {
                    Text("In Xcode, duplicate Secrets.example.plist, rename the copy to Secrets.plist, and paste your project URL and anon key from the Supabase dashboard.")
                        .font(.footnote)
                }
            }
            .navigationTitle("Setup")
        }
    }
}
