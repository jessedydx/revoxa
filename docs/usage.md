# Revoxa — Kısa kullanım kılavuzu

Bu belge günlük kullanım için hızlı referanstır. Genel bakış ve kurulum için [README.md](../README.md).

Revoxa **macOS**, **iPhone** ve **iPad** üzerinde çalışır. Veriler yalnızca cihazınızda (SwiftData) saklanır; hesap veya bulut senkronu yoktur.

## İlk açılış

### macOS (günlük kullanım)

Launchpad, Spotlight ve Dock için uygulamayı bir kez kurun:

```bash
./script/install.sh
```

Ardından **Uygulamalar** klasöründen veya Spotlight’ta `Revoxa` yazarak açın. Güncelleme sonrası aynı komutu tekrar çalıştırmanız yeterlidir.

macOS ilk açılışta güvenlik uyarısı gösterebilir; **Sağ tık → Aç** ile onaylayın.

Menü çubuğundaki Revoxa simgesi hızlı özet sunar: yaklaşan ödemeler, iptal adayları, ana pencereyi açma ve yeni abonelik ekleme.

### iPhone / iPad

Xcode ile `Revoxa.xcodeproj` → scheme **Revoxa iOS** kullanın. Simulator veya cihazda çalıştırın.

- **iPhone:** alt sekme çubuğu — Dashboard, Subscriptions, Calendar, Settings
- **iPad:** geniş düzende yan panel + içerik alanı (aynı bölümler)

### Dil

**Ayarlar → Genel → Dil** bölümünden seçebilirsiniz:

- **Türkçe** — arayüz Türkçe
- **English** — arayüz İngilizce
- **Sistem Dili** — cihaz sistem dilini takip eder

Tercih `@AppStorage` ile saklanır. Çoğu ekran dil değişince anında güncellenir; bazı sistem menüleri uygulama yeniden açıldığında yenilenir (Ayarlar’daki kısa not).

### Geliştirme (macOS)

1. `./script/build_and_run.sh` ile uygulamayı başlatın (önerilen).
2. Sol kenar çubuğundan bir bölüm seçin (varsayılan: **Dashboard**).
3. İlk aboneliği eklemek için **Subscriptions** → **Add Subscription** veya **⌘N**.

## Abonelik ekleme / düzenleme

| Alan | Açıklama |
|------|----------|
| Name | Abonelik adı |
| Amount / Currency | Tutar ve 3 harfli para birimi (ör. `TRY`, `USD`) |
| Billing cycle | Haftalık, aylık, üç aylık, yıllık veya özel gün sayısı |
| Next billing date | Bir sonraki tahmini ödeme tarihi |
| Category / Payment method | Sınıflandırma ve ödeme kanalı |
| Status | Active, Trial, Cancel Soon, Cancelled, Archived |
| Reminder days before | Yenilemeden kaç gün önce bildirim (0–365) |
| Cancellation URL | İptal sayfası bağlantısı (kayıt için; tarayıcıda saklanır) |
| Notes | Serbest metin |

Kayıt **Save** ile SwiftData’ya yazılır. Bildirimler açıksa hatırlatma yeniden planlanır.

**Silme:** Düzenleme formundaki delete aksiyonu; onay istenir.

**Arşivleme:** Formdaki durum aksiyonları veya status alanı ile Cancelled / Archived yapılabilir.

## Ekranlar

Ana navigasyon bölümleri: **Dashboard**, **Subscriptions**, **Calendar**, **Settings**. (Eski sürümlerdeki ayrı Upcoming / Cancel List / Archive ekranları kaldırıldı; aynı bilgiler aşağıdaki yerlerde.)

### Dashboard

Özet metrikler: tahmini aylık/yıllık maliyet, yaklaşan ödemeler listesi, en yüksek maliyetli abonelikler. İptal edilmiş ve arşivlenmiş kayıtlar maliyet toplamlarına dahil edilmez.

Farklı para birimleri için toplamlar TCMB döviz kurlarıyla dönüştürülebilir (ağ isteği yalnızca kur verisi içindir; abonelik kayıtları gönderilmez).

