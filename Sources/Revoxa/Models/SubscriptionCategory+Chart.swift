import SwiftUI

extension SubscriptionCategory {
    var chartColor: Color {
        switch self {
        case .entertainment:
            Color(hex: 0xF45B69)
        case .productivity:
            Color(hex: 0x4B7BEC)
        case .ai:
            Color(hex: 0x9B5DE5)
        case .cloud:
            Color(hex: 0x45A7E8)
        case .finance:
            Color(hex: 0x2FBF71)
        case .education:
            Color(hex: 0xF9A03F)
        case .health:
            Color(hex: 0xF15BB5)
        case .utilities:
            RevoxaColor.accent
        case .other:
            RevoxaColor.textSecondary
        }
    }
}
