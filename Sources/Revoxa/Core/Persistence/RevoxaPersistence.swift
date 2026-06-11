import Foundation
import SwiftData

enum RevoxaPersistence {
    private(set) static var isCloudKitEnabled = false

    static func makeModelContainer() throws -> ModelContainer {
        if ScreenshotFixtures.isEnabled {
            isCloudKitEnabled = false
            return try makeInMemoryContainer()
        }

        if isRunningUnitTests {
            isCloudKitEnabled = false
            return try makeInMemoryContainer()
        }

        do {
            let container = try makeCloudKitContainer()
            isCloudKitEnabled = true
            return container
        } catch {
            NSLog("RevoxaPersistence: CloudKit store unavailable (\(error)). Using local-only store.")
            isCloudKitEnabled = false
            return try makeLocalContainer()
        }
    }

    private static var isRunningUnitTests: Bool {
        ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil
    }

    private static func makeCloudKitContainer() throws -> ModelContainer {
        let schema = Schema([Subscription.self])
        let configuration = ModelConfiguration(
            "RevoxaCloud",
            schema: schema,
            cloudKitDatabase: .private(RevoxaCloudKitConstants.containerIdentifier)
        )
        return try ModelContainer(for: schema, configurations: configuration)
    }

    private static func makeLocalContainer() throws -> ModelContainer {
        try ModelContainer(for: Subscription.self)
    }

    private static func makeInMemoryContainer() throws -> ModelContainer {
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        return try ModelContainer(for: Subscription.self, configurations: configuration)
    }
}
