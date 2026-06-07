import Foundation
import Testing
@testable import Revoxa

struct CSVExporterTests {
    @Test
    func escapesCommasQuotesAndNewlines() {
        #expect(CSVExporter.escape("plain") == "plain")
        #expect(CSVExporter.escape("a,b") == "\"a,b\"")
        #expect(CSVExporter.escape("a \"quote\"") == "\"a \"\"quote\"\"\"")
        #expect(CSVExporter.escape("line\nbreak") == "\"line\nbreak\"")
        #expect(CSVExporter.escape("carriage\rreturn") == "\"carriage\rreturn\"")
    }

    @Test
    func subscriptionsCSVUsesLocalizedHeaderAndEscaping() {
        let subscription = Subscription(
            name: "AI, Pro",
            amount: Decimal(string: "20.5") ?? 20.5,
            currencyCode: "USD",
            billingCycle: .monthly,
            nextBillingDate: Date(timeIntervalSince1970: 0),
            category: .ai,
            paymentMethod: .creditCard,
            status: .active,
            cancellationURL: URL(string: "https://example.com/cancel"),
            notes: "note with \"quote\"",
            createdAt: Date(timeIntervalSince1970: 1),
            updatedAt: Date(timeIntervalSince1970: 2)
        )

        let csv = CSVExporter.subscriptionsCSV(for: [subscription], locale: Locale(identifier: "tr"))

        #expect(csv.hasPrefix("Ad,Tutar,Para birimi kodu,Döngü,Sonraki ödeme,Kategori,Ödeme yöntemi,Durum,Kaç gün önce hatırlatılsın,İptal bağlantısı,Notlar,Kullanım sıklığı,Değer puanı,İptal nedeni,Potansiyel aylık tasarruf,Son inceleme,Oluşturulma tarihi,Güncellenme tarihi\n"))
        #expect(csv.contains("\"AI, Pro\""))
        #expect(csv.contains("\"note with \"\"quote\"\"\""))
    }

    @Test
    func dashboardSummaryCSVUsesMetricValueCurrencyColumns() {
        let summary = DashboardSummary(
            monthlyTotals: [CurrencyTotal(currencyCode: "USD", amount: Decimal(10))],
            yearlyTotals: [CurrencyTotal(currencyCode: "USD", amount: Decimal(120))],
            renewalsWithin7Days: 1,
            renewalsWithin30Days: 2,
            mostExpensiveSubscription: nil,
            cancellationCandidateCount: 3,
            potentialMonthlySavings: [CurrencyTotal(currencyCode: "USD", amount: Decimal(5))],
            upcomingPayments: [],
            topExpensiveSubscriptions: [],
            cancellationCandidates: []
        )

        let csv = CSVExporter.dashboardSummaryCSV(for: summary, locale: Locale(identifier: "tr"))

        #expect(csv.hasPrefix("Metrik,Değer,Para birimi kodu\n"))
        #expect(csv.contains("Bu takvim ayında vadesi gelen ödemeler,10,USD\n"))
        #expect(csv.contains("7 gün içindeki yenilemeler,1,\n"))
    }
}
