import Foundation

enum RevoxaCurrency: String, CaseIterable, Identifiable, Codable {
    static let defaultCode = "TRY"

    case USD
    case EUR
    case TRY
    case GBP
    case CHF
    case JPY
    case CAD
    case AUD
    case PLN
    case SEK
    case NOK
    case DKK
    case CZK
    case HUF
    case CNY
    case INR
    case BRL
    case MXN

    var id: String { rawValue }

    var code: String { rawValue }

    var symbol: String {
        switch self {
        case .USD: "$"
        case .EUR: "€"
        case .TRY: "₺"
        case .GBP: "£"
        case .CHF: "CHF"
        case .JPY: "¥"
        case .CAD: "CA$"
        case .AUD: "A$"
        case .PLN: "zł"
        case .SEK: "kr"
        case .NOK: "kr"
        case .DKK: "kr"
        case .CZK: "Kč"
        case .HUF: "Ft"
        case .CNY: "¥"
        case .INR: "₹"
        case .BRL: "R$"
        case .MXN: "MX$"
        }
    }

    var title: String {
        L10n.t("currency.\(rawValue)")
    }

    var pickerLabel: String {
        "\(symbol) \(rawValue) · \(title)"
    }

    static func resolved(from code: String) -> RevoxaCurrency {
        let normalized = code
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .uppercased()

        guard normalized.count == 3, let currency = RevoxaCurrency(rawValue: normalized) else {
            return RevoxaCurrency(rawValue: Self.defaultCode) ?? .TRY
        }

        return currency
    }
}
