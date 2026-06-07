# Revoxa App Store İçerik Paketi

Bu dosya iOS, iPadOS ve macOS App Store gönderimi için hazırlanacak metinleri, URL içeriklerini ve ekran görüntüsü çekim listesini toplar.

## App Store Connect Alanları

| Alan | Taslak |
| --- | --- |
| App adı | Revoxa |
| Subtitle | Subscription tracker |
| Primary category | Productivity |
| Secondary category | Finance |
| Bundle ID | `com.revoxa.app` |
| SKU | `revoxa-app` |
| Primary language | English (U.S.) veya Turkish |
| Privacy Policy URL | `https://revoxa.app/privacy` |
| Support URL | `https://revoxa.app/support` |
| User Privacy Choices URL | Opsiyonel: `https://revoxa.app/privacy#choices` |

Not: Domain hazır değilse geçici olarak GitHub Pages kullanılabilir:

- `https://<github-user>.github.io/revoxa/privacy/`
- `https://<github-user>.github.io/revoxa/support/`

## English Metadata

### Name

Revoxa

### Subtitle

Subscription tracker

### Promotional Text

Track recurring payments, renewal dates, and subscription costs locally on your iPhone, iPad, and Mac.

### Description

Revoxa helps you keep recurring subscriptions in one clear, private place.

Add your subscriptions, set renewal dates, choose billing cycles, and see your upcoming payments before they surprise you. Revoxa is designed for people who want a simple way to understand recurring costs across streaming services, software tools, cloud plans, AI tools, and other digital services.

Key features:

- Track subscription name, amount, currency, billing cycle, renewal date, category, status, notes, and cancellation URL.
- See monthly and yearly cost estimates.
- Review upcoming payments in a dashboard and calendar view.
- Mark subscriptions as active, trial, cancel soon, cancelled, or archived.
- Use local renewal reminders.
- Export your data as CSV.
- Review category totals and high-cost subscriptions.
- Use the same focused experience on iPhone, iPad, and Mac.

Privacy-first by design:

Revoxa stores your subscription records locally on your device. There is no account, no advertising SDK, no third-party analytics SDK, and no backend service for your personal subscription data.

Revoxa may fetch public exchange-rate data from the Central Bank of the Republic of Türkiye (TCMB) to help show converted totals. Your subscription records are not sent with that request.

Revoxa is not a banking app and does not connect to your bank, card provider, email account, or App Store subscriptions. All records are entered and managed by you.

### Keywords

subscriptions,bills,budget,renewals,tracker,recurring,payments,calendar,expenses,finance

### What's New

Initial App Store candidate for tracking recurring subscriptions, renewal dates, local reminders, calendar payments, CSV export, and cost summaries.

### Review Notes

Revoxa is a local subscription tracking app.

No login is required.
No paid account is required.
No demo credentials are needed.
The app does not connect to banks, cards, email inboxes, iCloud, or external subscription accounts.

Suggested review flow:

1. Open the app.
2. Add a subscription from the plus button.
3. Enter name, amount, billing cycle, next billing date, category, and status.
4. Save the subscription.
5. Review Dashboard, Subscriptions, Calendar, and Settings.
6. Enable local notifications if you want to test the permission prompt.
7. Export CSV from Settings if file export behavior is being reviewed.

Network note:

The app may request public exchange-rate XML from `https://www.tcmb.gov.tr/kurlar/today.xml`. Subscription records are local and are not included in that request.

## Turkish Metadata

### Ad

Revoxa

### Alt Başlık

Abonelik takip aracı

### Promotional Text

Yenilenen ödemeleri, abonelik tarihlerini ve maliyetleri iPhone, iPad ve Mac üzerinde yerel olarak takip edin.

### Açıklama

Revoxa, dijital aboneliklerinizi sade ve özel bir yerde takip etmenize yardımcı olur.

Aboneliklerinizi ekleyin, yenileme tarihlerini belirleyin, faturalama döngülerini seçin ve yaklaşan ödemeleri önceden görün. Revoxa; yayın servisleri, yazılım araçları, bulut planları, AI araçları ve diğer dijital hizmetler için tekrarlayan maliyetleri anlamak isteyen kullanıcılar için tasarlanmıştır.

Öne çıkan özellikler:

