import Foundation

enum L10n {
    static func t(_ key: String, locale: Locale? = nil) -> String {
        localizedString(forKey: key, locale: locale ?? RevoxaLanguageSettings.resolvedLocale)
    }

    static func tf(_ key: String, locale: Locale? = nil, _ args: CVarArg...) -> String {
        let resolved = locale ?? RevoxaLanguageSettings.resolvedLocale
        let format = localizedString(forKey: key, locale: resolved)
        return withVaList(args) {
            NSString(format: format, locale: resolved, arguments: $0) as String
        }
    }

    private static func localizedString(forKey key: String, locale: Locale) -> String {
        let languageCode = languageCode(for: locale)
        let bundle = RevoxaResourceBundle.bundle

        for code in [languageCode, "en"] {
            guard let path = bundle.path(forResource: code, ofType: "lproj"),
                  let languageBundle = Bundle(path: path)
            else {
                continue
            }

            let value = languageBundle.localizedString(forKey: key, value: nil, table: nil)
            if value.isEmpty == false, value != key {
                return value
            }
        }

        if let value = catalogString(forKey: key, languageCode: languageCode, bundle: bundle) {
            return value
        }

        return key
    }

    private static func catalogString(forKey key: String, languageCode: String, bundle: Bundle) -> String? {
        guard let url = bundle.url(forResource: "Localizable", withExtension: "xcstrings"),
              let data = try? Data(contentsOf: url),
              let root = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let strings = root["strings"] as? [String: Any],
              let entry = strings[key] as? [String: Any],
              let localizations = entry["localizations"] as? [String: Any]
        else {
            return nil
        }

        for code in [languageCode, "en"] {
            guard let localization = localizations[code] as? [String: Any],
                  let stringUnit = localization["stringUnit"] as? [String: Any],
                  let value = stringUnit["value"] as? String,
                  value.isEmpty == false
            else {
                continue
            }

            return value
        }

        return nil
    }

    private static func languageCode(for locale: Locale) -> String {
        if let languageCode = locale.language.languageCode?.identifier {
            return languageCode
        }

        return locale.identifier
            .split(whereSeparator: { $0 == "_" || $0 == "-" })
            .first
            .map(String.init) ?? "en"
    }
}
