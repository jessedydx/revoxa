# Revoxa

Revoxa, aboneliklerinizi tek bir yerde takip etmeniz için tasarlanmış **kişisel macOS masaüstü uygulamasıdır**. Veriler yalnızca cihazınızda kalır; hesap, bulut senkronizasyonu veya harici backend yoktur.

Kısa kullanım adımları için [docs/usage.md](docs/usage.md) dosyasına bakın. Sürüm planı için [docs/roadmap.md](docs/roadmap.md).

## Revoxa nedir?

Dijital aboneliklerin (yazılım, yayın, bulut, AI araçları vb.) adını, tutarını, yenileme tarihini ve durumunu kaydedip özetleyen yerel bir yönetim aracıdır. Dashboard ile aylık/yıllık tahmini harcamayı görür, yaklaşan ödemeleri planlar, iptal etmeyi düşündüğünüz abonelikleri ayrı listede tutar ve CSV ile verinizi dışa aktarabilirsiniz.

## Bu sürümün kapsamı (v0.1)

Bu depo **v0.1 — kişisel macOS uygulaması** kapsamındadır:

- Tam abonelik CRUD (SwiftData)
- Dashboard, Upcoming, Cancel List, Insights, Archive ekranları
- Ayarlar: varsayılan para birimi, hatırlatma günü, görünüm, bildirimler
- CSV dışa aktarma (abonelik listesi + dashboard özeti)
- Yerel yenileme hatırlatmaları (UserNotifications)
- Birim testler (hesaplayıcılar, CSV, bildirim planlama)

Dağıtım hedefi değildir; App Store, StoreKit veya iCloud bu sürümde yoktur.

## macOS-only kişisel kullanım notu

- **Yalnızca macOS 14+** (Swift Package Manager executable + `script/build_and_run.sh` ile `.app` paketleme).
- **Kişisel kullanım** için tasarlanmıştır; üretim ortamı, çok kullanıcılı hesap veya resmi destek vaadi yoktur.
- Veriler **SwiftData** ile uygulama sandbox’ında yerel olarak saklanır; başka cihazla paylaşılmaz.
- İstediğiniz zaman **Settings → Clear All Data** ile tüm kayıtları silebilirsiniz.

## Kullanılan teknolojiler

| Alan | Teknoloji |
|------|-----------|
| Dil / UI | Swift 5.9, SwiftUI |
| Platform | macOS 14+ (`AppKit` entegrasyonu, `NSApplicationDelegate`) |
| Veri | SwiftData (`@Model` `Subscription`) |
| Tercihler | `@AppStorage` |
| Bildirimler | `UserNotifications` |
| Paketleme | Swift Package Manager (`Package.swift`) |
| Test | `swift test` (XCTest) |

## Özellikler

### Subscription CRUD

Abonelik ekleme, düzenleme ve silme. Alanlar: ad, tutar, para birimi, faturalama döngüsü (haftalık/aylık/üç aylık/yıllık/özel gün), sonraki ödeme tarihi, kategori, ödeme yöntemi, durum, hatırlatma günü, iptal URL’si, notlar.

**Subscriptions** ekranından veya **⌘N** ile yeni kayıt açılır. Durum ve kategori filtreleri, arama (⌘F) desteklenir.

### Dashboard

Aktif benzeri abonelikler için tahmini aylık/yıllık toplamlar (para birimi bazında), 7 gün içinde yenilenecekler, iptal adayı sayısı ve kategori dağılımı özeti.

### Upcoming

Aktif, deneme ve “Cancel Soon” abonelikler; sonraki ödeme tarihine göre gruplanmış yaklaşan ödemeler.

### Cancel List

Durumu **Cancel Soon** olan abonelikler; iptal URL’si açma ve düzenleme.

### Insights

Kategori bazında tahmini harcama, en pahalı abonelikler (aylık/yıllık tahmin) ve durum dağılımı.

### Archive

**Cancelled** ve **Archived** kayıtlar; arama, kategori filtresi, kalıcı silme.

### CSV export

**Settings → Data**: tüm abonelikler veya dashboard özet CSV’si (`NSSavePanel` ile kayıt).

### Local reminders

**Settings → Renewal reminders**: macOS yerel bildirimleri; abonelik başına `reminderDaysBefore` gün önce yenileme uyarısı. İzin verilmezse hatırlatmalar planlanmaz.

## Bilerek eklenmeyenler

Aşağıdakiler bu sürümün **kapsam dışı** bilinçli tercihleridir:

| Özellik | Not |
|---------|-----|
| App Store | Dağıtım ve inceleme süreci yok |
| StoreKit | Uygulama içi satın alma / abonelik yok |
| iCloud sync | Cihazlar arası senkron yok |
| Usage Limits | Kullanım kotası / limit takibi yok |
| Bank integration | Banka veya kart API entegrasyonu yok |
| Email scanning | Fatura / e-posta tarama yok |
| Backend | Sunucu, hesap ve uzaktan API yok |