### Subscriptions

Tüm kayıtların listesi. Üstte **durum filtresi** (Active, Trial, Cancel Soon, Cancelled, Archived) ve kategori filtresi; macOS’ta araç çubuğunda arama (**⌘F** odaklanır).

### Calendar

Aylık takvim görünümü; güne tıklayınca o günkü ödemeleri gösteren modal açılır.

**Insights** (kategori harcamaları, durum dağılımı): Takvim ekranındaki grafik düğmesiyle açılır. iPad’de benzer analizler geniş düzende kullanılabilir.

### Settings

| Ayar | Etki |
|------|------|
| Default currency code | Yeni aboneliklerde varsayılan para birimi |
| Default reminder days | Yeni aboneliklerde varsayılan hatırlatma |
| App appearance | Light, Dark veya System |
| Renewal reminders | Yerel bildirimleri aç/kapa |
| Export … CSV | Abonelik listesi veya dashboard özeti |
| Clear All Data | Tüm yerel kayıtları ve bildirimleri siler |

### macOS menü çubuğu

- **Yaklaşan ödemeler** özeti
- **İptal adayları** (Cancel Soon ve düşük değer önerileri)
- Ana pencereyi açma, yeni abonelik, çıkış

Menü çubuğundaki “Tüm yaklaşanlar” Dashboard’a gider.

## Klavye kısayolları (macOS)

| Kısayol | İşlem |
|---------|--------|
| ⌘N | Abonelik ekle |
| ⌘F | Arama alanına odaklan (Subscriptions) |
| ⌘, | Ayarlar |

## CSV dışa aktarma

1. **Settings → Data**
2. **Export subscriptions as CSV** — tüm alanlar (ad, tutar, döngü, durum, URL, zaman damgaları)
3. **Export dashboard summary as CSV** — özet metrikler

- **macOS:** dosya konumu `NSSavePanel` ile seçilir.
- **iOS / iPad:** paylaşım sayfası (share sheet) ile dosyayı kaydedebilir veya paylaşabilirsiniz.

## Yerel hatırlatmalar

1. **Settings → Enable local notifications** açın.
2. Sistem bildirim iznini onaylayın (macOS veya iOS Ayarlar).
3. Her abonelikte **Reminder days before** değerini ayarlayın.

Hatırlatmalar yalnızca aktif benzeri durumlar için planlanır. Bildirimleri kapatınca bekleyen istekler iptal edilir.

## Durumlar (özet)

| Durum | Tipik kullanım |
|-------|----------------|
| Active | Normal çalışan abonelik |
| Trial | Deneme süresi |
| Cancel Soon | İptal etmeyi planlıyorsunuz → Subscriptions filtresi veya menü çubuğu özeti |
| Cancelled | Sonlandırıldı → Subscriptions → Cancelled filtresi |
| Archived | Geçmiş kayıt → Subscriptions → Archived filtresi |

## Veri ve gizlilik

- Veri yalnızca cihazınızda kalır (Mac, iPhone veya iPad ayrı kopyalar; senkron yok).
- Yedek için düzenli **CSV export** alın.
- Cihaz değiştirmeden önce export alın; **CSV import** henüz yok (yol haritasında v0.2).

Gizlilik metni: [GitHub Pages — Privacy](https://jessedydx.github.io/revoxa/privacy/)

## Sorun giderme

| Sorun | Öneri |
|-------|--------|
| Bildirim gelmiyor | Sistem Ayarları → Bildirimler → Revoxa izinleri |
| Uygulama açılmıyor (macOS) | `swift build` veya `./script/build_and_run.sh`; macOS 14+ |
| Toplamlar “yanlış” | Farklı para birimleri ayrı gösterilir; TCMB kuru yüklenmemişse ham para birimi toplamları görünür |
| Simulator’da ikon güncellenmiyor | Uygulamayı silip yeniden yükleyin |

Daha fazla teknik detay: [README.md](../README.md).
