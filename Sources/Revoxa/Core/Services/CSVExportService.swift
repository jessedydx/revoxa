import Foundation
import UniformTypeIdentifiers

#if os(macOS)
import AppKit
#endif

enum CSVExportService {
    @MainActor
    static func exportSubscriptions(
        _ subscriptions: [Subscription],
        completion: ((Result<String, Error>) -> Void)? = nil
    ) {
        let csv = CSVExporter.subscriptionsCSV(for: subscriptions)
        saveCSV(csv, defaultFilename: L10n.t("csv.filename.subscriptions"), completion: completion)
    }

    @MainActor
    static func exportDashboardSummary(
        _ summary: DashboardSummary,
        completion: ((Result<String, Error>) -> Void)? = nil
    ) {
        let csv = CSVExporter.dashboardSummaryCSV(for: summary)
        saveCSV(csv, defaultFilename: L10n.t("csv.filename.dashboard"), completion: completion)
    }

    @MainActor
    private static func saveCSV(
        _ csv: String,
        defaultFilename: String,
        completion: ((Result<String, Error>) -> Void)?
    ) {
        #if os(macOS)
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.commaSeparatedText]
        panel.nameFieldStringValue = defaultFilename
        panel.canCreateDirectories = true

        guard panel.runModal() == .OK, let url = panel.url else {
            return
        }

        do {
            try csv.write(to: url, atomically: true, encoding: .utf8)
            completion?(.success(url.lastPathComponent))
        } catch {
            completion?(.failure(error))
        }
        #else
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(defaultFilename)
        do {
            try csv.write(to: url, atomically: true, encoding: .utf8)
            completion?(.success(url.lastPathComponent))
        } catch {
            completion?(.failure(error))
        }
        #endif
    }
}
