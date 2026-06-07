import Foundation
import SwiftData

@Model
final class Subscription: Identifiable {
    @Attribute(.unique) var id: UUID
    var name: String
    var amount: Decimal
    var cashbackAmount: Decimal?
    var currencyCode: String
    var billingCycle: BillingCycle
    var customBillingDays: Int?
    var nextBillingDate: Date
    var category: SubscriptionCategory
    var paymentMethod: PaymentMethod
    var status: SubscriptionStatus
    var reminderDaysBefore: Int
    var cancellationURL: URL?
    var notes: String?
    var templateID: String?
    var usageFrequency: UsageFrequency
    var valueRating: ValueRating
    var cancelReason: CancelReason?
    var potentialMonthlySaving: Decimal?
    var lastReviewedAt: Date?
    var createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        name: String,
        amount: Decimal,
        cashbackAmount: Decimal? = nil,
        currencyCode: String,
        billingCycle: BillingCycle,
        customBillingDays: Int? = nil,
        nextBillingDate: Date,
        category: SubscriptionCategory,
        paymentMethod: PaymentMethod,
        status: SubscriptionStatus = .active,
        reminderDaysBefore: Int = 3,
        cancellationURL: URL? = nil,
        notes: String? = nil,
        templateID: String? = nil,
        usageFrequency: UsageFrequency = .monthly,
        valueRating: ValueRating = .unknown,
        cancelReason: CancelReason? = nil,
        potentialMonthlySaving: Decimal? = nil,
        lastReviewedAt: Date? = nil,
        createdAt: Date = .now,
        updatedAt: Date = .now
    ) {
        self.id = id
        self.name = Self.sanitizedName(name)
        self.amount = Self.sanitizedAmount(amount)
        self.cashbackAmount = Self.sanitizedCashbackAmount(cashbackAmount)
        self.currencyCode = Self.sanitizedCurrencyCode(currencyCode)
        self.billingCycle = billingCycle
        self.customBillingDays = Self.sanitizedCustomBillingDays(customBillingDays, billingCycle: billingCycle)
        self.nextBillingDate = nextBillingDate
        self.category = category
        self.paymentMethod = paymentMethod
        self.status = status
        self.reminderDaysBefore = Self.sanitizedReminderDays(reminderDaysBefore)
        self.cancellationURL = cancellationURL
        self.notes = Self.sanitizedOptionalText(notes)
        self.templateID = Self.sanitizedOptionalText(templateID)
        self.usageFrequency = usageFrequency
        self.valueRating = valueRating
        self.cancelReason = cancelReason
        self.potentialMonthlySaving = Self.sanitizedPotentialMonthlySaving(potentialMonthlySaving)
        self.lastReviewedAt = lastReviewedAt
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    var isActiveLike: Bool {
        status == .active || status == .trial || status == .cancelSoon
    }

    var isCancellationCandidate: Bool {
        status == .cancelSoon
    }

    var isArchivedRecord: Bool {
        status == .archived || status == .cancelled
    }

    var isRecommendedCancellationCandidate: Bool {
        guard isActiveLike else { return false }
        return (usageFrequency == .rarely || usageFrequency == .never) && valueRating == .low
    }

    var appearsOnCancelList: Bool {
        isCancellationCandidate || isRecommendedCancellationCandidate
    }

    var subscriptionTemplate: SubscriptionTemplate? {
        SubscriptionTemplates.template(forID: templateID)
            ?? SubscriptionTemplates.inferredTemplate(forName: name)
    }

    var iconAssetName: String? {
        subscriptionTemplate?.iconAssetName
    }

    func update(
        name: String,
        amount: Decimal,
        cashbackAmount: Decimal?,
        currencyCode: String,
        billingCycle: BillingCycle,
        customBillingDays: Int?,
        nextBillingDate: Date,
        category: SubscriptionCategory,
        paymentMethod: PaymentMethod,
        status: SubscriptionStatus,
        reminderDaysBefore: Int,
        cancellationURL: URL?,
        notes: String?,
        templateID: String?,
        usageFrequency: UsageFrequency,
        valueRating: ValueRating,
        cancelReason: CancelReason?,
        potentialMonthlySaving: Decimal?,
        lastReviewedAt: Date?
    ) {
        self.name = Self.sanitizedName(name)
        self.amount = Self.sanitizedAmount(amount)
        self.cashbackAmount = Self.sanitizedCashbackAmount(cashbackAmount)
        self.currencyCode = Self.sanitizedCurrencyCode(currencyCode)
        self.billingCycle = billingCycle
        self.customBillingDays = Self.sanitizedCustomBillingDays(customBillingDays, billingCycle: billingCycle)
        self.nextBillingDate = nextBillingDate
        self.category = category
        self.paymentMethod = paymentMethod
        self.status = status
        self.reminderDaysBefore = Self.sanitizedReminderDays(reminderDaysBefore)
        self.cancellationURL = cancellationURL
        self.notes = Self.sanitizedOptionalText(notes)
        self.templateID = Self.sanitizedOptionalText(templateID)
        self.usageFrequency = usageFrequency
        self.valueRating = valueRating
        self.cancelReason = cancelReason
        self.potentialMonthlySaving = Self.sanitizedPotentialMonthlySaving(potentialMonthlySaving)
        self.lastReviewedAt = lastReviewedAt
        self.updatedAt = .now
    }
}

extension Subscription {
    static func sortedForList(_ subscriptions: [Subscription]) -> [Subscription] {
        subscriptions.sorted { left, right in
            if left.status.listSortPriority != right.status.listSortPriority {
                return left.status.listSortPriority < right.status.listSortPriority
            }

            if left.nextBillingDate != right.nextBillingDate {
                return left.nextBillingDate < right.nextBillingDate
            }

            return left.name.localizedCaseInsensitiveCompare(right.name) == .orderedAscending
        }
    }

    static func sanitizedName(_ value: String) -> String {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? RevoxaStrings.untitledSubscription : trimmed
    }

    static func sanitizedAmount(_ value: Decimal) -> Decimal {
        max(value, Decimal.zero)
    }

    static func sanitizedCashbackAmount(_ value: Decimal?) -> Decimal? {
        guard let value, value > .zero else { return nil }
        return value
    }

    static func sanitizedCurrencyCode(_ value: String) -> String {
        RevoxaCurrency.resolved(from: value).code
    }

    static func sanitizedReminderDays(_ value: Int) -> Int {
        min(max(value, 0), 365)
    }

    static func sanitizedCustomBillingDays(_ value: Int?, billingCycle: BillingCycle) -> Int? {
        guard billingCycle == .customDays else { return nil }
        return min(max(value ?? 30, 1), 3650)
    }

    static func sanitizedOptionalText(_ value: String?) -> String? {
        guard let value else { return nil }
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    static func sanitizedPotentialMonthlySaving(_ value: Decimal?) -> Decimal? {
        guard let value, value > .zero else { return nil }
        return value
    }
}
