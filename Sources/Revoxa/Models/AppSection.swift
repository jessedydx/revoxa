import SwiftUI

enum AppSection: String, CaseIterable, Identifiable {
    case dashboard
    case subscriptions
    case calendar
    case insights
    case settings

    var id: String { rawValue }

    /// Sidebar-visible sections (insights opens from the calendar screen).
    static var sidebarCases: [AppSection] {
        allCases.filter { $0 != .insights }
    }

    /// Sections opened as a sheet from the toolbar quick-nav icons.
    static var modalPresentableCases: Set<AppSection> {
        [.subscriptions, .calendar, .settings]
    }

    var presentsAsModal: Bool {
        Self.modalPresentableCases.contains(self)
    }

    /// Legacy `SceneStorage` / deep-link values mapped to a live section.
    static func resolved(from rawValue: String) -> AppSection {
        switch rawValue {
        case AppSection.insights.rawValue:
            return .calendar
        case "upcoming", "cancelList", "archive":
            return .dashboard
        default:
            return AppSection(rawValue: rawValue) ?? .dashboard
        }
    }

    var title: String {
        switch self {
        case .dashboard: L10n.t("section.dashboard")
        case .subscriptions: L10n.t("section.subscriptions")
        case .calendar: L10n.t("section.calendar")
        case .insights: L10n.t("section.insights")
        case .settings: L10n.t("section.settings")
        }
    }

    var systemImage: String {
        switch self {
        case .dashboard: "rectangle.3.group"
        case .subscriptions: "creditcard"
        case .calendar: "calendar"
        case .insights: "chart.line.uptrend.xyaxis"
        case .settings: "gearshape"
        }
    }
}
