import Foundation

enum CurrencyFormatter {
    static func string(from amount: Decimal, currencyCode: String) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = RevoxaLanguageSettings.resolvedLocale
        formatter.currencyCode = Subscription.sanitizedCurrencyCode(currencyCode)
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        formatter.usesGroupingSeparator = true

        return formatter.string(from: NSDecimalNumber(decimal: amount)) ?? "\(amount)"
    }
}
