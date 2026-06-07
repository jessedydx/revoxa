import Foundation
import Testing
@testable import Revoxa

struct ExchangeRateServiceTests {
    @Test
    func parsesTCMBForexSellingRatesAndConvertsToTRY() throws {
        let xml = """
        <?xml version="1.0" encoding="UTF-8"?>
        <Tarih_Date Tarih="25.05.2026" Date="05/25/2026">
            <Currency Kod="USD" CurrencyCode="USD">
                <Unit>1</Unit>
                <ForexSelling>45.7134</ForexSelling>
            </Currency>
            <Currency Kod="EUR" CurrencyCode="EUR">
                <Unit>1</Unit>
                <ForexSelling>53.2181</ForexSelling>
            </Currency>
            <Currency Kod="JPY" CurrencyCode="JPY">
                <Unit>100</Unit>
                <ForexSelling>31.8000</ForexSelling>
            </Currency>
        </Tarih_Date>
        """
        let fetchedAt = date(2026, 5, 31)

        let snapshot = try ExchangeRateService.parseTCMBSnapshot(
            from: Data(xml.utf8),
            fetchedAt: fetchedAt
        )

        #expect(snapshot.baseCurrencyCode == "TRY")
        #expect(snapshot.rateToTRY(for: "TRY") == Decimal(1))
        #expect(snapshot.rateToTRY(for: "USD") == Decimal(string: "45.7134"))
        #expect(snapshot.rateToTRY(for: "EUR") == Decimal(string: "53.2181"))
        #expect(snapshot.rateToTRY(for: "JPY") == Decimal(string: "0.318"))
        #expect(snapshot.convertToTRY(Decimal(10), from: "USD") == Decimal(string: "457.134"))
    }

    private func date(_ year: Int, _ month: Int, _ day: Int) -> Date {
        DateComponents(
            calendar: Calendar(identifier: .gregorian),
            year: year,
            month: month,
            day: day
        ).date!
    }
}
