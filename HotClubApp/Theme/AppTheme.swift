import SwiftUI
import UIKit

/// Resolved colors + appearance applied across the app.
struct ThemePalette {
    var accent: Color
    var background: Color
    var secondaryBackground: Color
    var primaryText: Color
    var secondaryText: Color
    var preferredColorScheme: ColorScheme?
}

enum ThemeAppearance: String, CaseIterable, Identifiable, Codable {
    case system
    case light
    case dark

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .system: return "System"
        case .light: return "Light"
        case .dark: return "Dark"
        }
    }

    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
}

/// Codable sRGB color for persisting custom theme picks.
struct RGBAColor: Equatable, Codable {
    var red: Double
    var green: Double
    var blue: Double
    var opacity: Double

    var color: Color {
        Color(red: red, green: green, blue: blue, opacity: opacity)
    }

    init(red: Double, green: Double, blue: Double, opacity: Double = 1) {
        self.red = red
        self.green = green
        self.blue = blue
        self.opacity = opacity
    }

    init(_ color: Color) {
        let ui = UIColor(color).resolvedColor(with: .current)
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0
        if ui.getRed(&r, green: &g, blue: &b, alpha: &a) {
            self.init(red: Double(r), green: Double(g), blue: Double(b), opacity: Double(a))
        } else {
            self.init(red: 0.5, green: 0.5, blue: 0.5, opacity: 1)
        }
    }
}

struct CustomThemeColors: Equatable, Codable {
    var accent: RGBAColor
    var background: RGBAColor
    var secondaryBackground: RGBAColor
    var primaryText: RGBAColor
    var secondaryText: RGBAColor
    var appearance: ThemeAppearance

    static let `default` = CustomThemeColors(
        accent: RGBAColor(red: 0.45, green: 0.22, blue: 0.12),
        background: RGBAColor(red: 0.98, green: 0.95, blue: 0.88),
        secondaryBackground: RGBAColor(red: 1.0, green: 0.99, blue: 0.94),
        primaryText: RGBAColor(red: 0.15, green: 0.1, blue: 0.06),
        secondaryText: RGBAColor(red: 0.35, green: 0.28, blue: 0.2),
        appearance: .light
    )

    var palette: ThemePalette {
        ThemePalette(
            accent: accent.color,
            background: background.color,
            secondaryBackground: secondaryBackground.color,
            primaryText: primaryText.color,
            secondaryText: secondaryText.color,
            preferredColorScheme: appearance.colorScheme
        )
    }

    static func decode(from json: String) -> CustomThemeColors {
        guard let data = json.data(using: .utf8),
              let decoded = try? JSONDecoder().decode(CustomThemeColors.self, from: data)
        else {
            return .default
        }
        return decoded
    }

    var json: String {
        guard let data = try? JSONEncoder().encode(self),
              let string = String(data: data, encoding: .utf8)
        else {
            return "{}"
        }
        return string
    }

    static var defaultJSON: String { CustomThemeColors.default.json }
}

struct SavedCustomTheme: Identifiable, Equatable, Codable {
    var id: UUID
    var name: String
    var colors: CustomThemeColors
}

struct CustomThemeLibrary: Equatable, Codable {
    var themes: [SavedCustomTheme]
    var selectedThemeID: UUID

    private static let defaultThemeID = UUID(uuidString: "00000000-0000-4000-8000-000000000001")!

    static let `default` = CustomThemeLibrary(
        themes: [
            SavedCustomTheme(id: defaultThemeID, name: "My Theme", colors: .default)
        ],
        selectedThemeID: defaultThemeID
    )

    var selectedTheme: SavedCustomTheme {
        themes.first(where: { $0.id == selectedThemeID }) ?? themes[0]
    }

    var palette: ThemePalette {
        selectedTheme.colors.palette
    }

    static var defaultJSON: String { CustomThemeLibrary.default.json }

    var json: String {
        guard let data = try? JSONEncoder().encode(self),
              let string = String(data: data, encoding: .utf8)
        else {
            return "{}"
        }
        return string
    }

