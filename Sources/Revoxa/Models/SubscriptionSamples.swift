import Foundation

extension Subscription {
    static var samples: [Subscription] {
        [
            Subscription(
                name: "ChatGPT Plus",
                amount: Decimal(20),
                currencyCode: "USD",
                billingCycle: .monthly,
                nextBillingDate: sampleDate(month: 6, day: 8),
                category: .ai,
                paymentMethod: .creditCard,
                status: .active,
                reminderDaysBefore: 3,
                cancellationURL: URL(string: "https://chatgpt.com"),
                templateID: "chatgpt"
            ),
            Subscription(
                name: "iCloud+",
                amount: Decimal(string: "2.99") ?? 2.99,
                currencyCode: "USD",
                billingCycle: .monthly,
                nextBillingDate: sampleDate(month: 6, day: 14),
                category: .cloud,
                paymentMethod: .apple,
                status: .active,
                reminderDaysBefore: 2,
                templateID: "icloud"
            ),
            Subscription(
                name: "Netflix",
                amount: Decimal(string: "15.49") ?? 15.49,
                currencyCode: "USD",
                billingCycle: .monthly,
                nextBillingDate: sampleDate(month: 6, day: 21),
                category: .entertainment,
                paymentMethod: .debitCard,
                status: .cancelSoon,
                reminderDaysBefore: 5,
                notes: L10n.t("sample.reviewNotes"),
                templateID: "netflix"
            ),
            Subscription(
                name: "Notion",
                amount: Decimal(96),
                currencyCode: "USD",
                billingCycle: .yearly,
                nextBillingDate: sampleDate(month: 9, day: 3),
                category: .productivity,
                paymentMethod: .paypal,
                status: .active,
                reminderDaysBefore: 14,
                templateID: "notion"
            )
        ]
    }

    private static func sampleDate(month: Int, day: Int) -> Date {
        var components = Calendar.current.dateComponents([.year], from: .now)
        components.month = month
        components.day = day

        let date = Calendar.current.date(from: components) ?? .now
        if date < .now {
            return Calendar.current.date(byAdding: .year, value: 1, to: date) ?? date
        }

        return date
    }
}
