import Foundation

struct BillingOccurrence: Identifiable, Equatable {
    let subscription: Subscription
    let date: Date

    var id: String {
        "\(subscription.id.uuidString)-\(date.timeIntervalSinceReferenceDate)"
    }
}

/// Projects billing dates onto calendar months and sums actual payment amounts per month.
struct BillingScheduleCalculator {
    var billingCalculator: BillingCalculator
    var calendar: Calendar

    init(
        billingCalculator: BillingCalculator = BillingCalculator(calendar: Self.makeCalendar()),
        calendar: Calendar? = nil
    ) {
        self.billingCalculator = billingCalculator
        self.calendar = calendar ?? billingCalculator.calendar
    }

    static func makeCalendar() -> Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = RevoxaLanguageSettings.resolvedLocale
        calendar.firstWeekday = 2
        return calendar
    }

    func monthInterval(containing date: Date) -> DateInterval {
        let components = calendar.dateComponents([.year, .month], from: date)
        let start = calendar.date(from: components) ?? calendar.startOfDay(for: date)
        let end = calendar.date(byAdding: .month, value: 1, to: start) ?? start
        return DateInterval(start: start, end: end)
    }

    func occurrences(for subscription: Subscription, in monthInterval: DateInterval) -> [BillingOccurrence] {
        var candidate = subscription.nextBillingDate
        var guardCount = 0

        while calendar.startOfDay(for: candidate) < monthInterval.start, guardCount < 600 {
            candidate = advancedDate(
                candidate,
                cycle: subscription.billingCycle,
                customDays: subscription.customBillingDays,
                anchorDate: subscription.nextBillingDate
            )
            guardCount += 1
        }

        var occurrences: [BillingOccurrence] = []
        while calendar.startOfDay(for: candidate) < monthInterval.end, guardCount < 700 {
            occurrences.append(BillingOccurrence(subscription: subscription, date: candidate))
            candidate = advancedDate(
                candidate,
                cycle: subscription.billingCycle,
                customDays: subscription.customBillingDays,
                anchorDate: subscription.nextBillingDate
            )
            guardCount += 1
        }

        return occurrences
    }

    func yearInterval(containing date: Date) -> DateInterval {
        let year = calendar.component(.year, from: date)
        let start = calendar.date(from: DateComponents(year: year, month: 1, day: 1)) ?? calendar.startOfDay(for: date)
        let end = calendar.date(byAdding: .year, value: 1, to: start) ?? start
        return DateInterval(start: start, end: end)
    }

    func categoryPaymentTotals(
        for subscriptions: [Subscription],
        in interval: DateInterval,
        exchangeRates: ExchangeRateSnapshot? = nil,
        displayCurrencyCode: String = RevoxaCurrency.defaultCode
    ) -> [CategoryPaymentTotal] {
        if let exchangeRates,
           let convertedTotals = convertedCategoryPaymentTotals(
            for: subscriptions,
            in: interval,
            exchangeRates: exchangeRates,
            displayCurrencyCode: displayCurrencyCode
           ) {
            return convertedTotals
        }

        return categoryPaymentTotalsGroupedByCurrency(for: subscriptions, in: interval)
    }

    func paymentTotals(for subscriptions: [Subscription], in monthInterval: DateInterval) -> [CurrencyTotal] {
        let groupedTotals = subscriptions.flatMap { subscription in
            occurrences(for: subscription, in: monthInterval)
        }
        .reduce(into: [String: Decimal]()) { partialResult, occurrence in
            let subscription = occurrence.subscription
            let currencyCode = Subscription.sanitizedCurrencyCode(subscription.currencyCode)
            partialResult[currencyCode, default: .zero] += billingCalculator.netBillingAmount(for: subscription)
        }

        return groupedTotals
            .map { CurrencyTotal(currencyCode: $0.key, amount: $0.value) }
            .sorted { $0.currencyCode < $1.currencyCode }
    }

    private func convertedCategoryPaymentTotals(
        for subscriptions: [Subscription],
        in interval: DateInterval,
        exchangeRates: ExchangeRateSnapshot,
        displayCurrencyCode: String
    ) -> [CategoryPaymentTotal]? {
        var grouped: [SubscriptionCategory: Decimal] = [:]
        let targetCurrencyCode = Subscription.sanitizedCurrencyCode(displayCurrencyCode)

        for subscription in subscriptions {
            let paymentAmount = billingCalculator.netBillingAmount(for: subscription)
            let occurrenceCount = occurrences(for: subscription, in: interval).count
            guard occurrenceCount > 0 else { continue }

            let totalForSubscription = paymentAmount * Decimal(occurrenceCount)
            guard let convertedAmount = exchangeRates.convert(
                totalForSubscription,
                from: subscription.currencyCode,
                to: targetCurrencyCode
            ) else {
                return nil
            }

            grouped[subscription.category, default: .zero] += convertedAmount
        }

        return grouped
            .map {
                CategoryPaymentTotal(
                    category: $0.key,
                    amount: $0.value,
                    currencyCode: targetCurrencyCode
                )
            }
            .sorted { $0.amount > $1.amount }
    }

    private func categoryPaymentTotalsGroupedByCurrency(
        for subscriptions: [Subscription],
        in interval: DateInterval
    ) -> [CategoryPaymentTotal] {
        struct Key: Hashable {
            let category: SubscriptionCategory
            let currencyCode: String
        }

        let grouped = subscriptions.reduce(into: [Key: Decimal]()) { result, subscription in
            let paymentAmount = billingCalculator.netBillingAmount(for: subscription)
            let occurrenceCount = occurrences(for: subscription, in: interval).count
            guard occurrenceCount > 0 else { return }

            let key = Key(
                category: subscription.category,
                currencyCode: Subscription.sanitizedCurrencyCode(subscription.currencyCode)
            )
            result[key, default: .zero] += paymentAmount * Decimal(occurrenceCount)
        }

        return grouped
            .map {
                CategoryPaymentTotal(
                    category: $0.key.category,
                    amount: $0.value,
                    currencyCode: $0.key.currencyCode
                )
            }
            .sorted {
                if $0.currencyCode == $1.currencyCode {
                    return $0.amount > $1.amount
                }

                return $0.currencyCode < $1.currencyCode
            }
    }

    private func advancedDate(
        _ date: Date,
        cycle: BillingCycle,
        customDays: Int?,
        anchorDate: Date
    ) -> Date {
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
}

struct CategoryPaymentTotal: Identifiable, Equatable {
    var id: String { "\(currencyCode)-\(category.rawValue)" }
    let category: SubscriptionCategory
    let amount: Decimal
    let currencyCode: String
}
