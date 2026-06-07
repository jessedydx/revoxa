import Foundation
import Testing
import UserNotifications
@testable import Revoxa

struct NotificationSchedulingServiceTests {
    private let calendar = Calendar(identifier: .gregorian)
    private let turkish = Locale(identifier: "tr")

    @Test
    func notificationIdentifierIsDeterministicFromSubscriptionID() {
        let client = MockNotificationSchedulingClient()
        let service = NotificationSchedulingService(notificationCenter: client, calendar: calendar)
        let id = UUID(uuidString: "11111111-1111-1111-1111-111111111111")!

        #expect(service.notificationIdentifier(subscriptionID: id) == "revoxa.subscription.11111111-1111-1111-1111-111111111111.renewal")
    }

    @Test
    func notificationBodyUsesReminderDays() {
        let service = NotificationSchedulingService(notificationCenter: MockNotificationSchedulingClient(), calendar: calendar)
        withTurkishLanguagePreference {
            #expect(
                service.notificationBody(for: makeSubscription(name: "Netflix", reminderDays: 3))
                    == L10n.tf("notification.body.days", locale: turkish, "Netflix", 3)
            )
            #expect(
                service.notificationBody(for: makeSubscription(name: "Spotify", reminderDays: 1))
                    == L10n.tf("notification.body.tomorrow", locale: turkish, "Spotify")
            )
            #expect(
                service.notificationBody(for: makeSubscription(name: "iCloud", reminderDays: 0))
                    == L10n.tf("notification.body.today", locale: turkish, "iCloud")
            )
        }
    }

    @Test
    func syncSchedulesActiveSubscriptionWhenEnabled() {
        let client = MockNotificationSchedulingClient()
        let service = NotificationSchedulingService(
            notificationCenter: client,
            calendar: calendar,
            billingCalculator: BillingCalculator(calendar: calendar)
        )
        let subscription = makeSubscription(
            name: "Netflix",
            reminderDays: 3,
            nextBillingDate: date(2026, 6, 10),
            status: .active
        )

        withTurkishLanguagePreference {
            service.syncNotification(for: subscription, enabled: true, now: date(2026, 6, 1))

            #expect(client.addedRequests.count == 1)
            #expect(client.addedRequests.first?.identifier == service.notificationIdentifier(subscriptionID: subscription.id))
            #expect(
                client.addedRequests.first?.content.body
                    == L10n.tf("notification.body.days", locale: turkish, "Netflix", 3)
            )
        }
        #expect(client.removedPendingIdentifiers.contains(service.notificationIdentifier(subscriptionID: subscription.id)))
    }

    @Test
    func syncCancelsWhenDisabledOrInactive() {
        let client = MockNotificationSchedulingClient()
        let service = NotificationSchedulingService(notificationCenter: client, calendar: calendar)
        let archived = makeSubscription(status: .archived)
        let active = makeSubscription(status: .active)

        service.syncNotification(for: archived, enabled: true)
        service.syncNotifications(for: [active], enabled: false)

        #expect(client.addedRequests.isEmpty)
        #expect(client.removedPendingIdentifiers.contains(service.notificationIdentifier(subscriptionID: archived.id)))
        #expect(client.removedPendingIdentifiers.contains(service.notificationIdentifier(subscriptionID: active.id)))
    }

    @Test
    func requestPermissionSkipsPromptWhenAlreadyAuthorized() async {
        let client = MockNotificationSchedulingClient()
        client.authorizationStatusValue = .authorized
        let service = NotificationSchedulingService(notificationCenter: client)

        let granted = await permissionResult(from: service)

        #expect(granted)
        #expect(client.requestAuthorizationCallCount == 0)
    }

    @Test
    func requestPermissionPromptsWhenNotDetermined() async {
        let client = MockNotificationSchedulingClient()
        client.authorizationStatusValue = .notDetermined
        client.grantsPermission = true
        let service = NotificationSchedulingService(notificationCenter: client)

        let granted = await permissionResult(from: service)

        #expect(granted)
        #expect(client.requestAuthorizationCallCount == 1)
    }

    @Test
    func requestPermissionFailsWhenDenied() async {
        let client = MockNotificationSchedulingClient()
        client.authorizationStatusValue = .denied
        let service = NotificationSchedulingService(notificationCenter: client)

        let granted = await permissionResult(from: service)

        #expect(granted == false)
        #expect(client.requestAuthorizationCallCount == 0)
    }

    private func permissionResult(from service: NotificationSchedulingService) async -> Bool {
        await withCheckedContinuation { continuation in
            service.requestPermission { continuation.resume(returning: $0) }
        }
    }

    private func makeSubscription(
        name: String = "Test",
        reminderDays: Int = 3,
        nextBillingDate: Date? = nil,
        status: SubscriptionStatus = .active
    ) -> Subscription {
        Subscription(
            name: name,
            amount: Decimal(10),
            currencyCode: "USD",
            billingCycle: .monthly,
            nextBillingDate: nextBillingDate ?? date(2026, 6, 10),
            category: .entertainment,
            paymentMethod: .creditCard,
            status: status,
            reminderDaysBefore: reminderDays
        )
    }

    private func date(_ year: Int, _ month: Int, _ day: Int) -> Date {
        DateComponents(calendar: calendar, year: year, month: month, day: day).date!
    }

    private func withTurkishLanguagePreference(_ operation: () -> Void) {
        let defaults = UserDefaults.standard
        let key = PreferenceKey.appLanguage
        let previous = defaults.string(forKey: key)
        defaults.set(AppLanguage.turkish.rawValue, forKey: key)
        defer {
            if let previous {
                defaults.set(previous, forKey: key)
            } else {
                defaults.removeObject(forKey: key)
            }
        }
        operation()
    }
}

private final class MockNotificationSchedulingClient: NotificationSchedulingClient {
    var addedRequests: [UNNotificationRequest] = []
    var removedPendingIdentifiers: [String] = []
    var removedDeliveredIdentifiers: [String] = []
    var grantsPermission = true
    var authorizationStatusValue: UNAuthorizationStatus = .notDetermined
    var requestAuthorizationCallCount = 0

    func authorizationStatus(completionHandler: @escaping @Sendable (UNAuthorizationStatus) -> Void) {
        completionHandler(authorizationStatusValue)
    }

    func requestAuthorization(
        options: UNAuthorizationOptions,
        completionHandler: @escaping @Sendable (Bool, Error?) -> Void
    ) {
        requestAuthorizationCallCount += 1
        completionHandler(grantsPermission, nil)
    }

    func add(_ request: UNNotificationRequest, withCompletionHandler completionHandler: (@Sendable (Error?) -> Void)?) {
        addedRequests.append(request)
        completionHandler?(nil)
    }

    func removePendingNotificationRequests(withIdentifiers identifiers: [String]) {
        removedPendingIdentifiers.append(contentsOf: identifiers)
    }

    func removeDeliveredNotifications(withIdentifiers identifiers: [String]) {
        removedDeliveredIdentifiers.append(contentsOf: identifiers)
    }
}
