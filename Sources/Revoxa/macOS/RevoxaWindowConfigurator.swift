#if os(macOS)
import AppKit

enum RevoxaWindowConfigurator {
    static func install() {
        let center = NotificationCenter.default
        for notificationName in [NSWindow.didBecomeKeyNotification, NSWindow.didBecomeMainNotification] {
            center.addObserver(
                forName: notificationName,
                object: nil,
                queue: .main
            ) { notification in
                guard let window = notification.object as? NSWindow else { return }
                configure(window)
            }
        }

        configureAll()
    }

    static func configureAll() {
        NSApp.windows.forEach(configure)
    }

    static func configure(_ window: NSWindow) {
        switch windowKind(for: window) {
        case .main:
            configureMainWindow(window)
        case .auxiliary:
            configureAuxiliaryWindow(window)
        }
    }

    private enum WindowKind {
        case main
        case auxiliary
    }

    private static func windowKind(for window: NSWindow) -> WindowKind {
        if RevoxaAppActions.isMainApplicationWindow(window) {
            return .main
        }
        return .auxiliary
    }

    private static func configureMainWindow(_ window: NSWindow) {
        window.title = RevoxaStrings.appName
        window.titleVisibility = .hidden
        window.isOpaque = true
        window.backgroundColor = .revoxaAppBackground
        window.titlebarAppearsTransparent = false
        window.isExcludedFromWindowsMenu = false
        window.collectionBehavior = [.managed, .participatesInCycle, .primary, .fullScreenPrimary]
    }

    private static func configureAuxiliaryWindow(_ window: NSWindow) {
        // Menu bar panels should not appear as empty tiles in Stage Manager / Mission Control.
        window.isExcludedFromWindowsMenu = true
        window.collectionBehavior = [.transient, .ignoresCycle, .canJoinAllApplications]
    }
}

private extension NSColor {
    static var revoxaAppBackground: NSColor {
        NSColor(name: nil) { appearance in
            let isDark = appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
            return isDark ? NSColor(hex: 0x100C09) : NSColor(hex: 0xF7F3EF)
        }
    }

    convenience init(hex: UInt) {
        self.init(
            srgbRed: CGFloat((hex >> 16) & 0xFF) / 255,
            green: CGFloat((hex >> 8) & 0xFF) / 255,
            blue: CGFloat(hex & 0xFF) / 255,
            alpha: 1
        )
    }
}
#endif
