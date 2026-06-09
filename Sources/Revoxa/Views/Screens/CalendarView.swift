import SwiftData
import SwiftUI

private enum CalendarLayout {
    static let pageHeaderHeight: CGFloat = 22
    static let minimumDayCellHeight: CGFloat = 72
    static let compactDayCellHeight: CGFloat = 50
}

struct CalendarView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Query(sort: \Subscription.nextBillingDate) private var subscriptions: [Subscription]
    @AppStorage(PreferenceKey.defaultCurrencyCode) private var displayCurrencyCode = PreferenceKey.defaultCurrencyCodeValue
    @State private var displayedMonth = Date()
    @State private var selectedCalendarDay: CalendarDay?
    @State private var editingSubscription: Subscription?
    @State private var exchangeRateSnapshot: ExchangeRateSnapshot?
    @State private var exchangeRateLoadFailed = false
    @State private var isShowingAnalytics = false

    private let billingSchedule = BillingScheduleCalculator()
    private let calendar = BillingScheduleCalculator.makeCalendar()
    private let exchangeRateService = ExchangeRateService.shared

    private var activeSubscriptions: [Subscription] {
        subscriptions.filter(\.isActiveLike)
    }

    private var monthInterval: DateInterval {
        billingSchedule.monthInterval(containing: displayedMonth)
    }

    private var monthDays: [CalendarDay] {
        RevoxaCalendar.days(for: monthInterval, occurrencesByDay: occurrencesByDay, calendar: calendar)
    }

    private var monthOccurrences: [BillingOccurrence] {
        activeSubscriptions.flatMap { subscription in
            billingSchedule.occurrences(for: subscription, in: monthInterval)
        }
        .sorted {
            if $0.date != $1.date {
                return $0.date < $1.date
            }

            return $0.subscription.name.localizedCaseInsensitiveCompare($1.subscription.name) == .orderedAscending
        }
    }

    private var occurrencesByDay: [Date: [BillingOccurrence]] {
        Dictionary(grouping: monthOccurrences) { occurrence in
            calendar.startOfDay(for: occurrence.date)
        }
    }

    private var monthTotals: [CurrencyTotal] {
        billingSchedule.paymentTotals(for: activeSubscriptions, in: monthInterval)
    }

    private var displayMonthTotals: [CurrencyTotal] {
        CurrencyDisplay.displayTotals(monthTotals, in: displayCurrencyCode, using: exchangeRateSnapshot)
    }

    private var calendarGridRowCount: Int {
        max((monthDays.count + 6) / 7, 1)
    }

    private var isCompactLayout: Bool {
        horizontalSizeClass == .compact
    }

    var body: some View {
        ZStack {
            RevoxaColor.appBackground
                .ignoresSafeArea()

            calendarContent
        }
        #if os(macOS)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    RevoxaAppActions.addSubscription()
                } label: {
                    Label(RevoxaStrings.addSubscription, systemImage: "plus")
                }
                .revoxaPrimaryButton()
                .keyboardShortcut("n", modifiers: .command)
            }
        }
        #endif
        .task {
            await refreshExchangeRates()
        }
        .onAppear {
            presentScreenshotSceneIfNeeded()
        }
        .onChange(of: subscriptions.count) { _, _ in
            presentScreenshotSceneIfNeeded()
        }
        .onChange(of: monthOccurrences.count) { _, _ in
            presentScreenshotSceneIfNeeded()
        }
        .sheet(item: $editingSubscription) { subscription in
            SubscriptionFormView(subscription: subscription) { subscription in
                modelContext.delete(subscription)
            }
        }
        .sheet(item: $selectedCalendarDay) { day in
            CalendarDayOccurrencesSheet(
                day: day,
                exchangeRateSnapshot: exchangeRateSnapshot,
                displayCurrencyCode: displayCurrencyCode
            ) { subscription in
                openSubscriptionEditor(fromDaySheet: subscription)
            }
            .revoxaPresentationDetents()
        }
        .sheet(isPresented: $isShowingAnalytics) {
            CalendarAnalyticsSheet(
                displayedMonth: displayedMonth,
                subscriptions: activeSubscriptions,
                exchangeRateSnapshot: exchangeRateSnapshot,
                displayCurrencyCode: displayCurrencyCode
            )
        }
    }

    @ViewBuilder
    private var calendarContent: some View {
        if isCompactLayout {
            ScrollView {
                VStack(alignment: .leading, spacing: RevoxaSpacing.medium) {
                    #if os(macOS)
                    pageHeader
                    #endif
                    calendarCard
                }
                .padding(RevoxaSpacing.medium)
                .frame(maxWidth: .infinity, alignment: .topLeading)
            }
        } else {
            GeometryReader { geometry in
                let verticalPadding = RevoxaSpacing.xLarge * 2
                #if os(macOS)
                let headerBlock = CalendarLayout.pageHeaderHeight + RevoxaSpacing.large
                #else
                let headerBlock: CGFloat = 0
                #endif
                let calendarCardHeight = geometry.size.height - verticalPadding - headerBlock

                ScrollView {
                    VStack(alignment: .leading, spacing: RevoxaSpacing.large) {
                        #if os(macOS)
                        pageHeader
                        #endif
                        calendarCard
                            .frame(height: max(calendarCardHeight, 520))
                    }
                    .padding(RevoxaSpacing.xLarge)
                    .frame(maxWidth: .infinity, alignment: .topLeading)
                }
            }
        }
    }

    private var pageHeader: some View {
        VStack(alignment: .leading, spacing: RevoxaSpacing.small) {
            Text(AppSection.calendar.title.uppercased())
                .font(.system(size: 14, weight: .bold))
                .tracking(1.2)
                .foregroundStyle(RevoxaColor.accent)
        }
    }

    private var calendarCard: some View {
        VStack(spacing: RevoxaSpacing.medium) {
            monthToolbar

            monthSummaryHeader

            CalendarWeekdayHeader(weekdays: weekdaySymbols, isCompact: isCompactLayout)

            calendarGrid
        }
        .padding(isCompactLayout ? RevoxaSpacing.medium : RevoxaSpacing.large)
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
        .shadow(color: Color.black.opacity(0.05), radius: 14, x: 0, y: 6)
    }

    @ViewBuilder
    private var calendarGrid: some View {
        if isCompactLayout {
            LazyVGrid(columns: calendarColumns, spacing: RevoxaSpacing.xSmall) {
                ForEach(monthDays) { day in
                    CalendarDayCell(
                        day: day,
                        cellHeight: CalendarLayout.compactDayCellHeight,
                        logoSize: 20,
                        isToday: calendar.isDateInToday(day.date),
                        isCompact: true
                    ) { selectedDay in
                        selectedCalendarDay = selectedDay
                    }
                }
            }
        } else {
            GeometryReader { geometry in
                let gridSpacing = RevoxaSpacing.small
                let rowCount = CGFloat(calendarGridRowCount)
                let rowHeight = max(
                    (geometry.size.height - gridSpacing * (rowCount - 1)) / rowCount,
                    CalendarLayout.minimumDayCellHeight
                )
                let logoSize = min(30, max(20, rowHeight - 24))

                LazyVGrid(columns: calendarColumns, spacing: gridSpacing) {
                    ForEach(monthDays) { day in
                        CalendarDayCell(
                            day: day,
                            cellHeight: rowHeight,
                            logoSize: logoSize,
                            isToday: calendar.isDateInToday(day.date),
                            isCompact: false
                        ) { selectedDay in
                            selectedCalendarDay = selectedDay
                        }
                    }
                }
            }
            .frame(maxHeight: .infinity)
        }
    }

    private var monthSummaryHeader: some View {
        VStack(spacing: RevoxaSpacing.xSmall) {
            Text(monthTitle)
                .font(.system(size: isCompactLayout ? 20 : 24, weight: .semibold, design: .rounded))
                .foregroundStyle(RevoxaColor.textPrimary)

            RevoxaCurrencyTotalsView(
                totals: displayMonthTotals,
                font: .system(size: isCompactLayout ? 26 : 34, weight: .bold, design: .rounded)
            )
            .multilineTextAlignment(.center)

            Text(monthSummaryText)
                .font(RevoxaFont.caption)
                .foregroundStyle(RevoxaColor.accent)
                .padding(.horizontal, RevoxaSpacing.medium)
                .padding(.vertical, RevoxaSpacing.xSmall)
                .background(RevoxaColor.accent.opacity(0.14))
                .clipShape(Capsule())

            if let exchangeRateFootnote {
                Text(exchangeRateFootnote)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(RevoxaColor.textSecondary)
                    .lineLimit(1)
            }
        }
        .frame(maxWidth: .infinity)
    }

    private var monthToolbar: some View {
        HStack {
            Button {
                moveMonth(by: -1)
            } label: {
                Label(L10n.t("calendar.previousMonth"), systemImage: "chevron.left")
                    .labelStyle(.iconOnly)
            }
            .buttonStyle(.borderless)

            Button {
                displayedMonth = Date()
            } label: {
                Text(L10n.t("calendar.today"))
            }
            .buttonStyle(.bordered)
            .controlSize(.small)

            Spacer()

            Button {
                isShowingAnalytics = true
            } label: {
                if isCompactLayout {
                    Image(systemName: "chart.pie.fill")
                        .accessibilityLabel(AppSection.insights.title)
                } else {
                    Label(AppSection.insights.title, systemImage: "chart.pie.fill")
                }
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
            .tint(RevoxaColor.accent)

            Button {
                moveMonth(by: 1)
            } label: {
                Label(L10n.t("calendar.nextMonth"), systemImage: "chevron.right")
                    .labelStyle(.iconOnly)
            }
            .buttonStyle(.borderless)
        }
    }

    private var calendarColumns: [GridItem] {
        Array(
            repeating: GridItem(
                .flexible(minimum: isCompactLayout ? 0 : 72),
                spacing: isCompactLayout ? RevoxaSpacing.xSmall : RevoxaSpacing.small
            ),
            count: 7
        )
    }

    private var monthTitle: String {
        monthInterval.start.formatted(
            .dateTime
                .month(.wide)
                .year()
                .locale(RevoxaLanguageSettings.resolvedLocale)
        )
    }

    private var monthSummaryText: String {
        L10n.tf("calendar.monthSummary", monthOccurrences.count)
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

    private var weekdaySymbols: [String] {
        let formatter = DateFormatter()
        formatter.locale = RevoxaLanguageSettings.resolvedLocale
        let symbols = formatter.veryShortStandaloneWeekdaySymbols ?? formatter.veryShortWeekdaySymbols ?? []
        guard symbols.count == 7 else { return ["M", "T", "W", "T", "F", "S", "S"] }

        let start = max(calendar.firstWeekday - 1, 0)
        return Array(symbols[start...]) + Array(symbols[..<start])
    }

    private func moveMonth(by value: Int) {
        displayedMonth = calendar.date(byAdding: .month, value: value, to: displayedMonth) ?? displayedMonth
    }

    private func presentScreenshotSceneIfNeeded() {
        guard ScreenshotFixtures.isEnabled,
              ScreenshotFixtures.requestedScene == .dayModal,
              selectedCalendarDay == nil,
              let day = monthDays
                .filter(\.isInDisplayedMonth)
                .max(by: { $0.occurrences.count < $1.occurrences.count }),
              day.occurrences.isEmpty == false
        else { return }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            selectedCalendarDay = day
        }
    }

    private func openSubscriptionEditor(fromDaySheet subscription: Subscription) {
        selectedCalendarDay = nil

        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 180_000_000)
            editingSubscription = subscription
        }
    }
}

