import SwiftUI

enum AppTheme: String, CaseIterable, Identifiable, Codable {
    case light
    case dark
    case system

    var id: String { rawValue }

    var title: String {
        switch self {
        case .light: L10n.t("theme.light")
        case .dark: L10n.t("theme.dark")
        case .system: L10n.t("theme.system")
        }
    }

    var preferredColorScheme: ColorScheme? {
        switch self {
        case .light: .light
        case .dark: .dark
        case .system: nil
        }
    }

    static func resolved(from rawValue: String) -> AppTheme {
        if let theme = AppTheme(rawValue: rawValue) {
            return theme
        }

        switch rawValue {
        case "dark":
            return .dark
        case "system":
            return .system
        default:
            return .system
        }
    }
}

enum PreferenceKey {
    static let defaultCurrencyCode = "settings.defaultCurrencyCode"
    static let defaultCurrencyCodeValue = RevoxaCurrency.defaultCode
    static let defaultReminderDays = "settings.defaultReminderDays"
    static let appTheme = "settings.appTheme"
    static let appAppearance = "settings.appAppearance"
    static let appLanguage = "settings.appLanguage"
    static let notificationsEnabled = "settings.notificationsEnabled"
    static let cachedExchangeRateSnapshot = "exchangeRates.cachedSnapshot"
}
