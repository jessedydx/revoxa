import Foundation

#if os(macOS)
import AppKit
#endif

extension Notification.Name {
    static let revoxaNavigateToSection = Notification.Name("revoxa.navigateToSection")
    static let revoxaPresentSectionModal = Notification.Name("revoxa.presentSectionModal")
    static let revoxaToggleSidebar = Notification.Name("revoxa.toggleSidebar")
    static let revoxaExportSubscriptionsCSV = Notification.Name("revoxa.exportSubscriptionsCSV")
}

enum RevoxaAppActions {
    static func activateMainWindow() {
        #if os(macOS)
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)

        if let mainWindow = NSApp.windows.first(where: isMainApplicationWindow) {
            mainWindow.makeKeyAndOrderFront(nil)
            return
        }

        NSApp.windows.first(where: isMainApplicationWindow)?.makeKeyAndOrderFront(nil)
        #endif
    }

    #if os(macOS)
    static func isMainApplicationWindow(_ window: NSWindow) -> Bool {
        window.isVisible
            && window.canBecomeMain
            && window.styleMask.contains(.titled)
            && window.styleMask.contains(.closable)
    }
    #endif

    static func navigate(to section: AppSection) {
        NotificationCenter.default.post(name: .revoxaNavigateToSection, object: section)
    }

    static func presentSectionModal(_ section: AppSection) {
        guard section.presentsAsModal else {
            navigate(to: section)
            return
        }

        activateMainWindow()
        NotificationCenter.default.post(name: .revoxaPresentSectionModal, object: section)
    }

    static func goToDashboard() {
        activateMainWindow()
        navigate(to: .dashboard)
    }

    static func addSubscription() {
        activateMainWindow()
        NotificationCenter.default.post(name: .revoxaAddSubscription, object: nil)
    }

    static func focusSearch() {
        activateMainWindow()
        navigate(to: .subscriptions)
        NotificationCenter.default.post(name: .revoxaFocusSearch, object: nil)
    }

    static func openSettings() {
        presentSectionModal(.settings)
    }

    static func viewAllUpcoming() {
        activateMainWindow()
        navigate(to: .dashboard)
    }

    static func toggleSidebar() {
        NotificationCenter.default.post(name: .revoxaToggleSidebar, object: nil)
    }

    static func exportSubscriptionsCSV() {
        NotificationCenter.default.post(name: .revoxaExportSubscriptionsCSV, object: nil)
    }

    static func quit() {
        #if os(macOS)
        NSApp.terminate(nil)
        #endif
    }
}
