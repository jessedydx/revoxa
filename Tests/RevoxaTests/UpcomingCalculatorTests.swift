import Foundation
import Testing
@testable import Revoxa

struct UpcomingCalculatorTests {
    private let calendar = Calendar(identifier: .gregorian)

    @Test
    func groupsActiveLikeSubscriptionsByPaymentWindow() {
        let calculator = UpcomingCalculator(
            billingCalculator: BillingCalculator(calendar: calendar),
            calendar: calendar
        )
        let subscriptions = [
            makeSubscription(name: "Today", status: .active, nextDate: date(2026, 5, 30)),
            makeSubscription(name: "Week", status: .trial, nextDate: date(2026, 6, 2)),
            makeSubscription(name: "Month", status: .cancelSoon, nextDate: date(2026, 6, 20)),
            makeSubscription(name: "Later", status: .active, nextDate: date(2026, 7, 4)),
            makeSubscription(name: "Cancelled", status: .cancelled, nextDate: date(2026, 5, 30)),
            makeSubscription(name: "Archived", status: .archived, nextDate: date(2026, 5, 30))
        ]

        let groups = calculator.groups(for: subscriptions, asOf: date(2026, 5, 30))

        #expect(groups.map(\.kind) == [.today, .thisWeek, .thisMonth, .later])
        #expect(groups.flatMap(\.payments).map(\.subscription.name) == ["Today", "Week", "Month", "Later"])
    }

    @Test
    func cancelledAndArchivedSubscriptionsAreExcludedFromUpcomingGroups() {
        let calculator = UpcomingCalculator(
            billingCalculator: BillingCalculator(calendar: calendar),
            calendar: calendar
        )
        let subscriptions = [
            makeSubscription(name: "Active", status: .active, nextDate: date(2026, 6, 2)),
            makeSubscription(name: "Cancelled", status: .cancelled, nextDate: date(2026, 6, 2)),
            makeSubscription(name: "Archived", status: .archived, nextDate: date(2026, 6, 2))
        ]

        let groups = calculator.groups(for: subscriptions, asOf: date(2026, 5, 30))

        #expect(groups.flatMap(\.payments).map(\.subscription.name) == ["Active"])
    }

    @Test
    func paymentsAreSortedByComputedNextBillingDate() {
        let calculator = UpcomingCalculator(
            billingCalculator: BillingCalculator(calendar: calendar),
            calendar: calendar
        )
        let subscriptions = [
            makeSubscription(name: "Second", status: .active, nextDate: date(2026, 6, 5)),
            makeSubscription(name: "First", status: .active, nextDate: date(2026, 6, 1)),
            makeSubscription(name: "Past Rolls Forward", status: .active, nextDate: date(2026, 5, 1))
        ]

        let groups = calculator.groups(for: subscriptions, asOf: date(2026, 5, 30))
        let names = groups.flatMap(\.payments).map(\.subscription.name)

        #expect(names == ["First", "Past Rolls Forward", "Second"])
    }

    private func makeSubscription(name: String, status: SubscriptionStatus, nextDate: Date) -> Subscription {
        Subscription(
            name: name,
            amount: Decimal(10),
            currencyCode: "USD",
            billingCycle: .monthly,
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
