import SwiftData
import SwiftUI

struct ContentView: View {
    @Query(sort: \Subscription.name) private var subscriptions: [Subscription]
    @SceneStorage("selectedSection") private var selectedSectionRawValue = AppSection.dashboard.rawValue
    @State private var columnVisibility: NavigationSplitViewVisibility = ScreenshotFixtures.isEnabled ? .detailOnly : .all
    @State private var isShowingAddSheet = false
    @State private var modalSection: AppSection?
    @State private var exportMessage: String?

    private var selectedSection: Binding<AppSection?> {
        Binding {
            resolvedSection(from: selectedSectionRawValue)
        } set: { newValue in
            selectedSectionRawValue = newValue?.rawValue ?? AppSection.dashboard.rawValue
        }
    }

    private var detailSection: AppSection {
        ScreenshotFixtures.requestedSection ?? selectedSection.wrappedValue ?? .dashboard
    }

    private func resolvedSection(from rawValue: String) -> AppSection {
        AppSection.resolved(from: rawValue)
    }

    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            SidebarView(selection: selectedSection)
        } detail: {
            DetailView(section: detailSection)
        }
        .background(RevoxaColor.appBackground)
        .toolbar {
            ToolbarItem(placement: .principal) {
                RevoxaBrandMark()
            }
            MainWindowToolbar()
        }
        .tint(RevoxaColor.accent)
        .configureRevoxaMainWindow()
        .onAppear {
            if let requestedSection = ScreenshotFixtures.requestedSection {
                selectedSectionRawValue = requestedSection.rawValue
            }

            let resolved = AppSection.resolved(from: selectedSectionRawValue)
            if resolved.rawValue != selectedSectionRawValue {
                selectedSectionRawValue = resolved.rawValue
            }

            presentScreenshotSceneIfNeeded()
        }
        .onReceive(NotificationCenter.default.publisher(for: .revoxaNavigateToSection)) { notification in
            guard let section = notification.object as? AppSection else { return }
            selectedSectionRawValue = resolvedSection(from: section.rawValue).rawValue
        }
        .onReceive(NotificationCenter.default.publisher(for: .revoxaPresentSectionModal)) { notification in
            guard let section = notification.object as? AppSection, section.presentsAsModal else { return }
            modalSection = section
        }
        .onReceive(NotificationCenter.default.publisher(for: .revoxaAddSubscription)) { _ in
            isShowingAddSheet = true
        }
        .onReceive(NotificationCenter.default.publisher(for: .revoxaToggleSidebar)) { _ in
            withAnimation {
                columnVisibility = columnVisibility == .all ? .detailOnly : .all
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .revoxaExportSubscriptionsCSV)) { _ in
            exportSubscriptions()
        }
        .alert(RevoxaStrings.exportTitle, isPresented: exportMessageBinding) {
            Button(RevoxaStrings.ok, role: .cancel) {
                exportMessage = nil
            }
        } message: {
            Text(exportMessage ?? "")
        }
        .sheet(isPresented: $isShowingAddSheet) {
            SubscriptionFormView()
        }
        .sheet(item: $modalSection) { section in
            SectionModalView(section: section)
        }
    }

    private var exportMessageBinding: Binding<Bool> {
        Binding {
            exportMessage != nil
        } set: { isPresented in
            if isPresented == false {
                exportMessage = nil
            }
        }
    }

    private func presentScreenshotSceneIfNeeded() {
        guard ScreenshotFixtures.isEnabled,
              ScreenshotFixtures.requestedScene == .editForm,
              isShowingAddSheet == false
        else { return }

        isShowingAddSheet = true
    }

    private func exportSubscriptions() {
        CSVExportService.exportSubscriptions(subscriptions) { result in
            switch result {
            case .success(let filename):
                exportMessage = RevoxaStrings.exported(filename)
            case .failure(let error):
                exportMessage = RevoxaStrings.exportFailed(error.localizedDescription)
            }
        }
    }
}
