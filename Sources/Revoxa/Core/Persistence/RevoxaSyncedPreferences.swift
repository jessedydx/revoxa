import Foundation

extension Notification.Name {
    static let revoxaSyncedPreferencesDidChange = Notification.Name("revoxa.syncedPreferencesDidChange")
    static let revoxaCloudDataDidChange = Notification.Name("revoxa.cloudDataDidChange")
}

enum RevoxaSyncedPreferences {
    static let syncedKeys: Set<String> = [
        PreferenceKey.defaultCurrencyCode,
        PreferenceKey.defaultReminderDays,
        PreferenceKey.appTheme,
        PreferenceKey.appLanguage,
    ]

    static func start() {
        guard ScreenshotFixtures.isEnabled == false else { return }

        migrateLocalToCloudIfNeeded()
        pullFromCloudToLocal()

        NotificationCenter.default.addObserver(
            forName: NSUbiquitousKeyValueStore.didChangeExternallyNotification,
            object: NSUbiquitousKeyValueStore.default,
            queue: .main
        ) { _ in
            pullFromCloudToLocal()
            NotificationCenter.default.post(name: .revoxaSyncedPreferencesDidChange, object: nil)
        }
    }

    static func pushLocalChange(key: String, value: Any) {
        guard syncedKeys.contains(key) else { return }

        let store = NSUbiquitousKeyValueStore.default
        switch value {
        case let string as String:
            store.set(string, forKey: key)
        case let int as Int:
            store.set(int, forKey: key)
        case let bool as Bool:
            store.set(bool, forKey: key)
        default:
            return
        }
        store.synchronize()
    }

    static func pullFromCloudToLocal() {
        let store = NSUbiquitousKeyValueStore.default
        store.synchronize()

        let defaults = UserDefaults.standard
        for key in syncedKeys {
            guard let cloudValue = store.object(forKey: key) else { continue }
            defaults.set(cloudValue, forKey: key)
        }
    }

    private static func migrateLocalToCloudIfNeeded() {
        let store = NSUbiquitousKeyValueStore.default
        store.synchronize()

        let defaults = UserDefaults.standard
        var didPush = false

        for key in syncedKeys {
            guard store.object(forKey: key) == nil,
                  let localValue = defaults.object(forKey: key)
            else {
                continue
            }

            store.set(localValue, forKey: key)
            didPush = true
        }

        if didPush {
            store.synchronize()
        }
    }
}
