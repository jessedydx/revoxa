# Revoxa

Revoxa is a **local-first subscription tracker** for **macOS, iPhone, and iPad**. Keep recurring costs, renewal dates, categories, and reminders on your device — no account, cloud sync, or backend.

- **Bundle ID:** `com.revoxa.app`
- **Version:** see [`VERSION`](VERSION)
- **UI languages:** English and Turkish (Settings → Language)

Turkish quick-start guide: [docs/usage.md](docs/usage.md) (Türkçe)

## What it does

Track digital subscriptions (streaming, software, cloud, AI tools, and more):

- Add and edit subscriptions with amount, currency, billing cycle, next billing date, category, status, notes, and cancellation URL
- See monthly and yearly cost estimates on the dashboard
- Review upcoming renewals in a calendar view
- Enable local renewal reminders
- Export subscriptions and dashboard summaries as CSV (macOS save panel; iOS share sheet)

Data is stored locally with **SwiftData**. You control your records.

## Platforms

| Platform | Minimum | Notes |
|----------|---------|--------|
| macOS | 14+ | Menu bar extra, unified window, `NSSavePanel` export |
| iOS / iPadOS | 17+ | Tab navigation (iPhone) or split view (iPad) |
| Xcode project | `Revoxa.xcodeproj` | Scheme: **Revoxa iOS** |

Shared Swift code lives in `Sources/Revoxa/`. Platform-specific UI is isolated under `macOS/` and `iOS/`.

## Main screens

| Screen | Description |
|--------|-------------|
| **Dashboard** | Monthly/yearly totals, upcoming payments, category overview |
| **Subscriptions** | Search, filters, add/edit/delete |
| **Calendar** | Month view of renewals; day detail sheet |
| **Settings** | Currency, theme, language, reminders, CSV export |

Exchange rates can be fetched from the public [TCMB daily XML feed](https://www.tcmb.gov.tr/kurlar/today.xml) to show converted totals. Subscription records are not sent with that request.

## Requirements

- macOS 14+ for the desktop app
- Xcode 15+ (or Swift 5.9+ toolchain) for building
- iOS 17+ simulator or device for the mobile target

## Quick start (macOS)

```bash
git clone https://github.com/jessedydx/revoxa.git
cd revoxa

swift build
swift test

# Build dist/Revoxa.app, sync to /Applications, and launch
./script/build_and_run.sh
```

Install a release build to `/Applications`:

```bash
./script/install-local.sh
```

**Tip:** For notifications and the correct app icon in Stage Manager, run the app from **`/Applications/Revoxa.app`**, not only `swift run` or a DerivedData build. See [docs/usage.md](docs/usage.md) for troubleshooting.

## Quick start (iOS)

```bash
xcodebuild \
  -project Revoxa.xcodeproj \
  -scheme "Revoxa iOS" \
  -destination "platform=iOS Simulator,name=iPhone 17 Pro" \
  CODE_SIGNING_ALLOWED=NO \
  build
```

Open `Revoxa.xcodeproj` in Xcode to run on a simulator or device once signing is configured.

## Scripts

| Script | Purpose |
|--------|---------|
| `script/build_and_run.sh` | Package macOS app, sync `/Applications`, launch |
| `script/build_and_run.sh --package-only` | Package only (no launch) |
| `script/install-local.sh` | Release build + `/Applications` install |
| `script/capture_app_store_screenshots.sh` | Capture raw screenshots + marketing frames |
| `script/generate_app_store_screenshots.swift` | Compose App Store marketing PNGs from raw shots |
| `script/verify_app_bundle.sh` | Validate `dist/Revoxa.app` icons and plist |

## Project layout

```
revoxa/
├── Package.swift                 # Shared Swift package (macOS + iOS)
├── Revoxa.xcodeproj/             # iOS / iPad Xcode project
├── Sources/Revoxa/               # App code, assets, localization
├── Tests/RevoxaTests/            # Unit tests
├── Configurations/Revoxa-iOS/    # iOS Info.plist & entitlements
├── docs/
│   ├── usage.md                  # Turkish usage guide
│   ├── roadmap.md                # Version roadmap
│   ├── app-store-content.md      # App Store metadata drafts
│   ├── privacy-policy.md         # Privacy policy draft (GitHub Pages)
│   ├── support.md                # Support page draft (GitHub Pages)
│   └── app-store-assets/         # Screenshots (raw + final)
├── script/                       # Build, install, screenshot tooling
└── VERSION
```

## App Store preparation

Store copy, screenshot specs, and workflow notes:

- [docs/app-store-content.md](docs/app-store-content.md)
- [docs/app-store-ios-macos-workflow.md](docs/app-store-ios-macos-workflow.md)
- Marketing screenshots: `docs/app-store-assets/screenshots/final/`

Privacy and support pages are drafted under `docs/` for [GitHub Pages](https://pages.github.com/) (required public URLs for App Store Connect).

## Intentionally out of scope (today)

| Area | Status |
|------|--------|
| User accounts / backend | Not planned for local-first model |
| Bank or email integration | Manual entry only |
| iCloud sync | Roadmap item |
| StoreKit / in-app purchases | Product decision pending |
| CSV import | Roadmap item |

See [docs/roadmap.md](docs/roadmap.md) for version planning.

## License

No `LICENSE` file is included yet. Add one before public distribution if you want to clarify terms.