    /// Loads the library, migrating a legacy single-custom JSON blob when needed.
    static func decode(from json: String, legacyCustomJSON: String = "") -> CustomThemeLibrary {
        let hasLegacy = !legacyCustomJSON.isEmpty && legacyCustomJSON != "{}"
        let hasLibrary = {
            guard let data = json.data(using: .utf8),
                  let decoded = try? JSONDecoder().decode(CustomThemeLibrary.self, from: data),
                  !decoded.themes.isEmpty
            else {
                return false
            }
            return true
        }()

        // Prefer legacy migration when the library key has never been written.
        if hasLegacy && !hasLibrary {
            let colors = CustomThemeColors.decode(from: legacyCustomJSON)
            let theme = SavedCustomTheme(id: UUID(), name: "My Theme", colors: colors)
            return CustomThemeLibrary(themes: [theme], selectedThemeID: theme.id)
        }

        if let data = json.data(using: .utf8),
           let decoded = try? JSONDecoder().decode(CustomThemeLibrary.self, from: data),
           !decoded.themes.isEmpty {
            var library = decoded
            library.ensureValidSelection()
            return library
        }

        return .default
    }

    mutating func ensureValidSelection() {
        if themes.isEmpty {
            let theme = SavedCustomTheme(id: UUID(), name: "My Theme", colors: .default)
            themes = [theme]
            selectedThemeID = theme.id
            return
        }
        if !themes.contains(where: { $0.id == selectedThemeID }) {
            selectedThemeID = themes[0].id
        }
    }

    mutating func updateSelected(_ update: (inout SavedCustomTheme) -> Void) {
        guard let index = themes.firstIndex(where: { $0.id == selectedThemeID }) else { return }
        update(&themes[index])
    }

    mutating func addTheme(named name: String? = nil, basedOn colors: CustomThemeColors? = nil) {
        let theme = SavedCustomTheme(
            id: UUID(),
            name: name ?? nextDefaultName(),
            colors: colors ?? .default
        )
        themes.append(theme)
        selectedThemeID = theme.id
    }

    mutating func duplicateSelected() {
        let source = selectedTheme
        addTheme(named: "\(source.name) Copy", basedOn: source.colors)
    }

    @discardableResult
    mutating func deleteSelected() -> Bool {
        guard themes.count > 1,
              let index = themes.firstIndex(where: { $0.id == selectedThemeID })
        else {
            return false
        }
        themes.remove(at: index)
        selectedThemeID = themes[min(index, themes.count - 1)].id
        return true
    }

    func nextSuggestedName() -> String {
        nextDefaultName()
    }

    private func nextDefaultName() -> String {
        let base = "My Theme"
        let existing = Set(themes.map(\.name))
        if !existing.contains(base) { return base }
        var index = 2
        while existing.contains("\(base) \(index)") {
            index += 1
        }
        return "\(base) \(index)"
    }
}

