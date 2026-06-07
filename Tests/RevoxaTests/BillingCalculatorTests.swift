import Foundation
import Testing
@testable import Revoxa

struct BillingCalculatorTests {
    private let calculator = BillingCalculator(calendar: Calendar(identifier: .gregorian))
    private let referenceDate = DateComponents(
        calendar: Calendar(identifier: .gregorian),
        year: 2026,
        month: 5,
        day: 30
    ).date!

    @Test
    func weeklySubscriptionCalculatesCostsAndNextDate() {
        let subscription = makeSubscription(
            amount: Decimal(10),
            cycle: .weekly,
            nextBillingDate: date(2026, 5, 29)
        )

        #expect(calculator.estimatedYearlyCost(for: subscription) == Decimal(520))
        #expect(calculator.estimatedMonthlyCost(for: subscription) == Decimal(520) / Decimal(12))
        #expect(calculator.nextBillingDate(for: subscription, after: referenceDate) == date(2026, 6, 5))
    }

    @Test
    func monthlySubscriptionCalculatesCostsAndNextDate() {
        let subscription = makeSubscription(
            amount: Decimal(15),
            cycle: .monthly,
            nextBillingDate: date(2026, 5, 15)
        )

        #expect(calculator.estimatedYearlyCost(for: subscription) == Decimal(180))
        #expect(calculator.estimatedMonthlyCost(for: subscription) == Decimal(15))
        #expect(calculator.nextBillingDate(for: subscription, after: referenceDate) == date(2026, 6, 15))
    }

    @Test
    func quarterlySubscriptionCalculatesCostsAndNextDate() {
        let subscription = makeSubscription(
            amount: Decimal(30),
            cycle: .quarterly,
            nextBillingDate: date(2026, 2, 28)
        )

        #expect(calculator.estimatedYearlyCost(for: subscription) == Decimal(120))
        #expect(calculator.estimatedMonthlyCost(for: subscription) == Decimal(10))
        #expect(calculator.nextBillingDate(for: subscription, after: referenceDate) == date(2026, 8, 28))
    }

    @Test
    func yearlySubscriptionCalculatesCostsAndNextDate() {
        let subscription = makeSubscription(
            amount: Decimal(120),
            cycle: .yearly,
            nextBillingDate: date(2025, 12, 1)
        )

        #expect(calculator.estimatedYearlyCost(for: subscription) == Decimal(120))
        #expect(calculator.estimatedMonthlyCost(for: subscription) == Decimal(10))
        #expect(calculator.nextBillingDate(for: subscription, after: referenceDate) == date(2026, 12, 1))
    }

    @Test
    func customDaySubscriptionCalculatesCostsAndNextDate() {
        let subscription = makeSubscription(
            amount: Decimal(10),
            cycle: .customDays,
            customDays: 10,
            nextBillingDate: date(2026, 5, 20)
        )

        #expect(calculator.estimatedYearlyCost(for: subscription) == Decimal(365))
        #expect(calculator.estimatedMonthlyCost(for: subscription) == Decimal(365) / Decimal(12))
        #expect(calculator.nextBillingDate(for: subscription, after: referenceDate) == date(2026, 5, 30))
    }

    @Test
    func allBillingCyclesCalculateExpectedMonthlyAndYearlyCosts() {
        let cases: [(BillingCycle, Int?, Decimal, Decimal)] = [
            (.weekly, nil, Decimal(520) / Decimal(12), Decimal(520)),
            (.monthly, nil, Decimal(10), Decimal(120)),
            (.quarterly, nil, Decimal(40) / Decimal(12), Decimal(40)),
            (.yearly, nil, Decimal(10) / Decimal(12), Decimal(10)),
            (.customDays, 10, Decimal(365) / Decimal(12), Decimal(365))
        ]

        for (cycle, customDays, expectedMonthly, expectedYearly) in cases {
            let subscription = makeSubscription(
                amount: Decimal(10),
                cycle: cycle,
                customDays: customDays,
                nextBillingDate: date(2026, 6, 10)
            )

            #expect(calculator.estimatedMonthlyCost(for: subscription) == expectedMonthly)
            #expect(calculator.estimatedYearlyCost(for: subscription) == expectedYearly)
        }
    }

    @Test
    func cashbackReducesEstimatedCostsWithoutGoingNegative() {
        let subscription = makeSubscription(
            amount: Decimal(100),
            cashbackAmount: Decimal(25),
            cycle: .monthly,
            nextBillingDate: date(2026, 6, 10)
        )
        let fullyDiscounted = makeSubscription(
            amount: Decimal(10),
            cashbackAmount: Decimal(50),
            cycle: .monthly,
            nextBillingDate: date(2026, 6, 10)
        )

        #expect(calculator.netBillingAmount(for: subscription) == Decimal(75))
        #expect(calculator.estimatedMonthlyCost(for: subscription) == Decimal(75))
        #expect(calculator.estimatedYearlyCost(for: subscription) == Decimal(900))
        #expect(calculator.netBillingAmount(for: fullyDiscounted) == Decimal.zero)
        #expect(calculator.estimatedMonthlyCost(for: fullyDiscounted) == Decimal.zero)
    }

    @Test
    func pastNextBillingDateAdvancesUntilFutureDate() {
        let subscription = makeSubscription(
            amount: Decimal(5),
            cycle: .monthly,
            nextBillingDate: date(2026, 1, 30)
        )

        #expect(calculator.nextBillingDate(for: subscription, after: referenceDate) == date(2026, 5, 30))
    }

    @Test
    func upcomingPaymentCheckUsesComputedNextBillingDate() {
        let upcoming = makeSubscription(
            amount: Decimal(5),
            cycle: .monthly,
            nextBillingDate: date(2026, 6, 4)
        )
        let later = makeSubscription(
            amount: Decimal(5),
            cycle: .monthly,
            nextBillingDate: date(2026, 6, 20)
        )

        #expect(calculator.daysUntilNextBilling(for: upcoming, after: referenceDate) == 5)
        #expect(calculator.isUpcoming(upcoming, withinDays: 7, after: referenceDate))
        #expect(calculator.isUpcoming(later, withinDays: 7, after: referenceDate) == false)
    }

    private func makeSubscription(
        amount: Decimal,
        cashbackAmount: Decimal? = nil,
        cycle: BillingCycle,
        customDays: Int? = nil,
        nextBillingDate: Date
    ) -> Subscription {
        Subscription(
            name: "Test",
            amount: amount,
            cashbackAmount: cashbackAmount,
            currencyCode: "USD",
            billingCycle: cycle,
            customBillingDays: customDays,
            nextBillingDate: nextBillingDate,
            category: .other,
            paymentMethod: .creditCard
        )
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
