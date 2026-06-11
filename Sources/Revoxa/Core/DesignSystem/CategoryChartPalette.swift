import SwiftUI

/// Distinct fills for analytics donut charts. Largest slice uses brand orange.
enum CategoryChartPalette {
    private static let slicePalette: [Color] = [
        RevoxaColor.accent,
        Color(hex: 0xE84855),
        Color(hex: 0x3D6FD9),
        Color(hex: 0x8B5CF6),
        Color(hex: 0x14B8A6),
        Color(hex: 0xF59E0B),
        Color(hex: 0xEC4899),
        Color(hex: 0x6366F1),
        Color(hex: 0x64748B),
    ]

    static func colorMap(for totals: [CategoryPaymentTotal]) -> [String: Color] {
        totals
            .filter { $0.amount > .zero }
            .sorted { $0.amount > $1.amount }
            .enumerated()
            .reduce(into: [:]) { map, entry in
                let paletteIndex = min(entry.offset, slicePalette.count - 1)
                map[entry.element.id] = slicePalette[paletteIndex]
            }
    }
}
