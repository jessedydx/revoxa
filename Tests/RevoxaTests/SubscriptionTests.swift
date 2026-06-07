import Foundation
import Testing
@testable import Revoxa

struct SubscriptionTests {
    private let turkish = Locale(identifier: "tr")
    @Test
    func initializerSanitizesUnsafeInput() {
        let subscription = Subscription(
            name: "  ",
            amount: Decimal(-9),
            currencyCode: "usd ",
            billingCycle: .monthly,
            nextBillingDate: Date(timeIntervalSince1970: 0),
            category: .other,
            paymentMethod: .other,
            reminderDaysBefore: 900,
            notes: "  "
        )

        UserDefaults.standard.set(AppLanguage.turkish.rawValue, forKey: PreferenceKey.appLanguage)
        defer { UserDefaults.standard.removeObject(forKey: PreferenceKey.appLanguage) }

        #expect(subscription.name == L10n.t("common.untitledSubscription", locale: turkish))
        #expect(subscription.amount == Decimal.zero)
        #expect(subscription.currencyCode == "USD")
        #expect(subscription.reminderDaysBefore == 365)
        #expect(subscription.customBillingDays == nil)
        #expect(subscription.notes == nil)
    }

    @Test
    func enumRawValuesStayStableForPersistence() {
        #expect(BillingCycle.weekly.rawValue == "weekly")
        #expect(BillingCycle.customDays.rawValue == "customDays")
        #expect(SubscriptionStatus.cancelSoon.rawValue == "cancelSoon")
        #expect(SubscriptionCategory.ai.rawValue == "ai")
        #expect(PaymentMethod.bankTransfer.rawValue == "bankTransfer")
        #expect(UsageFrequency.rarely.rawValue == "rarely")
        #expect(ValueRating.low.rawValue == "low")
        #expect(CancelReason.tooExpensive.rawValue == "tooExpensive")
    }

    @Test
    func valueReviewDefaultsAreBackwardCompatible() {
        let subscription = Subscription(
            name: "Test",
            amount: Decimal(10),
            currencyCode: "USD",
            billingCycle: .monthly,
            nextBillingDate: .now,
            category: .other,
            paymentMethod: .creditCard
        )

        #expect(subscription.usageFrequency == .monthly)
        #expect(subscription.valueRating == .unknown)
        #expect(subscription.cancelReason == nil)
        #expect(subscription.potentialMonthlySaving == nil)
        #expect(subscription.lastReviewedAt == nil)
    }

    @Test
    func subscriptionTemplatesPrefillFormAndInferExistingRecords() throws {
        let template = try #require(SubscriptionTemplates.template(forID: "chatgpt"))
        var state = SubscriptionFormState()

        state.apply(template: template, defaultCurrencyCode: "try")

        #expect(state.name == "ChatGPT")
        #expect(state.templateID == "chatgpt")
        #expect(state.currencyCode == "TRY")
        #expect(state.category == .ai)
        #expect(state.billingCycle == .monthly)
        #expect(state.cancellationURLText.isEmpty == false)

        let existingSubscription = Subscription(
            name: "ChatGPT Plus",
            amount: Decimal(20),
            currencyCode: "USD",
            billingCycle: .monthly,
            nextBillingDate: .now,
            category: .ai,
            paymentMethod: .creditCard
        )

        #expect(existingSubscription.subscriptionTemplate?.id == "chatgpt")
        #expect(existingSubscription.iconAssetName == "brand_chatgpt")
    }

    @Test
    func subscriptionTemplatesIncludeExpandedPopularServices() throws {
        let requiredIDs = [
            "storytel",
            "hepsiburada",
            "hetzner",
            "claude",
            "github",
            "figma",
            "dropbox",
            "slack",
            "zoom",
            "cursor",
            "midjourney",
            "apple-music",
            "duolingo",
            "linkedin-premium",
            "exxen",
            "blutv",
            "mubi",
            "tradingview",
            "cloudflare",
            "ens"
        ]

        for id in requiredIDs {
            let template = try #require(SubscriptionTemplates.template(forID: id))
            #expect(template.iconAssetName.hasPrefix("brand_"))
        }

        #expect(SubscriptionTemplates.inferredTemplate(forName: "Claude Pro")?.id == "claude")
        #expect(SubscriptionTemplates.inferredTemplate(forName: "Hepsiburada Premium")?.id == "hepsiburada")
        #expect(SubscriptionTemplates.inferredTemplate(forName: "TradingView Pro")?.id == "tradingview")
        #expect(SubscriptionTemplates.inferredTemplate(forName: "Cloudflare Pro")?.id == "cloudflare")
        #expect(SubscriptionTemplates.inferredTemplate(forName: "ENS Domain")?.id == "ens")
    }

