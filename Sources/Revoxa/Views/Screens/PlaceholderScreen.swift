import SwiftUI

struct PlaceholderScreen: View {
    let title: String
    let subtitle: String
    let systemImage: String

    var body: some View {
        ZStack {
            RevoxaColor.appBackground
                .ignoresSafeArea()

            VStack(alignment: .leading, spacing: RevoxaSpacing.xLarge) {
                header
                previewCard
                Spacer()
            }
            .padding(RevoxaSpacing.xLarge)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
        .navigationTitle(title)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: RevoxaSpacing.small) {
            HStack(spacing: RevoxaSpacing.medium) {
                Image(systemName: systemImage)
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundStyle(RevoxaColor.accent)
                    .frame(width: 44, height: 44)
                    .background(RevoxaColor.elevatedSurface)
                    .clipShape(RoundedRectangle(cornerRadius: RevoxaRadius.medium))

                Text(title)
                    .font(RevoxaFont.pageTitle)
                    .foregroundStyle(RevoxaColor.textPrimary)
            }

            Text(subtitle)
                .font(RevoxaFont.body)
                .foregroundStyle(RevoxaColor.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: 620, alignment: .leading)
        }
    }

    private var previewCard: some View {
        VStack(alignment: .leading, spacing: RevoxaSpacing.medium) {
            Text(L10n.t("placeholder.title"))
                .font(RevoxaFont.sectionTitle)
                .foregroundStyle(RevoxaColor.textPrimary)

            Text(L10n.t("placeholder.subtitle"))
                .font(RevoxaFont.body)
                .foregroundStyle(RevoxaColor.textSecondary)

            Divider()
                .overlay(RevoxaColor.border)

            HStack(spacing: RevoxaSpacing.small) {
                Capsule()
                    .fill(RevoxaColor.accent)
                    .frame(width: 34, height: 6)
                Capsule()
                    .fill(RevoxaColor.accentMuted)
                    .frame(width: 80, height: 6)
                Capsule()
                    .fill(RevoxaColor.border)
                    .frame(width: 120, height: 6)
            }
        }
        .padding(RevoxaSpacing.large)
        .frame(maxWidth: 520, alignment: .leading)
        .background(RevoxaColor.surface)
        .clipShape(RoundedRectangle(cornerRadius: RevoxaRadius.medium))
        .overlay {
            RoundedRectangle(cornerRadius: RevoxaRadius.medium)
                .stroke(RevoxaColor.border, lineWidth: 1)
        }
    }
}