- Abonelik adı, tutar, para birimi, faturalama döngüsü, yenileme tarihi, kategori, durum, not ve iptal bağlantısı takibi.
- Aylık ve yıllık maliyet tahminleri.
- Dashboard ve takvim görünümünde yaklaşan ödemeler.
- Aktif, deneme, iptal adayı, iptal edilmiş ve arşivlenmiş abonelik durumları.
- Yerel yenileme hatırlatmaları.
- CSV dışa aktarma.
- Kategori toplamları ve yüksek maliyetli abonelik analizi.
- iPhone, iPad ve Mac için odaklı ve tutarlı deneyim.

Gizlilik odaklı:

Revoxa abonelik kayıtlarınızı cihazınızda yerel olarak saklar. Hesap, reklam SDK'sı, üçüncü taraf analiz SDK'sı veya kişisel abonelik verileriniz için bir backend servisi yoktur.

Revoxa, toplamları dönüştürmeye yardımcı olmak için Türkiye Cumhuriyet Merkez Bankası'ndan (TCMB) herkese açık döviz kuru verisi çekebilir. Abonelik kayıtlarınız bu istekle gönderilmez.

Revoxa bir bankacılık uygulaması değildir; banka, kart sağlayıcısı, e-posta hesabı veya App Store aboneliklerinize bağlanmaz. Tüm kayıtları siz eklersiniz ve yönetirsiniz.

### Anahtar Kelimeler

abonelik,fatura,bütçe,yenileme,takip,ödeme,takvim,harcama,finans,uyarı

### Yenilikler

Tekrarlayan abonelikler, yenileme tarihleri, yerel hatırlatmalar, takvim ödemeleri, CSV dışa aktarma ve maliyet özetleri için ilk App Store adayı.

### App Review Notları

Revoxa yerel çalışan bir abonelik takip uygulamasıdır.

Giriş hesabı gerekmez.
Ücretli hesap gerekmez.
Demo kullanıcı adı veya şifre gerekmez.
Uygulama banka, kart, e-posta kutusu, iCloud veya harici abonelik hesaplarına bağlanmaz.

Önerilen inceleme akışı:

1. Uygulamayı açın.
2. Artı butonuyla abonelik ekleyin.
3. Ad, tutar, faturalama döngüsü, sonraki ödeme tarihi, kategori ve durum girin.
4. Aboneliği kaydedin.
5. Dashboard, Abonelikler, Takvim ve Ayarlar ekranlarını inceleyin.
6. Bildirim izin akışını test etmek için yerel bildirimleri açın.
7. Dosya dışa aktarma davranışını test etmek için Ayarlar'dan CSV dışa aktarın.

Ağ notu:

Uygulama `https://www.tcmb.gov.tr/kurlar/today.xml` adresinden herkese açık döviz kuru XML verisi isteyebilir. Abonelik kayıtları yereldir ve bu istekle gönderilmez.

## App Privacy Taslağı

App Store Connect gizlilik formu için önerilen başlangıç:

| Alan | Yanıt |
| --- | --- |
| Data collected | No data collected |
| Tracking | No |
| Third-party advertising | No |
| Third-party analytics | No |
| Account creation | No |
| Bank/card/email access | No |

Not: Revoxa yerel kullanıcı girdilerini SwiftData içinde cihazda saklar. Bu veriler geliştiriciye veya üçüncü taraflara gönderilmediği için App Store privacy label tarafında "Data Not Collected" seçimiyle uyumludur. TCMB döviz kuru isteği abonelik verisi içermez.

## Screenshot Çekim Listesi

Apple en fazla 10 screenshot yüklemeye izin verir. Revoxa için 5-6 güçlü ekran yeterli olur.

### iPhone

1. Dashboard
   - Caption: "See your subscription spending at a glance"
   - TR: "Abonelik harcamalarınızı tek bakışta görün"
2. Subscriptions
   - Caption: "Keep every recurring payment organized"
   - TR: "Tüm tekrarlayan ödemelerinizi düzenli tutun"
3. Calendar
   - Caption: "Know what renews and when"
   - TR: "Hangi ödeme ne zaman yenileniyor görün"
4. Day payments modal
   - Caption: "Review all payments due on a selected day"
   - TR: "Seçili gündeki tüm ödemeleri inceleyin"
5. Add/Edit subscription form
   - Caption: "Track cycles, categories, reminders, and notes"
   - TR: "Döngüleri, kategorileri, hatırlatmaları ve notları takip edin"
6. Settings / Export
   - Caption: "Export your local data anytime"
   - TR: "Yerel verinizi istediğiniz zaman dışa aktarın"

### iPad

1. Dashboard wide layout
   - Caption: "A wider view of recurring costs"
   - TR: "Tekrarlayan maliyetler için geniş görünüm"
2. Calendar wide layout
   - Caption: "Plan renewals on a larger calendar"
   - TR: "Yenilemeleri geniş takvimde planlayın"
