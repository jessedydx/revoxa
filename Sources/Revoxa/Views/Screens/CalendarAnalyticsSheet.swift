import SwiftUI

struct CalendarAnalyticsSheet: View {
    let displayedMonth: Date
    let subscriptions: [Subscription]
    let exchangeRateSnapshot: ExchangeRateSnapshot?
    let displayCurrencyCode: String

    @Environment(\.dismiss) private var dismiss
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    private let billingSchedule = BillingScheduleCalculator()

    private var monthInterval: DateInterval {
        billingSchedule.monthInterval(containing: displayedMonth)
    }

    private var yearInterval: DateInterval {
        billingSchedule.yearInterval(containing: displayedMonth)
    }

    private var monthlyTotals: [CategoryPaymentTotal] {
        billingSchedule.categoryPaymentTotals(
            for: subscriptions,
            in: monthInterval,
            exchangeRates: exchangeRateSnapshot,
            displayCurrencyCode: displayCurrencyCode
        )
    }

    private var yearlyTotals: [CategoryPaymentTotal] {
        billingSchedule.categoryPaymentTotals(
            for: subscriptions,
            in: yearInterval,
            exchangeRates: exchangeRateSnapshot,
            displayCurrencyCode: displayCurrencyCode
        )
    }

    private var periodTitle: String {
        displayedMonth.formatted(
            .dateTime
                .month(.wide)
                .year()
                .locale(RevoxaLanguageSettings.resolvedLocale)
        )
    }

    private var yearTitle: String {
        String(Calendar(identifier: .gregorian).component(.year, from: displayedMonth))
    }

    private var isCompactLayout: Bool {
        horizontalSizeClass == .compact
    }

    private var sheetMinWidth: CGFloat? {
        isCompactLayout ? nil : 760
    }

    private var sheetMinHeight: CGFloat? {
        isCompactLayout ? nil : 520
    }

    var body: some View {
        VStack(spacing: 0) {
            sheetHeader

            ScrollView {
                VStack(alignment: .leading, spacing: RevoxaSpacing.xLarge) {
                    Text(L10n.tf("calendar.analytics.subtitle", periodTitle, yearTitle))
                        .font(RevoxaFont.body)
                        .foregroundStyle(RevoxaColor.textSecondary)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    analyticsCharts
                }
                .padding(isCompactLayout ? RevoxaSpacing.medium : RevoxaSpacing.xLarge)
            }
        }
        .frame(minWidth: sheetMinWidth, minHeight: sheetMinHeight)
        .background(RevoxaColor.appBackground)
    }

    @ViewBuilder
    private var analyticsCharts: some View {
        if isCompactLayout {
            VStack(alignment: .leading, spacing: RevoxaSpacing.medium) {
                analyticsCard(
                    title: L10n.tf("calendar.analytics.monthlyChart", periodTitle),
                    totals: monthlyTotals
                )

                analyticsCard(
                    title: L10n.tf("calendar.analytics.yearlyChart", yearTitle),
                    totals: yearlyTotals
                )
            }
        } else {
            HStack(alignment: .top, spacing: RevoxaSpacing.large) {
                analyticsCard(
                    title: L10n.tf("calendar.analytics.monthlyChart", periodTitle),
                    totals: monthlyTotals
                )

                analyticsCard(
                    title: L10n.tf("calendar.analytics.yearlyChart", yearTitle),
                    totals: yearlyTotals
                )
            }
        }
    }

    private var sheetHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: RevoxaSpacing.xSmall) {
                Text(AppSection.insights.title.uppercased())
                    .font(.system(size: 12, weight: .bold))
                    .tracking(1.1)
                    .foregroundStyle(RevoxaColor.accent)

                Text(AppSection.insights.title)
                    .font(RevoxaFont.pageTitle)
                    .foregroundStyle(RevoxaColor.textPrimary)
            }

            Spacer()

            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 20))
                    .foregroundStyle(RevoxaColor.textSecondary)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, isCompactLayout ? RevoxaSpacing.medium : RevoxaSpacing.xLarge)
        .padding(.top, isCompactLayout ? RevoxaSpacing.medium : RevoxaSpacing.xLarge)
        .padding(.bottom, RevoxaSpacing.medium)
        .background(RevoxaColor.surface)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(RevoxaColor.border)
                .frame(height: 1)
        }
    }

    private func analyticsCard(title: String, totals: [CategoryPaymentTotal]) -> some View {
        VStack(alignment: .leading, spacing: RevoxaSpacing.medium) {
            Text(title)
                .font(RevoxaFont.sectionTitle)
                .foregroundStyle(RevoxaColor.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)

            CategoryDonutChartView(totals: totals)
                .padding(.vertical, RevoxaSpacing.small)
        }
        .padding(RevoxaSpacing.large)
        .frame(maxWidth: .infinity, alignment: .topLeading)
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
    }
}
