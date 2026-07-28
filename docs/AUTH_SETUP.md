# FamilyHub — Authentication Kurulum Rehberi

_Son güncelleme: 2026-07-13 · Auth kesin düzeltme oturumu_

Kod tarafındaki sağlamlaştırma tamamlandı (retry, hata sınıflandırma, güvenli
listener, tek GoogleSignIn örneği, state machine). Ancak **Google ile giriş**
yalnızca aşağıdaki **konsol** adımları tamamlanınca çalışır. Bunlar koddan
yapılamaz.

## Kök nedenler

### 1. Google ile giriş — `PlatformException / DEVELOPER_ERROR`
- `android/app/google-services.json` içinde `"oauth_client": []` **boş**. Native
  Google Sign-In, uygulamanın imza sertifikası (SHA-1) ile kayıtlı bir **Android
  OAuth Client** olmadan `DEVELOPER_ERROR (code 10)` verir.
- Kodda hardcoded `serverClientId` proje numarası **631270363894** idi; ancak
  `google-services.json` projesi **741752662749** (`familyhub-27bf2`). Web Client
  ID, Android uygulamasıyla **aynı** projeye ait olmalıdır. Uyumsuzluk garantili
  DEVELOPER_ERROR üretir.

### 2. E-posta ile giriş — `AuthRetryableFetchException`
- Supabase URL/anonKey geçerli (`env.g.dart` dolu). Hata gerçek **geçici ağ/fetch**
  kaynaklı. Kodda retry/sınıflandırma yoktu → tek geçici hatada giriş başarısız
  görünüyordu. Artık en fazla 2 kontrollü retry (500ms / 1500ms) uygulanıyor.

## GÜNCEL: Google artık tarayıcı-tabanlı Supabase OAuth kullanıyor

`signInWithGoogle` native `google_sign_in` yerine **Supabase `signInWithOAuth`**
akışına geçirildi. Bu, **SHA-1 / Android OAuth Client kaydı GEREKTİRMEZ** ve
`google-services.json`'daki boş `oauth_client` sorununu tamamen atlar.

Çalışması için gereken **tek** yapılandırma (Supabase + Google Cloud Console):
1. **Supabase Dashboard → Authentication → Providers → Google**: etkinleştir;
   Google Cloud'dan alınan **Web** Client ID + Client Secret'ı gir.
2. **Supabase Dashboard → Authentication → URL Configuration → Redirect URLs**:
   `com.miro.familyhub://login-callback` ekle (kodla birebir aynı).
3. **Google Cloud Console → Credentials → Web OAuth Client → Authorized redirect
   URIs**: Supabase callback'i ekle:
   `https://hgzwfkhxralceriwsqzk.supabase.co/auth/v1/callback`.

AndroidManifest'teki `com.miro.familyhub://login-callback` intent-filter zaten
mevcut. Bu üç adım tamamlanınca Google girişi çalışır; SHA kaydına gerek yoktur.

---

## (Alternatif / eski) Native google_sign_in için konsol adımları

### A. SHA parmak izlerini al
```bash
# Debug (geliştirme)
keytool -list -v -alias androiddebugkey \
  -keystore ~/.android/debug.keystore -storepass android -keypass android

# Release (imzalama keystore'unuz)
keytool -list -v -alias <RELEASE_ALIAS> -keystore <release.keystore>
```
Her ikisinden de **SHA-1** ve **SHA-256** değerlerini not edin.

### B. Firebase Console → Project `familyhub-27bf2`
1. Project Settings → Your apps → Android app (`com.miro.familyhub`).
2. **Add fingerprint** ile şunları ekleyin:
   - Debug SHA-1, Debug SHA-256
   - Release SHA-1, Release SHA-256
   - (Play App Signing kullanılacaksa) Play Console → Setup → App signing →
     **App signing key certificate** SHA-1 ve SHA-256'yı da ekleyin.
3. Güncellenmiş `google-services.json`'u indirip `android/app/google-services.json`
   olarak değiştirin. Yeni dosyada artık `oauth_client` **dolu** olmalıdır
   (client_type 1 = Android, client_type 3 = Web).

### C. Google Cloud Console (aynı proje: `familyhub-27bf2` / 741752662749)
1. APIs & Services → Credentials.
2. **Web application** tipinde bir OAuth 2.0 Client ID olduğundan emin olun; yoksa
   oluşturun. Bu Client ID = kodun `serverClientId` değeri.
3. Bu Web Client ID'yi derlemeye verin:
   ```bash
   flutter build apk --release \
     --dart-define=GOOGLE_SERVER_CLIENT_ID=<WEB_CLIENT_ID>.apps.googleusercontent.com
   ```
   (Verilmezse koddaki eski varsayılan kullanılır ve DEVELOPER_ERROR sürebilir.)

### D. Supabase Dashboard → Authentication → Providers → Google
1. Google provider'ı **etkinleştirin**.
2. **Authorized Client IDs** alanına Web Client ID'yi (ve gerekiyorsa Android
   Client ID'yi) ekleyin — native `signInWithIdToken` bunu doğrular.
3. (Browser OAuth kullanılmıyor; native token akışı aktif. Yine de redirect
   şeması `com.miro.familyhub://login-callback` manifestte tanımlı.)

## SHA özet tablosu
| Değer | Nereye |
|---|---|
| Debug SHA-1 / SHA-256 | Firebase → Android app → Add fingerprint |
| Release SHA-1 / SHA-256 | Firebase → Android app → Add fingerprint |
| Play App Signing SHA-1 / SHA-256 | Firebase → Android app → Add fingerprint |
| Web Client ID | `--dart-define=GOOGLE_SERVER_CLIENT_ID` + Supabase Authorized Client IDs |

## Kalan riskler (yalnızca dış yapılandırma — koddan doğrulanamaz)
- `google-services.json` hâlâ `oauth_client: []`. B ve C adımları yapılmadan
  Google girişi DEVELOPER_ERROR verir. **E-posta girişi ve retry/hata akışı ise
  bu adımlardan bağımsız çalışır.**
- Doğru Web Client ID (proje 741752662749) bu ortamdan bilinemiyor; D adımında
  girilmeli.
