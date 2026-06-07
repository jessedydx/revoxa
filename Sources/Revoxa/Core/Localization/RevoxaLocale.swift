import Foundation

enum RevoxaStrings {
    static var appName: String { L10n.t("app.name") }
    static var ok: String { L10n.t("common.ok") }
    static var cancel: String { L10n.t("common.cancel") }
    static var save: String { L10n.t("common.save") }
    static var delete: String { L10n.t("common.delete") }
    static var search: String { L10n.t("common.search") }
    static var settings: String { L10n.t("common.settings") }
    static var exportCSV: String { L10n.t("common.exportCSV") }
    static var addSubscription: String { L10n.t("common.addSubscription") }
    static var editSubscription: String { L10n.t("common.editSubscription") }
    static var exportTitle: String { L10n.t("common.exportTitle") }
    static var untitledSubscription: String { L10n.t("common.untitledSubscription") }
    static var allCategories: String { L10n.t("common.allCategories") }
    private static var recordCountSuffix: String { L10n.t("common.recordCountSuffix") }

    static func exported(_ filename: String) -> String {
        L10n.tf("common.exported", filename)
    }

    static func exportFailed(_ error: String) -> String {
        L10n.tf("common.exportFailed", error)
    }

    static func daysCount(_ count: Int) -> String {
        L10n.tf("common.daysCount", count)
    }

    static func daysUntilText(_ days: Int) -> String {
        switch days {
        case 0:
            L10n.t("common.daysUntil.today")
        case 1:
            L10n.t("common.daysUntil.one")
        default:
            L10n.tf("common.daysUntil.many", days)
        }
    }

    static func shownCount(_ count: Int) -> String {
        L10n.tf("common.shownCount", count, recordCountSuffix)
    }
}
