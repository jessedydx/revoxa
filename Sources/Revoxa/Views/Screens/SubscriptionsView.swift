import SwiftData
import SwiftUI

struct SubscriptionsView: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Subscription.name) private var subscriptions: [Subscription]
    @AppStorage(PreferenceKey.defaultCurrencyCode) private var displayCurrencyCode = PreferenceKey.defaultCurrencyCodeValue
    @State private var searchText = ""
    @State private var exchangeRateSnapshot: ExchangeRateSnapshot?
    @State private var selectedStatusFilter = SubscriptionStatusFilter.all
    @State private var selectedCategoryFilter = SubscriptionCategoryFilter.all
    @State private var editingSubscription: Subscription?
    @State private var isSearchPresented = false

    private var filteredSubscriptions: [Subscription] {
        Subscription.sortedForList(
            subscriptions.filter { subscription in
                matchesSearch(subscription)
                    && selectedStatusFilter.matches(subscription)
                    && selectedCategoryFilter.matches(subscription)
            }
        )
    }

    private var isCompactLayout: Bool {
        horizontalSizeClass == .compact
    }

    var body: some View {
        ZStack {
            RevoxaColor.appBackground
                .ignoresSafeArea()

            VStack(alignment: .leading, spacing: RevoxaSpacing.large) {
                #if os(macOS)
                header
                #endif
                filterBar
                content
            }
            .padding(isCompactLayout ? RevoxaSpacing.medium : RevoxaSpacing.xLarge)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
        .searchable(
            text: $searchText,
            isPresented: $isSearchPresented,
            placement: .toolbar,
            prompt: L10n.t("subscriptions.searchPrompt")
        )
        .onReceive(NotificationCenter.default.publisher(for: .revoxaFocusSearch)) { _ in
            isSearchPresented = true
        }
        .task {
            await refreshExchangeRates()
        }
        .sheet(item: $editingSubscription) { subscription in
            SubscriptionFormView(subscription: subscription) { subscription in
                modelContext.delete(subscription)
            }
        }
    }

    private func matchesSearch(_ subscription: Subscription) -> Bool {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard query.isEmpty == false else { return true }

        return subscription.name.localizedCaseInsensitiveContains(query)
            || subscription.currencyCode.localizedCaseInsensitiveContains(query)
            || subscription.category.title.localizedCaseInsensitiveContains(query)
            || subscription.status.title.localizedCaseInsensitiveContains(query)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: RevoxaSpacing.small) {
            Text(AppSection.subscriptions.title.uppercased())
                .font(.system(size: 14, weight: .bold))
                .tracking(1.2)
                .foregroundStyle(RevoxaColor.accent)
        }
    }

    private var filterBar: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: RevoxaSpacing.medium) {
                filterPickers

                Spacer()

                shownCountText
            }

            VStack(alignment: .leading, spacing: RevoxaSpacing.small) {
                filterPickers
                shownCountText
            }
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

    private var filterPickers: some View {
        HStack(spacing: RevoxaSpacing.small) {
            Picker(L10n.t("subscriptions.status"), selection: $selectedStatusFilter) {
                ForEach(SubscriptionStatusFilter.allCases) { filter in
                    Text(filter.title).tag(filter)
                }
            }
            .pickerStyle(.menu)
            .frame(maxWidth: .infinity, alignment: .leading)

            Picker(L10n.t("subscriptions.category"), selection: $selectedCategoryFilter) {
                ForEach(SubscriptionCategoryFilter.allCases) { filter in
                    Text(filter.title).tag(filter)
                }
            }
            .pickerStyle(.menu)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var shownCountText: some View {
        Text(RevoxaStrings.shownCount(filteredSubscriptions.count))
            .font(RevoxaFont.caption)
            .foregroundStyle(RevoxaColor.textSecondary)
    }

    @ViewBuilder
    private var content: some View {
        if subscriptions.isEmpty {
            SubscriptionEmptyState(
                title: L10n.t("subscriptions.empty.title"),
                message: L10n.t("subscriptions.empty.subtitle")
            )
        } else if filteredSubscriptions.isEmpty {
            SubscriptionEmptyState(
                title: L10n.t("subscriptions.noMatch.title"),
                message: L10n.t("subscriptions.noMatch.subtitle")
            )
        } else if isCompactLayout {
            SubscriptionCardList(
                subscriptions: filteredSubscriptions,
                exchangeRateSnapshot: exchangeRateSnapshot,
                displayCurrencyCode: displayCurrencyCode
            ) { subscription in
                editingSubscription = subscription
            }
        } else {
            SubscriptionTable(
                subscriptions: filteredSubscriptions,
                exchangeRateSnapshot: exchangeRateSnapshot,
                displayCurrencyCode: displayCurrencyCode
            ) { subscription in
                editingSubscription = subscription
            }
        }
    }

    private func refreshExchangeRates() async {
        guard ScreenshotFixtures.isEnabled == false else {
            exchangeRateSnapshot = nil
            return
        }

        let exchangeRateService = ExchangeRateService.shared
        do {
            exchangeRateSnapshot = try await exchangeRateService.latestRates()
        } catch {
            exchangeRateSnapshot = exchangeRateService.cachedSnapshot
        }
    }

}

private struct SubscriptionCardList: View {
    let subscriptions: [Subscription]
    let exchangeRateSnapshot: ExchangeRateSnapshot?
    let displayCurrencyCode: String
    let onSelect: (Subscription) -> Void

    var body: some View {
        ScrollView {
            LazyVStack(spacing: RevoxaSpacing.small) {
                ForEach(subscriptions) { subscription in
                    SubscriptionCardRow(
                        subscription: subscription,
                        exchangeRateSnapshot: exchangeRateSnapshot,
                        displayCurrencyCode: displayCurrencyCode
                    ) {
                        onSelect(subscription)
                    }
                }
            }
            .padding(.vertical, 2)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }
}

private struct SubscriptionCardRow: View {
    let subscription: Subscription
    let exchangeRateSnapshot: ExchangeRateSnapshot?
    let displayCurrencyCode: String
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            VStack(alignment: .leading, spacing: RevoxaSpacing.medium) {
                HStack(alignment: .top, spacing: RevoxaSpacing.small) {
                    SubscriptionLogoView(
                        subscriptionName: subscription.name,
                        iconAssetName: subscription.iconAssetName,
                        size: 38
                    )

                    VStack(alignment: .leading, spacing: RevoxaSpacing.xSmall) {
                        Text(subscription.name)
                            .font(RevoxaFont.body.weight(.semibold))
                            .foregroundStyle(RevoxaColor.textPrimary)
                            .lineLimit(2)

                        Text(subscription.category.title)
                            .font(RevoxaFont.caption)
                            .foregroundStyle(RevoxaColor.textSecondary)
                            .lineLimit(1)
                    }

                    Spacer(minLength: RevoxaSpacing.small)

                    RevoxaStatusBadge(status: subscription.status)
                }

                HStack(alignment: .firstTextBaseline, spacing: RevoxaSpacing.medium) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(
                            CurrencyDisplay.formattedAmount(
                                subscription.amount,
                                from: subscription.currencyCode,
                                to: displayCurrencyCode,
                                using: exchangeRateSnapshot
                            )
                        )
                            .font(RevoxaFont.body.weight(.semibold))
                            .foregroundStyle(RevoxaColor.textPrimary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.75)

                        Text(subscription.billingCycle.title)
                            .font(RevoxaFont.caption)
                            .foregroundStyle(RevoxaColor.textSecondary)
                            .lineLimit(1)
                    }

                    Spacer(minLength: RevoxaSpacing.small)

                    VStack(alignment: .trailing, spacing: 2) {
                        Text(RevoxaDateFormatter.mediumDate(subscription.nextBillingDate))
                            .font(RevoxaFont.caption.weight(.semibold))
                            .foregroundStyle(RevoxaColor.textPrimary)
                            .lineLimit(1)

                        Text(L10n.t("subscriptions.table.nextBilling"))
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(RevoxaColor.textSecondary)
                            .lineLimit(1)
                    }
                }
            }
            .padding(RevoxaSpacing.medium)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(RevoxaColor.surface)
            .clipShape(RoundedRectangle(cornerRadius: RevoxaRadius.medium, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: RevoxaRadius.medium, style: .continuous)
                    .stroke(RevoxaColor.borderSubtle, lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
    }
}

private struct SubscriptionTable: View {
    let subscriptions: [Subscription]
    let exchangeRateSnapshot: ExchangeRateSnapshot?
    let displayCurrencyCode: String
    let onSelect: (Subscription) -> Void

    var body: some View {
        VStack(spacing: 0) {
            SubscriptionTableHeader()

            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(subscriptions) { subscription in
                        SubscriptionTableRow(
                            subscription: subscription,
                            exchangeRateSnapshot: exchangeRateSnapshot,
                            displayCurrencyCode: displayCurrencyCode
                        ) {
                            onSelect(subscription)
                        }

                        if subscription.id != subscriptions.last?.id {
                            Divider()
                                .overlay(RevoxaColor.border)
                        }
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(RevoxaColor.surface)
        .clipShape(RoundedRectangle(cornerRadius: RevoxaRadius.medium))
        .overlay {
            RoundedRectangle(cornerRadius: RevoxaRadius.medium)
                .stroke(RevoxaColor.border, lineWidth: 1)
        }
    }
}

private struct SubscriptionTableHeader: View {
    var body: some View {
        HStack(spacing: RevoxaSpacing.medium) {
            TableHeaderText(L10n.t("subscriptions.table.name"), minWidth: 148, alignment: .leading)
                .frame(maxWidth: .infinity, alignment: .leading)
            TableHeaderText(L10n.t("subscriptions.table.amount"), minWidth: 78, alignment: .trailing)
            TableHeaderText(L10n.t("subscriptions.table.currency"), minWidth: 68, alignment: .leading)
            TableHeaderText(L10n.t("subscriptions.table.cycle"), minWidth: 78, alignment: .leading)
            TableHeaderText(L10n.t("subscriptions.table.nextBilling"), minWidth: 110, alignment: .leading)
            TableHeaderText(L10n.t("subscriptions.table.category"), minWidth: 92, alignment: .leading)
            TableHeaderText(L10n.t("subscriptions.table.status"), minWidth: 88, alignment: .leading)
        }
        .padding(.horizontal, RevoxaSpacing.large)
        .padding(.vertical, RevoxaSpacing.medium)
        .background(RevoxaColor.elevatedSurface)
    }
}

private struct SubscriptionTableRow: View {
    let subscription: Subscription
    let exchangeRateSnapshot: ExchangeRateSnapshot?
    let displayCurrencyCode: String
    let onSelect: () -> Void

    private var displayedAmount: (amount: Decimal, currencyCode: String) {
        CurrencyDisplay.convertedAmount(
            subscription.amount,
            from: subscription.currencyCode,
            to: displayCurrencyCode,
            using: exchangeRateSnapshot
        )
    }

    var body: some View {
        HStack(spacing: RevoxaSpacing.medium) {
            HStack(spacing: RevoxaSpacing.small) {
                SubscriptionLogoView(
                    subscriptionName: subscription.name,
                    iconAssetName: subscription.iconAssetName,
                    size: 32
                )

                Text(subscription.name)
                    .font(RevoxaFont.body.weight(.semibold))
                    .foregroundStyle(RevoxaColor.textPrimary)
                    .lineLimit(1)
            }
            .frame(minWidth: 148, maxWidth: .infinity, alignment: .leading)

            Text(CurrencyFormatter.string(from: displayedAmount.amount, currencyCode: displayedAmount.currencyCode))
                .font(RevoxaFont.body)
                .foregroundStyle(RevoxaColor.textPrimary)
                .lineLimit(1)
                .frame(minWidth: 78, alignment: .trailing)

            Text(displayedAmount.currencyCode)
                .font(RevoxaFont.body)
                .foregroundStyle(RevoxaColor.textSecondary)
                .frame(minWidth: 68, alignment: .leading)

            Text(subscription.billingCycle.title)
                .font(RevoxaFont.body)
                .foregroundStyle(RevoxaColor.textSecondary)
                .lineLimit(1)
                .frame(minWidth: 78, alignment: .leading)

            Text(RevoxaDateFormatter.mediumDate(subscription.nextBillingDate))
                .font(RevoxaFont.body)
                .foregroundStyle(RevoxaColor.textSecondary)
                .lineLimit(1)
                .frame(minWidth: 110, alignment: .leading)

            Text(subscription.category.title)
                .font(RevoxaFont.body)
                .foregroundStyle(RevoxaColor.textSecondary)
                .lineLimit(1)
                .frame(minWidth: 92, alignment: .leading)

            RevoxaStatusBadge(status: subscription.status)
                .frame(minWidth: 88, alignment: .leading)
        }
        .padding(.horizontal, RevoxaSpacing.large)
        .padding(.vertical, RevoxaSpacing.medium)
        .contentShape(Rectangle())
        .onTapGesture(perform: onSelect)
    }
}

private struct TableHeaderText: View {
    let title: String
    let minWidth: CGFloat
    let alignment: Alignment

    init(_ title: String, minWidth: CGFloat, alignment: Alignment) {
        self.title = title
        self.minWidth = minWidth
        self.alignment = alignment
    }

    var body: some View {
        Text(title)
            .font(RevoxaFont.caption)
            .foregroundStyle(RevoxaColor.textSecondary)
            .lineLimit(1)
            .frame(minWidth: minWidth, alignment: alignment)
    }
}

private struct SubscriptionEmptyState: View {
    let title: String
    let message: String

    var body: some View {
        RevoxaEmptyState(systemImage: "creditcard.trianglebadge.exclamationmark", title: title, message: message)
    }
}

private enum SubscriptionStatusFilter: String, CaseIterable, Identifiable {
    case all
    case active
    case trial
    case cancelSoon
    case cancelled
    case archived

    var id: String { rawValue }

    var title: String {
        switch self {
        case .all: L10n.t("statusFilter.all")
        case .active: L10n.t("status.active")
        case .trial: L10n.t("status.trial")
        case .cancelSoon: L10n.t("status.cancelSoon")
        case .cancelled: L10n.t("statusFilter.cancelled")
        case .archived: L10n.t("statusFilter.archive")
        }
    }

    func matches(_ subscription: Subscription) -> Bool {
        switch self {
        case .all:
            true
        case .active:
            subscription.status == .active
        case .trial:
            subscription.status == .trial
        case .cancelSoon:
            subscription.status == .cancelSoon
        case .cancelled:
            subscription.status == .cancelled
        case .archived:
            subscription.status == .archived
        }
    }
}
