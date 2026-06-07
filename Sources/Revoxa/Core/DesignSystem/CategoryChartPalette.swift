import SwiftUI

/// Distinct pastel fills for analytics donut charts. Largest slice uses brand orange.
enum CategoryChartPalette {
    static func colorMap(
        for totals: [CategoryPaymentTotal],
        colorScheme: ColorScheme
    ) -> [String: Color] {
        let ranked = totals
            .filter { $0.amount > .zero }
            .sorted { $0.amount > $1.amount }

        let accents = colorScheme == .dark ? darkAccents : lightAccents
        var map: [String: Color] = [:]

        for (index, total) in ranked.enumerated() {
            if index == 0 {
                map[total.id] = colorScheme == .dark ? brandOrangeDark : brandOrangeLight
            } else {
                map[total.id] = accents[(index - 1) % accents.count]
            }
        }

        return map
    }

    private static let brandOrangeLight = RevoxaColor.accent
    private static let brandOrangeDark = Color(hex: 0xFF9B45)

    private static let lightAccents: [Color] = [
        Color(hex: 0x9B7AE8),
        Color(hex: 0x4DA3E8),
        Color(hex: 0xE86BA0),
        Color(hex: 0x45C090),
        Color(hex: 0xE09040),
        Color(hex: 0x4DBBD4),
        Color(hex: 0xA8C84A),
        Color(hex: 0x6888E8),
    ]

    private static let darkAccents: [Color] = [
        Color(hex: 0xB898F5),
        Color(hex: 0x5AB0F0),
        Color(hex: 0xF080B0),
        Color(hex: 0x50D0A0),
        Color(hex: 0xF0A050),
        Color(hex: 0x58C8E0),
        Color(hex: 0xC0D860),
        Color(hex: 0x88A8F5),
    ]
}
