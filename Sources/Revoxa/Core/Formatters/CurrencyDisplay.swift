import Foundation

enum CurrencyDisplay {
    static func displayCurrencyCode(from defaults: UserDefaults = .standard) -> String {
        RevoxaCurrency.resolved(
            from: defaults.string(forKey: PreferenceKey.defaultCurrencyCode) ?? PreferenceKey.defaultCurrencyCodeValue
        ).code
    }

    static func convertedAmount(
        _ amount: Decimal,
        from sourceCurrencyCode: String,
        to displayCurrencyCode: String,
        using snapshot: ExchangeRateSnapshot?
    ) -> (amount: Decimal, currencyCode: String) {
        let source = Subscription.sanitizedCurrencyCode(sourceCurrencyCode)
        let target = Subscription.sanitizedCurrencyCode(displayCurrencyCode)

        if source == target {
            return (amount, target)
        }

        if let snapshot,
           let converted = snapshot.convert(amount, from: source, to: target) {
            return (converted, target)
        }

        return (amount, source)
    }

    static func formattedAmount(
        _ amount: Decimal,
        from sourceCurrencyCode: String,
        to displayCurrencyCode: String,
        using snapshot: ExchangeRateSnapshot?
    ) -> String {
        let display = convertedAmount(
            amount,
            from: sourceCurrencyCode,
            to: displayCurrencyCode,
            using: snapshot
        )
        return CurrencyFormatter.string(from: display.amount, currencyCode: display.currencyCode)
    }

    static func displayTotals(
        _ totals: [CurrencyTotal],
        in displayCurrencyCode: String,
        using snapshot: ExchangeRateSnapshot?
    ) -> [CurrencyTotal] {
        snapshot?.convertedTotals(totals, to: displayCurrencyCode) ?? totals
    }
}
