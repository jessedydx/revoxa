import SwiftUI

struct RevoxaCurrencyTotalsView: View {
    let totals: [CurrencyTotal]
    var font: Font = .system(size: 15, weight: .semibold, design: .rounded)
    var emptyText: String = "—"

    var body: some View {
        if totals.isEmpty {
            Text(emptyText)
                .font(font)
                .foregroundStyle(RevoxaColor.textPrimary)
        } else {
            VStack(alignment: .leading, spacing: RevoxaSpacing.xSmall) {
                ForEach(totals) { total in
                    Text(CurrencyFormatter.string(from: total.amount, currencyCode: total.currencyCode))
                        .font(font)
                        .foregroundStyle(RevoxaColor.textPrimary)
                        .lineLimit(1)
                }
            }
        }
    }
}
