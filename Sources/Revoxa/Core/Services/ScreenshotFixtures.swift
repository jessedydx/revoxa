import Foundation
import SwiftData

#if os(macOS)
import AppKit
import SwiftUI
#endif

enum ScreenshotScene: String {
    case dayModal = "day-modal"
    case editForm = "edit-form"
}

enum ScreenshotFixtures {
    static let launchArgument = "--revoxa-screenshot-fixtures"
    static let sectionArgumentPrefix = "--revoxa-screenshot-section="
    static let sceneArgumentPrefix = "--revoxa-screenshot-scene="
    static let outputArgumentPrefix = "--revoxa-screenshot-output="
    private static let environmentKey = "REVOXA_SCREENSHOT_FIXTURES"

    private static var activeModelContainer: ModelContainer?

    #if os(macOS)
    private static var screenshotWindowController: NSWindowController?
    #endif

    static var isEnabled: Bool {
        ProcessInfo.processInfo.arguments.contains(launchArgument)
            || ProcessInfo.processInfo.environment[environmentKey] == "1"
    }

    static var requestedSection: AppSection? {
        ProcessInfo.processInfo.arguments
            .first { $0.hasPrefix(sectionArgumentPrefix) }
            .map { String($0.dropFirst(sectionArgumentPrefix.count)) }
            .map(AppSection.resolved(from:))
    }

    static var requestedScene: ScreenshotScene? {
        ProcessInfo.processInfo.arguments
            .first { $0.hasPrefix(sceneArgumentPrefix) }
            .map { String($0.dropFirst(sceneArgumentPrefix.count)) }
            .flatMap(ScreenshotScene.init(rawValue:))
    }

    static var screenshotCaptureDelay: TimeInterval {
        requestedScene == nil ? 1.5 : 2.5
    }

    private static var screenshotOutputURL: URL? {
        ProcessInfo.processInfo.arguments
            .first { $0.hasPrefix(outputArgumentPrefix) }
            .map { String($0.dropFirst(outputArgumentPrefix.count)) }
            .map(URL.init(fileURLWithPath:))
    }

    static func makeModelContainer() throws -> ModelContainer {
        if isEnabled {
            configureDefaultsIfNeeded()

            let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
            let container = try ModelContainer(for: Subscription.self, configurations: configuration)
            activeModelContainer = container
            return container
        }

        let container = try ModelContainer(for: Subscription.self)
        activeModelContainer = container
        return container
    }

    static func configureDefaultsIfNeeded(defaults: UserDefaults = .standard) {
        guard isEnabled else { return }

        defaults.set(RevoxaCurrency.USD.code, forKey: PreferenceKey.defaultCurrencyCode)
        defaults.set(AppTheme.dark.rawValue, forKey: PreferenceKey.appTheme)
        defaults.set(AppLanguage.english.rawValue, forKey: PreferenceKey.appLanguage)
        defaults.set(false, forKey: PreferenceKey.notificationsEnabled)
    }

    #if os(macOS)
    @MainActor
    static func showMacScreenshotWindowIfNeeded() {
        guard isEnabled,
              screenshotWindowController == nil
        else { return }

        let modelContainer: ModelContainer
        if let activeModelContainer {
            modelContainer = activeModelContainer
        } else if let createdModelContainer = try? makeModelContainer() {
            modelContainer = createdModelContainer
        } else {
            return
        }

        let context = ModelContext(modelContainer)
        seedIfNeeded(in: context)

        let rootView = RevoxaRootView {
            ContentView()
                .frame(width: 1280, height: 800)
        }
        .modelContainer(modelContainer)

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 1280, height: 800),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.title = RevoxaStrings.appName
        window.contentView = NSHostingView(rootView: rootView)
        window.center()
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)

        screenshotWindowController = NSWindowController(window: window)
        RevoxaWindowConfigurator.configure(window)

        if let screenshotOutputURL {
            saveMacScreenshot(from: window, to: screenshotOutputURL)
        }
    }

    @MainActor
    private static func saveMacScreenshot(from window: NSWindow, to outputURL: URL) {
        DispatchQueue.main.asyncAfter(deadline: .now() + screenshotCaptureDelay) {
            guard let contentView = window.contentView,
                  let bitmap = contentView.bitmapImageRepForCachingDisplay(in: contentView.bounds)
            else { return }

            contentView.cacheDisplay(in: contentView.bounds, to: bitmap)
            guard let pngData = bitmap.representation(using: .png, properties: [:]) else { return }

            do {
                try FileManager.default.createDirectory(
                    at: outputURL.deletingLastPathComponent(),
                    withIntermediateDirectories: true
                )
                try pngData.write(to: outputURL)
            } catch {
                assertionFailure("Failed to write screenshot fixture: \(error)")
            }

            NSApp.terminate(nil)
        }
    }
    #endif

    @MainActor
    static func seedIfNeeded(in modelContext: ModelContext) {
        guard isEnabled else { return }
        configureDefaultsIfNeeded()

        let descriptor = FetchDescriptor<Subscription>()
        let existingCount = (try? modelContext.fetchCount(descriptor)) ?? 0
        guard existingCount == 0 else { return }

        for subscription in Subscription.samples {
            modelContext.insert(subscription)
        }

        try? modelContext.save()
    }
}
