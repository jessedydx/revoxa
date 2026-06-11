# Revoxa iOS + macOS App Store Hazırlık İş Akışı

Bu doküman, Apple Developer hesabı onaylanmadan önce yapılabilecek hazırlıkları ve hesap onayından sonra izlenecek Store sürecini tarif eder.

## Amaç

Revoxa'yı macOS uygulaması olarak korurken iOS sürümünü hazırlamak, iki platformu App Store için mümkünse tek uygulama kaydı ve universal purchase stratejisiyle yayına hazır hale getirmek.

## Mevcut Durum

- Proje Swift Package Manager tabanlı ortak kod katmanını kullanır; `Package.swift` artık macOS ve iOS platformlarını hedefler.
- macOS uygulaması mevcut paketleme akışıyla `dist/Revoxa.app` ve `/Applications/Revoxa.app` olarak doğrulanır.
- iOS için kalıcı Xcode projesi oluşturulmuştur: `Revoxa.xcodeproj`.
- iOS scheme adı: `Revoxa iOS`.
- iOS Bundle ID: `com.revoxa.app`.
- iOS hedef cihaz ailesi iPhone + iPad olarak ayarlanmıştır (`TARGETED_DEVICE_FAMILY = 1,2`).
- iOS build, iOS 26.5 simulator üzerinde doğrulanmıştır; generic iOS/device build signing kapalı şekilde geçmektedir.
- iOS AppIcon asset catalog iPhone, iPad ve iOS marketing boyutlarını içerir.
- Modeller, hesaplama servisleri, SwiftData kullanımı, lokalizasyon ve birçok SwiftUI ekran ortaklaştırılmıştır.
- `AppKit`, `MenuBarExtra`, pencere yönetimi, `NSSavePanel`, macOS toolbar ve bazı notification davranışları platforma özeldir.
- Apple Developer hesabı onaylanmadan signing team, provisioning profile, TestFlight upload ve App Store gönderimi tamamlanamaz.

## Teknik Hedefler ve Ayarlar

| Alan | Değer / Durum |
| --- | --- |
| iOS Xcode projesi | `Revoxa.xcodeproj` |
| iOS scheme | `Revoxa iOS` |
| Bundle ID | `com.revoxa.app` |
| Cihaz ailesi | iPhone + iPad |
| iOS minimum hedef | iOS 17 |
| iOS simulator doğrulaması | Başarılı |
| Generic iOS/device build | `CODE_SIGNING_ALLOWED=NO` ile başarılı |
| Xcode Cloud build numarası | `ci_scripts/ci_post_clone.sh` → `CI_BUILD_NUMBER` değerini `CURRENT_PROJECT_VERSION` olarak yazar |
| Signing | Apple Developer hesabı onayı ve Team ID bekliyor |
| Capabilities | Şu an özel capability yok; ihtiyaç çıkarsa App Store öncesi netleştirilecek |
| Privacy manifest | `Sources/Revoxa/Resources/PrivacyInfo.xcprivacy` mevcut |
| App Store içerikleri | `docs/app-store-content.md` |
| Privacy Policy taslağı | `docs/privacy-policy.md` |
| Support sayfası taslağı | `docs/support.md` |

## Developer Hesabı Onaylanmadan Yapılacaklar

1. Mevcut kodu platform uygunluğu açısından taramayı sürdür.
   - Ortak modeller, servisler ve UI parçacıkları ortak katmanda kalmalı.
   - macOS'a bağımlı kodlar izole kalmalı: `AppKit`, menü bar, pencere yönetimi, dosya kaydetme panelleri.

2. Mimariyi iOS ve macOS için koru.
   - Ortak katman: model, hesaplama, formatlama, lokalizasyon, SwiftData.
   - macOS katmanı: menü bar, pencere konfigürasyonu, macOS export ve ayarlar.
   - iOS katmanı: mobil app entry point, navigasyon, share/export, notification izin akışı.

3. iOS uygulama ekranlarını cilala.
   - iPhone ve iPad navigasyon modeli simulator üzerinde kontrol edilmeli.
   - Dashboard, abonelik listesi, abonelik formu, takvim ve ayarlar ekranları mobil düzende regresyon testinden geçirilmeli.
   - macOS davranışını bozmadan platform koşullu derleme kullan.

4. Veri ve bildirim davranışını doğrula.
   - SwiftData modelinin iOS simulator üzerinde çalıştığını test et.
   - Lokal bildirim izinlerini iOS davranışına uygun hale getir.
   - CSV export için iOS'ta share sheet, macOS'ta save panel kullan.

5. Store hazırlık paketini oluştur.
   - App adı, alt başlık, açıklama ve anahtar kelimeler.
   - Kategori ve yaş derecelendirme önerisi.
   - Privacy Policy ve Support URL içeriği.
   - TestFlight açıklaması ve App Review notları.
   - iOS ve macOS ekran görüntüsü metinleri.
   - App icon ve Store görsel ihtiyaç listesi.
   - İçerik paketi: `docs/app-store-content.md`.
   - Privacy Policy taslağı: `docs/privacy-policy.md`.
   - Support sayfası taslağı: `docs/support.md`.

6. Mac App Store gereksinimlerini hazırla.
   - App Sandbox entitlement dosyası: `Configurations/Revoxa-macOS/Revoxa-macOS.entitlements`
   - Gerekirse `PrivacyInfo.xcprivacy` dosyasını ekle.
   - macOS build ve paketleme akışının Store'a uygunluğunu kontrol et.

