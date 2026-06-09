import SwiftUI

/// Distinct pastel fills for analytics donut charts. Largest slice uses brand orange.
enum CategoryChartPalette {
    static func colorMap(for totals: [CategoryPaymentTotal]) -> [String: Color] {
        totals
            .filter { $0.amount > .zero }
            .reduce(into: [:]) { map, total in
                map[total.id] = total.category.chartColor
            }
    }
}
