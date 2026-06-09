import Foundation

struct ExchangeRateSnapshot: Codable, Equatable {
    let baseCurrencyCode: String
    let ratesToTRY: [String: Decimal]
    let rateDate: Date
    let fetchedAt: Date
    var isCached: Bool = false

    func rateToTRY(for currencyCode: String) -> Decimal? {
        let sanitizedCode = Subscription.sanitizedCurrencyCode(currencyCode)
        if sanitizedCode == baseCurrencyCode {
            return Decimal(1)
        }

        return ratesToTRY[sanitizedCode]
    }

    func convertToTRY(_ amount: Decimal, from currencyCode: String) -> Decimal? {
        guard let rate = rateToTRY(for: currencyCode) else { return nil }
        return amount * rate
    }

    func convert(_ amount: Decimal, from sourceCurrencyCode: String, to targetCurrencyCode: String) -> Decimal? {
        let source = Subscription.sanitizedCurrencyCode(sourceCurrencyCode)
        let target = Subscription.sanitizedCurrencyCode(targetCurrencyCode)

        if source == target {
            return amount
        }

        guard let amountInBase = convertToTRY(amount, from: source) else {
            return nil
        }

        if target == baseCurrencyCode {
            return amountInBase
        }

        guard let targetRate = rateToTRY(for: target), targetRate > .zero else {
            return nil
        }

        return amountInBase / targetRate
    }

    func convertedTotals(_ totals: [CurrencyTotal], to targetCurrencyCode: String) -> [CurrencyTotal]? {
        let target = Subscription.sanitizedCurrencyCode(targetCurrencyCode)
        var convertedTotal = Decimal.zero

        for total in totals {
            guard let convertedAmount = convert(total.amount, from: total.currencyCode, to: target) else {
                return nil
            }
            convertedTotal += convertedAmount
        }

        return [CurrencyTotal(currencyCode: target, amount: convertedTotal)]
    }

    func convertedTotalsToTRY(_ totals: [CurrencyTotal]) -> [CurrencyTotal]? {
        convertedTotals(totals, to: baseCurrencyCode)
    }
}

enum ExchangeRateServiceError: Error {
    case invalidResponse
    case missingRates
}

struct ExchangeRateService {
    static let shared = ExchangeRateService()

    var sourceURL: URL = URL(string: "https://www.tcmb.gov.tr/kurlar/today.xml")!
    var defaults: UserDefaults = .standard
    var session: URLSession = .shared
    var now: () -> Date = Date.init

    func latestRates() async throws -> ExchangeRateSnapshot {
        do {
            let (data, response) = try await session.data(from: sourceURL)
            guard let httpResponse = response as? HTTPURLResponse,
                  (200..<300).contains(httpResponse.statusCode)
            else {
                throw ExchangeRateServiceError.invalidResponse
            }

            let snapshot = try Self.parseTCMBSnapshot(from: data, fetchedAt: now())
            cache(snapshot)
            return snapshot
        } catch {
            if let cachedSnapshot {
                return cachedSnapshot
            }

            throw error
        }
    }

    var cachedSnapshot: ExchangeRateSnapshot? {
        guard let data = defaults.data(forKey: PreferenceKey.cachedExchangeRateSnapshot),
              var snapshot = try? JSONDecoder().decode(ExchangeRateSnapshot.self, from: data)
        else {
            return nil
        }

        snapshot.isCached = true
        return snapshot
    }

    func cache(_ snapshot: ExchangeRateSnapshot) {
        guard let data = try? JSONEncoder().encode(snapshot) else { return }
        defaults.set(data, forKey: PreferenceKey.cachedExchangeRateSnapshot)
    }

    static func parseTCMBSnapshot(from data: Data, fetchedAt: Date) throws -> ExchangeRateSnapshot {
        let parserDelegate = TCMBExchangeRateParserDelegate()
        let parser = XMLParser(data: data)
        parser.delegate = parserDelegate

        guard parser.parse(), parserDelegate.ratesToTRY.isEmpty == false else {
            throw parser.parserError ?? ExchangeRateServiceError.missingRates
        }

        return ExchangeRateSnapshot(
            baseCurrencyCode: "TRY",
            ratesToTRY: parserDelegate.ratesToTRY,
            rateDate: parserDelegate.rateDate ?? fetchedAt,
            fetchedAt: fetchedAt
        )
    }
}

private final class TCMBExchangeRateParserDelegate: NSObject, XMLParserDelegate {
    private var currentCurrencyCode: String?
    private var currentUnit = Decimal(1)
    private var currentElement = ""
    private var currentText = ""
    private var currentForexSelling: Decimal?
    private let dateFormatter: DateFormatter

    private(set) var ratesToTRY: [String: Decimal] = [:]
    private(set) var rateDate: Date?

    override init() {
        dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.dateFormat = "MM/dd/yyyy"
        super.init()
    }

    func parser(
        _ parser: XMLParser,
        didStartElement elementName: String,
        namespaceURI: String?,
        qualifiedName qName: String?,
        attributes attributeDict: [String: String] = [:]
    ) {
        currentElement = elementName
        currentText = ""

        if elementName == "Tarih_Date", let rawDate = attributeDict["Date"] {
            rateDate = dateFormatter.date(from: rawDate)
        }

        if elementName == "Currency" {
            currentCurrencyCode = attributeDict["CurrencyCode"] ?? attributeDict["Kod"]
            currentUnit = Decimal(1)
            currentForexSelling = nil
        }
    }

    func parser(_ parser: XMLParser, foundCharacters string: String) {
        currentText += string
    }

    func parser(
        _ parser: XMLParser,
        didEndElement elementName: String,
        namespaceURI: String?,
        qualifiedName qName: String?
    ) {
        let trimmedText = currentText.trimmingCharacters(in: .whitespacesAndNewlines)

        switch elementName {
        case "Unit":
            currentUnit = decimal(from: trimmedText) ?? Decimal(1)
        case "ForexSelling":
            currentForexSelling = decimal(from: trimmedText)
        case "Currency":
            if let code = currentCurrencyCode,
               let forexSelling = currentForexSelling,
               currentUnit > .zero {
                ratesToTRY[Subscription.sanitizedCurrencyCode(code)] = forexSelling / currentUnit
            }
            currentCurrencyCode = nil
            currentUnit = Decimal(1)
            currentForexSelling = nil
        default:
            break
        }

        currentText = ""
    }

    private func decimal(from value: String) -> Decimal? {
        Decimal(string: value, locale: Locale(identifier: "en_US_POSIX"))
    }
}
