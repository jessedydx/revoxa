import Foundation

extension Decimal {
    var chartDoubleValue: Double {
        NSDecimalNumber(decimal: self).doubleValue
    }

    func sharePercentage(of total: Decimal) -> Int {
        guard total > .zero else { return 0 }
        let ratio = (self as NSDecimalNumber).dividing(by: total as NSDecimalNumber)
        return Int((ratio.doubleValue * 100).rounded())
    }
}