## Proje yapısı

```
revoxa/
├── Package.swift              # SPM tanımı (macOS 14 executable)
├── README.md
├── docs/
│   ├── usage.md               # Kısa kullanım kılavuzu
│   └── roadmap.md             # Sürüm yol haritası
├── Sources/Revoxa/
│   ├── App/                   # @main, AppDelegate, menü kısayolları
│   ├── Core/
│   │   ├── DesignSystem/      # Renk, tipografi, spacing token’ları
│   │   ├── Extensions/
│   │   ├── Formatters/
│   │   └── Services/          # Billing, Dashboard, Upcoming, Insights, CSV, bildirimler
│   ├── Models/                # Subscription, enum’lar, tercihler
│   └── Views/
│       ├── Components/
│       ├── Navigation/        # Sidebar, Detail yönlendirme
│       └── Screens/           # Dashboard, Subscriptions, …
├── Tests/RevoxaTests/         # Birim testler
├── script/
│   ├── package_app.sh         # dist/Revoxa.app paketleme (debug/release)
│   ├── verify_app_bundle.sh   # .app icon / Info.plist doğrulama
│   ├── sync_applications.sh   # dist/Revoxa.app → /Applications
│   ├── install-local.sh       # Release → /Applications + lsregister + Dock
│   ├── build_and_run.sh       # Paketle + Applications güncelle + çalıştır
│   └── install.sh             # install-local.sh sarmalayıcısı
├── VERSION                    # CFBundleShortVersionString
└── dist/                      # Üretilen Revoxa.app (gitignore)
```

## Lokal çalıştırma adımları

### Gereksinimler

- macOS 14 veya üzeri
- Xcode 15+ veya Swift 5.9+ toolchain (`swift --version`)

### Derleme ve çalıştırma

```bash
cd /path/to/revoxa

# Derleme
swift build

# Testler
swift test

# .app oluşturup açma (önerilen, Debug)
# dist/Revoxa.app üretir ve /Applications/Revoxa.app dosyasını günceller
./script/build_and_run.sh

# Release .app
./script/build_and_run.sh --release --package-only
```

### Applications klasörüne kurulum (kişisel kullanım)

Xcode’dan çalıştırmak uygulamayı `/Applications` altına koymaz. Launchpad, Spotlight ve Dock için paketlenmiş `.app` gerekir:

```bash
./script/install-local.sh
# veya
./script/install.sh
```

Bu komutlar **Release** derler, `dist/Revoxa.app` oluşturur, bundle içindeki ikonları doğrular ve `/Applications/Revoxa.app` konumuna kopyalar. Launch Services kaydı yenilenir; Dock yeniden başlatılır. Sonrasında uygulama Finder → Uygulamalar, Launchpad, Spotlight (`Revoxa`), App Switcher, Stage Manager ve Dock’tan açılabilir. Menü çubuğu (`MenuBarExtra`) kurulu sürümde de çalışır.

**Stage Manager ve ikonlar için:** Uygulamayı Xcode veya DerivedData içindeki debug `.app` ile değil, yalnızca **`/Applications/Revoxa.app`** üzerinden açın. Aynı `com.revoxa.app` kimliğiyle iki kopya açıksa Stage Manager boş veya eski ikon gösterebilir.

İlk açılışta macOS güvenlik uyarısı çıkabilir (imza/notarization yok); **Sağ tık → Aç** ile bir kez onaylayabilirsiniz.

| Komut | Açıklama |
|-------|----------|
| `./script/install-local.sh` | Release build + doğrulama + `/Applications/Revoxa.app` |
| `./script/install-local.sh --refresh-finder` | Kurulum + Finder yeniden başlat |
| `./script/install.sh` | `install-local.sh` ile aynı |
| `./script/install.sh --dry-run` | Yalnızca Release paketleme (`dist/`) |
| `./script/verify_app_bundle.sh` | `dist/Revoxa.app` ikon / plist kontrolü |
| `./script/build_and_run.sh` | Debug paket + `/Applications` güncelle + aç |
| `./script/build_and_run.sh --release` | Release paket + `/Applications` güncelle + aç |
| `./script/build_and_run.sh --skip-applications-sync` | Yalnızca `dist/` (Applications dokunulmaz) |
| `./script/sync_applications.sh` | Mevcut `dist/Revoxa.app` → `/Applications` kopyala |
| `./script/build_and_run.sh --verify` | Paketle, aç, süreç doğrula |
| `./script/build_and_run.sh --debug` | lldb ile binary |

Doğrudan binary:

```bash
swift run Revoxa
```

