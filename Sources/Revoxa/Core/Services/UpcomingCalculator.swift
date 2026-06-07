import Foundation

struct UpcomingCalculator {
    var billingCalculator: BillingCalculator
    var calendar: Calendar

    init(
        billingCalculator: BillingCalculator = BillingCalculator(),
        calendar: Calendar = .current
    ) {
        self.billingCalculator = billingCalculator
        self.calendar = calendar
    }

    func groups(for subscriptions: [Subscription], asOf date: Date = .now) -> [UpcomingPaymentGroup] {
        let payments = subscriptions
            .filter(\.isActiveLike)
            .map {
                UpcomingPayment(
                    subscription: $0,
                    nextBillingDate: billingCalculator.nextBillingDate(for: $0, after: date),
                    daysUntil: billingCalculator.daysUntilNextBilling(for: $0, after: date)
                )
            }
            .sorted {
                if $0.nextBillingDate == $1.nextBillingDate {
                    return $0.subscription.name.localizedCaseInsensitiveCompare($1.subscription.name) == .orderedAscending
                }

                return $0.nextBillingDate < $1.nextBillingDate
            }

        return UpcomingPaymentGroupKind.allCases.compactMap { kind in
            let matchingPayments = payments.filter { kind.contains($0.nextBillingDate, asOf: date, calendar: calendar) }
            guard matchingPayments.isEmpty == false else { return nil }
            return UpcomingPaymentGroup(kind: kind, payments: matchingPayments)
        }
    }
}

struct UpcomingPayment: Identifiable {
    var id: UUID { subscription.id }
    let subscription: Subscription
    let nextBillingDate: Date
    let daysUntil: Int
}

struct UpcomingPaymentGroup: Identifiable {
    var id: UpcomingPaymentGroupKind { kind }
    let kind: UpcomingPaymentGroupKind
    let payments: [UpcomingPayment]
}

enum UpcomingPaymentGroupKind: String, CaseIterable, Identifiable {
    case today
    case thisWeek
    case thisMonth
    case later

    var id: String { rawValue }

    var title: String {
        switch self {
        case .today: L10n.t("upcomingGroup.today")
        case .thisWeek: L10n.t("upcomingGroup.thisWeek")
        case .thisMonth: L10n.t("upcomingGroup.thisMonth")
        case .later: L10n.t("upcomingGroup.later")
        }
    }

    func contains(_ paymentDate: Date, asOf date: Date, calendar: Calendar) -> Bool {
        let start = calendar.startOfDay(for: date)
        let end = calendar.startOfDay(for: paymentDate)
        let daysUntil = calendar.dateComponents([.day], from: start, to: end).day ?? 0

        return switch self {
        case .today:
            daysUntil == 0
        case .thisWeek:
            daysUntil > 0 && daysUntil <= 7
        case .thisMonth:
            daysUntil > 7 && daysUntil <= 30
        case .later:
            daysUntil > 30
        }
    }
}