3. Subscriptions list
   - Caption: "Browse and edit subscriptions comfortably"
   - TR: "Abonelikleri rahatça gezin ve düzenleyin"
4. Insights
   - Caption: "Understand where your recurring spend goes"
   - TR: "Tekrarlayan harcamanızın nereye gittiğini anlayın"

### macOS

1. Dashboard desktop
   - Caption: "A focused desktop view for your subscriptions"
   - TR: "Abonelikleriniz için odaklı masaüstü görünümü"
2. Subscriptions table/list
   - Caption: "Search, filter, and manage local records"
   - TR: "Yerel kayıtları arayın, filtreleyin ve yönetin"
3. Calendar
   - Caption: "A monthly view of upcoming payments"
   - TR: "Yaklaşan ödemeler için aylık görünüm"
4. Settings / CSV export
   - Caption: "Local preferences and portable CSV export"
   - TR: "Yerel tercihler ve taşınabilir CSV dışa aktarma"

## Screenshot Teknik Notları

- App Store Connect screenshot dosyaları `.jpeg`, `.jpg` veya `.png` olabilir.
- Her cihaz ailesi için 1-10 screenshot hazırlanmalı.
- iPhone için güncel büyük ekran setiyle başlamak pratik olur.
- iPad desteklendiği için iPad screenshot seti de hazırlanmalı.
- macOS platformu ayrı screenshot seti ister.
- Görseller gerçek uygulama ekranını temsil etmeli; gösterilen veriler demo/kurgu veri olmalı.
- Kişisel veri, gerçek banka bilgisi, gerçek e-posta, gerçek hesap veya üçüncü taraf gizli bilgi görünmemeli.

## Üretilen Screenshot Assetleri

Final App Store görselleri başlıklı/pazarlama çerçeveli PNG olarak hazırlandı. Ham ekran görüntüleri `docs/app-store-assets/screenshots/raw/` altında, App Store'a yüklenecek final görseller `docs/app-store-assets/screenshots/final/` altındadır.

Güncel screenshot standardı:

- Uygulama ekranları koyu temada yakalanır.
- Demo abonelikler USD tutarlarıyla gösterilir.
- Screenshot modunda TCMB kuru ile TRY dönüşümü kapalıdır; toplamlar dolar bazında kalır.

Tekrar üretim komutu:

```bash
swift script/generate_app_store_screenshots.swift
```

### iPhone final dosyaları

Boyut: `1290 x 2796`

- `docs/app-store-assets/screenshots/final/iphone/01-dashboard.png`
- `docs/app-store-assets/screenshots/final/iphone/02-subscriptions.png`
- `docs/app-store-assets/screenshots/final/iphone/03-calendar.png`
- `docs/app-store-assets/screenshots/final/iphone/04-day-modal.png`
- `docs/app-store-assets/screenshots/final/iphone/05-edit-form.png`
- `docs/app-store-assets/screenshots/final/iphone/06-settings.png`

### iPad final dosyaları

Boyut: `2048 x 2732`

- `docs/app-store-assets/screenshots/final/ipad/01-dashboard.png`
- `docs/app-store-assets/screenshots/final/ipad/02-calendar.png`
- `docs/app-store-assets/screenshots/final/ipad/03-subscriptions.png`
- `docs/app-store-assets/screenshots/final/ipad/04-settings.png`

### macOS final dosyaları

Boyut: `2880 x 1800`

- `docs/app-store-assets/screenshots/final/macos/01-dashboard.png`
- `docs/app-store-assets/screenshots/final/macos/02-subscriptions.png`
- `docs/app-store-assets/screenshots/final/macos/03-calendar.png`
- `docs/app-store-assets/screenshots/final/macos/04-settings.png`

## Kaynak Notları

- Apple App Store Connect "App information": app adı en fazla 30 karakter, subtitle en fazla 30 karakter, iOS/macOS için Privacy Policy URL gerekir.
- Apple "Platform version information": promotional text 170 karakter, description 4000 karakter, keywords 100 byte, Support URL alanı bulunur.
- Apple screenshot specification sayfası cihaz ailesine göre güncel screenshot boyutlarını listeler.

Resmi referanslar:

- https://developer.apple.com/help/app-store-connect/reference/app-information/
- https://developer.apple.com/help/app-store-connect/reference/platform-version-information/
- https://developer.apple.com/help/app-store-connect/reference/screenshot-specifications/
- https://developer.apple.com/help/app-store-connect/manage-app-information/manage-app-privacy/
