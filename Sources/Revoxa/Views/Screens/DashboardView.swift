import SwiftData
import SwiftUI

struct DashboardView: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Query(sort: \Subscription.nextBillingDate) private var subscriptions: [Subscription]
    @AppStorage(PreferenceKey.defaultCurrencyCode) private var displayCurrencyCode = PreferenceKey.defaultCurrencyCodeValue
    private let dashboardCalculator = DashboardCalculator()
    private let billingCalculator = BillingCalculator()
    private let exchangeRateService = ExchangeRateService.shared
    @State private var exchangeRateSnapshot: ExchangeRateSnapshot?
    @State private var exchangeRateLoadFailed = false

    private var summary: DashboardSummary {
        dashboardCalculator.summary(for: subscriptions)
    }

    private var displayMonthlyTotals: [CurrencyTotal] {
        CurrencyDisplay.displayTotals(summary.monthlyTotals, in: displayCurrencyCode, using: exchangeRateSnapshot)
    }

    private var displayYearlyTotals: [CurrencyTotal] {
        CurrencyDisplay.displayTotals(summary.yearlyTotals, in: displayCurrencyCode, using: exchangeRateSnapshot)
    }

    private var isCompactLayout: Bool {
        horizontalSizeClass == .compact
    }

    var body: some View {
        ZStack {
            RevoxaColor.appBackground
                .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: RevoxaSpacing.large) {
                    #if os(macOS)
                    header
                    #endif
                    heroGrid
                    contentGrid
                }
                .padding(isCompactLayout ? RevoxaSpacing.medium : RevoxaSpacing.xLarge)
                .frame(maxWidth: .infinity, alignment: .topLeading)
            }
        }
        .task {
            await refreshExchangeRates()
        }
    }

    private var header: some View {
        Text(L10n.t("section.dashboard").uppercased())
            .font(.system(size: 14, weight: .bold))
            .tracking(1.2)
            .foregroundStyle(RevoxaColor.accent)
    }

    private var heroGrid: some View {
        LazyVGrid(
            columns: heroColumns,
            spacing: RevoxaSpacing.medium
        ) {
            DashboardHeroCard(
                title: L10n.t("dashboard.thisMonth"),
                totals: displayMonthlyTotals,
                caption: L10n.t("dashboard.thisMonth.caption"),
                footnote: exchangeRateFootnote,
                style: .accent,
                isCompact: isCompactLayout
            )
            DashboardHeroCard(
                title: L10n.t("dashboard.yearly"),
                totals: displayYearlyTotals,
                caption: L10n.t("dashboard.yearly.caption"),
                footnote: exchangeRateFootnote,
                style: .surface,
                isCompact: isCompactLayout
            )
        }
    }

    private var heroColumns: [GridItem] {
        if isCompactLayout {
            return [GridItem(.flexible(minimum: 0), spacing: RevoxaSpacing.medium)]
        }

        return [
            GridItem(.flexible(minimum: 260), spacing: RevoxaSpacing.medium),
            GridItem(.flexible(minimum: 260), spacing: RevoxaSpacing.medium)
        ]
    }

    @ViewBuilder
    private var contentGrid: some View {
        if isCompactLayout {
            VStack(alignment: .leading, spacing: RevoxaSpacing.medium) {
                upcomingPaymentsCard
                topExpensiveSubscriptionsCard
            }
        } else {
            ViewThatFits(in: .horizontal) {
                HStack(alignment: .top, spacing: RevoxaSpacing.medium) {
                    upcomingPaymentsCard
                        .frame(maxWidth: .infinity, alignment: .topLeading)
                    topExpensiveSubscriptionsCard
                        .frame(maxWidth: .infinity, alignment: .topLeading)
                }

                VStack(alignment: .leading, spacing: RevoxaSpacing.medium) {
                    upcomingPaymentsCard
                    topExpensiveSubscriptionsCard
                }
            }
        }
    }

    private var upcomingPaymentsCard: some View {
        DashboardListCard(
            title: L10n.t("dashboard.upcoming"),
            count: summary.upcomingPayments.isEmpty ? nil : min(summary.upcomingPayments.count, 5)
        ) {
            if summary.upcomingPayments.isEmpty {
                DashboardEmptyRow(message: L10n.t("dashboard.noUpcoming"))
            } else {
                ForEach(summary.upcomingPayments.prefix(5)) { payment in
                    DashboardPaymentRow(payment: payment)
                }
            }
        }
    }

    private var topExpensiveSubscriptionsCard: some View {
        DashboardListCard(
            title: L10n.t("dashboard.topExpensive"),
            count: topExpensiveSubscriptions.isEmpty ? nil : topExpensiveSubscriptions.count
        ) {
            if topExpensiveSubscriptions.isEmpty {
                DashboardEmptyRow(message: L10n.t("dashboard.noCostSubscriptions"))
            } else {
                ForEach(topExpensiveSubscriptions) { subscription in
                    DashboardSubscriptionCostRow(
                        subscription: subscription,
                        billingCalculator: billingCalculator,
                        exchangeRateSnapshot: exchangeRateSnapshot,
                        displayCurrencyCode: displayCurrencyCode
                    )
                }
            }
        }
    }

    private var topExpensiveSubscriptions: [Subscription] {
        Array(sortedSubscriptionsByDisplayMonthlyCost.prefix(5))
    }

    private var sortedSubscriptionsByDisplayMonthlyCost: [Subscription] {
        subscriptions
            .filter(\.isActiveLike)
            .sorted { left, right in
                displayMonthlyCost(for: left) > displayMonthlyCost(for: right)
            }
    }

    private func displayMonthlyCost(for subscription: Subscription) -> Decimal {
        let monthlyCost = billingCalculator.estimatedMonthlyCost(for: subscription)
        return CurrencyDisplay.convertedAmount(
            monthlyCost,
            from: subscription.currencyCode,
            to: displayCurrencyCode,
            using: exchangeRateSnapshot
        ).amount
    }

    private var exchangeRateFootnote: String? {
        guard ScreenshotFixtures.isEnabled == false else {
            return nil
        }

        guard let exchangeRateSnapshot else {
            return exchangeRateLoadFailed ? L10n.t("exchangeRates.unavailable") : nil
        }

        let dateText = RevoxaDateFormatter.mediumDate(exchangeRateSnapshot.rateDate)
        if exchangeRateSnapshot.isCached {
            return L10n.tf("exchangeRates.cached", dateText)
        }

        return L10n.tf("exchangeRates.live", dateText)
    }

    private func refreshExchangeRates() async {
        guard ScreenshotFixtures.isEnabled == false else {
            exchangeRateSnapshot = nil
            exchangeRateLoadFailed = false
            return
        }

        do {
            exchangeRateSnapshot = try await exchangeRateService.latestRates()
            exchangeRateLoadFailed = false
        } catch {
            exchangeRateSnapshot = exchangeRateService.cachedSnapshot
            exchangeRateLoadFailed = exchangeRateSnapshot == nil
        }
    }
}

