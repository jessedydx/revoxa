import Foundation

struct BillingCalculator {
    var calendar: Calendar

    init(calendar: Calendar = .current) {
        self.calendar = calendar
    }

    func nextBillingDate(for subscription: Subscription, after date: Date = .now) -> Date {
        nextBillingDate(
            from: subscription.nextBillingDate,
            cycle: subscription.billingCycle,
            customDays: subscription.customBillingDays,
            after: date
        )
    }

    func nextBillingDate(
        from billingDate: Date,
        cycle: BillingCycle,
        customDays: Int?,
        after date: Date = .now
    ) -> Date {
        let comparisonDay = calendar.startOfDay(for: date)
        guard calendar.startOfDay(for: billingDate) < comparisonDay else {
            return billingDate
        }

        var candidate = billingDate
        while calendar.startOfDay(for: candidate) < comparisonDay {
            candidate = advancedDate(candidate, cycle: cycle, customDays: customDays, anchorDate: billingDate)
        }

        return candidate
    }

    func estimatedMonthlyCost(for subscription: Subscription) -> Decimal {
        estimatedYearlyCost(for: subscription) / Decimal(12)
    }

    func estimatedYearlyCost(for subscription: Subscription) -> Decimal {
        let netAmount = netBillingAmount(for: subscription)

        return switch subscription.billingCycle {
        case .weekly:
            netAmount * Decimal(52)
        case .monthly:
            netAmount * Decimal(12)
        case .quarterly:
            netAmount * Decimal(4)
        case .yearly:
            netAmount
        case .customDays:
            netAmount * Decimal(365) / Decimal(subscription.customBillingDays ?? 30)
        }
    }

    func netBillingAmount(for subscription: Subscription) -> Decimal {
        max(subscription.amount - (subscription.cashbackAmount ?? .zero), Decimal.zero)
    }

    func isUpcoming(_ subscription: Subscription, withinDays days: Int, after date: Date = .now) -> Bool {
        guard days >= 0 else { return false }
        let nextDate = nextBillingDate(for: subscription, after: date)
        let remainingDays = daysUntil(nextDate, from: date)
        return remainingDays >= 0 && remainingDays <= days
    }

    func daysUntilNextBilling(for subscription: Subscription, after date: Date = .now) -> Int {
        let nextDate = nextBillingDate(for: subscription, after: date)
        return daysUntil(nextDate, from: date)
    }

    private func advancedDate(_ date: Date, cycle: BillingCycle, customDays: Int?, anchorDate: Date) -> Date {
        switch cycle {
        case .weekly:
            calendar.date(byAdding: .day, value: 7, to: date) ?? date
        case .monthly:
            advancedMonthDate(date, by: 1, anchorDate: anchorDate)
        case .quarterly:
            advancedMonthDate(date, by: 3, anchorDate: anchorDate)
        case .yearly:
            advancedMonthDate(date, by: 12, anchorDate: anchorDate)
        case .customDays:
            calendar.date(byAdding: .day, value: max(customDays ?? 30, 1), to: date) ?? date
        }
    }

    private func advancedMonthDate(_ date: Date, by months: Int, anchorDate: Date) -> Date {
        guard let advanced = calendar.date(byAdding: .month, value: months, to: date) else {
            return date
        }

        let anchorDay = calendar.component(.day, from: anchorDate)
        let dayRange = calendar.range(of: .day, in: .month, for: advanced)
        let targetDay = min(anchorDay, dayRange?.count ?? anchorDay)
        var components = calendar.dateComponents([.year, .month, .hour, .minute, .second, .nanosecond], from: advanced)
        components.day = targetDay

        return calendar.date(from: components) ?? advanced
    }

    private func daysUntil(_ targetDate: Date, from date: Date) -> Int {
        let start = calendar.startOfDay(for: date)
        let end = calendar.startOfDay(for: targetDate)
        return calendar.dateComponents([.day], from: start, to: end).day ?? 0
    }
}

extension Subscription {
    func nextBillingDate(after date: Date = .now, using calculator: BillingCalculator = BillingCalculator()) -> Date {
        calculator.nextBillingDate(for: self, after: date)
    }

    func estimatedMonthlyCost(using calculator: BillingCalculator = BillingCalculator()) -> Decimal {
        calculator.estimatedMonthlyCost(for: self)
    }

    func estimatedYearlyCost(using calculator: BillingCalculator = BillingCalculator()) -> Decimal {
        calculator.estimatedYearlyCost(for: self)
    }

    func isUpcoming(withinDays days: Int, after date: Date = .now, using calculator: BillingCalculator = BillingCalculator()) -> Bool {
        calculator.isUpcoming(self, withinDays: days, after: date)
    }

    func daysUntilNextBilling(after date: Date = .now, using calculator: BillingCalculator = BillingCalculator()) -> Int {
        calculator.daysUntilNextBilling(for: self, after: date)
    }

    var monthlyCostEstimate: Decimal {
        estimatedMonthlyCost()
    }

    var yearlyCostEstimate: Decimal {
        estimatedYearlyCost()
    }

    var daysUntilNextBilling: Int {
        daysUntilNextBilling()
    }
}
