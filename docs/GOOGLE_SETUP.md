# Google Entegrasyonu Kurulum Rehberi (Takvim + Fotoğraflar)

FamilyHub, Google Takvim ve Google Fotoğraflar ile **doğrudan** bağlanabilir.
Bu, `google_sign_in` + `googleapis` paketleriyle çalışır (pubspec'te mevcut) ve
`lib/services/google_integration_service.dart` üzerinden kullanılır.

> **Not:** Android'de cihaz takvimi zaten OS üzerinden Google Takvim ile
> eşitlenir (mevcut `CalendarSyncService`). Aşağıdaki adımlar, **paylaşımlı aile
> takvimleri**, sunucu-tarafı senkron ve **Google Fotoğraflar** erişimi için
> gereklidir. Yapılandırma yapılmazsa uygulama sorunsuz çalışır; Google
> özellikleri "yapılandırılmadı" durumunda güvenle devre dışı kalır.

## 1. Google Cloud projesi oluştur
1. https://console.cloud.google.com → yeni proje: **FamilyHub**.
2. **APIs & Services → Library**'den şunları etkinleştir:
   - **Google Calendar API**
   - **Photos Library API**

## 2. OAuth onay ekranı (Consent Screen)
1. **APIs & Services → OAuth consent screen** → **External** seç.
2. Uygulama adı: `FamilyHub`, destek e-postası, geliştirici e-postası.
3. **Scopes** ekle:
   - `.../auth/calendar`
   - `.../auth/photoslibrary.readonly`
4. **Test users** olarak kendi Gmail adresini ekle (yayına almadan önce).

## 3. OAuth İstemci Kimlikleri (Credentials)
**APIs & Services → Credentials → Create Credentials → OAuth client ID**

### Android
- Application type: **Android**
- Package name: `com.miro.familyhub`
- SHA-1: `keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android` çıktısındaki SHA1
  - Yayın (release) için release keystore SHA-1'ini de ekle.

### Web (googleapis auth için gerekli)
- Application type: **Web application**
- Bu **Web client ID**'yi uygulamaya vereceğiz (aşağıda).

## 4. Uygulamaya İstemci Kimliğini Ver
Web client ID'yi `--dart-define` ile geçir:

```bash
flutter run --dart-define=GOOGLE_OAUTH_CLIENT_ID=XXXX.apps.googleusercontent.com
# veya release build:
flutter build apk --dart-define=GOOGLE_OAUTH_CLIENT_ID=XXXX.apps.googleusercontent.com
```

`GoogleIntegrationService.isConfigured` bu değer verilince `true` olur.

## 5. Android yapılandırması (google-services.json — Firebase kullanılıyorsa)
Uygulama zaten FCM için Firebase kullanıyorsa `android/app/google-services.json`
mevcuttur. Google Sign-In, `default_web_client_id` alanını buradan da okuyabilir;
`--dart-define` verilmezse bu dosyadaki değer kullanılır.

## 6. Test
1. Uygulamayı yukarıdaki `--dart-define` ile başlat.
2. Ayarlar → (eklenecek) "Google Bağlantısı" → **Google ile Bağlan**.
3. İzin ekranında Takvim + Fotoğraflar onayını ver.
4. `GoogleIntegrationService.fetchCalendarEvents()` etkinlikleri döndürmeli.

## Kod tarafı — hazır API
`lib/services/google_integration_service.dart`:
- `isConfigured` — yapılandırma var mı?
- `signIn()` / `signOut()` / `isSignedIn()`
- `fetchCalendarEvents({from, to})` — Google Takvim etkinlikleri
- `addCalendarEvent(...)` — Google Takvim'e etkinlik ekle
- Google Fotoğraflar: `authenticatedClient()` ile
  `https://photoslibrary.googleapis.com/v1/mediaItems` çağrısı (kurulum sonrası
  eklenecek — serviste yorumlu not var).

## Güvenlik
- İstemci kimliği gizli değildir ama yine de repoya sabit yazma; `--dart-define`
  veya CI secret kullan.
- Yalnızca gereken en dar kapsamları iste (Fotoğraflar için `readonly`).
- Kullanıcı istediğinde `signOut()` ile erişimi kaldırabilmeli.
