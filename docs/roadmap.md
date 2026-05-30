# Revoxa yol haritası

Ürün evrimi için planlanan ana sürümler. Mevcut depo **v0.1** ile uyumludur.

## v0.1 — Personal macOS app

**Durum:** Mevcut kapsam

- SwiftUI + SwiftData yerel abonelik yönetimi
- Dashboard, Subscriptions, Upcoming, Cancel List, Insights, Archive
- Settings: tercihler, CSV export, veriyi temizleme
- Yerel yenileme bildirimleri (`UserNotifications`)
- SPM + `script/build_and_run.sh` ile kişisel `.app` çalıştırma
- Birim testler (hesaplayıcılar, CSV, bildirim planlama)

**Kapsam dışı:** App Store, StoreKit, iCloud, backend, banka/e-posta entegrasyonu.

---

## v0.2 — Polish + import

**Hedef:** Günlük kullanımı güçlendirmek, veri taşınabilirliği

- UI/UX cilası (tutarlı dil, erişilebilirlik, boş durumlar)
- **CSV import** (export ile simetrik şema)
- Örnek / demo veri seçenekleri (geliştirme ve ilk kurulum)
- Form ve liste iyileştirmeleri (toplu işlemler, sıralama)
- Dokümantasyon ve yerel yedekleme akışı

---

## v0.3 — iCloud sync

**Hedef:** Aynı Apple ID ile Mac’ler arası senkron

- CloudKit veya SwiftData + iCloud container
- Çakışma çözümü stratejisi (son yazan / birleştirme kuralları)
- Gizlilik metni ve kullanıcıya açık “veri nerede” açıklaması
- Bildirimlerin cihaz bazlı kalması (senkron dışı)

---

## v0.4 — iOS companion

**Hedef:** Mobil okuma ve hızlı güncelleme

- iOS uygulaması (SwiftUI paylaşılan modeller / paket)
- v0.3 senkron ile tutarlı veri katmanı
- macOS’ta tam CRUD; iOS’ta öncelik: liste, yaklaşan, hatırlatma
- Widget / Live Activity değerlendirmesi (opsiyonel)

---

## v1.0 — App Store candidate

**Hedef:** Genel dağıtıma hazır ürün

- App Store Connect, kod imzalama, notarization
- Gizlilik manifesti, App Store açıklamaları
- StoreKit (varsa premium katman) — ürün kararına bağlı
- iCloud senkron stabilizasyonu
- Destek / geri bildirim kanalı, sürüm notları
- Kapsamlı test (UI, senkron, bildirimler)

---

## Karar kayıtları (özet)

| Konu | v0.1 | Sonraki |
|------|------|---------|
| Backend | Hayır | v1.0’da da zorunlu değil |
| Bank / e-posta | Hayır | Uzun vadede değerlendirme |
| Usage limits | Hayır | İhtiyaç netleşince |
| App Store | Hayır | v1.0 |

Bu dosya ürün niyetini yansıtır; tarihler ve kapsam sprint planlamasında güncellenebilir.
