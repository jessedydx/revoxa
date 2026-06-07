import SwiftUI

struct SubscriptionLogoView: View {
    enum ShapeStyle {
        case roundedRectangle
        case circle
    }

    let subscriptionName: String
    let iconAssetName: String?
    var size: CGFloat = 36
    var shapeStyle: ShapeStyle = .roundedRectangle

    var body: some View {
        switch shapeStyle {
        case .roundedRectangle:
            logoContent
                .frame(width: size, height: size)
                .background(RevoxaColor.elevatedSurface)
                .clipShape(RoundedRectangle(cornerRadius: min(8, size * 0.22), style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: min(8, size * 0.22), style: .continuous)
                        .stroke(RevoxaColor.border, lineWidth: 1)
                }
                .accessibilityLabel(subscriptionName)
        case .circle:
            logoContent
                .frame(width: size, height: size)
                .background(RevoxaColor.elevatedSurface)
                .clipShape(Circle())
                .overlay {
                    Circle()
                        .stroke(RevoxaColor.border, lineWidth: 1)
                }
                .accessibilityLabel(subscriptionName)
        }
    }

    private var logoContent: some View {
        ZStack {
            if let iconAssetName {
                Image(iconAssetName)
                    .resizable()
                    .scaledToFit()
                    .padding(size * 0.18)
                    .accessibilityHidden(true)
            } else {
                Text(initials)
                    .font(.system(size: max(11, size * 0.34), weight: .semibold, design: .rounded))
                    .foregroundStyle(RevoxaColor.textPrimary)
            }
        }
    }

    private var initials: String {
        let words = subscriptionName
            .split(whereSeparator: { $0.isWhitespace || $0 == "+" || $0 == "-" })
            .prefix(2)
            .compactMap(\.first)
        let value = String(words).uppercased()
        return value.isEmpty ? "?" : value
    }
}

struct RevoxaStatusBadge: View {
    let status: SubscriptionStatus

    var body: some View {
        Text(status.title)
            .font(RevoxaFont.caption)
            .foregroundStyle(foregroundColor)
            .padding(.horizontal, RevoxaSpacing.small)
            .padding(.vertical, RevoxaSpacing.xSmall)
            .background(backgroundColor)
            .clipShape(Capsule())
            .overlay {
                Capsule()
                    .stroke(borderColor, lineWidth: 1)
            }
    }

    private var foregroundColor: Color {
        switch status {
        case .active:
            RevoxaColor.textPrimary
        case .trial:
            RevoxaColor.accent
        case .cancelSoon:
            RevoxaColor.accent
        case .cancelled, .archived:
            RevoxaColor.textSecondary
        }
    }

    private var backgroundColor: Color {
        switch status {
        case .active:
            RevoxaColor.accent.opacity(0.14)
        case .trial:
            RevoxaColor.accentMuted.opacity(0.20)
        case .cancelSoon:
            RevoxaColor.accent.opacity(0.22)
        case .cancelled, .archived:
            RevoxaColor.border.opacity(0.55)
        }
    }

    private var borderColor: Color {
        switch status {
        case .active, .trial, .cancelSoon:
            RevoxaColor.accent.opacity(0.35)
        case .cancelled, .archived:
            RevoxaColor.border
        }
    }
}

struct RevoxaEmptyState: View {
    let systemImage: String
    let title: String
    let message: String

    var body: some View {
        VStack(spacing: RevoxaSpacing.medium) {
            Image(systemName: systemImage)
                .font(.system(size: 32, weight: .semibold))
                .foregroundStyle(RevoxaColor.accent)
                .frame(width: 64, height: 64)
                .background(RevoxaColor.elevatedSurface)
                .clipShape(RoundedRectangle(cornerRadius: RevoxaRadius.medium))
                .overlay {
                    RoundedRectangle(cornerRadius: RevoxaRadius.medium)
                        .stroke(RevoxaColor.accent.opacity(0.28), lineWidth: 1)
                }

            Text(title)
                .font(RevoxaFont.sectionTitle)
                .foregroundStyle(RevoxaColor.textPrimary)

            Text(message)
                .font(RevoxaFont.body)
                .foregroundStyle(RevoxaColor.textSecondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 440)
        }
        .padding(RevoxaSpacing.xLarge)
        .frame(maxWidth: .infinity, minHeight: 320)
        .revoxaCard()
    }
}

extension View {
    func revoxaCard() -> some View {
        self
            .background(
                LinearGradient(
                    colors: [RevoxaColor.premiumSurface, RevoxaColor.surface],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: RevoxaRadius.medium))
            .overlay {
                RoundedRectangle(cornerRadius: RevoxaRadius.medium)
                    .stroke(RevoxaColor.border, lineWidth: 1)
            }
    }

    func revoxaPrimaryButton() -> some View {
        self
            .buttonStyle(.borderedProminent)
            .tint(RevoxaColor.accent)
    }
}

extension Notification.Name {
    static let revoxaAddSubscription = Notification.Name("revoxa.addSubscription")
    static let revoxaFocusSearch = Notification.Name("revoxa.focusSearch")
    static let revoxaRefreshNotificationPermission = Notification.Name("revoxa.refreshNotificationPermission")
}
