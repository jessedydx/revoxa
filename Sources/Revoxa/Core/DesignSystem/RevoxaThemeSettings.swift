import SwiftData
import SwiftUI

enum RevoxaThemeSettings {
    static func readTheme(from defaults: UserDefaults = .standard) -> AppTheme {
        if let raw = defaults.string(forKey: PreferenceKey.appTheme) {
            return AppTheme.resolved(from: raw)
        }

        if let legacy = defaults.string(forKey: PreferenceKey.appAppearance) {
            return AppTheme.resolved(from: legacy)
        }

        return .system
    }

    static func writeTheme(_ theme: AppTheme, to defaults: UserDefaults = .standard) {
        defaults.set(theme.rawValue, forKey: PreferenceKey.appTheme)
        RevoxaSyncedPreferences.pushLocalChange(key: PreferenceKey.appTheme, value: theme.rawValue)
    }
}

struct RevoxaRootView<Content: View>: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.scenePhase) private var scenePhase
    @SyncedStringStorage(PreferenceKey.appTheme) private var appThemeRawValue = AppTheme.system.rawValue
    @SyncedStringStorage(PreferenceKey.appLanguage) private var appLanguageRawValue = AppLanguage.system.rawValue
    @AppStorage(PreferenceKey.hasSeenICloudOnboarding) private var hasSeenICloudOnboarding = false

    private let refreshesOnLanguageChange: Bool
    @ViewBuilder private let content: () -> Content

    @State private var preferencesRefreshToken = UUID()
    @State private var isShowingICloudOnboarding = false

    init(
        refreshesOnLanguageChange: Bool = true,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.refreshesOnLanguageChange = refreshesOnLanguageChange
        self.content = content
    }

    private var appTheme: AppTheme {
        if ScreenshotFixtures.isEnabled {
            return .dark
        }

        return AppTheme.resolved(from: appThemeRawValue)
    }

    private var effectiveLanguageRawValue: String {
        if ScreenshotFixtures.isEnabled {
            return AppLanguage.english.rawValue
        }

        return appLanguageRawValue
    }

    var body: some View {
        let root = content()
            .revoxaAppearance(theme: appTheme, languageRawValue: effectiveLanguageRawValue)
            .environment(RevoxaCloudSyncMonitor.shared)
            .task {
                await MainActor.run {
                    ScreenshotFixtures.seedIfNeeded(in: modelContext)
                    presentOnboardingIfNeeded()
                }
            }
            .onChange(of: scenePhase) { _, newPhase in
                guard newPhase == .active else { return }
                Task {
                    await RevoxaCloudSyncMonitor.shared.refreshAccountStatus()
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: .revoxaSyncedPreferencesDidChange)) { _ in
                preferencesRefreshToken = UUID()
            }
            .onReceive(NotificationCenter.default.publisher(for: .revoxaCloudDataDidChange)) { _ in
                RevoxaCloudNotificationCoordinator.refreshNotificationsIfNeeded(in: modelContext)
            }
            .sheet(isPresented: $isShowingICloudOnboarding) {
                ICloudOnboardingSheet()
            }

        Group {
            if refreshesOnLanguageChange {
                root
                    .id(appLanguageRawValue)
                    .id(preferencesRefreshToken)
            } else {
                root
                    .id(preferencesRefreshToken)
            }
        }
    }

    private func presentOnboardingIfNeeded() {
        guard ScreenshotFixtures.isEnabled == false,
              hasSeenICloudOnboarding == false,
              RevoxaPersistence.isCloudKitEnabled
        else {
            return
        }

        isShowingICloudOnboarding = true
    }
}

private struct RevoxaAppearanceModifier: ViewModifier {
    let theme: AppTheme
    let languageRawValue: String

    func body(content: Content) -> some View {
        content
            .preferredColorScheme(theme.preferredColorScheme)
            .environment(\.locale, RevoxaLanguageSettings.environmentLocale(for: languageRawValue))
    }
}

extension View {
    func revoxaAppearance(
        theme: AppTheme = RevoxaThemeSettings.readTheme(),
        languageRawValue: String = RevoxaLanguageSettings.readLanguage().rawValue
    ) -> some View {
        modifier(RevoxaAppearanceModifier(theme: theme, languageRawValue: languageRawValue))
    }

    func revoxaThemedRoot() -> some View {
        RevoxaRootView {
            self
        }
    }
}