// MARK: - Hero cards

private struct DashboardHeroCard: View {
    enum Style {
        case accent
        case surface
    }

    let title: String
    let totals: [CurrencyTotal]
    let caption: String
    let footnote: String?
    let style: Style
    var isCompact = false

    private var isAccent: Bool { style == .accent }

    var body: some View {
        VStack(alignment: .leading, spacing: isCompact ? RevoxaSpacing.small : RevoxaSpacing.medium) {
            Text(title)
                .font(RevoxaFont.sectionTitle)
                .foregroundStyle(primaryColor)
                .lineLimit(2)

            CurrencyTotalsInline(
                totals: totals,
                font: .system(size: isCompact ? 27 : 30, weight: .bold, design: .rounded),
                color: primaryColor
            )
            .frame(minHeight: 38, alignment: .leading)

            Text(caption)
                .font(RevoxaFont.caption)
                .foregroundStyle(secondaryColor)
                .lineLimit(2)

            if let footnote {
                Text(footnote)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(secondaryColor)
                    .lineLimit(2)
            }
        }
        .padding(isCompact ? RevoxaSpacing.medium : RevoxaSpacing.large)
        .frame(maxWidth: .infinity, minHeight: isCompact ? 148 : 166, alignment: .topLeading)
        .background(background)
        .clipShape(RoundedRectangle(cornerRadius: RevoxaRadius.large, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: RevoxaRadius.large, style: .continuous)
                .stroke(isAccent ? Color.white.opacity(0.18) : RevoxaColor.border, lineWidth: 1)
        }
        .shadow(color: shadowColor, radius: 14, x: 0, y: 6)
    }

    private var primaryColor: Color {
        isAccent ? Color.white : RevoxaColor.textPrimary
    }

    private var secondaryColor: Color {
        isAccent ? Color.white.opacity(0.82) : RevoxaColor.textSecondary
    }

    @ViewBuilder
    private var background: some View {
        if isAccent {
            LinearGradient(
                colors: [RevoxaColor.accent, RevoxaColor.accentMuted],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        } else {
            LinearGradient(
                colors: [RevoxaColor.premiumSurface, RevoxaColor.surface],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }

    private var shadowColor: Color {
        isAccent ? RevoxaColor.accent.opacity(0.28) : Color.black.opacity(0.06)
    }
}

// MARK: - List cards

private struct DashboardListCard<Content: View>: View {
    let title: String
    let count: Int?
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: RevoxaSpacing.medium) {
            HStack {
                Text(title)
                    .font(RevoxaFont.sectionTitle)
                    .foregroundStyle(RevoxaColor.textPrimary)

                Spacer()

                if let count {
                    Text("\(count)")
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundStyle(RevoxaColor.accent)
                        .padding(.horizontal, RevoxaSpacing.small)
                        .padding(.vertical, 3)
                        .background(RevoxaColor.accent.opacity(0.12))
                        .clipShape(Capsule())
                }
            }

            VStack(spacing: RevoxaSpacing.xSmall) {
                content
            }
        }
        .padding(RevoxaSpacing.medium)
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .revoxaDashboardCard()
    }
}

private struct DashboardPaymentRow: View {
    let payment: DashboardPayment

