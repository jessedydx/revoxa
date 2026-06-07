import Foundation

struct SubscriptionFormState {
    var name: String
    var amountText: String
    var cashbackAmountText: String
    var currencyCode: String
    var billingCycle: BillingCycle
    var customBillingDays: Int
    var nextBillingDate: Date?
    var category: SubscriptionCategory
    var paymentMethod: PaymentMethod
    var status: SubscriptionStatus
    var reminderDaysBefore: Int
    var cancellationURLText: String
    var notes: String
    var templateID: String?
    var usageFrequency: UsageFrequency
    var valueRating: ValueRating
    var cancelReason: CancelReason?
    var potentialMonthlySavingText: String
    var lastReviewedAt: Date?

    init(subscription: Subscription? = nil) {
        self.name = subscription?.name ?? ""
        self.amountText = subscription.map { DecimalInputFormatter.editingString(from: $0.amount) } ?? ""
        self.cashbackAmountText = subscription?.cashbackAmount.map {
            DecimalInputFormatter.editingString(from: $0)
        } ?? ""
        self.currencyCode = subscription?.currencyCode ?? RevoxaCurrency.defaultCode
        self.billingCycle = subscription?.billingCycle ?? .monthly
        self.customBillingDays = subscription?.customBillingDays ?? 30
        self.nextBillingDate = subscription?.nextBillingDate ?? .now
        self.category = subscription?.category ?? .other
        self.paymentMethod = subscription?.paymentMethod ?? .creditCard
        self.status = subscription?.status ?? .active
        self.reminderDaysBefore = subscription?.reminderDaysBefore ?? 3
        self.cancellationURLText = subscription?.cancellationURL?.absoluteString ?? ""
        self.notes = subscription?.notes ?? ""
        self.templateID = subscription?.subscriptionTemplate?.id
        self.usageFrequency = subscription?.usageFrequency ?? .monthly
        self.valueRating = subscription?.valueRating ?? .unknown
        self.cancelReason = subscription?.cancelReason
        self.potentialMonthlySavingText = subscription?.potentialMonthlySaving.map {
            DecimalInputFormatter.editingString(from: $0)
        } ?? ""
        self.lastReviewedAt = subscription?.lastReviewedAt
    }

    var trimmedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var trimmedCurrencyCode: String {
        currencyCode.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
    }

    var parsedAmount: Decimal? {
        DecimalInputFormatter.decimal(from: amountText)
    }

    var parsedCashbackAmount: Decimal? {
        let trimmed = cashbackAmountText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.isEmpty == false else { return nil }
        return DecimalInputFormatter.decimal(from: trimmed)
    }

    var parsedPotentialMonthlySaving: Decimal? {
        let trimmed = potentialMonthlySavingText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.isEmpty == false else { return nil }
        return DecimalInputFormatter.decimal(from: trimmed)
    }

    var parsedCancellationURL: URL? {
        let trimmed = cancellationURLText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.isEmpty == false else { return nil }
        return URL(string: trimmed)
    }

    func validationErrors() -> [String] {
        var errors: [String] = []

        if trimmedName.isEmpty {
            errors.append(L10n.t("validation.nameEmpty"))
        }

        guard let parsedAmount else {
            errors.append(L10n.t("validation.amountInvalid"))
            return errors
        }

        if parsedAmount <= Decimal.zero {
            errors.append(L10n.t("validation.amountPositive"))
        }

        let trimmedCashback = cashbackAmountText.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmedCashback.isEmpty == false && parsedCashbackAmount == nil {
            errors.append(L10n.t("validation.cashbackInvalid"))
        }

        if let parsedCashbackAmount, parsedCashbackAmount < .zero {
            errors.append(L10n.t("validation.cashbackNegative"))
        }

        if trimmedCurrencyCode.isEmpty {
            errors.append(L10n.t("validation.currencyEmpty"))
        }

        if nextBillingDate == nil {
            errors.append(L10n.t("validation.nextBillingRequired"))
        }

        if billingCycle == .customDays && customBillingDays < 1 {
            errors.append(L10n.t("validation.customDaysMin"))
        }

        let trimmedURL = cancellationURLText.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmedURL.isEmpty == false && isValidCancellationURL == false {
            errors.append(L10n.t("validation.cancelURLInvalid"))
        }

        let trimmedSaving = potentialMonthlySavingText.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmedSaving.isEmpty == false && parsedPotentialMonthlySaving == nil {
            errors.append(L10n.t("validation.savingInvalid"))
        }

        if let parsedPotentialMonthlySaving, parsedPotentialMonthlySaving < .zero {
            errors.append(L10n.t("validation.savingNegative"))
        }

        return errors
    }

    var isValidCancellationURL: Bool {
        let trimmed = cancellationURLText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.isEmpty == false else { return true }
        guard let url = URL(string: trimmed),
              let scheme = url.scheme?.lowercased(),
              ["http", "https"].contains(scheme),
              url.host?.isEmpty == false
        else {
            return false
        }

        return true
    }

    func makeSubscription() -> Subscription? {
        guard validationErrors().isEmpty,
              let parsedAmount,
              let nextBillingDate
        else {
            return nil
        }

        let subscription = Subscription(
            name: trimmedName,
            amount: parsedAmount,
            cashbackAmount: parsedCashbackAmount,
            currencyCode: trimmedCurrencyCode,
            billingCycle: billingCycle,
            customBillingDays: customBillingDays,
            nextBillingDate: nextBillingDate,
            category: category,
            paymentMethod: paymentMethod,
            status: status,
            reminderDaysBefore: reminderDaysBefore,
            cancellationURL: parsedCancellationURL,
            notes: notes,
            templateID: templateID,
            usageFrequency: usageFrequency,
            valueRating: valueRating,
            cancelReason: cancelReason,
            potentialMonthlySaving: parsedPotentialMonthlySaving,
            lastReviewedAt: .now
        )
        ValueReviewCalculator().refreshStoredMetrics(for: subscription, markReviewed: false)
        return subscription
    }

    func apply(to subscription: Subscription) -> Bool {
        guard validationErrors().isEmpty,
              let parsedAmount,
              let nextBillingDate
        else {
            return false
        }

        subscription.update(
            name: trimmedName,
            amount: parsedAmount,
            cashbackAmount: parsedCashbackAmount,
            currencyCode: trimmedCurrencyCode,
            billingCycle: billingCycle,
            customBillingDays: customBillingDays,
            nextBillingDate: nextBillingDate,
            category: category,
            paymentMethod: paymentMethod,
            status: status,
            reminderDaysBefore: reminderDaysBefore,
            cancellationURL: parsedCancellationURL,
            notes: notes,
            templateID: templateID,
            usageFrequency: usageFrequency,
            valueRating: valueRating,
            cancelReason: cancelReason,
            potentialMonthlySaving: parsedPotentialMonthlySaving,
            lastReviewedAt: .now
        )
        ValueReviewCalculator().refreshStoredMetrics(for: subscription, markReviewed: false)

        return true
    }

    mutating func apply(template: SubscriptionTemplate, defaultCurrencyCode: String) {
        templateID = template.id
        name = template.displayName
        currencyCode = RevoxaCurrency.resolved(from: defaultCurrencyCode).code
        billingCycle = template.defaultBillingCycle
        category = template.category
        paymentMethod = template.defaultPaymentMethod
        cancellationURLText = template.cancellationURL?.absoluteString ?? ""
    }
}
