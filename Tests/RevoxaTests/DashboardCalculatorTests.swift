import Foundation
import Testing
@testable import Revoxa

struct DashboardCalculatorTests {
    private let calendar = Calendar(identifier: .gregorian)

    @Test
    func summaryIncludesOnlyActiveLikeSubscriptionsInCostTotals() {
        let calculator = DashboardCalculator(
            billingCalculator: BillingCalculator(calendar: calendar)
        )
        let subscriptions = [
            makeSubscription(name: "Active", amount: 10, currency: "USD", cycle: .monthly, status: .active, nextDate: date(2026, 6, 2)),
            makeSubscription(name: "Trial", amount: 20, currency: "USD", cycle: .monthly, status: .trial, nextDate: date(2026, 6, 12)),
            makeSubscription(name: "Cancel Soon", amount: 30, currency: "EUR", cycle: .monthly, status: .cancelSoon, nextDate: date(2026, 7, 1)),
            makeSubscription(name: "Cancelled", amount: 40, currency: "USD", cycle: .monthly, status: .cancelled, nextDate: date(2026, 6, 2)),
            makeSubscription(name: "Archived", amount: 50, currency: "EUR", cycle: .monthly, status: .archived, nextDate: date(2026, 6, 2))
        ]

        let summary = calculator.summary(for: subscriptions, asOf: date(2026, 5, 30))

        #expect(summary.monthlyTotals.isEmpty)
        #expect(summary.yearlyTotals == [
            CurrencyTotal(currencyCode: "EUR", amount: Decimal(360)),
            CurrencyTotal(currencyCode: "USD", amount: Decimal(360))
        ])
        #expect(summary.cancellationCandidateCount == 1)
    }

    @Test
    func archivedAndCancelledSubscriptionsDoNotAffectMostExpensiveOrUpcomingTotals() {
        let calculator = DashboardCalculator(
            billingCalculator: BillingCalculator(calendar: calendar)
        )
        let subscriptions = [
            makeSubscription(name: "Active Cheap", amount: 10, currency: "USD", cycle: .monthly, status: .active, nextDate: date(2026, 6, 2)),
            makeSubscription(name: "Cancelled Expensive", amount: 999, currency: "USD", cycle: .monthly, status: .cancelled, nextDate: date(2026, 6, 2)),
            makeSubscription(name: "Archived Expensive", amount: 999, currency: "EUR", cycle: .monthly, status: .archived, nextDate: date(2026, 6, 2))
        ]

        let summary = calculator.summary(for: subscriptions, asOf: date(2026, 5, 30))

        #expect(summary.monthlyTotals.isEmpty)
        #expect(summary.yearlyTotals == [CurrencyTotal(currencyCode: "USD", amount: Decimal(120))])
        #expect(summary.mostExpensiveSubscription?.name == "Active Cheap")
        #expect(summary.upcomingPayments.map(\.subscription.name) == ["Active Cheap"])
    }

    @Test
    func thisMonthTotalsIncludePaymentsScheduledInCurrentMonth() {
        let calculator = DashboardCalculator(
            billingCalculator: BillingCalculator(calendar: calendar)
        )
        let subscriptions = [
            makeSubscription(
                name: "Due In May",
                amount: 100,
                currency: "TRY",
                cycle: .monthly,
                status: .active,
                nextDate: date(2026, 5, 18)
            ),
            makeSubscription(
                name: "Due In June",
                amount: 999,
                currency: "TRY",
                cycle: .monthly,
                status: .active,
                nextDate: date(2026, 6, 2)
            ),
            makeSubscription(
                name: "Annual",
                amount: 1200,
                currency: "USD",
                cycle: .yearly,
                status: .active,
                nextDate: date(2026, 9, 1)
            )
        ]

        let summary = calculator.summary(for: subscriptions, asOf: date(2026, 5, 30))

        #expect(summary.monthlyTotals == [CurrencyTotal(currencyCode: "TRY", amount: Decimal(100))])
    }

    @Test
    func summaryCalculatesUpcomingWindowsAndLists() {
        let calculator = DashboardCalculator(
            billingCalculator: BillingCalculator(calendar: calendar)
        )
        let subscriptions = [
            makeSubscription(name: "Soon", amount: 10, cycle: .monthly, status: .active, nextDate: date(2026, 6, 2)),
            makeSubscription(name: "Month", amount: 25, cycle: .monthly, status: .trial, nextDate: date(2026, 6, 20)),
            makeSubscription(name: "Later", amount: 50, cycle: .monthly, status: .active, nextDate: date(2026, 8, 1)),
            makeSubscription(name: "Candidate", amount: 8, cycle: .monthly, status: .cancelSoon, nextDate: date(2026, 6, 5))
        ]

        let summary = calculator.summary(for: subscriptions, asOf: date(2026, 5, 30))

        #expect(summary.renewalsWithin7Days == 2)
        #expect(summary.renewalsWithin30Days == 3)
        #expect(summary.mostExpensiveSubscription?.name == "Later")
        #expect(summary.upcomingPayments.map(\.subscription.name).prefix(3) == ["Soon", "Candidate", "Month"])
        #expect(summary.topExpensiveSubscriptions.map(\.name) == ["Later", "Month", "Soon", "Candidate"])
        #expect(summary.cancellationCandidates.map(\.name) == ["Candidate"])
    }

    private func makeSubscription(
        name: String,
        amount: Decimal,
        currency: String = "USD",
        cycle: BillingCycle,
        status: SubscriptionStatus,
        nextDate: Date
    ) -> Subscription {
        Subscription(
            name: name,
            amount: amount,
            currencyCode: currency,
            billingCycle: cycle,
            nextBillingDate: nextDate,
            category: .productivity,
            paymentMethod: .creditCard,
            status: status
        )
    }

    private func date(_ year: Int, _ month: Int, _ day: Int) -> Date {
        DateComponents(calendar: calendar, year: year, month: month, day: day).date!
    }
}