    @Test
    func cancellationCandidateMatchesCancelSoonStatusOnly() {
        let candidate = Subscription(
            name: "Candidate",
            amount: Decimal(10),
            currencyCode: "USD",
            billingCycle: .monthly,
            nextBillingDate: .now,
            category: .other,
            paymentMethod: .creditCard,
            status: .cancelSoon
        )
        let cancelled = Subscription(
            name: "Cancelled",
            amount: Decimal(10),
            currencyCode: "USD",
            billingCycle: .monthly,
            nextBillingDate: .now,
            category: .other,
            paymentMethod: .creditCard,
            status: .cancelled
        )

        #expect(candidate.isCancellationCandidate)
        #expect(cancelled.isCancellationCandidate == false)
    }

    @Test
    func archivedRecordMatchesArchivedAndCancelledStatuses() {
        let archived = Subscription(
            name: "Archived",
            amount: Decimal(10),
            currencyCode: "USD",
            billingCycle: .monthly,
            nextBillingDate: .now,
            category: .other,
            paymentMethod: .creditCard,
            status: .archived
        )
        let cancelled = Subscription(
            name: "Cancelled",
            amount: Decimal(10),
            currencyCode: "USD",
            billingCycle: .monthly,
            nextBillingDate: .now,
            category: .other,
            paymentMethod: .creditCard,
            status: .cancelled
        )
        let active = Subscription(
            name: "Active",
            amount: Decimal(10),
            currencyCode: "USD",
            billingCycle: .monthly,
            nextBillingDate: .now,
            category: .other,
            paymentMethod: .creditCard,
            status: .active
        )

        #expect(archived.isArchivedRecord)
        #expect(cancelled.isArchivedRecord)
        #expect(active.isArchivedRecord == false)
    }

