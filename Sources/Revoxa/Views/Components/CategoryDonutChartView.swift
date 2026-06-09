import SwiftUI

/// Donut chart with contiguous filled slices separated by visible border strokes (no angular gaps).
struct CategoryDonutChartView: View {
    let totals: [CategoryPaymentTotal]

    @Environment(\.colorScheme) private var colorScheme
    @State private var hoveredCategoryID: String?

    private var displayTotals: [CategoryPaymentTotal] {
        totals.filter { $0.amount > .zero }
    }

    /// Tek para birimindeyse aynı kategorinin satırlarını birleştir.
    private var chartTotals: [CategoryPaymentTotal] {
        guard displayTotals.count > 1 else { return displayTotals }

        let currencies = Set(displayTotals.map(\.currencyCode))
        guard currencies.count == 1, let currencyCode = currencies.first else {
            return displayTotals
        }

        var merged: [SubscriptionCategory: Decimal] = [:]
        for total in displayTotals {
            merged[total.category, default: .zero] += total.amount
        }

        return merged
            .map { CategoryPaymentTotal(category: $0.key, amount: $0.value, currencyCode: currencyCode) }
            .sorted { $0.amount > $1.amount }
    }

    private var totalAmount: Decimal {
        chartTotals.reduce(into: .zero) { $0 += $1.amount }
    }

    private var sliceColors: [String: Color] {
        CategoryChartPalette.colorMap(for: chartTotals)
    }

    private var slices: [DonutSlice] {
        DonutSlice.make(
            from: chartTotals,
            totalAmount: totalAmount,
            colors: sliceColors
        )
    }

    var body: some View {
        if displayTotals.isEmpty {
            Text(L10n.t("calendar.analytics.empty"))
                .font(RevoxaFont.body)
                .foregroundStyle(RevoxaColor.textSecondary)
                .frame(maxWidth: .infinity, minHeight: 320, alignment: .center)
        } else {
            GeometryReader { geometry in
                let side = min(geometry.size.width, geometry.size.height)
                let originX = (geometry.size.width - side) / 2
                let originY = (geometry.size.height - side) / 2

                ZStack {
                    Canvas { context, size in
                        let geo = DonutGeometry(side: min(size.width, size.height))
                        draw(in: &context, geo: geo)
                    }
                    .frame(width: side, height: side)
                    .position(x: geometry.size.width / 2, y: geometry.size.height / 2)

                    centerLabel
                        .frame(width: side * 0.52)
                        .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
                }
                .contentShape(Rectangle())
                .onContinuousHover { phase in
                    switch phase {
                    case .active(let location):
                        let geo = DonutGeometry(side: side)
                        let point = CGPoint(x: location.x - originX, y: location.y - originY)
                        let id = geo.sliceID(at: point, slices: slices)
                        if id != hoveredCategoryID {
                            withAnimation(.spring(response: 0.28, dampingFraction: 0.76)) {
                                hoveredCategoryID = id
                            }
                        }
                    case .ended:
                        withAnimation(.spring(response: 0.28, dampingFraction: 0.8)) {
                            hoveredCategoryID = nil
                        }
                    }
                }
            }
            .aspectRatio(1, contentMode: .fit)
            .frame(maxWidth: .infinity)
            .frame(height: 340)
        }
    }

    @ViewBuilder
    private var centerLabel: some View {
        VStack(spacing: 8) {
            if let hovered = slices.first(where: { $0.id == hoveredCategoryID }) {
                Text(hovered.total.category.title)
                    .font(.system(size: 23, weight: .bold, design: .rounded))
                    .foregroundStyle(RevoxaColor.textPrimary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.7)

                Text(detailText(for: hovered.total))
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundStyle(RevoxaColor.textSecondary)
                    .multilineTextAlignment(.center)
            } else {
                Text(CurrencyFormatter.string(from: totalAmount, currencyCode: centerCurrencyCode))
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundStyle(RevoxaColor.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)

                Text(L10n.tf("calendar.analytics.subscriptionCount", slices.count))
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(RevoxaColor.textSecondary)
            }
        }
        .allowsHitTesting(false)
        .animation(.easeInOut(duration: 0.16), value: hoveredCategoryID)
    }

    private var centerCurrencyCode: String {
        chartTotals.first?.currencyCode ?? RevoxaCurrency.defaultCode
    }

    private func detailText(for total: CategoryPaymentTotal) -> String {
        let amount = CurrencyFormatter.string(from: total.amount, currencyCode: total.currencyCode)
        return "\(amount) · \(total.amount.sharePercentage(of: totalAmount))%"
    }

    private func draw(in context: inout GraphicsContext, geo: DonutGeometry) {
        let separatorColor = separatorLineColor
        let separatorWidth = geo.separatorWidth

        for slice in slices {
            let isHovered = hoveredCategoryID == slice.id
            let accent = slice.fillColor

            let fill: Color = {
                if hoveredCategoryID == nil || isHovered { return accent }
                return accent.opacity(colorScheme == .dark ? 0.38 : 0.48)
            }()

            let slicePath = geo.annulusSectorPath(start: slice.start, end: slice.end)

            if isHovered {
                var glow = context
                glow.addFilter(.shadow(color: accent.opacity(0.55), radius: 16, x: 0, y: 0))
                glow.fill(slicePath, with: .color(accent.opacity(0.45)))
            }

            context.fill(slicePath, with: .color(fill))
            context.stroke(
                slicePath,
                with: .color(separatorColor),
                style: StrokeStyle(lineWidth: separatorWidth, lineJoin: .miter)
            )
        }

        strokeRingOutlines(in: &context, geo: geo, separatorColor: separatorColor, separatorWidth: separatorWidth)
    }

