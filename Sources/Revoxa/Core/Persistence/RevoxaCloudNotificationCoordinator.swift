import Foundation
import SwiftData

@MainActor
enum RevoxaCloudNotificationCoordinator {
    private static let notificationService = NotificationSchedulingService()

    static func refreshNotificationsIfNeeded(in modelContext: ModelContext) {
        guard UserDefaults.standard.bool(forKey: PreferenceKey.notificationsEnabled) else { return }

        let descriptor = FetchDescriptor<Subscription>(sortBy: [SortDescriptor(\.name)])
        guard let subscriptions = try? modelContext.fetch(descriptor) else { return }

        notificationService.syncNotifications(for: subscriptions, enabled: true)
    }
}
