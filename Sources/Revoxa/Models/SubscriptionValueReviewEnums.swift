import Foundation

enum UsageFrequency: String, Codable, CaseIterable, Identifiable {
    case daily
    case weekly
    case monthly
    case rarely
    case never

    var id: String { rawValue }

    var title: String {
        switch self {
        case .daily: L10n.t("usage.daily")
        case .weekly: L10n.t("usage.weekly")
        case .monthly: L10n.t("usage.monthly")
        case .rarely: L10n.t("usage.rarely")
        case .never: L10n.t("usage.never")
        }
    }
}

enum ValueRating: String, Codable, CaseIterable, Identifiable {
    case high
    case medium
    case low
    case unknown

    var id: String { rawValue }

    var title: String {
        switch self {
        case .high: L10n.t("value.high")
        case .medium: L10n.t("value.medium")
        case .low: L10n.t("value.low")
        case .unknown: L10n.t("value.unknown")
        }
    }
}

enum CancelReason: String, Codable, CaseIterable, Identifiable {
    case unused
    case tooExpensive
    case foundAlternative
    case trialEnding
    case temporaryNeed
    case other

    var id: String { rawValue }

    var title: String {
        switch self {
        case .unused: L10n.t("cancelReason.unused")
        case .tooExpensive: L10n.t("cancelReason.tooExpensive")
        case .foundAlternative: L10n.t("cancelReason.foundAlternative")
        case .trialEnding: L10n.t("cancelReason.trialEnding")
        case .temporaryNeed: L10n.t("cancelReason.temporaryNeed")
        case .other: L10n.t("cancelReason.other")
        }
    }
}
