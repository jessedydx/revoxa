import SwiftUI

struct ICloudOnboardingSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(RevoxaCloudSyncMonitor.self) private var cloudSyncMonitor

    var body: some View {
        VStack(alignment: .leading, spacing: RevoxaSpacing.large) {
            HStack(spacing: RevoxaSpacing.medium) {
                Image(systemName: "icloud.fill")
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundStyle(RevoxaColor.accent)

                VStack(alignment: .leading, spacing: RevoxaSpacing.xSmall) {
                    Text(L10n.t("icloud.onboarding.title"))
                        .font(RevoxaFont.sectionTitle)
                        .foregroundStyle(RevoxaColor.textPrimary)

                    Text(L10n.t("icloud.onboarding.subtitle"))
                        .font(RevoxaFont.body)
                        .foregroundStyle(RevoxaColor.textSecondary)
                }
            }

            VStack(alignment: .leading, spacing: RevoxaSpacing.small) {
                onboardingRow(
                    systemImage: "arrow.triangle.2.circlepath.icloud.fill",
                    text: L10n.t("icloud.onboarding.point.sync")
                )
                onboardingRow(
                    systemImage: "lock.icloud.fill",
                    text: L10n.t("icloud.onboarding.point.privacy")
                )
                onboardingRow(
                    systemImage: "bell.badge.fill",
                    text: L10n.t("icloud.onboarding.point.notifications")
                )
            }

            if cloudSyncMonitor.isUsingCloudKitStore && cloudSyncMonitor.isAvailable == false {
                Text(cloudSyncMonitor.statusTitle)
                    .font(RevoxaFont.caption)
                    .foregroundStyle(RevoxaColor.accent)
            }

            HStack {
                if cloudSyncMonitor.isUsingCloudKitStore && cloudSyncMonitor.isAvailable == false {
                    Button(L10n.t("icloud.openSettings")) {
                        cloudSyncMonitor.openSystemICloudSettings()
                    }
                    .buttonStyle(.bordered)
                }

                Spacer()

                Button(L10n.t("icloud.onboarding.continue")) {
                    UserDefaults.standard.set(true, forKey: PreferenceKey.hasSeenICloudOnboarding)
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .tint(RevoxaColor.accent)
            }
        }
        .padding(RevoxaSpacing.xLarge)
        .frame(maxWidth: 520)
        .background(RevoxaColor.surface)
    }

    private func onboardingRow(systemImage: String, text: String) -> some View {
        HStack(alignment: .top, spacing: RevoxaSpacing.small) {
            Image(systemName: systemImage)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(RevoxaColor.accent)
                .frame(width: 22)

            Text(text)
                .font(RevoxaFont.body)
                .foregroundStyle(RevoxaColor.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}
