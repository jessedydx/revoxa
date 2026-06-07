import SwiftUI

struct SidebarView: View {
    @Binding var selection: AppSection?

    var body: some View {
        List(AppSection.sidebarCases, selection: $selection) { section in
            Label {
                Text(section.title)
                    .font(RevoxaFont.body)
            } icon: {
                Image(systemName: section.systemImage)
                    .foregroundStyle(selection == section ? RevoxaColor.accent : RevoxaColor.textSecondary)
                    .frame(width: 18)
            }
                .tag(section)
        }
        .listStyle(.sidebar)
        .navigationSplitViewColumnWidth(min: 230, ideal: 250, max: 300)
    }
}
