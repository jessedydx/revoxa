import Foundation

struct InsightsCalculator {
    var billingCalculator: BillingCalculator
    var valueReviewCalculator: ValueReviewCalculator

    init(
        billingCalculator: BillingCalculator = BillingCalculator(),
        valueReviewCalculator: ValueReviewCalculator? = nil
    ) {
        self.billingCalculator = billingCalculator
        self.valueReviewCalculator = valueReviewCalculator ?? ValueReviewCalculator(billingCalculator: billingCalculator)
    }

    func summary(
        for subscriptions: [Subscription],
        exchangeRates: ExchangeRateSnapshot? = nil,
        displayCurrencyCode: String = RevoxaCurrency.defaultCode
    ) -> InsightsSummary {
        let spendSubscriptions = subscriptions.filter(\.isActiveLike)
        let categoryTotals = categoryTotals(
            for: spendSubscriptions,
            exchangeRates: exchangeRates,
            displayCurrencyCode: displayCurrencyCode
        )
        let topSubscriptions = spendSubscriptions
            .sorted {
                displayMonthlyCost(
                    for: $0,
                    exchangeRates: exchangeRates,
                    displayCurrencyCode: displayCurrencyCode
                )
                    > displayMonthlyCost(
                        for: $1,
                        exchangeRates: exchangeRates,
                        displayCurrencyCode: displayCurrencyCode
                    )
            }
            .prefix(10)
            .map {
                ExpensiveSubscription(
                    subscription: $0,
                    estimatedMonthlyCost: billingCalculator.estimatedMonthlyCost(for: $0),
                    estimatedYearlyCost: billingCalculator.estimatedYearlyCost(for: $0)
                )
            }
        let statusDistribution = SubscriptionStatus.allCases.map { status in
            StatusDistribution(status: status, count: subscriptions.filter { $0.status == status }.count)
        }

        return InsightsSummary(
            categoryTotals: categoryTotals,
            topSubscriptions: Array(topSubscriptions),
            statusDistribution: statusDistribution,
            lowValueSubscriptions: valueReviewCalculator.lowValueSubscriptions(from: subscriptions),
            rarelyUsedSubscriptions: valueReviewCalculator.rarelyUsedSubscriptions(from: subscriptions),
            savingsOpportunities: valueReviewCalculator.savingsOpportunities(from: subscriptions)
        )
    }

    private func categoryTotals(
        for subscriptions: [Subscription],
        exchangeRates: ExchangeRateSnapshot?,
        displayCurrencyCode: String
    ) -> [CategorySpendTotal] {
        if let exchangeRates,
           let convertedTotals = convertedCategoryTotals(
            for: subscriptions,
            exchangeRates: exchangeRates,
            displayCurrencyCode: displayCurrencyCode
           ) {
            return convertedTotals
        }

        return categoryTotalsGroupedByCurrency(for: subscriptions)
    }

    private func convertedCategoryTotals(
        for subscriptions: [Subscription],
        exchangeRates: ExchangeRateSnapshot,
        displayCurrencyCode: String
    ) -> [CategorySpendTotal]? {
        var grouped: [SubscriptionCategory: (monthly: Decimal, yearly: Decimal)] = [:]
        let targetCurrencyCode = Subscription.sanitizedCurrencyCode(displayCurrencyCode)

        for subscription in subscriptions {
            let monthly = billingCalculator.estimatedMonthlyCost(for: subscription)
            let yearly = billingCalculator.estimatedYearlyCost(for: subscription)
            guard let convertedMonthly = exchangeRates.convert(
                monthly,
                from: subscription.currencyCode,
                to: targetCurrencyCode
            ),
            let convertedYearly = exchangeRates.convert(
                yearly,
                from: subscription.currencyCode,
                to: targetCurrencyCode
            )
            else {
                return nil
            }

            grouped[subscription.category, default: (Decimal.zero, Decimal.zero)].monthly += convertedMonthly
            grouped[subscription.category, default: (Decimal.zero, Decimal.zero)].yearly += convertedYearly
        }

        return grouped
            .map {
                CategorySpendTotal(
                    currencyCode: targetCurrencyCode,
                    category: $0.key,
                    estimatedMonthlyTotal: $0.value.monthly,
                    estimatedYearlyTotal: $0.value.yearly
                )
            }
            .sorted { $0.estimatedMonthlyTotal > $1.estimatedMonthlyTotal }
    }

    private func categoryTotalsGroupedByCurrency(for subscriptions: [Subscription]) -> [CategorySpendTotal] {
        struct Key: Hashable {
            let currencyCode: String
            let category: SubscriptionCategory
        }

        let grouped = subscriptions.reduce(into: [Key: (monthly: Decimal, yearly: Decimal)]()) { result, subscription in
            let key = Key(
                currencyCode: Subscription.sanitizedCurrencyCode(subscription.currencyCode),
                category: subscription.category
            )
            result[key, default: (Decimal.zero, Decimal.zero)].monthly += billingCalculator.estimatedMonthlyCost(for: subscription)
            result[key, default: (Decimal.zero, Decimal.zero)].yearly += billingCalculator.estimatedYearlyCost(for: subscription)
        }

        return grouped
            .map {
                CategorySpendTotal(
                    currencyCode: $0.key.currencyCode,
                    category: $0.key.category,
                    estimatedMonthlyTotal: $0.value.monthly,
                    estimatedYearlyTotal: $0.value.yearly
                )
            }
            .sorted {
                if $0.currencyCode == $1.currencyCode {
                    return $0.estimatedMonthlyTotal > $1.estimatedMonthlyTotal
                }

                return $0.currencyCode < $1.currencyCode
            }
    }

    private func displayMonthlyCost(
        for subscription: Subscription,
        exchangeRates: ExchangeRateSnapshot?,
        displayCurrencyCode: String
    ) -> Decimal {
        let monthlyCost = billingCalculator.estimatedMonthlyCost(for: subscription)
        return CurrencyDisplay.convertedAmount(
            monthlyCost,
            from: subscription.currencyCode,
            to: displayCurrencyCode,
            using: exchangeRates
        ).amount
    }
}

struct InsightsSummary {
    let categoryTotals: [CategorySpendTotal]
    let topSubscriptions: [ExpensiveSubscription]
    let statusDistribution: [StatusDistribution]
    let lowValueSubscriptions: [Subscription]
    let rarelyUsedSubscriptions: [Subscription]
    let savingsOpportunities: [Subscription]
}

struct CategorySpendTotal: Identifiable, Equatable {
    var id: String { "\(currencyCode)-\(category.rawValue)" }
    let currencyCode: String
    let category: SubscriptionCategory
    let estimatedMonthlyTotal: Decimal
    let estimatedYearlyTotal: Decimal
}

struct ExpensiveSubscription: Identifiable {
    var id: UUID { subscription.id }
    let subscription: Subscription
    let estimatedMonthlyCost: Decimal
    let estimatedYearlyCost: Decimal
}

struct StatusDistribution: Identifiable, Equatable {
    var id: SubscriptionStatus { status }
    let status: SubscriptionStatus
    let count: Int
}
