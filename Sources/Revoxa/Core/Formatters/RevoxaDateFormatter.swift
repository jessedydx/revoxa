import Foundation

enum RevoxaDateFormatter {
    static func mediumDate(_ date: Date) -> String {
        date.formatted(
            .dateTime
                .day()
                .month(.abbreviated)
                .year()
                .locale(RevoxaLanguageSettings.resolvedLocale)
        )
    }

    static func compactDate(_ date: Date) -> String {
        date.formatted(
            .dateTime
                .day()
                .month(.abbreviated)
                .locale(RevoxaLanguageSettings.resolvedLocale)
        )
    }
}
