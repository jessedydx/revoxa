import Foundation

struct ValueReviewCalculator {
    var billingCalculator: BillingCalculator

    init(billingCalculator: BillingCalculator = BillingCalculator()) {
        self.billingCalculator = billingCalculator
    }

    func isRecommendedCancellationCandidate(_ subscription: Subscription) -> Bool {
        guard subscription.isActiveLike else { return false }
        let lowUsage = subscription.usageFrequency == .rarely || subscription.usageFrequency == .never
        return lowUsage && subscription.valueRating == .low
    }

    func appearsOnCancelList(_ subscription: Subscription) -> Bool {
        subscription.isCancellationCandidate || isRecommendedCancellationCandidate(subscription)
    }

    func qualifiesForPotentialSaving(_ subscription: Subscription) -> Bool {
        guard subscription.isActiveLike else { return false }
        return subscription.isCancellationCandidate
            || isRecommendedCancellationCandidate(subscription)
            || subscription.valueRating == .low
    }

    func computedPotentialMonthlySaving(for subscription: Subscription) -> Decimal {
        guard qualifiesForPotentialSaving(subscription) else { return .zero }
        return billingCalculator.estimatedMonthlyCost(for: subscription)
    }

    func refreshStoredMetrics(for subscription: Subscription, markReviewed: Bool = true) {
        let saving = computedPotentialMonthlySaving(for: subscription)
        subscription.potentialMonthlySaving = saving > .zero ? saving : nil
        if markReviewed {
            subscription.lastReviewedAt = .now
        }
    }

    func potentialMonthlySavings(for subscriptions: [Subscription]) -> [CurrencyTotal] {
        let eligible = subscriptions.filter(qualifiesForPotentialSaving)
        let grouped = eligible.reduce(into: [String: Decimal]()) { partialResult, subscription in
            let amount = subscription.potentialMonthlySaving ?? computedPotentialMonthlySaving(for: subscription)
            guard amount > .zero else { return }
            let currencyCode = Subscription.sanitizedCurrencyCode(subscription.currencyCode)
            partialResult[currencyCode, default: .zero] += amount
        }

        return grouped
            .map { CurrencyTotal(currencyCode: $0.key, amount: $0.value) }
            .sorted { $0.currencyCode < $1.currencyCode }
    }

    func lowValueSubscriptions(from subscriptions: [Subscription]) -> [Subscription] {
        subscriptions
            .filter { $0.isActiveLike && $0.valueRating == .low }
            .sorted {
                billingCalculator.estimatedMonthlyCost(for: $0) > billingCalculator.estimatedMonthlyCost(for: $1)
            }
    }

    func rarelyUsedSubscriptions(from subscriptions: [Subscription]) -> [Subscription] {
        subscriptions
            .filter { $0.isActiveLike && ($0.usageFrequency == .rarely || $0.usageFrequency == .never) }
            .sorted {
                billingCalculator.estimatedMonthlyCost(for: $0) > billingCalculator.estimatedMonthlyCost(for: $1)
            }
    }

    func savingsOpportunities(from subscriptions: [Subscription]) -> [Subscription] {
        subscriptions
            .filter(qualifiesForPotentialSaving)
            .sorted {
                let left = $0.potentialMonthlySaving ?? computedPotentialMonthlySaving(for: $0)
                let right = $1.potentialMonthlySaving ?? computedPotentialMonthlySaving(for: $1)
                return left > right
            }
    }
}
