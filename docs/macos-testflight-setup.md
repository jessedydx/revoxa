# Revoxa macOS → TestFlight Kurulum Rehberi

Bu rehber, **menü çubuğu ikonu dahil gerçek macOS uygulamasını** TestFlight’a yüklemek içindir.

> **Önemli:** Şu an TestFlight’taki sürüm **iOS/iPad** build’idir. Mac’te çalışsa bile menü çubuğu yoktur.  
> Menü çubuğu için **ayrı bir macOS build** yüklemen gerekir.

---

## Kısa özet

| Ne | Nerede | Kim yapar |
| --- | --- | --- |
| Apple hesabı / sözleşmeler | developer.apple.com | Sen |
| Uygulama kaydı | appstoreconnect.apple.com | Sen |
| macOS `.app` üretimi | Terminal (proje klasörü) | Sen |
| İmzalama + `.pkg` | Terminal veya Xcode | Sen |
| Yükleme | **Transporter** uygulaması | Sen |
| Test | Mac’te **TestFlight** uygulaması | Sen |

---

## Aşama 0 — İki uygulamayı ayırt et

Terminal’de kontrol:

```bash
# Yerel macOS (doğru — menü çubuğu var)
ls dist/Revoxa.app/Contents/MacOS/Revoxa

# TestFlight iOS (menü çubuğu yok)
ls /Applications/Revoxa.app/Wrapper/Revoxa.app 2>/dev/null && echo "Bu iOS sürümü"
```

---

## Aşama 1 — Apple Developer (bir kez)

