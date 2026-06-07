import SwiftUI

struct DetailView: View {
    let section: AppSection

    var body: some View {
        switch section {
        case .dashboard:
            DashboardView()
        case .subscriptions:
            SubscriptionsView()
        case .calendar:
            CalendarView()
        case .insights:
            CalendarView()
        case .settings:
            SettingsView()
        }
    }
}
