# Revoxa — Kısa kullanım kılavuzu

Bu belge günlük kullanım için hızlı referanstır. Genel bakış ve kurulum için [README.md](../README.md).

## İlk açılış

### Günlük kullanım (Applications)

Launchpad, Spotlight ve Dock için uygulamayı bir kez kurun:

```bash
./script/install.sh
```

Ardından **Uygulamalar** klasöründen veya Spotlight’ta `Revoxa` yazarak açın. Güncelleme sonrası aynı komutu tekrar çalıştırmanız yeterlidir.

macOS ilk açılışta güvenlik uyarısı gösterebilir; **Sağ tık → Aç** ile onaylayın.

### Dil

**Ayarlar → Genel → Dil** bölümünden seçebilirsiniz:

- **Türkçe** — arayüz Türkçe
- **English** — arayüz İngilizce
- **Sistem Dili** — macOS sistem dilini takip eder

Tercih `@AppStorage` ile saklanır. Çoğu ekran dil değişince anında güncellenir; bazı sistem menüleri uygulama yeniden açıldığında yenilenir (Ayarlar’daki kısa not).

### Geliştirme

1. `./script/build_and_run.sh` veya `swift run Revoxa` ile uygulamayı başlatın.
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
| Cancellation URL | İptal sayfası (Cancel List’te açılır) |
| Notes | Serbest metin |

Kayıt **Save** ile SwiftData’ya yazılır. Bildirimler açıksa hatırlatma yeniden planlanır.

**Silme**: Formdaki delete aksiyonu veya listeden düzenleme sheet’i üzerinden; onay istenir.

## Ekranlar

### Dashboard

Özet metrikler: tahmini aylık/yıllık maliyet (para birimine göre), 7 gün içinde yenilenecek sayısı, iptal adayları. İptal edilmiş ve arşivlenmiş kayıtlar maliyet toplamlarına dahil edilmez.

### Subscriptions

Tüm kayıtların listesi. Üstte durum ve kategori filtresi; araç çubuğunda arama (**⌘F** odaklanır).

### Upcoming

Yaklaşan ödemeler, tarih grupları halinde. Yalnızca aktif benzeri durumlar (Active, Trial, Cancel Soon).

### Cancel List

**Cancel Soon** durumundakiler. İptal bağlantısı varsa tarayıcıda açılabilir.

### Insights

Kategori harcamaları, en yüksek tahmini maliyetli abonelikler, durum dağılımı.

### Archive

**Cancelled** ve **Archived** kayıtlar. Kalıcı silme yalnızca bu ekrandan (onaylı).

### Settings (⌘,)

| Ayar | Etki |
|------|------|
| Default currency code | Yeni aboneliklerde varsayılan para birimi |
| Default reminder days | Yeni aboneliklerde varsayılan hatırlatma |
| App appearance | Dark Only veya System |
| Renewal reminders | Yerel macOS bildirimleri aç/kapa |
| Export … CSV | Abonelik listesi veya dashboard özeti |
| Clear All Data | Tüm yerel kayıtları ve bildirimleri siler |

## Klavye kısayolları

| Kısayol | İşlem |
|---------|--------|
| ⌘N | Abonelik ekle |
| ⌘F | Arama alanına odaklan (Subscriptions / Archive) |
| ⌘, | Ayarlar |

## CSV dışa aktarma

1. **Settings → Data**
2. **Export subscriptions as CSV** — tüm alanlar (ad, tutar, döngü, durum, URL, zaman damgaları)
3. **Export dashboard summary as CSV** — özet metrikler

Dosya konumu `NSSavePanel` ile seçilir.

## Yerel hatırlatmalar

1. **Settings → Enable local notifications** açın.
2. macOS izin isteğini onaylayın.
3. Her abonelikte **Reminder days before** değerini ayarlayın.

Hatırlatmalar yalnızca aktif benzeri durumlar için planlanır. Bildirimleri kapatınca bekleyen istekler iptal edilir.

## Durumlar (özet)

| Durum | Tipik kullanım |
|-------|----------------|
| Active | Normal çalışan abonelik |
| Trial | Deneme süresi |
| Cancel Soon | İptal etmeyi planlıyorsunuz → Cancel List |
| Cancelled | Sonlandırıldı → Archive |
| Archived | Geçmiş kayıt → Archive |

## Veri ve gizlilik

- Veri yalnızca bu Mac’te kalır.
- Yedek için düzenli **CSV export** alın.
- Cihaz değiştirmeden önce export alın; import henüz v0.1’de yok.

## Sorun giderme

| Sorun | Öneri |
|-------|--------|
| Bildirim gelmiyor | Sistem Ayarları → Bildirimler → Revoxa izinleri |
| Uygulama açılmıyor | `swift build` çıktısını kontrol edin; macOS 14+ |
| Toplamlar “yanlış” | Farklı para birimleri birleştirilmez; tahmin döngüye dayalıdır |

Daha fazla teknik detay: [README.md](../README.md).
