#if os(iOS)
import SwiftUI

struct RevoxaMobileRootView: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @State private var selectedSection = ScreenshotFixtures.requestedSection ?? AppSection.dashboard
    @State private var isShowingAddSheet = false
    @State private var columnVisibility: NavigationSplitViewVisibility = .detailOnly

    private let sections: [AppSection] = [
        .dashboard,
        .subscriptions,
        .calendar,
        .settings
    ]

    private var usesWideLayout: Bool {
        horizontalSizeClass == .regular
    }

    var body: some View {
        Group {
            if usesWideLayout {
                wideLayout
            } else {
                compactLayout
            }
        }
        .tint(RevoxaColor.accent)
        .onReceive(NotificationCenter.default.publisher(for: .revoxaNavigateToSection)) { notification in
            guard let section = notification.object as? AppSection else { return }
            selectedSection = AppSection.resolved(from: section.rawValue)
        }
        .onReceive(NotificationCenter.default.publisher(for: .revoxaPresentSectionModal)) { notification in
            guard let section = notification.object as? AppSection else { return }
            selectedSection = AppSection.resolved(from: section.rawValue)
        }
        .onReceive(NotificationCenter.default.publisher(for: .revoxaAddSubscription)) { _ in
            isShowingAddSheet = true
        }
        .sheet(isPresented: $isShowingAddSheet) {
            SubscriptionFormView()
                .presentationDetents([.large])
        }
        .onAppear {
            applyScreenshotSectionIfNeeded()
            presentScreenshotSceneIfNeeded()
        }
        .onChange(of: usesWideLayout) { _, _ in
            applyScreenshotSectionIfNeeded()
        }
    }

    private func applyScreenshotSectionIfNeeded() {
        guard ScreenshotFixtures.isEnabled,
              let section = ScreenshotFixtures.requestedSection
        else { return }

        guard usesWideLayout == false, section != .dashboard else {
            selectedSection = section
            return
        }

        // TabView can stay blank when cold-launched directly on a non-default tab.
        selectedSection = .dashboard
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            selectedSection = section
        }
    }

    private func presentScreenshotSceneIfNeeded() {
        guard ScreenshotFixtures.isEnabled,
              ScreenshotFixtures.requestedScene == .editForm,
              isShowingAddSheet == false
        else { return }

        isShowingAddSheet = true
    }

    private var compactLayout: some View {
        TabView(selection: $selectedSection) {
            ForEach(sections) { section in
                sectionNavigation(section)
                .tabItem {
                    Label(section.title, systemImage: section.systemImage)
                }
                .tag(section)
            }
        }
    }

    private var wideLayout: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            List {
                ForEach(sections) { section in
                    Button {
                        selectedSection = section
                    } label: {
                        Label(section.title, systemImage: section.systemImage)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(section == selectedSection ? RevoxaColor.accent : RevoxaColor.textPrimary)
                    .listRowBackground(
                        section == selectedSection ? RevoxaColor.accent.opacity(0.12) : Color.clear
                    )
                }
            }
            .navigationTitle("Revoxa")
            .listStyle(.sidebar)
        } detail: {
            sectionNavigation(selectedSection)
        }
        .navigationSplitViewStyle(.balanced)
    }

    private func sectionNavigation(_ section: AppSection) -> some View {
        NavigationStack {
            DetailView(section: section)
                .navigationTitle(section.title)
                .navigationBarTitleDisplayMode(.large)
                .toolbar {
                    if section != .settings {
                        ToolbarItem(placement: .primaryAction) {
                            Button {
                                isShowingAddSheet = true
                            } label: {
                                Label(RevoxaStrings.addSubscription, systemImage: "plus")
                            }
                            .revoxaPrimaryButton()
                        }
                    }
                }
        }
    }
}
#endif