private struct CalendarWeekdayHeader: View {
    let weekdays: [String]
    let isCompact: Bool

    var body: some View {
        HStack(spacing: isCompact ? RevoxaSpacing.xSmall : RevoxaSpacing.small) {
            ForEach(Array(weekdays.enumerated()), id: \.offset) { _, weekday in
                Text(weekday)
                    .font(.system(size: isCompact ? 10 : 12, weight: .bold, design: .rounded))
                    .foregroundStyle(RevoxaColor.textSecondary)
                    .frame(maxWidth: .infinity)
            }
        }
    }
}

private struct CalendarDayCell: View {
    let day: CalendarDay
    let cellHeight: CGFloat
    let logoSize: CGFloat
    let isToday: Bool
    let isCompact: Bool
    let onSelectDay: (CalendarDay) -> Void

    private var visibleOccurrences: [BillingOccurrence] {
        Array(day.occurrences.prefix(isCompact ? 1 : 3))
    }

    @ViewBuilder
    var body: some View {
        if day.occurrences.isEmpty {
            cellContent
                .accessibilityLabel(accessibilityLabel)
        } else {
            Button {
                onSelectDay(day)
            } label: {
                cellContent
            }
            .buttonStyle(.plain)
            .accessibilityLabel(accessibilityLabel)
        }
    }

