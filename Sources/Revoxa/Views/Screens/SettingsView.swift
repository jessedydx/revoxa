import SwiftData
import SwiftUI

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Query(sort: \Subscription.name) private var subscriptions: [Subscription]

    @AppStorage(PreferenceKey.defaultCurrencyCode) private var defaultCurrencyCode = PreferenceKey.defaultCurrencyCodeValue
    @AppStorage(PreferenceKey.defaultReminderDays) private var defaultReminderDays = 3
    @AppStorage(PreferenceKey.appTheme) private var appThemeRawValue = AppTheme.system.rawValue
    @AppStorage(PreferenceKey.appLanguage) private var appLanguageRawValue = AppLanguage.system.rawValue
    @AppStorage(PreferenceKey.notificationsEnabled) private var notificationsEnabled = false

    @State private var isConfirmingClearAllData = false
    @State private var exportMessage: String?
    @State private var showNotificationPermissionAlert = false

    private let dashboardCalculator = DashboardCalculator()
    private let notificationService = NotificationSchedulingService()

    private var isCompactLayout: Bool {
        horizontalSizeClass == .compact
    }

    private var appThemeBinding: Binding<AppTheme> {
        Binding {
            AppTheme.resolved(from: appThemeRawValue)
        } set: { newValue in
            appThemeRawValue = newValue.rawValue
        }
    }

    private var appLanguageBinding: Binding<AppLanguage> {
        Binding {
            AppLanguage.resolved(from: appLanguageRawValue)
        } set: { newValue in
            appLanguageRawValue = newValue.rawValue
        }
    }

    var body: some View {
        ZStack {
            RevoxaColor.appBackground
                .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: RevoxaSpacing.xLarge) {
                    header
                    generalSection
                    dataSection
                }
                .padding(isCompactLayout ? RevoxaSpacing.medium : RevoxaSpacing.xLarge)
                .frame(maxWidth: .infinity, alignment: .topLeading)
            }
        }
        .confirmationDialog(L10n.t("settings.clearAll.confirm"), isPresented: $isConfirmingClearAllData) {
            Button(L10n.t("settings.clearAll.button"), role: .destructive) {
                clearAllData()
            }
            Button(RevoxaStrings.cancel, role: .cancel) {}
        } message: {
            Text(L10n.t("settings.clearAll.message"))
        }
        .alert(RevoxaStrings.exportTitle, isPresented: exportMessageBinding) {
            Button(RevoxaStrings.ok, role: .cancel) {
                exportMessage = nil
            }
        } message: {
            Text(exportMessage ?? "")
        }
        .alert(L10n.t("settings.notificationDenied.title"), isPresented: $showNotificationPermissionAlert) {
            Button(L10n.t("settings.openNotificationSettings")) {
                NotificationSchedulingService.openSystemNotificationSettings()
            }
            Button(RevoxaStrings.cancel, role: .cancel) {}
        } message: {
            Text(L10n.t("settings.notificationDenied.message"))
        }
        .onAppear {
            guard ScreenshotFixtures.isEnabled == false else { return }

            notificationService.registerWithNotificationCenterIfNeeded()
            refreshNotificationToggleFromSystem()
        }
        .onReceive(NotificationCenter.default.publisher(for: .revoxaRefreshNotificationPermission)) { _ in
            refreshNotificationToggleFromSystem()
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: RevoxaSpacing.small) {
            Text(AppSection.settings.title.uppercased())
                .font(.system(size: 14, weight: .bold))
                .tracking(1.2)
                .foregroundStyle(RevoxaColor.accent)
        }
    }

    @ViewBuilder
    private var generalSection: some View {
        SettingsSection(title: L10n.t("settings.general")) {
            if isCompactLayout {
                mobileGeneralSettings
            } else {
                desktopGeneralSettings
            }
        }
    }

    private var desktopGeneralSettings: some View {
        Grid(alignment: .leading, horizontalSpacing: RevoxaSpacing.large, verticalSpacing: RevoxaSpacing.medium) {
            GridRow {
                settingsLabel(L10n.t("settings.currency"))
                Picker(L10n.t("settings.currency"), selection: defaultCurrencyBinding) {
                    ForEach(RevoxaCurrency.allCases) { currency in
                        Text(currency.pickerLabel).tag(currency)
                    }
                }
                .labelsHidden()
                .frame(width: 280)
            }

            GridRow {
                settingsLabel(L10n.t("settings.defaultReminderDays"))
                Stepper(value: $defaultReminderDays, in: 0...365) {
                    Text(RevoxaStrings.daysCount(defaultReminderDays))
                        .foregroundStyle(RevoxaColor.textPrimary)
                }
            }

            GridRow {
                settingsLabel(L10n.t("theme.title"))
                Picker(L10n.t("theme.title"), selection: appThemeBinding) {
                    ForEach(AppTheme.allCases) { theme in
                        Text(theme.title).tag(theme)
                    }
                }
                .pickerStyle(.segmented)
                .labelsHidden()
                .frame(maxWidth: 280)
            }

            GridRow {
                settingsLabel(L10n.t("language.title"))
                Picker(L10n.t("language.title"), selection: appLanguageBinding) {
                    ForEach(AppLanguage.allCases) { language in
                        Text(language.displayName).tag(language)
                    }
                }
                .pickerStyle(.segmented)
                .labelsHidden()
                .frame(maxWidth: 360)
            }

            Text(L10n.t("language.note"))
                .font(RevoxaFont.caption)
                .foregroundStyle(RevoxaColor.textSecondary)
                .gridCellColumns(2)

            GridRow {
                settingsLabel(L10n.t("settings.renewalReminders"))
                Toggle(L10n.t("settings.enableLocalNotifications"), isOn: notificationsEnabledBinding)
                    .toggleStyle(.switch)
            }
        }
    }

    private var mobileGeneralSettings: some View {
        VStack(alignment: .leading, spacing: RevoxaSpacing.medium) {
            mobileSettingsRow(L10n.t("settings.currency")) {
                Picker(L10n.t("settings.currency"), selection: defaultCurrencyBinding) {
                    ForEach(RevoxaCurrency.allCases) { currency in
                        Text(currency.pickerLabel).tag(currency)
                    }
                }
                .labelsHidden()
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            mobileSettingsRow(L10n.t("settings.defaultReminderDays")) {
                Stepper(value: $defaultReminderDays, in: 0...365) {
                    Text(RevoxaStrings.daysCount(defaultReminderDays))
                        .foregroundStyle(RevoxaColor.textPrimary)
                }
            }

            mobileSettingsRow(L10n.t("theme.title")) {
                Picker(L10n.t("theme.title"), selection: appThemeBinding) {
                    ForEach(AppTheme.allCases) { theme in
                        Text(theme.title).tag(theme)
                    }
                }
                .pickerStyle(.segmented)
                .labelsHidden()
            }

            mobileSettingsRow(L10n.t("language.title")) {
                Picker(L10n.t("language.title"), selection: appLanguageBinding) {
                    ForEach(AppLanguage.allCases) { language in
                        Text(language.displayName).tag(language)
                    }
                }
                .pickerStyle(.segmented)
                .labelsHidden()
            }

            Text(L10n.t("language.note"))
                .font(RevoxaFont.caption)
                .foregroundStyle(RevoxaColor.textSecondary)

            mobileSettingsRow(L10n.t("settings.renewalReminders")) {
                Toggle(L10n.t("settings.enableLocalNotifications"), isOn: notificationsEnabledBinding)
                    .toggleStyle(.switch)
            }
        }
    }

    private var dataSection: some View {
        SettingsSection(title: L10n.t("settings.data")) {
            VStack(alignment: .leading, spacing: RevoxaSpacing.medium) {
                ViewThatFits(in: .horizontal) {
                    HStack {
                        exportButtons
                    }

                    VStack(alignment: .leading, spacing: RevoxaSpacing.small) {
                        exportButtons
                    }
                }

                if ScreenshotFixtures.isEnabled == false {
                    Divider()
                        .overlay(RevoxaColor.border)

                    ViewThatFits(in: .horizontal) {
                        HStack {
                            deleteAllContent

                            Spacer()

                            deleteAllButton
                        }

                        VStack(alignment: .leading, spacing: RevoxaSpacing.xSmall) {
                            deleteAllContent
                            deleteAllButton
                        }
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var exportButtons: some View {
        Button(L10n.t("settings.exportSubscriptions")) {
            exportSubscriptions()
        }
        .tint(RevoxaColor.accent)

        Button(L10n.t("settings.exportDashboard")) {
            exportDashboardSummary()
        }
        .tint(RevoxaColor.accent)

        if isCompactLayout == false {
            Spacer()
        }
    }

    private var deleteAllContent: some View {
        VStack(alignment: .leading, spacing: RevoxaSpacing.xSmall) {
            Text(L10n.t("settings.deleteAll.title"))
                .font(RevoxaFont.body.weight(.semibold))
                .foregroundStyle(RevoxaColor.textPrimary)

            Text(L10n.t("settings.deleteAll.subtitle"))
                .font(RevoxaFont.caption)
                .foregroundStyle(RevoxaColor.textSecondary)
        }
    }

    private var deleteAllButton: some View {
        Button(L10n.t("settings.clearAll.button"), role: .destructive) {
            isConfirmingClearAllData = true
        }
        .tint(.red)
    }

    private var defaultCurrencyBinding: Binding<RevoxaCurrency> {
        Binding {
            RevoxaCurrency.resolved(from: defaultCurrencyCode)
        } set: { newValue in
            defaultCurrencyCode = newValue.code
        }
    }

    private var notificationsEnabledBinding: Binding<Bool> {
        Binding {
            notificationsEnabled
        } set: { newValue in
            if newValue {
                notificationService.requestPermission { granted in
                    if granted {
                        notificationsEnabled = true
                        notificationService.syncNotifications(for: subscriptions, enabled: true)
                    } else {
                        notificationsEnabled = false
                        showNotificationPermissionAlert = true
                    }
                }
            } else {
                notificationsEnabled = false
                notificationService.syncNotifications(for: subscriptions, enabled: false)
            }
        }
    }

    private func refreshNotificationToggleFromSystem() {
        notificationService.authorizationStatus { status in
            switch status {
            case .authorized, .provisional, .ephemeral:
                guard notificationsEnabled == false else { return }
                notificationsEnabled = true
                notificationService.syncNotifications(for: subscriptions, enabled: true)
            case .denied, .notDetermined:
                guard notificationsEnabled else { return }
                notificationsEnabled = false
                notificationService.syncNotifications(for: subscriptions, enabled: false)
            @unknown default:
                break
            }
        }
    }

    private var exportMessageBinding: Binding<Bool> {
        Binding {
            exportMessage != nil
        } set: { isPresented in
            if isPresented == false {
                exportMessage = nil
            }
        }
    }

    private func settingsLabel(_ title: String) -> some View {
        Text(title)
            .font(RevoxaFont.caption)
            .foregroundStyle(RevoxaColor.textSecondary)
            .frame(width: 160, alignment: .trailing)
    }

    private func mobileSettingsRow<Content: View>(
        _ title: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: RevoxaSpacing.xSmall) {
            Text(title)
                .font(RevoxaFont.caption)
                .foregroundStyle(RevoxaColor.textSecondary)

            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func exportSubscriptions() {
        CSVExportService.exportSubscriptions(subscriptions) { result in
            switch result {
            case .success(let filename):
                exportMessage = RevoxaStrings.exported(filename)
            case .failure(let error):
                exportMessage = RevoxaStrings.exportFailed(error.localizedDescription)
            }
        }
    }

    private func exportDashboardSummary() {
        let summary = dashboardCalculator.summary(for: subscriptions)
        CSVExportService.exportDashboardSummary(summary) { result in
            switch result {
            case .success(let filename):
                exportMessage = RevoxaStrings.exported(filename)
            case .failure(let error):
                exportMessage = RevoxaStrings.exportFailed(error.localizedDescription)
            }
        }
    }

    private func clearAllData() {
        notificationService.cancelNotifications(for: subscriptions)
        subscriptions.forEach(modelContext.delete)
    }
}

private struct SettingsSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: RevoxaSpacing.medium) {
            Text(title)
                .font(RevoxaFont.sectionTitle)
                .foregroundStyle(RevoxaColor.textPrimary)

            content
        }
        .padding(RevoxaSpacing.large)
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .background(RevoxaColor.surface)
        .clipShape(RoundedRectangle(cornerRadius: RevoxaRadius.medium))
        .overlay {
            RoundedRectangle(cornerRadius: RevoxaRadius.medium)
                .stroke(RevoxaColor.border, lineWidth: 1)
        }
    }
}
