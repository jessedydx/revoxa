import Foundation

struct DashboardCalculator {
    var billingCalculator: BillingCalculator
    var billingSchedule: BillingScheduleCalculator
    var valueReviewCalculator: ValueReviewCalculator

    init(
        billingCalculator: BillingCalculator = BillingCalculator(calendar: BillingScheduleCalculator.makeCalendar()),
        billingSchedule: BillingScheduleCalculator? = nil,
        valueReviewCalculator: ValueReviewCalculator? = nil
    ) {
        self.billingCalculator = billingCalculator
        self.billingSchedule = billingSchedule ?? BillingScheduleCalculator(billingCalculator: billingCalculator)
        self.valueReviewCalculator = valueReviewCalculator ?? ValueReviewCalculator(billingCalculator: billingCalculator)
    }

    func summary(for subscriptions: [Subscription], asOf date: Date = .now) -> DashboardSummary {
        let includedSubscriptions = subscriptions.filter(\.isActiveLike)
        let monthInterval = billingSchedule.monthInterval(containing: date)
        let monthlyTotals = billingSchedule.paymentTotals(for: includedSubscriptions, in: monthInterval)
        let yearlyTotals = totalsByCurrency(for: includedSubscriptions, estimate: billingCalculator.estimatedYearlyCost)
        let sortedByMonthlyCost = includedSubscriptions.sorted {
            billingCalculator.estimatedMonthlyCost(for: $0) > billingCalculator.estimatedMonthlyCost(for: $1)
        }
        let upcomingPayments = includedSubscriptions
            .map { DashboardPayment(subscription: $0, nextBillingDate: billingCalculator.nextBillingDate(for: $0, after: date), daysUntil: billingCalculator.daysUntilNextBilling(for: $0, after: date)) }
            .sorted { $0.nextBillingDate < $1.nextBillingDate }
        let cancellationCandidates = subscriptions
            .filter(\.appearsOnCancelList)
            .sorted { $0.nextBillingDate < $1.nextBillingDate }
        let potentialMonthlySavings = valueReviewCalculator.potentialMonthlySavings(for: subscriptions)

        return DashboardSummary(
            monthlyTotals: monthlyTotals,
            yearlyTotals: yearlyTotals,
            renewalsWithin7Days: upcomingPayments.filter { $0.daysUntil <= 7 }.count,
            renewalsWithin30Days: upcomingPayments.filter { $0.daysUntil <= 30 }.count,
            mostExpensiveSubscription: sortedByMonthlyCost.first,
            cancellationCandidateCount: cancellationCandidates.count,
            potentialMonthlySavings: potentialMonthlySavings,
            upcomingPayments: upcomingPayments,
            topExpensiveSubscriptions: Array(sortedByMonthlyCost.prefix(5)),
            cancellationCandidates: cancellationCandidates
        )
    }

    private func totalsByCurrency(
        for subscriptions: [Subscription],
        estimate: (Subscription) -> Decimal
    ) -> [CurrencyTotal] {
        let groupedTotals = subscriptions.reduce(into: [String: Decimal]()) { partialResult, subscription in
            let currencyCode = Subscription.sanitizedCurrencyCode(subscription.currencyCode)
            partialResult[currencyCode, default: Decimal.zero] += estimate(subscription)
        }

        return groupedTotals
            .map { CurrencyTotal(currencyCode: $0.key, amount: $0.value) }
            .sorted { $0.currencyCode < $1.currencyCode }
    }
}

struct DashboardSummary {
    let monthlyTotals: [CurrencyTotal]
    let yearlyTotals: [CurrencyTotal]
    let renewalsWithin7Days: Int
    let renewalsWithin30Days: Int
    let mostExpensiveSubscription: Subscription?
    let cancellationCandidateCount: Int
    let potentialMonthlySavings: [CurrencyTotal]
    let upcomingPayments: [DashboardPayment]
    let topExpensiveSubscriptions: [Subscription]
    let cancellationCandidates: [Subscription]
}

struct CurrencyTotal: Identifiable, Equatable {
    var id: String { currencyCode }
    let currencyCode: String
    let amount: Decimal
}

struct DashboardPayment: Identifiable {
    var id: UUID { subscription.id }
    let subscription: Subscription
    let nextBillingDate: Date
    let daysUntil: Int
}
