import SwiftUI

struct SectionModalView: View {
    let section: AppSection

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            DetailView(section: section)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button(L10n.t("toolbar.closeModal")) {
                            dismiss()
                        }
                    }
                }
        }
        .frame(
            minWidth: preferredSize.width,
            idealWidth: preferredSize.width,
            minHeight: preferredSize.height,
            idealHeight: preferredSize.height
        )
        .background(RevoxaColor.appBackground)
    }

    private var preferredSize: CGSize {
        switch section {
        case .subscriptions:
            CGSize(width: 980, height: 720)
        case .calendar:
            CGSize(width: 940, height: 760)
        case .settings:
            CGSize(width: 760, height: 620)
        default:
            CGSize(width: 880, height: 640)
        }
    }
}
