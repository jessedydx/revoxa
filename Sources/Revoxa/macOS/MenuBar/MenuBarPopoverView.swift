#if os(macOS)
import SwiftData
import SwiftUI

struct MenuBarPopoverView: View {
    @Query(sort: \Subscription.nextBillingDate) private var subscriptions: [Subscription]

    private let dashboardCalculator = DashboardCalculator()
    private let exchangeRateService = ExchangeRateService.shared
    @State private var exchangeRateSnapshot: ExchangeRateSnapshot?
    @State private var exchangeRateLoadFailed = false

    private var summary: DashboardSummary {
        dashboardCalculator.summary(for: subscriptions)
    }

    private var displayMonthlyTotals: [CurrencyTotal] {
        exchangeRateSnapshot?.convertedTotalsToTRY(summary.monthlyTotals) ?? summary.monthlyTotals
    }

    private var displayYearlyTotals: [CurrencyTotal] {
        exchangeRateSnapshot?.convertedTotalsToTRY(summary.yearlyTotals) ?? summary.yearlyTotals
    }

    private var upcomingPayments: [DashboardPayment] {
        Array(summary.upcomingPayments.prefix(5))
    }

    private var cancelCandidates: [Subscription] {
        Array(summary.cancellationCandidates.prefix(3))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: RevoxaSpacing.large) {
                header
                summarySection

                if subscriptions.isEmpty {
                    emptySubscriptionsState
                } else {
                    upcomingSection
                    cancelCandidatesSection
                }

                footerActions
            }
            .padding(RevoxaSpacing.large)
        }
        .frame(width: 360, height: 520)
        .background(RevoxaColor.appBackground)
        .task {
            await refreshExchangeRates()
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: RevoxaSpacing.xSmall) {
            HStack(spacing: RevoxaSpacing.small) {
                RevoxaMenuBarIcon.accentBrandMark()
                Text(RevoxaStrings.appName)
                    .font(RevoxaFont.sectionTitle)
                    .foregroundStyle(RevoxaColor.textPrimary)
            }

            Text(L10n.t("menubar.summary"))
                .font(RevoxaFont.caption)
                .foregroundStyle(RevoxaColor.textSecondary)
        }
    }

    private var summarySection: some View {
        VStack(alignment: .leading, spacing: RevoxaSpacing.medium) {
            Text(L10n.t("menubar.overview"))
                .font(RevoxaFont.caption)
                .foregroundStyle(RevoxaColor.textSecondary)

            if let exchangeRateFootnote {
                Text(exchangeRateFootnote)
                    .font(RevoxaFont.caption)
                    .foregroundStyle(RevoxaColor.textSecondary)
            }

            VStack(spacing: RevoxaSpacing.small) {
                MenuBarMetricRow(
                    title: L10n.t("menubar.thisMonthTotal"),
                    content: { RevoxaCurrencyTotalsView(totals: displayMonthlyTotals, font: RevoxaFont.body.weight(.semibold)) }
                )
                MenuBarMetricRow(
                    title: L10n.t("menubar.yearlyEstimate"),
                    content: { RevoxaCurrencyTotalsView(totals: displayYearlyTotals, font: RevoxaFont.body.weight(.semibold)) }
                )
                MenuBarMetricRow(
                    title: L10n.t("menubar.within7Days"),
                    content: {
                        Text("\(summary.renewalsWithin7Days)")
                            .font(RevoxaFont.body.weight(.semibold))
                            .foregroundStyle(RevoxaColor.textPrimary)
                    }
                )
                MenuBarMetricRow(
                    title: L10n.t("menubar.cancelCandidates"),
                    content: {
                        Text("\(summary.cancellationCandidateCount)")
                            .font(RevoxaFont.body.weight(.semibold))
                            .foregroundStyle(RevoxaColor.textPrimary)
                    }
                )
            }
            .padding(RevoxaSpacing.medium)
            .background(RevoxaColor.surface)
            .clipShape(RoundedRectangle(cornerRadius: RevoxaRadius.medium))
            .overlay {
                RoundedRectangle(cornerRadius: RevoxaRadius.medium)
                    .stroke(RevoxaColor.border, lineWidth: 1)
            }
        }
    }

    private var emptySubscriptionsState: some View {
        VStack(alignment: .leading, spacing: RevoxaSpacing.medium) {
            Text(L10n.t("menubar.noSubscriptions"))
                .font(RevoxaFont.body.weight(.semibold))
                .foregroundStyle(RevoxaColor.textPrimary)

            Button(L10n.t("menubar.addFirst")) {
                RevoxaAppActions.addSubscription()
            }
            .buttonStyle(.borderedProminent)
            .tint(RevoxaColor.accent)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(RevoxaSpacing.medium)
        .background(RevoxaColor.surface)
        .clipShape(RoundedRectangle(cornerRadius: RevoxaRadius.medium))
        .overlay {
            RoundedRectangle(cornerRadius: RevoxaRadius.medium)
                .stroke(RevoxaColor.border, lineWidth: 1)
        }
    }

    private var upcomingSection: some View {
        MenuBarSection(title: L10n.t("section.upcoming")) {
            if upcomingPayments.isEmpty {
                MenuBarEmptyRow(message: L10n.t("menubar.noUpcoming"))
            } else {
                ForEach(upcomingPayments) { payment in
                    MenuBarUpcomingRow(payment: payment, exchangeRateSnapshot: exchangeRateSnapshot)
                    if payment.id != upcomingPayments.last?.id {
                        Divider().overlay(RevoxaColor.borderSubtle)
                    }
                }
            }
        }
    }

    private var cancelCandidatesSection: some View {
        MenuBarSection(title: L10n.t("menubar.cancelCandidates")) {
            if cancelCandidates.isEmpty {
                MenuBarEmptyRow(message: L10n.t("cancelList.empty.title"))
            } else {
                ForEach(cancelCandidates) { subscription in
                    MenuBarCancelRow(subscription: subscription, exchangeRateSnapshot: exchangeRateSnapshot)
                    if subscription.id != cancelCandidates.last?.id {
                        Divider().overlay(RevoxaColor.borderSubtle)
                    }
                }
            }
        }
    }

    private var footerActions: some View {
        VStack(spacing: RevoxaSpacing.small) {
            Button(L10n.t("menubar.openRevoxa")) {
                RevoxaAppActions.activateMainWindow()
            }
            .frame(maxWidth: .infinity)

            HStack(spacing: RevoxaSpacing.small) {
                Button(RevoxaStrings.addSubscription) {
                    RevoxaAppActions.addSubscription()
                }

                Button(L10n.t("menubar.viewAllUpcoming")) {
                    RevoxaAppActions.viewAllUpcoming()
                }
            }

            Button(L10n.t("menubar.quit")) {
                RevoxaAppActions.quit()
            }
            .frame(maxWidth: .infinity)
        }
        .controlSize(.small)
    }

    private var exchangeRateFootnote: String? {
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
        do {
            exchangeRateSnapshot = try await exchangeRateService.latestRates()
            exchangeRateLoadFailed = false
        } catch {
            exchangeRateSnapshot = exchangeRateService.cachedSnapshot
            exchangeRateLoadFailed = exchangeRateSnapshot == nil
        }
    }
}