Ayarlar penceresi: **Revoxa → Settings…** veya **⌘,**.

### Icon / Stage Manager sorun giderme

Dock ve Uygulamalar klasöründe ikon görünüp **Stage Manager**’da boş kutu görünüyorsa, çoğunlukla eski kurulum veya macOS ikon önbelleği kaynaklıdır.

1. Revoxa’yı tamamen kapatın (`⌘Q` veya Activity Monitor).
2. Proje kökünden yeniden kurun:

   ```bash
   ./script/install-local.sh
   ```

3. Uygulamayı **Finder → Uygulamalar → Revoxa** ile açın (Xcode ▶ Run değil).
4. Hâlâ boşsa:
   - Revoxa’yı kapatın
   - `./script/install-local.sh --refresh-finder` (Dock + Finder yenilenir)
   - Gerekirse Terminal’de (yalnızca ikon önbelleği; verilerinize dokunmaz):

     ```bash
     touch /Applications/Revoxa.app
     killall Dock
     killall Finder
     ```

5. Sorun sürerse Mac’i yeniden başlatın.

**Notlar:**

- `MenuBarIcon` yalnızca menü çubuğu şablon simgesidir; uygulama ikonu `AppIcon` asset setinden gelir.
- Finder’da uygulama ikonuna sağ tıklayıp “Get Info” ile özel ikon atamayın; Stage Manager bazen bundle içindeki `AppIcon.icns` yerine bu önbelleği kullanır.
- İsteğe bağlı derin önbellek temizliği (sudo, sistem geneli ikon cache):

  ```bash
  sudo rm -rf /Library/Caches/com.apple.iconservices.store
  sudo find /private/var/folders/ \( -name com.apple.dock.iconcache -o -name com.apple.iconservices \) -exec rm -rf {} \;
  killall Dock
  ```

### Bildirimler / Sistem Ayarları’nda görünmüyor

Revoxa, **Sistem Ayarları → Bildirimler** listesine yalnızca uygulama en az bir kez bildirim izni istedikten sonra eklenir. Liste boşsa veya Revoxa yoksa:

1. `./script/install-local.sh` ile `/Applications/Revoxa.app` kurun.
2. Uygulamayı **Uygulamalar** klasöründen açın (`swift run` veya Xcode DerivedData değil).
3. İlk açılışta macOS izin penceresi çıkabilir — **İzin Ver** deyin.
4. **Revoxa → Ayarlar** (⌘,) → **Yerel bildirimleri etkinleştir** anahtarını bir kez açın.
5. **Sistem Ayarları → Bildirimler** içinde **Revoxa** görünmeli; **Bildirimlere izin ver** açık olsun.

Hâlâ listede yoksa: Revoxa’yı tamamen kapatın (`⌘Q`), `./script/install-local.sh` tekrar çalıştırın, Uygulamalar’dan yeniden açın. Gerekirse Mac’i yeniden başlatın.

## Bilinen sınırlamalar

- **Para birimi dönüşümü yok**: Dashboard ve Insights, her para birimini ayrı toplar; tek bir “genel toplam” döviz kuru ile birleştirilmez.
- **Tahminler**: Aylık/yıllık maliyetler `BillingCalculator` ile faturalama döngüsünden türetilir; gerçek banka ekstresi değildir.
- **Tek cihaz**: Veri yedekleme/geri yükleme yalnızca CSV export ve manuel yönetimle sınırlıdır; CSV import henüz yok (plan: v0.2).
- **Bildirimler**: Sistem izni gerekir; uygulama kapalıyken davranış macOS bildirim politikasına bağlıdır.
- **UI dili**: Ayarlar’dan Türkçe, English veya Sistem Dili seçilebilir (`Localizable.xcstrings`).
- **Kişisel dağıtım**: `./script/install.sh` ile `/Applications` kurulumu desteklenir; App Store, notarization, DMG ve otomatik güncelleme yoktur (yerel ad-hoc imza yalnızca çalıştırmayı kolaylaştırır).

## Gelecek fikirleri

Detaylı sürüm planı: [docs/roadmap.md](docs/roadmap.md).

Özet:

- **v0.2**: UI cilası, CSV import, örnek veri iyileştirmeleri
- **v0.3**: iCloud / CloudKit senkron
- **v0.4**: iOS companion
- **v1.0**: App Store adayı (StoreKit, gizlilik, notarization)

Ek fikirler: çoklu para birimi raporlama, bütçe hedefleri, tekrarlayan ödeme geçmişi, menü çubuğu widget’ı, kısayol ile hızlı ekleme.

## Lisans

Bu depoda lisans dosyası yoksa kullanım koşulları depo sahibine aittir; dağıtım öncesi bir `LICENSE` eklemeniz önerilir.
