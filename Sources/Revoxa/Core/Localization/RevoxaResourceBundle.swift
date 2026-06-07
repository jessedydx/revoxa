import Foundation

enum RevoxaResourceBundle {
    private static let bundleName = "Revoxa_Revoxa"

    /// Resolves the SPM resource bundle for both `swift run` and a packaged `.app`.
    static let bundle: Bundle = {
        if let resolved = locatePackagedBundle(), hasLocalizations(resolved) {
            return resolved
        }

        if hasLocalizations(.module) {
            return .module
        }

        return locatePackagedBundle() ?? .module
    }()

    private static func locatePackagedBundle() -> Bundle? {
        let fileManager = FileManager.default

        var candidates: [URL] = []

        if let executableURL = Bundle.main.executableURL {
            candidates.append(
                executableURL
                    .deletingLastPathComponent()
                    .appendingPathComponent("\(bundleName).bundle")
            )
        }

        if let resourceURL = Bundle.main.resourceURL {
            candidates.append(resourceURL.appendingPathComponent("\(bundleName).bundle"))
        }

        candidates.append(
            Bundle.main.bundleURL
                .appendingPathComponent("Contents/MacOS/\(bundleName).bundle")
        )

        for url in candidates {
            var isDirectory: ObjCBool = false
            guard fileManager.fileExists(atPath: url.path, isDirectory: &isDirectory),
                  isDirectory.boolValue,
                  let bundle = Bundle(url: url)
            else {
                continue
            }
            return bundle
        }

        return nil
    }

    private static func hasLocalizations(_ bundle: Bundle) -> Bool {
        bundle.path(forResource: "Localizable", ofType: "strings", inDirectory: "en.lproj") != nil
            || bundle.url(forResource: "Localizable", withExtension: "xcstrings") != nil
    }
}