enum AppTheme: String, CaseIterable, Identifiable {
    case system
    case shellac
    case hotClub
    case cobalt
    case sepia
    case emerald
    case champagne
    case custom

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .system: return "System"
        case .shellac: return "Shellac"
        case .hotClub: return "20 W. 20th"
        case .cobalt: return "Cobalt"
        case .sepia: return "Sepia"
        case .emerald: return "Emerald"
        case .champagne: return "Champagne"
        case .custom: return "Custom"
        }
    }

    /// Built-in palette. For `.custom`, returns the default custom seed (Shellac-like).
    var builtInPalette: ThemePalette {
        switch self {
        case .system:
            return ThemePalette(
                accent: .accentColor,
                background: Color(.systemGroupedBackground),
                secondaryBackground: Color(.secondarySystemGroupedBackground),
                primaryText: Color.primary,
                secondaryText: Color.secondary,
                preferredColorScheme: nil
            )
        case .shellac:
            return ThemePalette(
                accent: Color(red: 0.86, green: 0.73, blue: 0.06),
                background: Color(red: 0.98, green: 0.95, blue: 0.88),
                secondaryBackground: Color(red: 1.0, green: 0.99, blue: 0.94),
                primaryText: Color(red: 0.15, green: 0.1, blue: 0.06),
                secondaryText: Color(red: 0.35, green: 0.28, blue: 0.2),
                preferredColorScheme: .light
            )
        case .hotClub:
            return ThemePalette(
                accent: Color(red: 0.85, green: 0.73, blue: 0.06),
                background: Color(red: 0.78, green: 0.34, blue: 0.13),
                secondaryBackground: Color(red: 0.12, green: 0.12, blue: 0.14),
                primaryText: Color(red: 0.85, green: 0.73, blue: 0.06),
                secondaryText: Color(red: 0.65, green: 0.67, blue: 0.72),
                preferredColorScheme: .dark
            )
        case .cobalt:
            return ThemePalette(
                accent: Color(red: 0.35, green: 0.65, blue: 0.95),
                background: Color(red: 0.06, green: 0.09, blue: 0.14),
                secondaryBackground: Color(red: 0.1, green: 0.13, blue: 0.2),
                primaryText: Color(red: 0.95, green: 0.95, blue: 0.96),
                secondaryText: Color(red: 0.65, green: 0.67, blue: 0.72),
                preferredColorScheme: .dark
            )
        case .sepia:
            return ThemePalette(
                accent: Color(red: 0.55, green: 0.35, blue: 0.15),
                background: Color(red: 0.96, green: 0.93, blue: 0.86),
                secondaryBackground: Color(red: 0.99, green: 0.97, blue: 0.92),
                primaryText: Color(red: 0.2, green: 0.14, blue: 0.08),
                secondaryText: Color(red: 0.4, green: 0.32, blue: 0.22),
                preferredColorScheme: .light
            )
        case .emerald:
            return ThemePalette(
                accent: Color(red: 0.3, green: 0.75, blue: 0.5),
                background: Color(red: 0.06, green: 0.1, blue: 0.08),
                secondaryBackground: Color(red: 0.1, green: 0.16, blue: 0.13),
                primaryText: Color(red: 0.92, green: 0.96, blue: 0.93),
                secondaryText: Color(red: 0.6, green: 0.7, blue: 0.64),
                preferredColorScheme: .dark
            )
        case .champagne:
            return ThemePalette(
                accent: Color(red: 0.72, green: 0.55, blue: 0.28),
                background: Color(red: 0.99, green: 0.97, blue: 0.93),
                secondaryBackground: Color(red: 1.0, green: 0.99, blue: 0.96),
                primaryText: Color(red: 0.18, green: 0.14, blue: 0.1),
                secondaryText: Color(red: 0.45, green: 0.38, blue: 0.28),
                preferredColorScheme: .light
            )
        case .custom:
            return CustomThemeColors.default.palette
        }
    }

    static func resolve(
        selectionRaw: String,
        customLibraryJSON: String,
        legacyCustomJSON: String = ""
    ) -> ThemePalette {
        let selection = AppTheme(rawValue: selectionRaw) ?? .system
        if selection == .custom {
            return CustomThemeLibrary.decode(
                from: customLibraryJSON,
                legacyCustomJSON: legacyCustomJSON
            ).palette
        }
        return selection.builtInPalette
    }
}

private struct AppThemeKey: EnvironmentKey {
    static let defaultValue: ThemePalette = AppTheme.system.builtInPalette
}

extension EnvironmentValues {
    var appTheme: ThemePalette {
        get { self[AppThemeKey.self] }
        set { self[AppThemeKey.self] = newValue }
    }
}

extension View {
    func appThemedBackground() -> some View {
        modifier(AppThemedBackgroundModifier())
    }
}

private struct AppThemedBackgroundModifier: ViewModifier {
    @Environment(\.appTheme) private var theme

    func body(content: Content) -> some View {
        content
            .scrollContentBackground(.hidden)
            .background(theme.background)
    }
}