1. Tarayıcıda aç: [https://developer.apple.com/account](https://developer.apple.com/account)
2. Giriş yap.
3. **Agreements, Tax, and Banking** bölümünde tüm sözleşmeler **Active** olmalı.
4. Aç: [https://developer.apple.com/account/resources/identifiers/list](https://developer.apple.com/account/resources/identifiers/list)
5. `com.revoxa.app` kayıtlı olmalı (iOS için zaten varsa aynısını kullan).

### Sertifikalar (Mac App Store)

1. Mac’te **Xcode** aç.
2. **Xcode → Settings… → Accounts** (veya Preferences → Accounts).
3. Apple ID’n ekle / seç → **Manage Certificates…**
4. Sol alttan **+**:
   - **Apple Distribution** (yoksa oluştur)
   - **Mac App Distribution** / **3rd Party Mac Developer Application** (yoksa oluştur)
   - **Mac Installer Distribution** (yoksa oluştur)
5. Pencereyi kapat.

### Provisioning profile (Mac App Store)

TestFlight macOS paketi, ana uygulama içinde provisioning profile ister.

1. Aç: [https://developer.apple.com/account/resources/profiles/list](https://developer.apple.com/account/resources/profiles/list)
2. **Profiles** → **+**
3. Distribution türü olarak **Mac App Store** seç.
4. App ID / Bundle ID: `com.revoxa.app`
5. Sertifika: `Apple Distribution: ERKAN KARATAS (5JAMN2986A)`
6. Profile adı örneği: `Revoxa macOS App Store`
7. Profili indir.
8. İndirilen `.provisionprofile` dosyasını çift tıkla veya yolunu terminalde kullan.

Profil genelde şu klasöre düşer:

```bash
~/Library/MobileDevice/Provisioning\ Profiles/
```

---

## Aşama 2 — App Store Connect (bir kez)

1. Aç: [https://appstoreconnect.apple.com](https://appstoreconnect.apple.com)
2. **Apps** → **Revoxa** uygulamasını aç.
3. **App Information**:
   - Bundle ID: `com.revoxa.app`
   - Privacy Policy URL dolu olmalı (Store için zorunlu).
4. İlk macOS yüklemesinden sonra aynı uygulama kaydında **macOS** platformu otomatik bağlanır; ayrı uygulama oluşturmana gerek yok.

---

## Aşama 3 — macOS Xcode build al (Terminal)

Proje klasöründe:

```bash
cd /Users/karatasailesi/Projects/revoxa

# Testler (önerilir)
swift test

# macOS target'ın derlendiğini kontrol et
xcodebuild -project Revoxa.xcodeproj \
  -scheme 'Revoxa macOS' \
  -configuration Debug \
  -destination 'platform=macOS' \
  CODE_SIGNING_ALLOWED=NO \
  build
```

Başarılıysa Xcode içindeki gerçek macOS target derlenir. TestFlight paketi bir sonraki aşamada Xcode archive/export ile üretilecek.

### Her yeni TestFlight yüklemesinde

Apple aynı build numarasını kabul etmez.

Manuel Transporter yüklemesinde:

1. `VERSION` dosyasını artır (ör. `0.1.0` → `0.1.1`).
2. Aşağıdaki Xcode export paketleme betiğini tekrar çalıştır; betik Xcode target sürümlerini otomatik günceller.

Xcode Cloud ile push sonrası otomatik build alıyorsan:

1. App Store Connect / Xcode Cloud workflow `Revoxa macOS` scheme'ini archive etmeli.
2. Workflow push ile tetiklenmeli.
3. `ci_scripts/ci_post_clone.sh` otomatik çalışır ve `CI_BUILD_NUMBER` değerini `CURRENT_PROJECT_VERSION` yapar.
4. Böylece aynı `VERSION` altında her push farklı TestFlight build numarası alabilir.

---

## Aşama 4 — Xcode archive/export ile .pkg oluştur

### 4a) Sertifikaları kontrol et

Terminal:

```bash
security find-identity -v -p codesigning | grep -E "Apple Distribution|3rd Party Mac Developer Application"
security find-identity -v -p basic | grep -i "Installer"
```

Gerekenler:

- `Apple Distribution: ... (TEAMID)`
- `3rd Party Mac Developer Installer: ... (TEAMID)` veya Xcode'daki adıyla `Mac Installer Distribution`

### 4b) Hazırlık betiğini çalıştır

```bash
export REVOXA_PROVISIONING_PROFILE='/path/to/Revoxa-macOS-App-Store.provisionprofile'
./script/prepare_macos_xcode_app_store_upload.sh
```

Betik:

- provisioning profile dosyasını Xcode'un beklediği profile klasörüne kopyalar,
- `VERSION` ve varsa `REVOXA_BUILD_NUMBER` değerleriyle Xcode projesini günceller,
- `Revoxa macOS` scheme'i için release archive alır,
- uygulamayı `Apple Distribution` ve Mac App Store profile ile imzalar,
- geçerli Mac Installer Distribution sertifikasını SHA-1 ile seçer,
- Xcode `app-store-connect` export yöntemiyle `dist/Revoxa-macOS.pkg` üretir,
- `.pkg` imzasını ve paket içindeki `Revoxa.app` kod imzasını doğrular.

İmzalama hatası alırsan: Xcode → Settings → Accounts → Download Manual Profiles dene; Team ID ve profile dosyasının `com.revoxa.app` için olduğundan emin ol.

---

## Aşama 5 — App Store Connect’e yükle

### Transporter ile (önerilen)

1. Mac App Store’dan **Transporter** uygulamasını indir (yoksa).
2. Transporter’ı aç → Apple ID ile giriş.
3. **+** veya dosyayı sürükle.
4. Dosya: `dist/Revoxa-macOS.pkg`
5. **Deliver** / **Teslim Et**.

### Yükleme sonrası

1. [appstoreconnect.apple.com](https://appstoreconnect.apple.com) → **Revoxa** → **TestFlight**.
2. **macOS** sekmesine geç (üstte iOS / macOS).
3. Build durumu **Processing** → bir süre sonra **Ready to Test**.

İşleme genelde 5–30 dakika sürer.

---

## Aşama 6 — Mac’te TestFlight’tan kur

1. Eski **iOS** Revoxa’yı kaldır (karışmasın):

   ```bash
   # TestFlight iOS sürümü — Wrapper klasörü varsa bu iOS’tur
   sudo rm -rf /Applications/Revoxa.app
   ```

2. Mac’te **TestFlight** uygulamasını aç.
3. **Revoxa** → macOS build’ini **Install**.
4. Uygulamayı aç.
5. Menü çubuğunun sağ üstünde **Revoxa ikonu** görünmeli.

### Doğrulama

```bash
# macOS TestFlight sürümü — Wrapper OLMAMALI
ls /Applications/Revoxa.app/Contents/MacOS/Revoxa && echo "macOS sürümü OK"
```

---

## Sık sorunlar

| Sorun | Çözüm |
| --- | --- |
| Menü çubuğu yok | iOS build kurmuşsun; macOS build yükle (Aşama 6). |
| Upload reddedildi | Manuel akışta `VERSION` artırıp yeniden paketle; Xcode Cloud'da `CI_BUILD_NUMBER` ile yeni build numarası üretildiğini kontrol et. |
| Xcode Cloud build App Store Connect'te görünmüyor | Workflow tetikleyicisini, branch'i, `Revoxa macOS` scheme'ini ve archive/distribution adımını kontrol et. |
| Xcode Cloud aynı build numarası hatası veriyor | `ci_scripts/ci_post_clone.sh` çalışıyor mu kontrol et; `CI_BUILD_NUMBER` `CURRENT_PROJECT_VERSION` olarak yazılmalı. |
| İmzalama hatası | Xcode’da Apple Distribution sertifikası oluştur. |
| Gatekeeper identity policy hatası | Manuel `productbuild` paketini kullanma; `prepare_macos_xcode_app_store_upload.sh` ile Xcode archive/export paketi üret, yeni sürümle yeniden yükle. |
| Missing provisioning profile | `REVOXA_PROVISIONING_PROFILE` değerini Mac App Store profile dosyasına ver. |
| Missing application identifier | Mac App Store profile'ın `com.revoxa.app` için olduğundan emin ol; Xcode export betiğini yeniden çalıştır. |
| Installer certificate bulunamadı | Xcode → Settings → Accounts → Manage Certificates → `Mac Installer Distribution` oluştur. |
| Processing takılı | 1 saat bekle; Apple e-postasına bak (export compliance vb.). |
| Yerel vs TestFlight karışıyor | Tek seferde bir kaynaktan çalıştır: ya `dist/` ya TestFlight macOS. |

---

## Sonraki yüklemeler (rutin)

### Manuel Transporter

1. Kodu değiştir.
2. `VERSION` artır.
3. `REVOXA_PROVISIONING_PROFILE='...' ./script/prepare_macos_xcode_app_store_upload.sh`
4. `dist/Revoxa-macOS.pkg` → Transporter.
5. TestFlight macOS → test et.

### Xcode Cloud

1. Kodu değiştir.
2. Görünen sürüm değişecekse `VERSION` artır; sadece ara TestFlight build ise aynı kalabilir.
3. Commit + push yap.
4. Xcode Cloud workflow `Revoxa macOS` için archive alır.
5. App Store Connect → TestFlight → macOS sekmesinde yeni build işlenir.

---

## Agent notu

Apple ID şifresi, app-specific password veya banka bilgisi paylaşılmamalı. İmzalama ve Transporter adımları senin Mac’inde yapılır.
