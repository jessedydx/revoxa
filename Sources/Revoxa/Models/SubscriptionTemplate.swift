import Foundation

struct SubscriptionTemplate: Identifiable, Hashable {
    let id: String
    let displayName: String
    let iconAssetName: String
    let category: SubscriptionCategory
    let defaultBillingCycle: BillingCycle
    let defaultPaymentMethod: PaymentMethod
    let cancellationURL: URL?
    let aliases: [String]

    var searchTerms: [String] {
        [displayName, id] + aliases
    }
}

enum SubscriptionTemplates {
    static let all: [SubscriptionTemplate] = [
        SubscriptionTemplate(
            id: "netflix",
            displayName: "Netflix",
            iconAssetName: "brand_netflix",
            category: .entertainment,
            defaultBillingCycle: .monthly,
            defaultPaymentMethod: .creditCard,
            cancellationURL: URL(string: "https://www.netflix.com/account"),
            aliases: ["netflix"]
        ),
        SubscriptionTemplate(
            id: "youtube-premium",
            displayName: "YouTube Premium",
            iconAssetName: "brand_youtube",
            category: .entertainment,
            defaultBillingCycle: .monthly,
            defaultPaymentMethod: .creditCard,
            cancellationURL: URL(string: "https://www.youtube.com/paid_memberships"),
            aliases: ["youtube", "youtube premium"]
        ),
        SubscriptionTemplate(
            id: "spotify",
            displayName: "Spotify",
            iconAssetName: "brand_spotify",
            category: .entertainment,
            defaultBillingCycle: .monthly,
            defaultPaymentMethod: .creditCard,
            cancellationURL: URL(string: "https://www.spotify.com/account/subscription/"),
            aliases: ["spotify", "spotify premium"]
        ),
        SubscriptionTemplate(
            id: "chatgpt",
            displayName: "ChatGPT",
            iconAssetName: "brand_chatgpt",
            category: .ai,
            defaultBillingCycle: .monthly,
            defaultPaymentMethod: .creditCard,
            cancellationURL: URL(string: "https://chatgpt.com/#settings/Subscription"),
            aliases: ["chatgpt", "openai", "chatgpt plus"]
        ),
        SubscriptionTemplate(
            id: "icloud",
            displayName: "iCloud+",
            iconAssetName: "brand_icloud",
            category: .cloud,
            defaultBillingCycle: .monthly,
            defaultPaymentMethod: .apple,
            cancellationURL: URL(string: "https://support.apple.com/HT207594"),
            aliases: ["icloud", "icloud+", "apple icloud"]
        ),
        SubscriptionTemplate(
            id: "google-one",
            displayName: "Google One",
            iconAssetName: "brand_googleone",
            category: .cloud,
            defaultBillingCycle: .monthly,
            defaultPaymentMethod: .creditCard,
            cancellationURL: URL(string: "https://one.google.com/settings"),
            aliases: ["google one", "google storage"]
        ),
        SubscriptionTemplate(
            id: "microsoft-365",
            displayName: "Microsoft 365",
            iconAssetName: "brand_microsoft365",
            category: .productivity,
            defaultBillingCycle: .yearly,
            defaultPaymentMethod: .creditCard,
            cancellationURL: URL(string: "https://account.microsoft.com/services"),
            aliases: ["microsoft 365", "office", "office 365"]
        ),
        SubscriptionTemplate(
            id: "adobe-creative-cloud",
            displayName: "Adobe Creative Cloud",
            iconAssetName: "brand_adobecreativecloud",
            category: .productivity,
            defaultBillingCycle: .monthly,
            defaultPaymentMethod: .creditCard,
            cancellationURL: URL(string: "https://account.adobe.com/plans"),
            aliases: ["adobe", "creative cloud"]
        ),
        SubscriptionTemplate(
            id: "canva",
            displayName: "Canva",
            iconAssetName: "brand_canva",
            category: .productivity,
            defaultBillingCycle: .monthly,
            defaultPaymentMethod: .creditCard,
            cancellationURL: URL(string: "https://www.canva.com/settings/billing-and-plans"),
            aliases: ["canva", "canva pro"]
        ),
        SubscriptionTemplate(
            id: "notion",
            displayName: "Notion",
            iconAssetName: "brand_notion",
            category: .productivity,
            defaultBillingCycle: .monthly,
            defaultPaymentMethod: .creditCard,
            cancellationURL: URL(string: "https://www.notion.so/my-settings/billing"),
            aliases: ["notion", "notion plus"]
        ),
        SubscriptionTemplate(
            id: "prime-video",
            displayName: "Prime Video",
            iconAssetName: "brand_primevideo",
            category: .entertainment,
            defaultBillingCycle: .monthly,
            defaultPaymentMethod: .creditCard,
            cancellationURL: URL(string: "https://www.primevideo.com/settings"),
            aliases: ["prime", "prime video", "amazon prime"]
        ),
        SubscriptionTemplate(
            id: "disney-plus",
            displayName: "Disney+",
            iconAssetName: "brand_disneyplus",
            category: .entertainment,
            defaultBillingCycle: .monthly,
            defaultPaymentMethod: .creditCard,
            cancellationURL: URL(string: "https://www.disneyplus.com/account"),
            aliases: ["disney", "disney+", "disney plus"]
        ),
        SubscriptionTemplate(
            id: "storytel",
            displayName: "Storytel",
            iconAssetName: "brand_storytel",
            category: .entertainment,
            defaultBillingCycle: .monthly,
            defaultPaymentMethod: .creditCard,
            cancellationURL: URL(string: "https://www.storytel.com/account"),
            aliases: ["storytel", "audiobook", "sesli kitap"]
        ),
        SubscriptionTemplate(
            id: "hepsiburada",
            displayName: "Hepsiburada",
            iconAssetName: "brand_hepsiburada",
            category: .other,
            defaultBillingCycle: .monthly,
            defaultPaymentMethod: .creditCard,
            cancellationURL: URL(string: "https://www.hepsiburada.com/hesabim"),
            aliases: ["hepsiburada", "hepsipay", "premium"]
        ),
        SubscriptionTemplate(
            id: "hetzner",
            displayName: "Hetzner",
            iconAssetName: "brand_hetzner",
            category: .cloud,
            defaultBillingCycle: .monthly,
            defaultPaymentMethod: .creditCard,
            cancellationURL: URL(string: "https://accounts.hetzner.com/login"),
            aliases: ["hetzner", "hetzner cloud", "server", "vps"]
        ),
        SubscriptionTemplate(
            id: "claude",
            displayName: "Claude",
            iconAssetName: "brand_claude",
            category: .ai,
            defaultBillingCycle: .monthly,
            defaultPaymentMethod: .creditCard,
            cancellationURL: URL(string: "https://claude.ai/settings/billing"),
            aliases: ["claude", "anthropic", "claude pro"]
        ),
        SubscriptionTemplate(
            id: "github",
            displayName: "GitHub",
            iconAssetName: "brand_github",
            category: .productivity,
            defaultBillingCycle: .monthly,
            defaultPaymentMethod: .creditCard,
            cancellationURL: URL(string: "https://github.com/settings/billing"),
            aliases: ["github", "github copilot", "copilot"]
        ),
        SubscriptionTemplate(
            id: "figma",
            displayName: "Figma",
            iconAssetName: "brand_figma",
            category: .productivity,
            defaultBillingCycle: .monthly,
            defaultPaymentMethod: .creditCard,
            cancellationURL: URL(string: "https://www.figma.com/files/team"),
            aliases: ["figma", "figjam", "design"]
        ),
        SubscriptionTemplate(
            id: "dropbox",
            displayName: "Dropbox",
            iconAssetName: "brand_dropbox",
            category: .cloud,
            defaultBillingCycle: .monthly,
            defaultPaymentMethod: .creditCard,
            cancellationURL: URL(string: "https://www.dropbox.com/account/plan"),
            aliases: ["dropbox", "dropbox plus", "storage"]
        ),
        SubscriptionTemplate(
            id: "slack",
            displayName: "Slack",
            iconAssetName: "brand_slack",
            category: .productivity,
            defaultBillingCycle: .monthly,
            defaultPaymentMethod: .creditCard,
            cancellationURL: URL(string: "https://slack.com/account/billing"),
            aliases: ["slack", "workspace", "team chat"]
        ),
        SubscriptionTemplate(
            id: "zoom",
            displayName: "Zoom",
            iconAssetName: "brand_zoom",
            category: .productivity,
            defaultBillingCycle: .monthly,
            defaultPaymentMethod: .creditCard,
            cancellationURL: URL(string: "https://zoom.us/billing"),
            aliases: ["zoom", "zoom pro", "meeting"]
        ),
        SubscriptionTemplate(
            id: "cursor",
            displayName: "Cursor",
            iconAssetName: "brand_cursor",
            category: .ai,
            defaultBillingCycle: .monthly,
            defaultPaymentMethod: .creditCard,
            cancellationURL: URL(string: "https://cursor.com/settings"),
            aliases: ["cursor", "cursor pro", "ai editor"]
        ),
        SubscriptionTemplate(
            id: "midjourney",
            displayName: "Midjourney",
            iconAssetName: "brand_midjourney",
            category: .ai,
            defaultBillingCycle: .monthly,
            defaultPaymentMethod: .creditCard,
            cancellationURL: URL(string: "https://www.midjourney.com/account"),
            aliases: ["midjourney", "image generation", "ai image"]
        ),
        SubscriptionTemplate(
            id: "apple-music",
            displayName: "Apple Music",
            iconAssetName: "brand_applemusic",
            category: .entertainment,
            defaultBillingCycle: .monthly,
            defaultPaymentMethod: .apple,
            cancellationURL: URL(string: "https://support.apple.com/HT202039"),
            aliases: ["apple music", "music", "apple"]
        ),
        SubscriptionTemplate(
            id: "duolingo",
            displayName: "Duolingo",
            iconAssetName: "brand_duolingo",
            category: .education,
            defaultBillingCycle: .monthly,
            defaultPaymentMethod: .creditCard,
            cancellationURL: URL(string: "https://www.duolingo.com/settings/super"),
            aliases: ["duolingo", "super duolingo", "language"]
        ),
        SubscriptionTemplate(
            id: "linkedin-premium",
            displayName: "LinkedIn Premium",
            iconAssetName: "brand_linkedin",
            category: .productivity,
            defaultBillingCycle: .monthly,
            defaultPaymentMethod: .creditCard,
            cancellationURL: URL(string: "https://www.linkedin.com/premium/products"),
            aliases: ["linkedin", "linkedin premium"]
        ),
        SubscriptionTemplate(
            id: "exxen",
            displayName: "Exxen",
            iconAssetName: "brand_exxen",
            category: .entertainment,
            defaultBillingCycle: .monthly,
            defaultPaymentMethod: .creditCard,
            cancellationURL: URL(string: "https://www.exxen.com/account"),
            aliases: ["exxen", "exxenspor"]
        ),
        SubscriptionTemplate(
            id: "blutv",
            displayName: "BluTV",
            iconAssetName: "brand_blutv",
            category: .entertainment,
            defaultBillingCycle: .monthly,
            defaultPaymentMethod: .creditCard,
            cancellationURL: URL(string: "https://www.blutv.com/hesabim"),
            aliases: ["blutv", "blu tv"]
        ),
        SubscriptionTemplate(
            id: "mubi",
            displayName: "MUBI",
            iconAssetName: "brand_mubi",
            category: .entertainment,
            defaultBillingCycle: .monthly,
            defaultPaymentMethod: .creditCard,
            cancellationURL: URL(string: "https://mubi.com/settings/subscription"),
            aliases: ["mubi", "film", "cinema"]
        ),
        SubscriptionTemplate(
            id: "tradingview",
            displayName: "TradingView",
            iconAssetName: "brand_tradingview",
            category: .finance,
            defaultBillingCycle: .monthly,
            defaultPaymentMethod: .creditCard,
            cancellationURL: URL(string: "https://www.tradingview.com/settings/"),
            aliases: ["tradingview", "trading view", "tv pro", "chart"]
        ),
        SubscriptionTemplate(
            id: "cloudflare",
            displayName: "Cloudflare",
            iconAssetName: "brand_cloudflare",
            category: .cloud,
            defaultBillingCycle: .monthly,
            defaultPaymentMethod: .creditCard,
            cancellationURL: URL(string: "https://dash.cloudflare.com/?to=/:account/billing"),
            aliases: ["cloudflare", "cf", "cdn", "workers", "registrar"]
        ),
        SubscriptionTemplate(
            id: "ens",
            displayName: "ENS",
            iconAssetName: "brand_ens",
            category: .utilities,
            defaultBillingCycle: .yearly,
            defaultPaymentMethod: .creditCard,
            cancellationURL: URL(string: "https://app.ens.domains/"),
            aliases: ["ens", "ens domain", "ethereum name service", ".eth", "eth domain"]
        ),
    ]

    static func template(forID id: String?) -> SubscriptionTemplate? {
        guard let id else { return nil }
        return all.first { $0.id == id }
    }

    static func inferredTemplate(forName name: String) -> SubscriptionTemplate? {
        let normalizedName = normalized(name)
        guard normalizedName.isEmpty == false else { return nil }

        return all.first { template in
            template.searchTerms.contains { term in
                let normalizedTerm = normalized(term)
                return normalizedName == normalizedTerm
                    || normalizedName.contains(normalizedTerm)
                    || normalizedTerm.contains(normalizedName)
            }
        }
    }

    private static func normalized(_ value: String) -> String {
        value
            .folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
            .filter { $0.isLetter || $0.isNumber }
    }
}
