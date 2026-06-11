# Revoxa — Agent talimatları

Bu dosya Cursor ve diğer kod ajanları için proje içi kalıcı yönlendirmedir.

## Derleme ve test

Kullanıcı **açıkça istemedikçe** derleme, paketleme veya test çalıştırma:

- `./script/build_and_run.sh` (ve `--package-only`, `--release` vb. varyantları)
- `./script/install-local.sh`, `./script/sync_applications.sh`
- `swift build`, `swift test`, `xcodebuild`

Kod değişikliği yaptıktan sonra bu komutları **otomatik çalıştırma**. Kullanıcı “derle”, “build al”, “test et” veya benzeri bir talimat verdiğinde çalıştır.

## Komutlar

| Komut | Ne zaman |
|--------|----------|
| `swift test` | Kullanıcı test istediğinde |
| `./script/build_and_run.sh` | Kullanıcı derleme/çalıştırma istediğinde |
| `./script/build_and_run.sh --package-only` | Kullanıcı paket istediğinde (açmadan) |
| `./script/build_and_run.sh --release --package-only` | Kullanıcı release paketi istediğinde |
| `./script/build_and_run.sh --skip-applications-sync` | Kullanıcı yalnızca `dist/` istediğinde |
| `./script/install-local.sh` | Kullanıcı release kurulum istediğinde |

## Önemli proje notları

- Gerçek kullanım ve bildirimler için uygulama **`/Applications/Revoxa.app`** üzerinden açılmalı; `swift run` veya yalnızca `dist/` yeterli değildir.
- Menü çubuğu simgesi: `MenuBarIcon` — uygulama ikonu: `AppIcon` (karıştırma).
- Yerel kurulum: `./script/install-local.sh` ve `./script/install.sh` aynı `/Applications` senkronunu kullanır.
- iOS + macOS App Store hazırlık süreci için ayrı iş akışı dokümanı: `docs/app-store-ios-macos-workflow.md`.
