import SwiftUI

#if os(macOS)
import AppKit
#elseif os(iOS)
import UIKit
#endif

enum RevoxaColor {
    static let appBackground = Color.revoxaAdaptive(light: 0xF7F3EF, dark: 0x100C09)
    static let surface = Color.revoxaAdaptive(light: 0xFFFFFF, dark: 0x19120D)
    static let elevatedSurface = Color.revoxaAdaptive(light: 0xF0EBE5, dark: 0x241A12)
    static let premiumSurface = Color.revoxaAdaptive(light: 0xFAF7F4, dark: 0x1E1510)
    static let border = Color.revoxaAdaptive(light: 0xDDD0C4, dark: 0x3A281B)
    static let borderSubtle = Color.revoxaAdaptive(light: 0xE8E0D8, dark: 0x2A1D15)
    static let accent = Color(hex: 0xF28A2E)
    static let accentMuted = Color.revoxaAdaptive(light: 0xC46E1A, dark: 0x9A5524)
    static let textPrimary = Color.revoxaAdaptive(light: 0x1A1410, dark: 0xF6EDE4)
    static let textSecondary = Color.revoxaAdaptive(light: 0x6B5E54, dark: 0xB6A89A)
    static let destructive = Color.revoxaAdaptive(light: 0xC62828, dark: 0xFF6B6B)
}

enum RevoxaSpacing {
    static let xSmall: CGFloat = 6
    static let small: CGFloat = 10
    static let medium: CGFloat = 16
    static let large: CGFloat = 24
    static let xLarge: CGFloat = 32
}

enum RevoxaRadius {
    static let small: CGFloat = 6
    static let medium: CGFloat = 8
    static let large: CGFloat = 14
    static let xLarge: CGFloat = 20
}

enum RevoxaFont {
    static let pageTitle = Font.system(size: 30, weight: .semibold, design: .rounded)
    static let sectionTitle = Font.system(size: 17, weight: .semibold)
    static let body = Font.system(size: 13, weight: .regular)
    static let caption = Font.system(size: 12, weight: .medium)
    static let metric = Font.system(size: 26, weight: .semibold, design: .rounded)
}

extension Color {
    static func revoxaAdaptive(light lightHex: UInt, dark darkHex: UInt, opacity: Double = 1) -> Color {
        #if os(macOS)
        Color(
            nsColor: NSColor(name: nil, dynamicProvider: { appearance in
                let isDark = appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
                return NSColor(hex: isDark ? darkHex : lightHex, opacity: opacity)
            })
        )
        #elseif os(iOS)
        Color(
            uiColor: UIColor { traits in
                UIColor(
                    hex: traits.userInterfaceStyle == .dark ? darkHex : lightHex,
                    opacity: opacity
                )
            }
        )
        #else
        Color(hex: lightHex, opacity: opacity)
        #endif
    }
}

#if os(macOS)
private extension NSColor {
    convenience init(hex: UInt, opacity: Double = 1) {
        self.init(
            red: CGFloat((hex >> 16) & 0xFF) / 255,
            green: CGFloat((hex >> 8) & 0xFF) / 255,
            blue: CGFloat(hex & 0xFF) / 255,
            alpha: opacity
        )
    }
}
#elseif os(iOS)
private extension UIColor {
    convenience init(hex: UInt, opacity: Double = 1) {
        self.init(
            red: CGFloat((hex >> 16) & 0xFF) / 255,
            green: CGFloat((hex >> 8) & 0xFF) / 255,
            blue: CGFloat(hex & 0xFF) / 255,
            alpha: opacity
        )
    }
}
#endif