    @Test
    func listSortingPrioritizesStatusThenNextBillingDate() {
        let subscriptions = [
            makeSubscription(name: "Cancelled Soon", status: .cancelled, nextBillingDate: date(2026, 6, 1)),
            makeSubscription(name: "Active Later", status: .active, nextBillingDate: date(2026, 7, 1)),
            makeSubscription(name: "Trial Soon", status: .trial, nextBillingDate: date(2026, 5, 15)),
            makeSubscription(name: "Active Soon", status: .active, nextBillingDate: date(2026, 6, 1)),
            makeSubscription(name: "Archive Soon", status: .archived, nextBillingDate: date(2026, 5, 1)),
            makeSubscription(name: "Cancel Candidate", status: .cancelSoon, nextBillingDate: date(2026, 5, 1))
        ]

        let sortedNames = Subscription.sortedForList(subscriptions).map(\.name)

        #expect(sortedNames == [
            "Active Soon",
            "Active Later",
            "Trial Soon",
            "Cancel Candidate",
            "Cancelled Soon",
            "Archive Soon"
        ])
    }

    @Test
    func monthlyAndYearlyEstimatesUseDecimalMath() {
        let yearlySubscription = Subscription(
            name: "Annual Tool",
            amount: Decimal(120),
            currencyCode: "USD",
            billingCycle: .yearly,
            nextBillingDate: .now,
            category: .productivity,
            paymentMethod: .creditCard
        )

        #expect(yearlySubscription.monthlyCostEstimate == Decimal(10))
        #expect(yearlySubscription.yearlyCostEstimate == Decimal(120))
    }

    @Test
    func customDaysEstimateUsesStoredDayCount() {
        let customSubscription = Subscription(
            name: "Custom Tool",
            amount: Decimal(10),
            currencyCode: "USD",
            billingCycle: .customDays,
            customBillingDays: 10,
            nextBillingDate: .now,
            category: .utilities,
            paymentMethod: .creditCard
        )

        #expect(customSubscription.customBillingDays == 10)
        #expect(customSubscription.yearlyCostEstimate == Decimal(365))
    }

    @Test
    func formStateRejectsInvalidValues() {
        var state = SubscriptionFormState()
        state.name = ""
        state.amountText = "0"
        state.cashbackAmountText = "bad"
        state.currencyCode = ""
        state.cancellationURLText = "not-a-url"

        UserDefaults.standard.set(AppLanguage.turkish.rawValue, forKey: PreferenceKey.appLanguage)
        defer { UserDefaults.standard.removeObject(forKey: PreferenceKey.appLanguage) }

        let errors = state.validationErrors()

        #expect(errors.contains(L10n.t("validation.nameEmpty", locale: turkish)))
        #expect(errors.contains(L10n.t("validation.amountPositive", locale: turkish)))
        #expect(errors.contains(L10n.t("validation.cashbackInvalid", locale: turkish)))
        #expect(errors.contains(L10n.t("validation.currencyEmpty", locale: turkish)))
        #expect(errors.contains(L10n.t("validation.cancelURLInvalid", locale: turkish)))
        #expect(state.makeSubscription() == nil)
    }

    @Test
    func cancellationURLValidationRequiresHTTPURLWithHost() {
        var state = SubscriptionFormState()

        state.cancellationURLText = ""
        #expect(state.isValidCancellationURL)

        state.cancellationURLText = "https://example.com/cancel"
        #expect(state.isValidCancellationURL)

        state.cancellationURLText = "ftp://example.com/cancel"
        #expect(state.isValidCancellationURL == false)

        state.cancellationURLText = "https://"
        #expect(state.isValidCancellationURL == false)

        state.cancellationURLText = "not-a-url"
        #expect(state.isValidCancellationURL == false)
    }

    @Test
    func formStateCreatesSubscriptionFromValidValues() throws {
        var state = SubscriptionFormState()
        state.name = "  Linear  "
        state.amountText = "8.50"
        state.cashbackAmountText = "1.25"
        state.currencyCode = "usd"
        state.billingCycle = .customDays
        state.customBillingDays = 45
        state.category = .productivity
        state.paymentMethod = .creditCard
        state.status = .trial
        state.reminderDaysBefore = 7
        state.cancellationURLText = "https://linear.app/settings"
        state.notes = " Team trial "

        let subscription = try #require(state.makeSubscription())

        #expect(subscription.name == "Linear")
        #expect(subscription.amount == Decimal(string: "8.50"))
        #expect(subscription.cashbackAmount == Decimal(string: "1.25"))
        #expect(subscription.currencyCode == "USD")
        #expect(subscription.billingCycle == .customDays)
        #expect(subscription.customBillingDays == 45)
        #expect(subscription.status == .trial)
        #expect(subscription.cancellationURL?.absoluteString == "https://linear.app/settings")
        #expect(subscription.notes == "Team trial")
    }

    @Test
    func samplesCoverDashboardAndListStates() {
        let samples = Subscription.samples

        #expect(samples.isEmpty == false)
        #expect(samples.contains { $0.status == .cancelSoon })
        #expect(samples.allSatisfy { $0.amount >= Decimal.zero })
        #expect(samples.allSatisfy { $0.currencyCode.count == 3 })
    }

    private func makeSubscription(
        name: String,
        status: SubscriptionStatus,
        nextBillingDate: Date
    ) -> Subscription {
        Subscription(
            name: name,
            amount: Decimal(10),
            currencyCode: "USD",
            billingCycle: .monthly,
            nextBillingDate: nextBillingDate,
            category: .other,
            paymentMethod: .creditCard,
            status: status
        )
    }

    private func date(_ year: Int, _ month: Int, _ day: Int) -> Date {
        DateComponents(calendar: Calendar(identifier: .gregorian), year: year, month: month, day: day).date!
    }
}
