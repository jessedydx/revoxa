import XCTest
@testable import Revoxa

final class RevoxaSyncedPreferencesTests: XCTestCase {
    func testSyncedKeysIncludeCorePreferences() {
        XCTAssertTrue(RevoxaSyncedPreferences.syncedKeys.contains(PreferenceKey.defaultCurrencyCode))
        XCTAssertTrue(RevoxaSyncedPreferences.syncedKeys.contains(PreferenceKey.defaultReminderDays))
        XCTAssertTrue(RevoxaSyncedPreferences.syncedKeys.contains(PreferenceKey.appTheme))
        XCTAssertTrue(RevoxaSyncedPreferences.syncedKeys.contains(PreferenceKey.appLanguage))
        XCTAssertFalse(RevoxaSyncedPreferences.syncedKeys.contains(PreferenceKey.notificationsEnabled))
    }

    func testPushLocalChangeIgnoresUnsyncedKeys() {
        RevoxaSyncedPreferences.pushLocalChange(key: PreferenceKey.notificationsEnabled, value: true)
        XCTAssertNil(NSUbiquitousKeyValueStore.default.object(forKey: PreferenceKey.notificationsEnabled))
    }
}