    var body: some View {
        HStack(spacing: RevoxaSpacing.medium) {
            rowTitle(
                payment.subscription.name,
                subtitle: payment.subscription.category.title,
                iconAssetName: payment.subscription.iconAssetName
            )

            Spacer()

            VStack(alignment: .trailing, spacing: RevoxaSpacing.xSmall) {
                Text(RevoxaDateFormatter.compactDate(payment.nextBillingDate))
                    .font(RevoxaFont.caption)
                    .foregroundStyle(RevoxaColor.textPrimary)
                Text(RevoxaStrings.daysUntilText(payment.daysUntil))
                    .font(RevoxaFont.caption)
                    .foregroundStyle(RevoxaColor.textSecondary)
            }
        }
        .dashboardRowChrome()
    }
}

private struct DashboardSubscriptionCostRow: View {
    let subscription: Subscription
    let billingCalculator: BillingCalculator
    let exchangeRateSnapshot: ExchangeRateSnapshot?
    let displayCurrencyCode: String

    var body: some View {
        HStack(spacing: RevoxaSpacing.medium) {
            rowTitle(subscription.name, subtitle: subscription.billingCycle.title, iconAssetName: subscription.iconAssetName)

            Spacer()

            Text(costText)
                .font(RevoxaFont.body.weight(.semibold))
                .foregroundStyle(RevoxaColor.textPrimary)
        }
        .dashboardRowChrome()
    }

    private var costText: String {
        let monthlyCost = billingCalculator.estimatedMonthlyCost(for: subscription)
        return CurrencyDisplay.formattedAmount(
            monthlyCost,
            from: subscription.currencyCode,
            to: displayCurrencyCode,
            using: exchangeRateSnapshot
        )
    }
}

private struct DashboardCancellationRow: View {
    let subscription: Subscription

    var body: some View {
        HStack(spacing: RevoxaSpacing.medium) {
            rowTitle(subscription.name, subtitle: subscription.category.title, iconAssetName: subscription.iconAssetName)

            Spacer()

            Text(RevoxaDateFormatter.compactDate(subscription.nextBillingDate))
                .font(RevoxaFont.caption)
                .foregroundStyle(RevoxaColor.accent)
        }
        .dashboardRowChrome()
    }
}

private struct DashboardEmptyRow: View {
    let message: String

    var body: some View {
        Text(message)
            .font(RevoxaFont.body)
            .foregroundStyle(RevoxaColor.textSecondary)
            .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
    }
}

// MARK: - Shared building blocks

private struct CurrencyTotalsInline: View {
    let totals: [CurrencyTotal]
    let font: Font
    let color: Color
    var emptyText: String = "—"

    var body: some View {
        if totals.isEmpty {
            Text(emptyText)
                .font(font)
                .foregroundStyle(color)
        } else {
            VStack(alignment: .leading, spacing: 2) {
                ForEach(totals) { total in
                    Text(CurrencyFormatter.string(from: total.amount, currencyCode: total.currencyCode))
                        .font(font)
                        .foregroundStyle(color)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }
            }
        }
    }
}

private func rowTitle(_ title: String, subtitle: String, iconAssetName: String?) -> some View {
    HStack(spacing: RevoxaSpacing.small) {
        SubscriptionLogoView(subscriptionName: title, iconAssetName: iconAssetName, size: 32)

        VStack(alignment: .leading, spacing: RevoxaSpacing.xSmall) {
            Text(title)
                .font(RevoxaFont.body.weight(.semibold))
                .foregroundStyle(RevoxaColor.textPrimary)
                .lineLimit(1)

            Text(subtitle)
                .font(RevoxaFont.caption)
                .foregroundStyle(RevoxaColor.textSecondary)
                .lineLimit(1)
        }
    }
}

private extension View {
    func revoxaDashboardCard() -> some View {
        self
            .background(
                LinearGradient(
                    colors: [RevoxaColor.premiumSurface, RevoxaColor.surface],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: RevoxaRadius.large, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: RevoxaRadius.large, style: .continuous)
                    .stroke(RevoxaColor.borderSubtle, lineWidth: 1)
            }
            .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 4)
    }

    func dashboardRowChrome() -> some View {
        self
            .padding(.horizontal, RevoxaSpacing.small)
            .padding(.vertical, RevoxaSpacing.small)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(RevoxaColor.elevatedSurface.opacity(0.55))
            .clipShape(RoundedRectangle(cornerRadius: RevoxaRadius.medium, style: .continuous))
    }
}
