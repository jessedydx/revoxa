# Revoxa — Agent talimatları

Bu dosya Cursor ve diğer kod ajanları için proje içi kalıcı yönlendirmedir.

## Build ve `/Applications` senkronu (zorunlu)

**Revoxa uygulama kodunda** (`Sources/Revoxa/`, `script/`, `AppIcon/`, paketleme betikleri vb.) **anlamlı bir değişiklik yaptıktan sonra**, görevi bitirmeden önce şunu çalıştır:

```bash
./script/build_and_run.sh --package-only
```

Bu komut:

1. `dist/Revoxa.app` üretir (Debug),
2. **`/Applications/Revoxa.app` dosyasını otomatik günceller** (`script/sync_applications.sh`),
3. Uygulamayı açmaz (`--package-only`).

Kullanıcı test için uygulamayı açacaksa veya sen açman gerekiyorsa:

```bash
./script/build_and_run.sh
```

Release derleme + tam kurulum (doğrulama dahil):

```bash
./script/install-local.sh
```

### Ne zaman bu adımı atla

- Yalnızca `README.md`, `docs/`, yorum veya `.md` dosyaları değiştiyse (çalıştırılabilir kod yoksa).
- Kullanıcı açıkça **“build çalıştırma”** veya **`--skip-applications-sync`** istediyse.

### İzin / hata

`/Applications` yazılamıyorsa kullanıcıya bildir; gerekirse:

```bash
sudo ./script/sync_applications.sh
```

## Diğer komutlar

| Komut | Ne zaman |
|--------|----------|
| `swift test` | Mantık / model / servis değişikliği sonrası (mümkünse) |
| `./script/build_and_run.sh --release --package-only` | Release paketini doğrulamak için |
| `./script/build_and_run.sh --skip-applications-sync` | Yalnızca `dist/` yeterliyse |

## Önemli proje notları

- Gerçek kullanım ve bildirimler için uygulama **`/Applications/Revoxa.app`** üzerinden açılmalı; `swift run` veya yalnızca `dist/` yeterli değildir.
- Menü çubuğu simgesi: `MenuBarIcon` — uygulama ikonu: `AppIcon` (karıştırma).
- Yerel kurulum: `./script/install-local.sh` ve `./script/install.sh` aynı `/Applications` senkronunu kullanır.
- iOS + macOS App Store hazırlık süreci için ayrı iş akışı dokümanı: `docs/app-store-ios-macos-workflow.md`.

Kullanıcıya her seferinde “Applications’ı güncelle” demesine gerek kalmamalı; bu dosya build/sync adımını varsayılan kılar.
