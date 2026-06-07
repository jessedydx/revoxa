import Foundation

enum BillingCycle: String, Codable, CaseIterable, Identifiable {
    case weekly
    case monthly
    case quarterly
    case yearly
    case customDays

    var id: String { rawValue }

    var title: String {
        switch self {
        case .weekly: L10n.t("billingCycle.weekly")
        case .monthly: L10n.t("billingCycle.monthly")
        case .quarterly: L10n.t("billingCycle.quarterly")
        case .yearly: L10n.t("billingCycle.yearly")
        case .customDays: L10n.t("billingCycle.customDays")
        }
    }
}

enum SubscriptionStatus: String, Codable, CaseIterable, Identifiable {
    case active
    case trial
    case cancelSoon
    case cancelled
    case archived

    var id: String { rawValue }

    var title: String {
        switch self {
        case .active: L10n.t("status.active")
        case .trial: L10n.t("status.trial")
        case .cancelSoon: L10n.t("status.cancelSoon")
        case .cancelled: L10n.t("status.cancelled")
        case .archived: L10n.t("status.archived")
        }
    }

    var listSortPriority: Int {
        switch self {
        case .active: 0
        case .trial: 1
        case .cancelSoon: 2
        case .cancelled: 3
        case .archived: 4
        }
    }
}

enum SubscriptionCategory: String, Codable, CaseIterable, Identifiable {
    case entertainment
    case productivity
    case ai
    case cloud
    case finance
    case education
    case health
    case utilities
    case other

    var id: String { rawValue }

    var title: String {
        switch self {
        case .entertainment: L10n.t("category.entertainment")
        case .productivity: L10n.t("category.productivity")
        case .ai: L10n.t("category.ai")
        case .cloud: L10n.t("category.cloud")
        case .finance: L10n.t("category.finance")
        case .education: L10n.t("category.education")
        case .health: L10n.t("category.health")
        case .utilities: L10n.t("category.utilities")
        case .other: L10n.t("category.other")
        }
    }
}

enum PaymentMethod: String, Codable, CaseIterable, Identifiable {
    case creditCard
    case debitCard
    case apple
    case paypal
    case bankTransfer
    case other

    var id: String { rawValue }

    var title: String {
        switch self {
        case .creditCard: L10n.t("payment.creditCard")
        case .debitCard: L10n.t("payment.debitCard")
        case .apple: L10n.t("payment.apple")
        case .paypal: L10n.t("payment.paypal")
        case .bankTransfer: L10n.t("payment.bankTransfer")
        case .other: L10n.t("payment.other")
        }
    }
}
