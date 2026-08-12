import SwiftUI

struct RootView: View {
    @Environment(AppModel.self) private var app
    @AppStorage("selectedAppTheme") private var themeRaw = AppTheme.system.rawValue
    @AppStorage("customThemeLibrary") private var customLibraryJSON = ""
    /// Legacy single-custom blob; used only to migrate into `customThemeLibrary`.
    @AppStorage("customThemeColors") private var legacyCustomThemeJSON = ""

    private var theme: ThemePalette {
        AppTheme.resolve(
            selectionRaw: themeRaw,
            customLibraryJSON: customLibraryJSON,
            legacyCustomJSON: legacyCustomThemeJSON
        )
    }

    var body: some View {
        Group {
            if app.isBootstrapping {
                ProgressView("Loading…")
            } else if app.secretsError != nil {
                MissingSecretsView(message: app.secretsError ?? "Missing configuration.")
            } else if !app.isSignedIn {
                LoginView()
            } else {
                MainTabView()
            }
        }
        .environment(\.appTheme, theme)
        .tint(theme.accent)
        .preferredColorScheme(theme.preferredColorScheme)
        .onAppear(perform: persistResolvedCustomLibraryIfNeeded)
    }

    private func persistResolvedCustomLibraryIfNeeded() {
        let resolved = CustomThemeLibrary.decode(
            from: customLibraryJSON,
            legacyCustomJSON: legacyCustomThemeJSON
        )
        if customLibraryJSON.isEmpty || customLibraryJSON == "{}" {
            customLibraryJSON = resolved.json
        }
        if !legacyCustomThemeJSON.isEmpty {
            legacyCustomThemeJSON = ""
        }
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
