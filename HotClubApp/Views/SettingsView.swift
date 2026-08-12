import SwiftUI

struct SettingsView: View {
    @Environment(AppModel.self) private var app
    @Environment(\.appTheme) private var theme
    @AppStorage("selectedAppTheme") private var themeRaw = AppTheme.system.rawValue
    @AppStorage("customThemeLibrary") private var customLibraryJSON = ""
    @AppStorage("customThemeColors") private var legacyCustomThemeJSON = ""

    @State private var signOutError: String?
    @State private var isNamingNewTheme = false
    @State private var newThemeName = ""

    private var isCustomSelected: Bool {
        themeRaw == AppTheme.custom.rawValue
    }

    private var library: Binding<CustomThemeLibrary> {
        Binding(
            get: {
                CustomThemeLibrary.decode(
                    from: customLibraryJSON,
                    legacyCustomJSON: legacyCustomThemeJSON
                )
            },
            set: { newValue in
                customLibraryJSON = newValue.json
                if !legacyCustomThemeJSON.isEmpty {
                    legacyCustomThemeJSON = ""
                }
            }
        )
    }

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

                if isCustomSelected {
                    Section("Custom themes") {
                        Picker("Theme", selection: selectedThemeIDBinding) {
                            ForEach(library.wrappedValue.themes) { saved in
                                Text(displayName(for: saved)).tag(saved.id)
                            }
                        }

                        TextField("Name", text: selectedThemeNameBinding)
                            .textInputAutocapitalization(.words)

                        Button("New Theme…") {
                            newThemeName = library.wrappedValue.nextSuggestedName()
                            isNamingNewTheme = true
                        }

                        Button("Duplicate Theme") {
                            var updated = library.wrappedValue
                            updated.duplicateSelected()
                            library.wrappedValue = updated
                        }

                        Button("Delete Theme", role: .destructive) {
                            var updated = library.wrappedValue
                            _ = updated.deleteSelected()
                            library.wrappedValue = updated
                        }
                        .disabled(library.wrappedValue.themes.count <= 1)
                    }

                    Section("Colors") {
                        Picker("Appearance", selection: customAppearanceBinding) {
                            ForEach(ThemeAppearance.allCases) { appearance in
                                Text(appearance.displayName).tag(appearance)
                            }
                        }

                        ColorPicker("Accent", selection: customColorBinding(\.accent), supportsOpacity: false)
                        ColorPicker("Background", selection: customColorBinding(\.background), supportsOpacity: false)
                        ColorPicker("Secondary background", selection: customColorBinding(\.secondaryBackground), supportsOpacity: false)
                        ColorPicker("Primary text", selection: customColorBinding(\.primaryText), supportsOpacity: false)
                        ColorPicker("Secondary text", selection: customColorBinding(\.secondaryText), supportsOpacity: false)

                        Button("Reset Colors") {
                            var updated = library.wrappedValue
                            updated.updateSelected { $0.colors = .default }
                            library.wrappedValue = updated
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
            .onAppear(perform: migrateLegacyCustomThemeIfNeeded)
            .alert("New Theme", isPresented: $isNamingNewTheme) {
                TextField("Theme name", text: $newThemeName)
                    .textInputAutocapitalization(.words)
                Button("Create") {
                    createTheme(named: newThemeName)
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Choose a name for your custom theme.")
            }
        }
    }

    private func displayName(for theme: SavedCustomTheme) -> String {
        let trimmed = theme.name.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "Untitled" : trimmed
    }

    private func createTheme(named name: String) {
        var updated = library.wrappedValue
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        updated.addTheme(named: trimmed.isEmpty ? nil : trimmed)
        library.wrappedValue = updated
    }

    private var selectedThemeIDBinding: Binding<UUID> {
        Binding(
            get: { library.wrappedValue.selectedThemeID },
            set: { newValue in
                var updated = library.wrappedValue
                updated.selectedThemeID = newValue
                updated.ensureValidSelection()
                library.wrappedValue = updated
            }
        )
    }

    private var selectedThemeNameBinding: Binding<String> {
        Binding(
            get: { library.wrappedValue.selectedTheme.name },
            set: { newValue in
                var updated = library.wrappedValue
                updated.updateSelected { $0.name = newValue }
                library.wrappedValue = updated
            }
        )
    }

    private var customAppearanceBinding: Binding<ThemeAppearance> {
        Binding(
            get: { library.wrappedValue.selectedTheme.colors.appearance },
            set: { newValue in
                var updated = library.wrappedValue
                updated.updateSelected { $0.colors.appearance = newValue }
                library.wrappedValue = updated
            }
        )
    }

    private func customColorBinding(_ keyPath: WritableKeyPath<CustomThemeColors, RGBAColor>) -> Binding<Color> {
        Binding(
            get: { library.wrappedValue.selectedTheme.colors[keyPath: keyPath].color },
            set: { newColor in
                var updated = library.wrappedValue
                updated.updateSelected { $0.colors[keyPath: keyPath] = RGBAColor(newColor) }
                library.wrappedValue = updated
            }
        )
    }

    private func migrateLegacyCustomThemeIfNeeded() {
        let current = CustomThemeLibrary.decode(
            from: customLibraryJSON,
            legacyCustomJSON: legacyCustomThemeJSON
        )
        if customLibraryJSON != current.json {
            customLibraryJSON = current.json
        }
        if !legacyCustomThemeJSON.isEmpty {
            legacyCustomThemeJSON = ""
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