private struct MenuBarSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: RevoxaSpacing.small) {
            Text(title)
                .font(RevoxaFont.caption)
                .foregroundStyle(RevoxaColor.textSecondary)

            VStack(alignment: .leading, spacing: 0) {
                content
            }
            .padding(RevoxaSpacing.medium)
            .background(RevoxaColor.surface)
            .clipShape(RoundedRectangle(cornerRadius: RevoxaRadius.medium))
            .overlay {
                RoundedRectangle(cornerRadius: RevoxaRadius.medium)
                    .stroke(RevoxaColor.border, lineWidth: 1)
            }
        }
    }
}

private struct MenuBarMetricRow<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        HStack(alignment: .top) {
            Text(title)
                .font(RevoxaFont.caption)
                .foregroundStyle(RevoxaColor.textSecondary)
                .frame(maxWidth: .infinity, alignment: .leading)

            content
                .frame(maxWidth: .infinity, alignment: .trailing)
        }
    }
}

private struct MenuBarEmptyRow: View {
    let message: String

    var body: some View {
        Text(message)
            .font(RevoxaFont.body)
            .foregroundStyle(RevoxaColor.textSecondary)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct MenuBarUpcomingRow: View {
    let payment: DashboardPayment
    let exchangeRateSnapshot: ExchangeRateSnapshot?

    var body: some View {
        HStack(alignment: .top, spacing: RevoxaSpacing.small) {
            VStack(alignment: .leading, spacing: 2) {
                Text(payment.subscription.name)
                    .font(RevoxaFont.body.weight(.semibold))
                    .foregroundStyle(RevoxaColor.textPrimary)
                    .lineLimit(1)

                Text(RevoxaDateFormatter.compactDate(payment.nextBillingDate))
                    .font(RevoxaFont.caption)
                    .foregroundStyle(RevoxaColor.textSecondary)
            }

            Spacer(minLength: RevoxaSpacing.small)

            VStack(alignment: .trailing, spacing: 2) {
                Text(formattedAmount(payment.subscription.amount, currencyCode: payment.subscription.currencyCode))
                    .font(RevoxaFont.body.weight(.semibold))
                    .foregroundStyle(RevoxaColor.accent)
                    .lineLimit(1)

                Text(RevoxaStrings.daysUntilText(payment.daysUntil))
                    .font(RevoxaFont.caption)
                    .foregroundStyle(RevoxaColor.textSecondary)
            }
        }
        .padding(.vertical, RevoxaSpacing.xSmall)
    }

    private func formattedAmount(_ amount: Decimal, currencyCode: String) -> String {
        if let convertedAmount = exchangeRateSnapshot?.convertToTRY(amount, from: currencyCode) {
            return CurrencyFormatter.string(from: convertedAmount, currencyCode: "TRY")
        }

        return CurrencyFormatter.string(from: amount, currencyCode: currencyCode)
    }
}

private struct MenuBarCancelRow: View {
    let subscription: Subscription
    let exchangeRateSnapshot: ExchangeRateSnapshot?

    var body: some View {
        HStack(alignment: .top, spacing: RevoxaSpacing.small) {
            Text(subscription.name)
                .font(RevoxaFont.body.weight(.semibold))
                .foregroundStyle(RevoxaColor.textPrimary)
                .lineLimit(1)

            Spacer(minLength: RevoxaSpacing.small)

            VStack(alignment: .trailing, spacing: 2) {
                Text(formattedAmount(subscription.amount, currencyCode: subscription.currencyCode))
                    .font(RevoxaFont.caption)
                    .foregroundStyle(RevoxaColor.textPrimary)

                Text(RevoxaDateFormatter.compactDate(subscription.nextBillingDate))
                    .font(RevoxaFont.caption)
                    .foregroundStyle(RevoxaColor.textSecondary)
            }
        }
        .padding(.vertical, RevoxaSpacing.xSmall)
    }

    private func formattedAmount(_ amount: Decimal, currencyCode: String) -> String {
        if let convertedAmount = exchangeRateSnapshot?.convertToTRY(amount, from: currencyCode) {
            return CurrencyFormatter.string(from: convertedAmount, currencyCode: "TRY")
        }

        return CurrencyFormatter.string(from: amount, currencyCode: currencyCode)
    }
}
#endif
