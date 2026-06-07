import Foundation
import Testing
@testable import Revoxa

struct ValueReviewCalculatorTests {
    private let calendar = Calendar(identifier: .gregorian)

    @Test
    func recommendedCandidateRequiresRareUsageAndLowValue() {
        let calculator = ValueReviewCalculator()

        let recommended = makeSubscription(
            status: .active,
            valueRating: .low,
            usageFrequency: .never
        )
        let notRecommended = makeSubscription(
            status: .active,
            valueRating: .high,
            usageFrequency: .never
        )

        #expect(calculator.isRecommendedCancellationCandidate(recommended))
        #expect(calculator.isRecommendedCancellationCandidate(notRecommended) == false)
        #expect(recommended.isRecommendedCancellationCandidate)
    }

    @Test
    func potentialMonthlySavingsIncludeLowValueAndCancelSoon() {
        let calculator = ValueReviewCalculator(
            billingCalculator: BillingCalculator(calendar: calendar)
        )
        let subscriptions = [
            makeSubscription(name: "Low", amount: 10, status: .active, valueRating: .low, usageFrequency: .weekly),
            makeSubscription(name: "Soon", amount: 20, status: .cancelSoon, valueRating: .medium, usageFrequency: .monthly),
            makeSubscription(name: "Healthy", amount: 30, status: .active, valueRating: .high, usageFrequency: .daily)
        ]

        let savings = calculator.potentialMonthlySavings(for: subscriptions)

        #expect(savings == [CurrencyTotal(currencyCode: "USD", amount: Decimal(30))])
    }

    @Test
    func refreshStoredMetricsUpdatesPotentialSaving() {
        let calculator = ValueReviewCalculator()
        let subscription = makeSubscription(
            amount: 12,
            status: .active,
            valueRating: .low,
            usageFrequency: .rarely
        )

        calculator.refreshStoredMetrics(for: subscription, markReviewed: false)

        #expect(subscription.potentialMonthlySaving == Decimal(12))
    }

    private func makeSubscription(
        name: String = "Test",
        amount: Decimal = 10,
        status: SubscriptionStatus = .active,
        valueRating: ValueRating = .unknown,
        usageFrequency: UsageFrequency = .monthly
    ) -> Subscription {
        Subscription(
            name: name,
            amount: amount,
            currencyCode: "USD",
            billingCycle: .monthly,
            nextBillingDate: date(2026, 6, 10),
            category: .other,
            paymentMethod: .creditCard,
            status: status,
            usageFrequency: usageFrequency,
            valueRating: valueRating
        )
    }

    private func date(_ year: Int, _ month: Int, _ day: Int) -> Date {
        DateComponents(calendar: calendar, year: year, month: month, day: day).date!
    }
}
