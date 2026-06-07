enum SubscriptionCategoryFilter: String, CaseIterable, Identifiable {
    case all
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
        guard let category else { return RevoxaStrings.allCategories }
        return category.title
    }

    var category: SubscriptionCategory? {
        switch self {
        case .all: nil
        case .entertainment: .entertainment
        case .productivity: .productivity
        case .ai: .ai
        case .cloud: .cloud
        case .finance: .finance
        case .education: .education
        case .health: .health
        case .utilities: .utilities
        case .other: .other
        }
    }

    func matches(_ subscription: Subscription) -> Bool {
        guard let category else { return true }
        return subscription.category == category
    }
}
