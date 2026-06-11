import Foundation

enum AppLanguage: String, CaseIterable, Identifiable, Codable {
    case system
    case turkish
    case english

    var id: String { rawValue }

    /// `nil` means follow the macOS system locale.
    var locale: Locale? {
        switch self {
        case .system:
            nil
        case .turkish:
            Locale(identifier: "tr")
        case .english:
            Locale(identifier: "en")
        }
    }

    var displayName: String {
        switch self {
        case .system:
            L10n.t("language.system")
        case .turkish:
            L10n.t("language.turkish")
        case .english:
            L10n.t("language.english")
        }
    }

    static func resolved(from rawValue: String) -> AppLanguage {
        AppLanguage(rawValue: rawValue) ?? .system
    }
}

enum RevoxaLanguageSettings {
    static func readLanguage(from defaults: UserDefaults = .standard) -> AppLanguage {
        let raw = defaults.string(forKey: PreferenceKey.appLanguage) ?? AppLanguage.system.rawValue
        return AppLanguage.resolved(from: raw)
    }

    static func writeLanguage(_ language: AppLanguage, to defaults: UserDefaults = .standard) {
        defaults.set(language.rawValue, forKey: PreferenceKey.appLanguage)
        RevoxaSyncedPreferences.pushLocalChange(key: PreferenceKey.appLanguage, value: language.rawValue)
    }

    static var resolvedLocale: Locale {
        readLanguage().locale ?? .autoupdatingCurrent
    }

    static var environmentLocale: Locale {
        environmentLocale(for: readLanguage().rawValue)
    }

    static func environmentLocale(for languageRawValue: String) -> Locale {
        switch AppLanguage.resolved(from: languageRawValue) {
        case .system:
            .autoupdatingCurrent
        case .turkish:
            Locale(identifier: "tr")
        case .english:
            Locale(identifier: "en")
        }
    }
}
