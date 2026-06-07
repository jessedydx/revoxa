import Foundation
import Testing
@testable import Revoxa

struct InsightsCalculatorTests {
    @Test
    func categoryTotalsGroupByCurrencyAndExcludeInactiveSpend() {
        let calculator = InsightsCalculator()
        let subscriptions = [
            makeSubscription(name: "AI USD", amount: 20, currency: "USD", category: .ai, status: .active),
            makeSubscription(name: "Cloud USD", amount: 10, currency: "USD", category: .cloud, status: .trial),
            makeSubscription(name: "AI EUR", amount: 15, currency: "EUR", category: .ai, status: .cancelSoon),
            makeSubscription(name: "Cancelled USD", amount: 99, currency: "USD", category: .ai, status: .cancelled),
            makeSubscription(name: "Archived USD", amount: 99, currency: "USD", category: .cloud, status: .archived)
        ]

        let summary = calculator.summary(for: subscriptions)

        #expect(summary.categoryTotals == [
            CategorySpendTotal(currencyCode: "EUR", category: .ai, estimatedMonthlyTotal: Decimal(15), estimatedYearlyTotal: Decimal(180)),
            CategorySpendTotal(currencyCode: "USD", category: .ai, estimatedMonthlyTotal: Decimal(20), estimatedYearlyTotal: Decimal(240)),
            CategorySpendTotal(currencyCode: "USD", category: .cloud, estimatedMonthlyTotal: Decimal(10), estimatedYearlyTotal: Decimal(120))
        ])
    }

    @Test
    func statusDistributionCountsEveryStatus() {
        let calculator = InsightsCalculator()
        let subscriptions = [
            makeSubscription(name: "Active", status: .active),
            makeSubscription(name: "Trial", status: .trial),
            makeSubscription(name: "Cancel Soon", status: .cancelSoon),
            makeSubscription(name: "Cancelled", status: .cancelled),
            makeSubscription(name: "Archived", status: .archived)
        ]

        let summary = calculator.summary(for: subscriptions)

        #expect(summary.statusDistribution == [
            StatusDistribution(status: .active, count: 1),
            StatusDistribution(status: .trial, count: 1),
            StatusDistribution(status: .cancelSoon, count: 1),
            StatusDistribution(status: .cancelled, count: 1),
            StatusDistribution(status: .archived, count: 1)
        ])
    }

    @Test
    func categoryTotalsConvertToTRYWhenExchangeRatesAvailable() {
        let calculator = InsightsCalculator()
        let subscriptions = [
            makeSubscription(name: "AI USD", amount: 10, currency: "USD", category: .ai, status: .active),
            makeSubscription(name: "AI EUR", amount: 10, currency: "EUR", category: .ai, status: .active)
        ]
        let exchangeRates = ExchangeRateSnapshot(
            baseCurrencyCode: "TRY",
            ratesToTRY: ["USD": Decimal(40), "EUR": Decimal(50)],
            rateDate: .now,
            fetchedAt: .now
        )

        let summary = calculator.summary(for: subscriptions, exchangeRates: exchangeRates)

        #expect(summary.categoryTotals == [
            CategorySpendTotal(
                currencyCode: "TRY",
                category: .ai,
                estimatedMonthlyTotal: Decimal(900),
                estimatedYearlyTotal: Decimal(10_800)
            )
        ])
    }

    @Test
    func topSubscriptionsSortByConvertedMonthlyCostWhenExchangeRatesAvailable() {
        let calculator = InsightsCalculator()
        let subscriptions = [
            makeSubscription(name: "Small USD", amount: 10, currency: "USD", category: .ai, status: .active),
            makeSubscription(name: "Large EUR", amount: 10, currency: "EUR", category: .cloud, status: .active)
        ]
        let exchangeRates = ExchangeRateSnapshot(
            baseCurrencyCode: "TRY",
            ratesToTRY: ["USD": Decimal(40), "EUR": Decimal(50)],
            rateDate: .now,
            fetchedAt: .now
        )

        let summary = calculator.summary(for: subscriptions, exchangeRates: exchangeRates)

        #expect(summary.topSubscriptions.map(\.subscription.name) == ["Large EUR", "Small USD"])
    }

    @Test
    func topSubscriptionsReturnOnlyMostExpensiveActiveLikeItems() {
        let calculator = InsightsCalculator()
        let subscriptions = (1...12).map {
            makeSubscription(name: "Sub \($0)", amount: Decimal($0), status: .active)
        } + [
            makeSubscription(name: "Cancelled Expensive", amount: 999, status: .cancelled)
        ]

        let summary = calculator.summary(for: subscriptions)

        #expect(summary.topSubscriptions.count == 10)
        #expect(summary.topSubscriptions.first?.subscription.name == "Sub 12")
        #expect(summary.topSubscriptions.last?.subscription.name == "Sub 3")
        #expect(summary.topSubscriptions.contains { $0.subscription.name == "Cancelled Expensive" } == false)
    }

    private func makeSubscription(
        name: String,
        amount: Decimal = Decimal(10),
        currency: String = "USD",
        category: SubscriptionCategory = .productivity,
        status: SubscriptionStatus
    ) -> Subscription {
        Subscription(
            name: name,
            amount: amount,
            currencyCode: currency,
            billingCycle: .monthly,
            nextBillingDate: .now,
            category: category,
            paymentMethod: .creditCard,
            status: status
        )
    }
}
