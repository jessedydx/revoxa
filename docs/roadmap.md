# Revoxa roadmap

Product direction for Revoxa. The repo currently ships a **multi-platform v0.1** (macOS + iPhone + iPad) with App Store preparation in progress.

## v0.1 — Local subscription tracker (current)

**Status:** Shipped locally; App Store submission pending Apple Developer approval

**Platforms:** macOS 14+, iOS / iPadOS 17+

**Screens:** Dashboard, Subscriptions, Calendar, Settings (plus Insights on iPad)

**Core features:**

- SwiftUI + SwiftData local subscription management
- Billing cycles, categories, status, notes, cancellation URLs
- Monthly / yearly cost estimates and calendar view
- Local renewal reminders (`UserNotifications`)
- CSV export (macOS save panel, iOS share sheet)
- English + Turkish UI
- Shared Swift package + `Revoxa.xcodeproj` for iOS
- macOS packaging via `script/build_and_run.sh`
- Unit tests (calculators, CSV, notifications, exchange rates)

**App Store prep (pre–Developer account):**

- Marketing screenshots (iPhone, iPad, macOS)
- Metadata drafts, privacy/support pages (GitHub Pages)
- Privacy manifest, macOS App Sandbox entitlements
- iOS notification usage description

**Out of scope for v0.1:** iCloud sync, backend, bank/email integration, StoreKit.

---

## v0.2 — Polish + import

**Goal:** Daily-use improvements and data portability

- UI/UX polish (accessibility, empty states, consistency)
- **CSV import** (symmetric with export schema)
- Demo / sample data options for first launch
- List and form improvements (sorting, batch actions)
- Documentation and local backup guidance

---

## v0.3 — iCloud sync

**Goal:** Sync across devices with the same Apple ID

- CloudKit or SwiftData + iCloud container
- Conflict resolution strategy
- Updated privacy copy (“where your data lives”)
- Notifications remain device-local

---

## v1.0 — App Store release

**Goal:** Public distribution on Mac App Store and iOS App Store

- App Store Connect metadata, review, and universal purchase strategy (if desired)
- Production signing, TestFlight, and release builds
- StoreKit (optional premium tier — product decision)
- Stabilized iCloud sync (if v0.3 ships first)
- Support channel and release notes

---

## Decision log

| Topic | v0.1 | Later |
| --- | --- | --- |
| Backend | No | Not required for v1.0 |
| Bank / email integration | No | Revisit only if product direction changes |
| iOS app | Yes (shipped in repo) | iPad + iPhone maintained with macOS |
| App Store | Prepared, not submitted | v1.0 target |
| Age rating | Documented as 4+ | Enter in Connect after account approval |

This file reflects product intent; scope and timing may change during sprint planning.
