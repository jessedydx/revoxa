import Foundation
import UserNotifications

#if os(macOS)
import AppKit
#elseif os(iOS)
import UIKit
#endif

protocol NotificationSchedulingClient {
    func authorizationStatus(completionHandler: @escaping @Sendable (UNAuthorizationStatus) -> Void)
    func requestAuthorization(
        options: UNAuthorizationOptions,
        completionHandler: @escaping @Sendable (Bool, Error?) -> Void
    )
    func add(_ request: UNNotificationRequest, withCompletionHandler completionHandler: (@Sendable (Error?) -> Void)?)
    func removePendingNotificationRequests(withIdentifiers identifiers: [String])
    func removeDeliveredNotifications(withIdentifiers identifiers: [String])
}

extension UNUserNotificationCenter: NotificationSchedulingClient {
    func authorizationStatus(completionHandler: @escaping @Sendable (UNAuthorizationStatus) -> Void) {
        getNotificationSettings { settings in
            completionHandler(settings.authorizationStatus)
        }
    }
}

struct NotificationSchedulingService {
    var notificationCenter: NotificationSchedulingClient
    var calendar: Calendar
    var billingCalculator: BillingCalculator

    private static let authorizationOptions: UNAuthorizationOptions = [.alert, .sound]

    init(
        notificationCenter: NotificationSchedulingClient = UNUserNotificationCenter.current(),
        calendar: Calendar = .current,
        billingCalculator: BillingCalculator = BillingCalculator()
    ) {
        self.notificationCenter = notificationCenter
        self.calendar = calendar
        self.billingCalculator = billingCalculator
    }

    func authorizationStatus(completion: @escaping (UNAuthorizationStatus) -> Void) {
        notificationCenter.authorizationStatus { status in
            DispatchQueue.main.async {
                completion(status)
            }
        }
    }

    /// Ensures macOS registers this app under System Settings → Notifications (requires a real bundle ID).
    func registerWithNotificationCenterIfNeeded() {
        guard ScreenshotFixtures.isEnabled == false else { return }

        notificationCenter.authorizationStatus { [notificationCenter] status in
            guard status == .notDetermined else { return }
            notificationCenter.requestAuthorization(options: Self.authorizationOptions) { _, _ in }
        }
    }

    func requestPermission(completion: @escaping (Bool) -> Void) {
        notificationCenter.authorizationStatus { [notificationCenter] status in
            switch status {
            case .authorized, .provisional, .ephemeral:
                DispatchQueue.main.async {
                    completion(true)
                }
            case .denied:
                DispatchQueue.main.async {
                    completion(false)
                }
            case .notDetermined:
                notificationCenter.requestAuthorization(options: Self.authorizationOptions) { granted, _ in
                    DispatchQueue.main.async {
                        completion(granted)
                    }
                }
            @unknown default:
                DispatchQueue.main.async {
                    completion(false)
                }
            }
        }
    }

    @MainActor
    static func openSystemNotificationSettings() {
        #if os(macOS)
        let bundleID = Bundle.main.bundleIdentifier ?? "com.revoxa.app"
        let candidates = [
            "x-apple.systempreferences:com.apple.Notifications-Settings.extension?id=\(bundleID)",
            "x-apple.systempreferences:com.apple.preference.notifications?id=\(bundleID)",
            "x-apple.systempreferences:com.apple.preference.notifications",
        ]
        for candidate in candidates {
            guard let url = URL(string: candidate), NSWorkspace.shared.open(url) else { continue }
            return
        }
        #elseif os(iOS)
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
        #endif
    }

    func syncNotifications(for subscriptions: [Subscription], enabled: Bool, now: Date = .now) {
        if enabled {
            subscriptions.forEach { syncNotification(for: $0, enabled: true, now: now) }
        } else {
            cancelNotifications(for: subscriptions)
        }
    }

    func syncNotification(for subscription: Subscription, enabled: Bool, now: Date = .now) {
        cancelNotification(for: subscription)

        guard enabled,
              subscription.isActiveLike,
              let request = notificationRequest(for: subscription, now: now)
        else {
            return
        }

        notificationCenter.add(request, withCompletionHandler: nil)
    }

    func cancelNotification(for subscription: Subscription) {
        cancelNotification(subscriptionID: subscription.id)
    }

    func cancelNotifications(for subscriptions: [Subscription]) {
        let identifiers = subscriptions.map { notificationIdentifier(subscriptionID: $0.id) }
        notificationCenter.removePendingNotificationRequests(withIdentifiers: identifiers)
        notificationCenter.removeDeliveredNotifications(withIdentifiers: identifiers)
    }

    func cancelNotification(subscriptionID: UUID) {
        let identifier = notificationIdentifier(subscriptionID: subscriptionID)
        notificationCenter.removePendingNotificationRequests(withIdentifiers: [identifier])
        notificationCenter.removeDeliveredNotifications(withIdentifiers: [identifier])
    }

    func notificationIdentifier(subscriptionID: UUID) -> String {
        "revoxa.subscription.\(subscriptionID.uuidString).renewal"
    }

    func notificationRequest(for subscription: Subscription, now: Date = .now) -> UNNotificationRequest? {
        guard let reminderDate = reminderDate(for: subscription, now: now),
              reminderDate > now
        else {
            return nil
        }

        let content = UNMutableNotificationContent()
        content.title = RevoxaStrings.appName
        content.body = notificationBody(for: subscription)
        content.sound = .default

        let dateComponents = calendar.dateComponents(
            [.year, .month, .day, .hour, .minute],
            from: reminderDate
        )
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)

        return UNNotificationRequest(
            identifier: notificationIdentifier(subscriptionID: subscription.id),
            content: content,
            trigger: trigger
        )
    }

    func reminderDate(for subscription: Subscription, now: Date = .now) -> Date? {
        let nextBillingDate = billingCalculator.nextBillingDate(for: subscription, after: now)
        return calendar.date(
            byAdding: .day,
            value: -subscription.reminderDaysBefore,
            to: nextBillingDate
        )
    }

    func notificationBody(for subscription: Subscription) -> String {
        if subscription.reminderDaysBefore == 0 {
            return L10n.tf("notification.body.today", subscription.name)
        }

        if subscription.reminderDaysBefore == 1 {
            return L10n.tf("notification.body.tomorrow", subscription.name)
        }

        return L10n.tf("notification.body.days", subscription.name, subscription.reminderDaysBefore)
    }
}
