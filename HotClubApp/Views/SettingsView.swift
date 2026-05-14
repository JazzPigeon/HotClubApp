import SwiftUI

struct SettingsView: View {
    @Environment(AppModel.self) private var app
    @Environment(\.appTheme) private var theme
    @AppStorage("selectedAppTheme") private var themeRaw = AppTheme.system.rawValue

    @State private var signOutError: String?

    var body: some View {
        NavigationStack {
            Form {
                Section("Appearance") {
                    Picker("Color theme", selection: $themeRaw) {
                        ForEach(AppTheme.allCases) { t in
                            Text(t.displayName).tag(t.rawValue)
                        }
                    }
                }
                if let signOutError {
                    Section {
                        Text(signOutError)
                            .foregroundStyle(.red)
                    }
                }
                Section {
                    Button("Sign out", role: .destructive) {
                        Task { await signOut() }
                    }
                }
            }
            .navigationTitle("Settings")
            .scrollContentBackground(.hidden)
            .background(theme.background)
        }
    }

    private func signOut() async {
        signOutError = nil
        do {
            try await app.signOut()
        } catch {
            signOutError = error.localizedDescription
        }
    }
}
