import Foundation
import Testing
@testable import Revoxa

struct BillingScheduleCalculatorTests {
    private let calendar = Calendar(identifier: .gregorian)
    private let billingCalculator = BillingCalculator(calendar: Calendar(identifier: .gregorian))
    private let schedule: BillingScheduleCalculator

    init() {
        schedule = BillingScheduleCalculator(
            billingCalculator: billingCalculator,
            calendar: calendar
        )
    }

    @Test
    func yearlyPaymentCountsOnlyInBillingMonth() {
        let subscriptions = [
            makeSubscription(
                name: "Annual",
                amount: 1200,
                cycle: .yearly,
                nextDate: date(2026, 9, 15)
            )
        ]
        let mayInterval = schedule.monthInterval(containing: date(2026, 5, 20))
        let septemberInterval = schedule.monthInterval(containing: date(2026, 9, 10))

        #expect(schedule.paymentTotals(for: subscriptions, in: mayInterval).isEmpty)
        #expect(schedule.paymentTotals(for: subscriptions, in: septemberInterval) == [
            CurrencyTotal(currencyCode: "USD", amount: Decimal(1200))
        ])
    }

    @Test
    func monthlyPaymentCountsWhenDueInMonth() {
        let subscriptions = [
            makeSubscription(
                name: "Monthly",
                amount: 100,
                cycle: .monthly,
                nextDate: date(2026, 5, 12)
            )
        ]
        let mayInterval = schedule.monthInterval(containing: date(2026, 5, 30))
        let juneInterval = schedule.monthInterval(containing: date(2026, 6, 1))

        #expect(schedule.paymentTotals(for: subscriptions, in: mayInterval) == [
            CurrencyTotal(currencyCode: "USD", amount: Decimal(100))
        ])
        #expect(schedule.paymentTotals(for: subscriptions, in: juneInterval) == [
            CurrencyTotal(currencyCode: "USD", amount: Decimal(100))
        ])
    }

    @Test
    func categoryPaymentTotalsGroupByCategoryForMonth() {
        let subscriptions = [
            makeSubscription(
                name: "Streaming",
                amount: 100,
                cycle: .monthly,
                nextDate: date(2026, 5, 12),
                category: .entertainment
            ),
            makeSubscription(
                name: "Cloud",
                amount: 50,
                cycle: .monthly,
                nextDate: date(2026, 5, 20),
                category: .cloud
            )
        ]
        let mayInterval = schedule.monthInterval(containing: date(2026, 5, 30))

        #expect(
            schedule.categoryPaymentTotals(for: subscriptions, in: mayInterval) == [
                CategoryPaymentTotal(category: .entertainment, amount: 100, currencyCode: "USD"),
                CategoryPaymentTotal(category: .cloud, amount: 50, currencyCode: "USD")
            ]
        )
    }

    @Test
    func cashbackReducesScheduledPaymentAmount() {
        let subscription = Subscription(
            name: "Cashback",
            amount: 100,
            cashbackAmount: 25,
            currencyCode: "TRY",
            billingCycle: .monthly,
            nextBillingDate: date(2026, 5, 8),
            category: .utilities,
            paymentMethod: .creditCard
        )
        let mayInterval = schedule.monthInterval(containing: date(2026, 5, 20))

        #expect(schedule.paymentTotals(for: [subscription], in: mayInterval) == [
            CurrencyTotal(currencyCode: "TRY", amount: Decimal(75))
        ])
    }

    private func makeSubscription(
        name: String,
        amount: Decimal,
        cycle: BillingCycle,
        nextDate: Date,
        category: SubscriptionCategory = .productivity
    ) -> Subscription {
        Subscription(
            name: name,
            amount: amount,
            currencyCode: "USD",
            billingCycle: cycle,
            nextBillingDate: nextDate,
            category: category,
            paymentMethod: .creditCard
        )
    }

    private func date(_ year: Int, _ month: Int, _ day: Int) -> Date {
        DateComponents(calendar: calendar, year: year, month: month, day: day).date!
    }
}
