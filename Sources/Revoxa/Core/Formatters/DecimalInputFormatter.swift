import Foundation

/// Parses and formats user-entered money amounts in subscription forms (locale-aware comma/dot).
enum DecimalInputFormatter {
    static func editingString(from amount: Decimal, locale: Locale = RevoxaLanguageSettings.resolvedLocale) -> String {
        let formatter = NumberFormatter()
        formatter.locale = locale
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 2
        formatter.usesGroupingSeparator = false

        return formatter.string(from: NSDecimalNumber(decimal: amount)) ?? "\(amount)"
    }

    static func decimal(from text: String, locale: Locale = RevoxaLanguageSettings.resolvedLocale) -> Decimal? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.isEmpty == false else { return nil }

        let posix = Locale(identifier: "en_US_POSIX")
        let hasComma = trimmed.contains(",")
        let hasDot = trimmed.contains(".")

        if hasComma && hasDot {
            let normalized = normalizedDecimalString(trimmed, locale: locale)
            return Decimal(string: normalized, locale: posix)
        }

        let decimalSeparator = locale.decimalSeparator ?? "."

        if hasComma && hasDot == false {
            if decimalSeparator == "," {
                return Decimal(string: trimmed, locale: locale)
                    ?? Decimal(string: normalizedDecimalString(trimmed, locale: locale), locale: posix)
            }
            return Decimal(string: trimmed, locale: posix)
                ?? Decimal(string: trimmed, locale: locale)
        }

        if hasDot && hasComma == false {
            if decimalSeparator == "," {
                return Decimal(string: trimmed, locale: posix)
            }
            return Decimal(string: trimmed, locale: locale)
                ?? Decimal(string: trimmed, locale: posix)
        }

        return Decimal(string: trimmed, locale: locale)
            ?? Decimal(string: trimmed, locale: posix)
    }

    private static func normalizedDecimalString(_ text: String, locale: Locale) -> String {
        let groupingSeparator = locale.groupingSeparator ?? ""

        var working = text
        if groupingSeparator.isEmpty == false {
            working = working.replacingOccurrences(of: groupingSeparator, with: "")
        }

        let hasComma = working.contains(",")
        let hasDot = working.contains(".")

        if hasComma && hasDot {
            if let lastComma = working.lastIndex(of: ","),
               let lastDot = working.lastIndex(of: ".")
            {
                if lastComma > lastDot {
                    working = working.replacingOccurrences(of: ".", with: "")
                    working = working.replacingOccurrences(of: ",", with: ".")
                } else {
                    working = working.replacingOccurrences(of: ",", with: "")
                }
            }
        } else if hasComma {
            working = working.replacingOccurrences(of: ",", with: ".")
        }

        return working
    }
}
