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

## Aşama 3 — macOS build al (Terminal)

Proje klasöründe:

```bash
cd /Users/karatasailesi/Projects/revoxa

# Testler (önerilir)
swift test

# Mac App Store uyumlu release paketi
./script/package_app.sh --release --app-store
./script/verify_mac_app_store_entitlements.sh dist/Revoxa.app
```

Başarılıysa: `dist/Revoxa.app` oluşur.

### Her yeni TestFlight yüklemesinde

Apple aynı build numarasını kabul etmez.

1. `VERSION` dosyasını artır (ör. `0.1.0` → `0.1.1`).
2. Yukarıdaki `package_app.sh` komutunu tekrar çalıştır.

---

## Aşama 4 — İmzala ve .pkg oluştur

### 4a) İmzalama kimliğini bul

Terminal:

```bash
security find-identity -v -p codesigning | grep "Apple Distribution"
```

Çıktıdaki tırnak içindeki metni kopyala, örnek:

`Apple Distribution: Adın Soyadın (XXXXXXXXXX)`

Installer sertifikası `.pkg` imzalamak içindir; `-p codesigning` çıktısında görünmeyebilir. Bulmak için:

```bash
security find-identity -v -p basic | grep -i "Installer"
```

Bu da boşsa Keychain Access içinde sertifika adını kopyala. Ekran görüntündeki format buna benzer:

`3rd Party Mac Developer Installer: ERKAN KARATAS (5JAMN2986A)`

### 4b) Hazırlık betiğini çalıştır

```bash
export REVOXA_SIGN_IDENTITY='Apple Distribution: Adın Soyadın (XXXXXXXXXX)'
export REVOXA_INSTALLER_IDENTITY='3rd Party Mac Developer Installer: Adın Soyadın (XXXXXXXXXX)'
export REVOXA_PROVISIONING_PROFILE='/path/to/Revoxa-macOS-App-Store.provisionprofile'
# Normalde imzalama kimliğinden otomatik bulunur; gerekirse açık ver:
export REVOXA_TEAM_ID='XXXXXXXXXX'
./script/prepare_macos_app_store_upload.sh
```

Betik:

- provisioning profile dosyasını `Revoxa.app/Contents/embedded.provisionprofile` olarak ekler,
- provisioning profile ile uyumlu `com.apple.application-identifier` entitlement'ını imzaya ekler,
- Safari/Downloads kaynaklı `com.apple.quarantine` attribute'larını app içinden temizler,
- `dist/Revoxa.app` imzalar (sandbox entitlement ile),
- `dist/Revoxa-macOS.pkg` üretir,
- sonraki adımı hatırlatır.

İmzalama hatası alırsan: Xcode → Settings → Accounts → Download Manual Profiles dene; Team ID’nin doğru olduğundan emin ol.

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
| Upload reddedildi | Build numarasını (`VERSION`) artır, yeniden paketle. |
| İmzalama hatası | Xcode’da Apple Distribution sertifikası oluştur. |
| Missing provisioning profile | `REVOXA_PROVISIONING_PROFILE` değerini Mac App Store profile dosyasına ver. |
| Missing application identifier | Güncel `prepare_macos_app_store_upload.sh` ile yeniden imzala; gerekirse `REVOXA_TEAM_ID` ver. |
| `com.apple.quarantine` hatası | Güncel betik app içindeki quarantine attribute'larını temizler; paketi yeniden üret. |
| Processing takılı | 1 saat bekle; Apple e-postasına bak (export compliance vb.). |
| Yerel vs TestFlight karışıyor | Tek seferde bir kaynaktan çalıştır: ya `dist/` ya TestFlight macOS. |

---

## Sonraki yüklemeler (rutin)

1. Kodu değiştir.
2. `VERSION` artır.
3. `./script/package_app.sh --release --app-store`
4. `REVOXA_SIGN_IDENTITY='...' REVOXA_PROVISIONING_PROFILE='...' ./script/prepare_macos_app_store_upload.sh`
5. `dist/Revoxa-macOS.pkg` → Transporter.
6. TestFlight macOS → test et.

---

## Agent notu

Apple ID şifresi, app-specific password veya banka bilgisi paylaşılmamalı. İmzalama ve Transporter adımları senin Mac’inde yapılır.
