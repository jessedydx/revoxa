import SwiftUI

/// Donut chart with separated slices and hover / touch percentage labels.
struct CategoryDonutChartView: View {
    let totals: [CategoryPaymentTotal]

    @Environment(\.colorScheme) private var colorScheme
    @State private var hoveredCategoryID: String?
    @State private var isInteracting = false

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
                let geo = DonutGeometry(side: side)

                ZStack {
                    Canvas { context, size in
                        let canvasGeo = DonutGeometry(side: min(size.width, size.height))
                        draw(in: &context, geo: canvasGeo)
                    }
                    .frame(width: side, height: side)
                    .position(x: geometry.size.width / 2, y: geometry.size.height / 2)

                    if isInteracting {
                        ForEach(Array(slices.enumerated()), id: \.element.id) { index, slice in
                            sliceLabel(for: slice, geo: geo, index: index)
                                .position(
                                    x: originX + geo.labelPoint(for: slice, index: index).x,
                                    y: originY + geo.labelPoint(for: slice, index: index).y
                                )
                        }
                    }

                    centerLabel
                        .frame(width: side * 0.52)
                        .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
                }
                .contentShape(Rectangle())
                .applyChartInteraction(
                    onActive: { location in
                        handlePointer(
                            at: location,
                            geo: geo,
                            originX: originX,
                            originY: originY
                        )
                    },
                    onEnded: {
                        withAnimation(.spring(response: 0.28, dampingFraction: 0.8)) {
                            isInteracting = false
                            hoveredCategoryID = nil
                        }
                    }
                )
            }
            .aspectRatio(1, contentMode: .fit)
            .frame(maxWidth: .infinity)
            .frame(height: 340)
        }
    }

    @ViewBuilder
    private func sliceLabel(for slice: DonutSlice, geo: DonutGeometry, index: Int) -> some View {
        let percentage = slice.total.amount.sharePercentage(of: totalAmount)
        let showsTitle = slice.sweep >= geo.minimumLabelSweep

        VStack(spacing: 2) {
            if showsTitle {
                Text(slice.total.category.title)
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
            }

            Text("\(percentage)%")
                .font(.system(size: showsTitle ? 12 : 11, weight: .bold, design: .rounded))
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 8)
        .padding(.vertical, showsTitle ? 5 : 4)
        .background(
            Capsule(style: .continuous)
                .fill(slice.fillColor.opacity(colorScheme == .dark ? 0.92 : 0.96))
        )
        .overlay {
            Capsule(style: .continuous)
                .stroke(Color.white.opacity(colorScheme == .dark ? 0.18 : 0.35), lineWidth: 1)
        }
        .shadow(color: slice.fillColor.opacity(0.28), radius: 6, y: 2)
        .allowsHitTesting(false)
        .transition(.scale(scale: 0.85).combined(with: .opacity))
    }

    @ViewBuilder
    private var centerLabel: some View {
        VStack(spacing: 8) {
            if isInteracting, let hovered = slices.first(where: { $0.id == hoveredCategoryID }) {
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
        .animation(.easeInOut(duration: 0.16), value: isInteracting)
    }

    private var centerCurrencyCode: String {
        chartTotals.first?.currencyCode ?? RevoxaCurrency.defaultCode
    }

    private func detailText(for total: CategoryPaymentTotal) -> String {
        let amount = CurrencyFormatter.string(from: total.amount, currencyCode: total.currencyCode)
        return "\(amount) · \(total.amount.sharePercentage(of: totalAmount))%"
    }

    private func handlePointer(
        at location: CGPoint,
        geo: DonutGeometry,
        originX: CGFloat,
        originY: CGFloat
    ) {
        let point = CGPoint(x: location.x - originX, y: location.y - originY)

        guard geo.isInRing(at: point) else {
            if isInteracting || hoveredCategoryID != nil {
                withAnimation(.spring(response: 0.28, dampingFraction: 0.8)) {
                    isInteracting = false
                    hoveredCategoryID = nil
                }
            }
            return
        }

        let sliceID = geo.sliceID(at: point, slices: slices)
        if isInteracting == false || sliceID != hoveredCategoryID {
            withAnimation(.spring(response: 0.28, dampingFraction: 0.76)) {
                isInteracting = true
                hoveredCategoryID = sliceID
            }
        }
    }

    private func draw(in context: inout GraphicsContext, geo: DonutGeometry) {
        for slice in slices {
            let isHovered = hoveredCategoryID == slice.id
            let accent = slice.fillColor

            let fill: Color = {
                guard isInteracting else { return accent }
                if isHovered { return accent }
                return accent.opacity(colorScheme == .dark ? 0.42 : 0.52)
            }()

            let slicePath = geo.annulusSectorPath(start: slice.start, end: slice.end)

            if isInteracting && isHovered {
                var glow = context
                glow.addFilter(.shadow(color: accent.opacity(0.5), radius: 14, x: 0, y: 0))
                glow.fill(slicePath, with: .color(accent.opacity(0.4)))
            }

            context.fill(slicePath, with: .color(fill))
        }

        context.stroke(
            Path(ellipseIn: geo.innerHoleRect),
            with: .color(ringOutlineColor),
            style: StrokeStyle(lineWidth: 1.5)
        )
        context.stroke(
            Path(ellipseIn: geo.outerRingRect),
            with: .color(ringOutlineColor.opacity(0.9)),
            style: StrokeStyle(lineWidth: 1.5)
        )
    }

    private var ringOutlineColor: Color {
        colorScheme == .dark
            ? Color.white.opacity(0.14)
            : Color.black.opacity(0.08)
    }
}

// MARK: - Interaction

private extension View {
    @ViewBuilder
    func applyChartInteraction(
        onActive: @escaping (CGPoint) -> Void,
        onEnded: @escaping () -> Void
    ) -> some View {
        #if os(macOS)
        self.onContinuousHover { phase in
            switch phase {
            case .active(let location):
                onActive(location)
            case .ended:
                onEnded()
            }
        }
        #else
        self.simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { value in
                    onActive(value.location)
                }
                .onEnded { _ in
                    onEnded()
                }
        )
        #endif
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

    var sweep: Double { end - start }

    static func make(
        from totals: [CategoryPaymentTotal],
        totalAmount: Decimal,
        colors: [String: Color]
    ) -> [DonutSlice] {
        guard totalAmount > .zero, totals.isEmpty == false else { return [] }

        let fallback = RevoxaColor.textSecondary.opacity(0.4)
        let gapRadians = totals.count > 1 ? DonutGeometry.sliceGapRadians : 0
        let totalGap = gapRadians * Double(totals.count)
        let usableSweep = (2 * Double.pi) - totalGap

        var cursor = gapRadians / 2
        var result: [DonutSlice] = []

        for total in totals {
            let share = (total.amount as NSDecimalNumber)
                .dividing(by: totalAmount as NSDecimalNumber)
                .doubleValue
            let sweep = share * usableSweep
            result.append(
                DonutSlice(
                    total: total,
                    fillColor: colors[total.id] ?? fallback,
                    start: cursor,
                    end: cursor + sweep
                )
            )
            cursor += sweep + gapRadians
        }

        return result
    }
}

// MARK: - Geometry

private struct DonutGeometry {
    static let sliceGapRadians = Double.pi / 180 * 2.2

    let side: CGFloat
    let center: CGPoint
    let outerRadius: CGFloat
    let innerRadius: CGFloat
    let innerHoleRect: CGRect
    let outerRingRect: CGRect
    let minimumLabelSweep: Double

    init(side: CGFloat) {
        self.side = side
        center = CGPoint(x: side / 2, y: side / 2)
        outerRadius = side * 0.38
        innerRadius = side * 0.245
        minimumLabelSweep = Double.pi / 180 * 14

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

    func labelPoint(for slice: DonutSlice, index: Int) -> CGPoint {
        let midAngle = (slice.start + slice.end) / 2
        let layerOffset: CGFloat = index.isMultiple(of: 2) ? 0 : 14
        let radius = outerRadius + side * 0.11 + layerOffset
        return point(atClockAngle: midAngle, radius: radius)
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

    func isInRing(at point: CGPoint) -> Bool {
        let dx = point.x - center.x
        let dy = point.y - center.y
        let distance = hypot(dx, dy)
        return distance >= innerRadius * 0.94 && distance <= outerRadius * 1.04
    }

    func sliceID(at point: CGPoint, slices: [DonutSlice]) -> String? {
        guard isInRing(at: point) else {
            return nil
        }

        let dx = point.x - center.x
        let dy = point.y - center.y
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