    private func strokeRingOutlines(
        in context: inout GraphicsContext,
        geo: DonutGeometry,
        separatorColor: Color,
        separatorWidth: CGFloat
    ) {
        context.stroke(
            Path(ellipseIn: geo.innerHoleRect),
            with: .color(separatorColor),
            style: StrokeStyle(lineWidth: separatorWidth)
        )
        context.stroke(
            Path(ellipseIn: geo.outerRingRect),
            with: .color(separatorColor.opacity(0.85)),
            style: StrokeStyle(lineWidth: 1)
        )
    }

    private var separatorLineColor: Color {
        colorScheme == .dark
            ? Color.black.opacity(0.55)
            : Color.white.opacity(0.95)
    }
}

// MARK: - Slice layout

private struct DonutSlice: Identifiable, Equatable {
    let total: CategoryPaymentTotal
    let fillColor: Color
    /// Clock angle: 0 at top, clockwise, radians.
    let start: Double
    let end: Double

    var id: String { total.id }

    static func make(
        from totals: [CategoryPaymentTotal],
        totalAmount: Decimal,
        colors: [String: Color]
    ) -> [DonutSlice] {
        guard totalAmount > .zero, totals.isEmpty == false else { return [] }

        let fallback = RevoxaColor.textSecondary.opacity(0.4)
        var cursor = 0.0
        var result: [DonutSlice] = []

        for total in totals {
            let share = (total.amount as NSDecimalNumber)
                .dividing(by: totalAmount as NSDecimalNumber)
                .doubleValue
            let sweep = share * (2 * Double.pi)
            result.append(
                DonutSlice(
                    total: total,
                    fillColor: colors[total.id] ?? fallback,
                    start: cursor,
                    end: cursor + sweep
                )
            )
            cursor += sweep
        }

        return result
    }
}

// MARK: - Geometry

private struct DonutGeometry {
    let side: CGFloat
    let center: CGPoint
    let outerRadius: CGFloat
    let innerRadius: CGFloat
    let separatorWidth: CGFloat
    let innerHoleRect: CGRect
    let outerRingRect: CGRect

    init(side: CGFloat) {
        self.side = side
        center = CGPoint(x: side / 2, y: side / 2)
        outerRadius = side * 0.40
        innerRadius = side * 0.26
        separatorWidth = max(side * 0.014, 2)

        innerHoleRect = CGRect(
            x: center.x - innerRadius,
            y: center.y - innerRadius,
            width: innerRadius * 2,
            height: innerRadius * 2
        )
        outerRingRect = CGRect(
            x: center.x - outerRadius,
            y: center.y - outerRadius,
            width: outerRadius * 2,
            height: outerRadius * 2
        )
    }

    func fullAnnulusPath() -> Path {
        var path = Path()
        path.addEllipse(in: outerRingRect)
        path.addEllipse(in: innerHoleRect)
        return path
    }

    /// Filled annulus sector from `start` to `end` (clockwise from top).
    func annulusSectorPath(start: Double, end: Double) -> Path {
        var path = Path()

        path.move(to: point(atClockAngle: start, radius: outerRadius))
        path.addArc(
            center: center,
            radius: outerRadius,
            startAngle: swiftUIAngle(start),
            endAngle: swiftUIAngle(end),
            clockwise: true
        )
        path.addLine(to: point(atClockAngle: end, radius: innerRadius))
        path.addArc(
            center: center,
            radius: innerRadius,
            startAngle: swiftUIAngle(end),
            endAngle: swiftUIAngle(start),
            clockwise: false
        )
        path.closeSubpath()

        return path
    }

    /// Clock angle (0 at top) → SwiftUI `Angle` (0 at east).
    private func swiftUIAngle(_ clockAngle: Double) -> Angle {
        .radians(clockAngle - Double.pi / 2)
    }

    func point(atClockAngle angle: Double, radius: CGFloat) -> CGPoint {
        CGPoint(
            x: center.x + radius * CGFloat(sin(angle)),
            y: center.y - radius * CGFloat(cos(angle))
        )
    }

    func sliceID(at point: CGPoint, slices: [DonutSlice]) -> String? {
        let dx = point.x - center.x
        let dy = point.y - center.y
        let distance = hypot(dx, dy)

        guard distance >= innerRadius * 0.98, distance <= outerRadius * 1.02 else {
            return nil
        }

        var angle = atan2(Double(dx), Double(-dy))
        if angle < 0 {
            angle += 2 * Double.pi
        }

        for (index, slice) in slices.enumerated() {
            let isLast = index == slices.count - 1
            if angle >= slice.start && (isLast ? angle <= slice.end : angle < slice.end) {
                return slice.id
            }
        }

        return nil
    }
}
