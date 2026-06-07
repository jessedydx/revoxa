import Foundation

enum CSVExporter {
    static func subscriptionsCSV(
        for subscriptions: [Subscription],
        locale: Locale = RevoxaLanguageSettings.resolvedLocale
    ) -> String {
        var rows = [localizedSubscriptionHeaders(locale: locale)]

        rows += subscriptions.map { subscription in
            [
                subscription.name,
                NSDecimalNumber(decimal: subscription.amount).stringValue,
                subscription.currencyCode,
                subscription.billingCycle.rawValue,
                isoString(from: subscription.nextBillingDate),
                subscription.category.rawValue,
                subscription.paymentMethod.rawValue,
                subscription.status.rawValue,
                "\(subscription.reminderDaysBefore)",
                subscription.cancellationURL?.absoluteString ?? "",
                subscription.notes ?? "",
                subscription.usageFrequency.rawValue,
                subscription.valueRating.rawValue,
                subscription.cancelReason?.rawValue ?? "",
                subscription.potentialMonthlySaving.map { NSDecimalNumber(decimal: $0).stringValue } ?? "",
                subscription.lastReviewedAt.map { isoString(from: $0) } ?? "",
                isoString(from: subscription.createdAt),
                isoString(from: subscription.updatedAt)
            ]
        }

        return csvString(rows: rows)
    }

    static func dashboardSummaryCSV(
        for summary: DashboardSummary,
        locale: Locale = RevoxaLanguageSettings.resolvedLocale
    ) -> String {
        var rows = [[
            L10n.t("csv.header.metric", locale: locale),
            L10n.t("csv.header.value", locale: locale),
            L10n.t("csv.header.currencyCode", locale: locale)
        ]]

        rows += summary.monthlyTotals.map {
            [L10n.t("csv.metric.estimatedMonthlyTotal", locale: locale), NSDecimalNumber(decimal: $0.amount).stringValue, $0.currencyCode]
        }
        rows += summary.yearlyTotals.map {
            [L10n.t("csv.metric.estimatedYearlyTotal", locale: locale), NSDecimalNumber(decimal: $0.amount).stringValue, $0.currencyCode]
        }
        rows.append([L10n.t("csv.metric.renewalsWithin7Days", locale: locale), "\(summary.renewalsWithin7Days)", ""])
        rows.append([L10n.t("csv.metric.renewalsWithin30Days", locale: locale), "\(summary.renewalsWithin30Days)", ""])
        rows.append([L10n.t("csv.metric.cancellationCandidateCount", locale: locale), "\(summary.cancellationCandidateCount)", ""])
        rows += summary.potentialMonthlySavings.map {
            [L10n.t("csv.metric.potentialMonthlySaving", locale: locale), NSDecimalNumber(decimal: $0.amount).stringValue, $0.currencyCode]
        }

        if let mostExpensiveSubscription = summary.mostExpensiveSubscription {
            rows.append([L10n.t("csv.metric.mostExpensiveSubscription", locale: locale), mostExpensiveSubscription.name, mostExpensiveSubscription.currencyCode])
        }

        return csvString(rows: rows)
    }

    static func csvString(rows: [[String]]) -> String {
        rows
            .map { row in row.map(escape).joined(separator: ",") }
            .joined(separator: "\n")
            + "\n"
    }

    static func escape(_ value: String) -> String {
        let mustQuote = value.contains(",")
            || value.contains("\"")
            || value.contains("\n")
            || value.contains("\r")

        guard mustQuote else { return value }
        return "\"\(value.replacingOccurrences(of: "\"", with: "\"\""))\""
    }

    private static func isoString(from date: Date) -> String {
        ISO8601DateFormatter().string(from: date)
    }

    private static func localizedSubscriptionHeaders(locale: Locale) -> [String] {
        [
            L10n.t("subscriptions.table.name", locale: locale),
            L10n.t("subscriptions.table.amount", locale: locale),
            L10n.t("csv.header.currencyCode", locale: locale),
            L10n.t("subscriptions.table.cycle", locale: locale),
            L10n.t("subscriptions.table.nextBilling", locale: locale),
            L10n.t("subscriptions.table.category", locale: locale),
            L10n.t("form.paymentMethod", locale: locale),
            L10n.t("subscriptions.table.status", locale: locale),
            L10n.t("form.reminderDaysBefore", locale: locale),
            L10n.t("form.cancellationURL", locale: locale),
            L10n.t("form.notes", locale: locale),
            L10n.t("form.usageFrequency", locale: locale),
            L10n.t("form.valueRating", locale: locale),
            L10n.t("form.cancelReason", locale: locale),
            L10n.t("form.potentialSaving", locale: locale),
            L10n.t("form.lastReviewed", locale: locale),
            L10n.t("csv.header.createdAt", locale: locale),
            L10n.t("csv.header.updatedAt", locale: locale)
        ]
    }
}
