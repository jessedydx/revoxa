import SwiftUI

#if os(macOS)
import AppKit
#endif

enum RevoxaMenuBarIcon {
    static let assetName = "MenuBarIcon"

    /// Template image for `MenuBarExtra` (adapts to light/dark menu bar).
    static var templateImage: Image {
        Image(assetName)
            .renderingMode(.template)
    }

    /// Orange brand mark (same asset as menu bar, tinted with app accent).
    static func accentBrandMark(size: CGFloat = 18) -> some View {
        Image(assetName)
            .resizable()
            .renderingMode(.template)
            .foregroundStyle(RevoxaColor.accent)
            .scaledToFit()
            .frame(width: size, height: size)
    }

    /// AppKit helper if a status item is configured manually.
    #if os(macOS)
    static var templateNSImage: NSImage? {
        guard let image = NSImage(named: assetName) else { return nil }
        image.isTemplate = true
        return image
    }
    #endif
}

struct RevoxaBrandMark: View {
    var iconSize: CGFloat = 18

    var body: some View {
        Button {
            RevoxaAppActions.goToDashboard()
        } label: {
            HStack(spacing: RevoxaSpacing.small) {
                RevoxaMenuBarIcon.accentBrandMark(size: iconSize)
                    .accessibilityHidden(true)

                Text(RevoxaStrings.appName)
                    .font(.headline)
                    .foregroundStyle(RevoxaColor.textPrimary)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(L10n.t("toolbar.goToDashboard"))
        .help(L10n.t("toolbar.goToDashboard"))
    }
}
