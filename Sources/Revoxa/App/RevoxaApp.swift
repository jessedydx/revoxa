import SwiftData
import SwiftUI
import UserNotifications

#if os(macOS)
import AppKit
#endif

@main
struct RevoxaApp: App {
    #if os(macOS)
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    #else
    init() {
        RevoxaIOSNavigationAppearance.configure()
    }
    #endif

    private let modelContainer: ModelContainer = {
        do {
            return try ScreenshotFixtures.makeModelContainer()
        } catch {
            fatalError("Failed to create SwiftData container: \(error)")
        }
    }()

    @SceneBuilder
    var body: some Scene {
        mainWindowScene

        #if os(macOS)
        menuBarScene
        settingsScene
        #endif
    }

    #if os(macOS)
    private var mainWindowScene: some Scene {
        WindowGroup(RevoxaStrings.appName, id: "main") {
            RevoxaRootView {
                ContentView()
                    .frame(minWidth: 1180, minHeight: 760)
            }
        }
        .modelContainer(modelContainer)
        .windowStyle(.titleBar)
        .windowToolbarStyle(.unifiedCompact)
        .commands {
            CommandGroup(after: .newItem) {
                Button(RevoxaStrings.addSubscription) {
                    RevoxaAppActions.addSubscription()
                }
                .keyboardShortcut("n", modifiers: .command)
            }

            CommandMenu(L10n.t("command.find")) {
                Button(RevoxaStrings.search) {
                    RevoxaAppActions.focusSearch()
                }
                .keyboardShortcut("f", modifiers: .command)
            }

            CommandGroup(replacing: .appSettings) {
                Button(L10n.t("command.settingsEllipsis")) {
                    RevoxaAppActions.openSettings()
                }
                .keyboardShortcut(",", modifiers: .command)
            }
        }
    }

    private var menuBarScene: some Scene {
        MenuBarExtra {
            RevoxaRootView(refreshesOnLanguageChange: false) {
                MenuBarPopoverView()
            }
        } label: {
            RevoxaMenuBarIcon.templateImage
                .accessibilityLabel(RevoxaStrings.appName)
        }
        .menuBarExtraStyle(.window)
        .modelContainer(modelContainer)
    }

    private var settingsScene: some Scene {
        Settings {
            RevoxaRootView {
                SettingsView()
                    .frame(width: 640, height: 580)
            }
        }
        .modelContainer(modelContainer)
    }
    #else
    private var mainWindowScene: some Scene {
        WindowGroup(RevoxaStrings.appName, id: "main") {
            RevoxaRootView {
                RevoxaMobileRootView()
            }
        }
        .modelContainer(modelContainer)
    }
    #endif
}

#if os(macOS)
final class AppDelegate: NSObject, NSApplicationDelegate, UNUserNotificationCenterDelegate {
    private let notificationService = NotificationSchedulingService()

    func applicationDidFinishLaunching(_ notification: Notification) {
        migrateLegacyAppearancePreferenceIfNeeded()
        NSApp.setActivationPolicy(.regular)
        UNUserNotificationCenter.current().delegate = self
        notificationService.registerWithNotificationCenterIfNeeded()
        RevoxaWindowConfigurator.install()

        DispatchQueue.main.async {
            ScreenshotFixtures.showMacScreenshotWindowIfNeeded()
            RevoxaWindowConfigurator.configureAll()
            RevoxaAppActions.activateMainWindow()
        }
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound])
    }

    func applicationDidBecomeActive(_ notification: Notification) {
        RevoxaWindowConfigurator.configureAll()
        NotificationCenter.default.post(name: .revoxaRefreshNotificationPermission, object: nil)
    }

    private func migrateLegacyAppearancePreferenceIfNeeded() {
        let defaults = UserDefaults.standard
        guard defaults.string(forKey: PreferenceKey.appTheme) == nil,
              let legacy = defaults.string(forKey: PreferenceKey.appAppearance)
        else {
            return
        }

        RevoxaThemeSettings.writeTheme(AppTheme.resolved(from: legacy), to: defaults)
    }
}
#endif