### macOS App Sandbox planı

Mac App Store dağıtımı için App Sandbox zorunludur. Revoxa'nın mevcut özellikleriyle uyumlu minimum entitlement seti:

| Entitlement | Neden |
| --- | --- |
| `com.apple.security.app-sandbox` | Mac App Store zorunluluğu |
| `com.apple.security.network.client` | TCMB döviz kuru (`ExchangeRateService`) |
| `com.apple.security.files.user-selected.read-write` | CSV dışa aktarma (`NSSavePanel`) |

Eklenmeyen / gerekmediği doğrulananlar:

- Banka, e-posta, konum, kamera, mikrofon erişimi yok
- Sunucu veya gelen ağ bağlantısı yok
- iCloud / App Group paylaşımı yok (SwiftData yerel container'da)
- Yerel bildirimler için ayrı sandbox entitlement gerekmez

Doğrulama:

```bash
xcodebuild -project Revoxa.xcodeproj \
  -scheme 'Revoxa macOS' \
  -configuration Debug \
  -destination 'platform=macOS' \
  CODE_SIGNING_ALLOWED=NO \
  build
```

Not: Yerel `/Applications` kurulumu `script/package_app.sh` akışını kullanır. Mac App Store/TestFlight paketi ise `Revoxa macOS` Xcode target'ından `script/prepare_macos_xcode_app_store_upload.sh` ile archive/export edilmelidir; bu akış `Apple Distribution`, Mac App Store provisioning profile ve Mac Installer Distribution sertifikasını birlikte kullanır.

### Xcode Cloud / GitHub push akışı

App Store Connect'te GitHub bağlıysa push sonrası otomatik TestFlight build için Xcode Cloud workflow şu şekilde kalmalı:

- Branch tetikleyicisi kullanılan ana branch'i izlemeli.
- Archive scheme'i `Revoxa macOS` olmalı.
- Distribution hedefi App Store Connect / TestFlight olmalı.
- Internal testing grubu yeni build'leri alacak şekilde bağlı olmalı.

`VERSION` dosyası görünen sürümü (`MARKETING_VERSION`) belirler. Xcode Cloud'da `ci_scripts/ci_post_clone.sh` çalıştığında Apple'ın `CI_BUILD_NUMBER` ortam değişkeni build numarası (`CURRENT_PROJECT_VERSION`) olarak yazılır. Bu sayede aynı görünen sürüm altında birden fazla TestFlight build gönderilebilir.

7. Lokal doğrulama yap.
   - `swift build`
   - `swift test`
   - İstenirse `./script/build_and_run.sh --package-only` ile macOS paketini doğrula.
   - iOS simulator build: `Revoxa.xcodeproj` / `Revoxa iOS`.
   - iOS generic/device build: `CODE_SIGNING_ALLOWED=NO`.
   - iPhone ve iPad simulator üzerinde ana ekran akışları.

## Developer Hesabı Onaylandıktan Sonra

1. Apple Developer sözleşmeleri, vergi ve banka durumunu kontrol et.
2. `com.revoxa.app` Bundle ID kaydını Apple Developer tarafında kesinleştir.
3. Mümkünse iOS + macOS'u aynı App Store Connect uygulama kaydı altında planla.
4. Signing, provisioning ve capabilities ayarlarını yap.
   - Xcode target için Team ID atanmalı.
   - Automatic signing veya manuel provisioning stratejisi netleşmeli.
   - Gerekirse entitlement dosyaları App Store gereksinimlerine göre güncellenmeli.
   - iCloud container: `iCloud.com.revoxa.app` (CloudKit + Key-Value store). iOS ve macOS target'larında **iCloud** capability açık olmalı.
5. TestFlight için ilk iOS build'i yükle.
6. macOS build'i Mac App Store gereksinimleriyle doğrula. Adım adım macOS TestFlight rehberi: `docs/macos-testflight-setup.md`.
7. Store metadata, privacy bilgileri, ekran görüntüleri ve review notlarını gir.
8. Son kontrol listesinden sonra App Review'a gönder.

## Riskler

- iOS uyarlaması sırasında macOS davranışı bozulabilir.
- Mac App Store için sandbox kısıtları mevcut macOS özelliklerinde değişiklik gerektirebilir.
- App Store Review sonucu garanti edilemez; gizlilik, izin metinleri ve Store metadata uygulama davranışıyla tutarlı olmalıdır.
- Universal purchase kararı verildikten sonra platform kaydı stratejisini geri almak zor olabilir.

## Geri Dönüş Planı

- iOS hazırlığı mümkünse ayrı branch veya küçük commitler halinde ilerletilir.
- Ortak kod ayrımı yapılırken macOS build PR veya manuel doğrulamada kontrol edilir.
- Platforma özel değişiklikler `#if os(macOS)` ve `#if os(iOS)` bloklarıyla izole edilir.
- Store metadata ve görsel dosyaları koddan ayrı tutulur; gerekirse kolayca revize edilir.

## Agent Notu

Bu süreçte ajan, kullanıcıdan şifre veya gizli hesap bilgisi istememelidir. Apple Developer hesabı, sözleşme, banka/vergi ve son App Review gönderimi gibi hesap sahibi aksiyonları kullanıcı tarafından onaylanmalıdır.
