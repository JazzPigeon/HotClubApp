import SwiftUI

enum AppTheme: String, CaseIterable, Identifiable {
    case system
    case shellac
    case vinylNight
    case cobalt

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .system: return "System"
        case .shellac: return "Shellac"
        case .vinylNight: return "Vinyl Night"
        case .cobalt: return "Cobalt"
        }
    }

    var usesDarkChrome: Bool {
        switch self {
        case .system: return false
        case .shellac: return false
        case .vinylNight, .cobalt: return true
        }
    }

    var preferredColorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .shellac: return .light
        case .vinylNight, .cobalt: return .dark
        }
    }

    var accent: Color {
        switch self {
        case .system:
            return .accentColor
        case .shellac:
            return Color(red: 0.45, green: 0.22, blue: 0.12)
        case .vinylNight:
            return Color(red: 0.85, green: 0.2, blue: 0.18)
        case .cobalt:
            return Color(red: 0.35, green: 0.65, blue: 0.95)
        }
    }

    var background: Color {
        switch self {
        case .system:
            return Color(.systemGroupedBackground)
        case .shellac:
            return Color(red: 0.98, green: 0.95, blue: 0.88)
        case .vinylNight:
            return Color(red: 0.07, green: 0.07, blue: 0.08)
        case .cobalt:
            return Color(red: 0.06, green: 0.09, blue: 0.14)
        }
    }

    var secondaryBackground: Color {
        switch self {
        case .system:
            return Color(.secondarySystemGroupedBackground)
        case .shellac:
            return Color(red: 1.0, green: 0.99, blue: 0.94)
        case .vinylNight:
            return Color(red: 0.12, green: 0.12, blue: 0.14)
        case .cobalt:
            return Color(red: 0.1, green: 0.13, blue: 0.2)
        }
    }

    var primaryText: Color {
        switch self {
        case .system:
            return Color.primary
        case .shellac:
            return Color(red: 0.15, green: 0.1, blue: 0.06)
        case .vinylNight, .cobalt:
            return Color(red: 0.95, green: 0.95, blue: 0.96)
        }
    }

    var secondaryText: Color {
        switch self {
        case .system:
            return Color.secondary
        case .shellac:
            return Color(red: 0.35, green: 0.28, blue: 0.2)
        case .vinylNight, .cobalt:
            return Color(red: 0.65, green: 0.67, blue: 0.72)
        }
    }
}

private struct AppThemeKey: EnvironmentKey {
    static let defaultValue: AppTheme = .system
}

extension EnvironmentValues {
    var appTheme: AppTheme {
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
