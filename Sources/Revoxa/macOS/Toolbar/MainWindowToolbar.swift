import SwiftUI

struct MainWindowToolbar: ToolbarContent {
    var body: some ToolbarContent {
        ToolbarItemGroup(placement: .primaryAction) {
            Button {
                RevoxaAppActions.addSubscription()
            } label: {
                Label(RevoxaStrings.addSubscription, systemImage: "plus")
            }
            .help(RevoxaStrings.addSubscription)
            .keyboardShortcut("n", modifiers: .command)

            Button {
                RevoxaAppActions.focusSearch()
            } label: {
                Label(RevoxaStrings.search, systemImage: "magnifyingglass")
            }
            .help(RevoxaStrings.search)
            .keyboardShortcut("f", modifiers: .command)

            Button {
                RevoxaAppActions.exportSubscriptionsCSV()
            } label: {
                Label(RevoxaStrings.exportCSV, systemImage: "square.and.arrow.up")
            }
            .help(L10n.t("toolbar.exportSubscriptions.help"))
        }
    }
}