    private var cellContent: some View {
        VStack(alignment: .leading, spacing: RevoxaSpacing.xSmall) {
            HStack {
                Spacer()

                Text("\(day.dayNumber)")
                    .font(.system(size: isCompact ? 11 : 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(day.isInDisplayedMonth ? RevoxaColor.textPrimary : RevoxaColor.textSecondary.opacity(0.55))
            }

            if visibleOccurrences.isEmpty == false {
                HStack(spacing: -5) {
                    ForEach(visibleOccurrences) { occurrence in
                        SubscriptionLogoView(
                            subscriptionName: occurrence.subscription.name,
                            iconAssetName: occurrence.subscription.iconAssetName,
                            size: logoSize,
                            shapeStyle: .circle
                        )
                        .shadow(color: Color.black.opacity(0.14), radius: 3, x: 0, y: 1)
                        .help(occurrence.subscription.name)
                    }

                    if day.occurrences.count > visibleOccurrences.count {
                        Text("+\(day.occurrences.count - visibleOccurrences.count)")
                            .font(.system(size: 9, weight: .bold, design: .rounded))
                            .foregroundStyle(RevoxaColor.textPrimary)
                            .frame(width: logoSize, height: logoSize)
                            .background(RevoxaColor.elevatedSurface)
                            .clipShape(Circle())
                            .overlay {
                                Circle().stroke(RevoxaColor.border, lineWidth: 1)
                            }
                    }
                }
                .padding(.leading, 2)
            }

            Spacer(minLength: 0)
        }
        .padding(isCompact ? 3 : RevoxaSpacing.xSmall)
        .frame(maxWidth: .infinity, minHeight: cellHeight, maxHeight: cellHeight, alignment: .topLeading)
        .background(background)
        .clipShape(RoundedRectangle(cornerRadius: RevoxaRadius.medium, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: RevoxaRadius.medium, style: .continuous)
                .stroke(borderColor, lineWidth: isToday ? 1.4 : 1)
        }
        .contentShape(RoundedRectangle(cornerRadius: RevoxaRadius.medium, style: .continuous))
        .opacity(day.isInDisplayedMonth ? 1 : 0.45)
    }

    private var background: Color {
        if day.occurrences.isEmpty == false {
            return day.occurrences.first?.categoryTint.opacity(0.18) ?? RevoxaColor.elevatedSurface
        }

        return RevoxaColor.elevatedSurface.opacity(day.isInDisplayedMonth ? 0.62 : 0.34)
    }

    private var borderColor: Color {
        if isToday {
            return RevoxaColor.accent.opacity(0.72)
        }

        return RevoxaColor.borderSubtle
    }

    private var accessibilityLabel: String {
        if day.occurrences.isEmpty {
            return "\(day.dayNumber), \(L10n.t("calendar.noPaymentsForDay"))"
        }

        return "\(day.dayNumber), \(L10n.tf("calendar.dayPaymentCount", day.occurrences.count))"
    }
}

private struct CalendarDayOccurrencesSheet: View {
    let day: CalendarDay
    let exchangeRateSnapshot: ExchangeRateSnapshot?
    let displayCurrencyCode: String
    let onSelectSubscription: (Subscription) -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    private var isCompactLayout: Bool {
        horizontalSizeClass == .compact
    }

    private var sheetMinWidth: CGFloat? {
        isCompactLayout ? nil : 520
    }

    private var sheetMinHeight: CGFloat? {
        isCompactLayout ? nil : 420
    }

    private var dateTitle: String {
        day.date.formatted(
            .dateTime
                .day()
                .month(.wide)
                .year()
                .locale(RevoxaLanguageSettings.resolvedLocale)
        )
    }

    var body: some View {
        VStack(spacing: 0) {
            sheetHeader

            ScrollView {
                VStack(alignment: .leading, spacing: RevoxaSpacing.medium) {
                    if day.occurrences.isEmpty {
                        RevoxaEmptyState(
                            systemImage: "calendar.badge.exclamationmark",
                            title: L10n.t("calendar.selectedDay"),
                            message: L10n.t("calendar.noPaymentsForDay")
                        )
                    } else {
                        ForEach(day.occurrences) { occurrence in
                            CalendarDayOccurrenceRow(
                                occurrence: occurrence,
                                exchangeRateSnapshot: exchangeRateSnapshot,
                                displayCurrencyCode: displayCurrencyCode
                            ) {
                                onSelectSubscription(occurrence.subscription)
                            }
                        }
                    }
                }
                .padding(isCompactLayout ? RevoxaSpacing.medium : RevoxaSpacing.xLarge)
                .frame(maxWidth: .infinity, alignment: .topLeading)
            }
        }
        .frame(minWidth: sheetMinWidth, minHeight: sheetMinHeight)
        .background(RevoxaColor.appBackground)
    }

    private var sheetHeader: some View {
        HStack(alignment: .center, spacing: RevoxaSpacing.medium) {
            VStack(alignment: .leading, spacing: RevoxaSpacing.xSmall) {
                Text(L10n.t("calendar.selectedDay").uppercased())
                    .font(.system(size: 12, weight: .bold))
                    .tracking(1.1)
                    .foregroundStyle(RevoxaColor.accent)

                Text(dateTitle)
                    .font(isCompactLayout ? RevoxaFont.sectionTitle : RevoxaFont.pageTitle)
                    .foregroundStyle(RevoxaColor.textPrimary)
                    .lineLimit(2)
            }

            Spacer()

            if day.occurrences.isEmpty == false {
                Text(L10n.tf("calendar.dayPaymentCount", day.occurrences.count))
                    .font(RevoxaFont.caption)
                    .foregroundStyle(RevoxaColor.accent)
                    .padding(.horizontal, RevoxaSpacing.small)
                    .padding(.vertical, RevoxaSpacing.xSmall)
                    .background(RevoxaColor.accent.opacity(0.14))
                    .clipShape(Capsule())
            }

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
}

private struct CalendarDayOccurrenceRow: View {
    let occurrence: BillingOccurrence
    let exchangeRateSnapshot: ExchangeRateSnapshot?
    let displayCurrencyCode: String
    let onSelect: () -> Void

    private var subscription: Subscription {
        occurrence.subscription
    }

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: RevoxaSpacing.medium) {
                SubscriptionLogoView(
                    subscriptionName: subscription.name,
                    iconAssetName: subscription.iconAssetName,
                    size: 44,
                    shapeStyle: .roundedRectangle
                )

                VStack(alignment: .leading, spacing: RevoxaSpacing.xSmall) {
                    Text(subscription.name)
                        .font(RevoxaFont.sectionTitle)
                        .foregroundStyle(RevoxaColor.textPrimary)
                        .lineLimit(1)

                    HStack(spacing: RevoxaSpacing.xSmall) {
                        Text(subscription.category.title)
                            .font(RevoxaFont.caption)
                            .foregroundStyle(subscription.category.chartColor)
                            .lineLimit(1)

                        Text("/")
                            .font(RevoxaFont.caption)
                            .foregroundStyle(RevoxaColor.textSecondary)

                        Text(subscription.billingCycle.title)
                            .font(RevoxaFont.caption)
                            .foregroundStyle(RevoxaColor.textSecondary)
                            .lineLimit(1)
                    }
                }

                Spacer(minLength: RevoxaSpacing.small)

                VStack(alignment: .trailing, spacing: RevoxaSpacing.xSmall) {
                    Text(
                        CurrencyDisplay.formattedAmount(
                            subscription.amount,
                            from: subscription.currencyCode,
                            to: displayCurrencyCode,
                            using: exchangeRateSnapshot
                        )
                    )
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundStyle(RevoxaColor.textPrimary)
                        .lineLimit(1)

                    Image(systemName: "chevron.right")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(RevoxaColor.textSecondary)
                }
            }
            .padding(RevoxaSpacing.medium)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                LinearGradient(
                    colors: [
                        subscription.category.chartColor.opacity(0.14),
                        RevoxaColor.surface
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: RevoxaRadius.medium, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: RevoxaRadius.medium, style: .continuous)
                    .stroke(RevoxaColor.borderSubtle, lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(subscription.name)
    }
}

private extension View {
    @ViewBuilder
    func revoxaPresentationDetents() -> some View {
        #if os(iOS)
        self.presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        #else
        self
        #endif
    }
}

private struct CalendarDay: Identifiable {
    var id: Date { date }
    let date: Date
    let dayNumber: Int
    let isInDisplayedMonth: Bool
    let occurrences: [BillingOccurrence]
}

private extension BillingOccurrence {
    var categoryTint: Color {
        subscription.category.chartColor
    }
}

private enum RevoxaCalendar {
    static func days(
        for monthInterval: DateInterval,
        occurrencesByDay: [Date: [BillingOccurrence]],
        calendar: Calendar
    ) -> [CalendarDay] {
        let monthStart = monthInterval.start
        let monthEnd = monthInterval.end
        let firstWeekdayOffset = weekdayOffset(for: monthStart, calendar: calendar)
        let gridStart = calendar.date(byAdding: .day, value: -firstWeekdayOffset, to: monthStart) ?? monthStart
        let lastMonthDay = calendar.date(byAdding: .day, value: -1, to: monthEnd) ?? monthStart
        let lastWeekdayOffset = 6 - weekdayOffset(for: lastMonthDay, calendar: calendar)
        let gridEnd = calendar.date(byAdding: .day, value: lastWeekdayOffset + 1, to: lastMonthDay) ?? monthEnd
        let numberOfDays = calendar.dateComponents([.day], from: gridStart, to: gridEnd).day ?? 0

        return (0..<max(numberOfDays, 35)).compactMap { index in
            guard let date = calendar.date(byAdding: .day, value: index, to: gridStart) else {
                return nil
            }

            let dayStart = calendar.startOfDay(for: date)
            return CalendarDay(
                date: dayStart,
                dayNumber: calendar.component(.day, from: date),
                isInDisplayedMonth: monthInterval.contains(dayStart),
                occurrences: occurrencesByDay[dayStart] ?? []
            )
        }
    }

    private static func weekdayOffset(for date: Date, calendar: Calendar) -> Int {
        (calendar.component(.weekday, from: date) - calendar.firstWeekday + 7) % 7
    }
}
