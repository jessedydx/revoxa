import CloudKit
import CoreData
import Foundation
import Observation

@Observable
@MainActor
final class RevoxaCloudSyncMonitor {
    static let shared = RevoxaCloudSyncMonitor()

    private(set) var accountStatus: CKAccountStatus = .couldNotDetermine
    private(set) var lastRemoteChangeAt: Date?
    private(set) var isUsingCloudKitStore = false

    var isAvailable: Bool {
        accountStatus == .available
    }

    var statusTitle: String {
        guard isUsingCloudKitStore else {
            return L10n.t("icloud.status.localOnly")
        }

        switch accountStatus {
        case .available:
            return L10n.t("icloud.status.available")
        case .noAccount:
            return L10n.t("icloud.status.noAccount")
        case .restricted:
            return L10n.t("icloud.status.restricted")
        case .couldNotDetermine:
            return L10n.t("icloud.status.unknown")
        case .temporarilyUnavailable:
            return L10n.t("icloud.status.temporarilyUnavailable")
        @unknown default:
            return L10n.t("icloud.status.unknown")
        }
    }

    var statusDetail: String {
        guard isUsingCloudKitStore else {
            return L10n.t("icloud.status.localOnly.detail")
        }

        if let lastRemoteChangeAt {
            let formatted = lastRemoteChangeAt.formatted(date: .abbreviated, time: .shortened)
            return L10n.tf("icloud.status.lastSync", formatted)
        }

        return L10n.t("icloud.status.detail")
    }

    func start(isUsingCloudKitStore: Bool) {
        self.isUsingCloudKitStore = isUsingCloudKitStore
        registerForRemoteChanges()

        Task {
            await refreshAccountStatus()
        }
    }

    func refreshAccountStatus() async {
        do {
            let container = CKContainer(identifier: RevoxaCloudKitConstants.containerIdentifier)
            accountStatus = try await container.accountStatus()
        } catch {
            accountStatus = .couldNotDetermine
        }
    }

    func openSystemICloudSettings() {
        #if os(macOS)
        if let url = URL(string: "x-apple.systempreferences:com.apple.preferences.AppleIDPrefPane") {
            NSWorkspace.shared.open(url)
        }
        #else
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
        #endif
    }

    private func registerForRemoteChanges() {
        NotificationCenter.default.addObserver(
            forName: .NSPersistentStoreRemoteChange,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.handleRemoteChange()
            }
        }
    }

    private func handleRemoteChange() {
        lastRemoteChangeAt = .now
        NotificationCenter.default.post(name: .revoxaCloudDataDidChange, object: nil)
    }
}

#if os(macOS)
import AppKit
#else
import UIKit
#endif
