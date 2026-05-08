# 🔒 Security

## Güvenlik Özellikleri

### 🔐 Secret Yönetimi

| Yöntem | Kullanım | Güvenlik Seviyesi |
|--------|----------|-------------------|
| `envied` | Compile-time obfuscation | 🔴 Yüksek |
| `flutter_secure_storage` | Runtime token storage | 🔴 Yüksek |
| `String.fromEnvironment` | Build-time injection | 🟡 Orta |
| `--dart-define` | CI/CD secret injection | 🟡 Orta |

### 🛡️ Veritabanı Güvenliği (RLS)

Tüm tablolarda **Row Level Security (RLS)** aktiftir.

```sql
-- Örnek: Kullanıcı sadece kendi profilini görebilir
create policy "Users can view own profile"
  on public.profiles for select
  using (auth.uid() = id);

-- Örnek: Aile üyeleri birbirini görebilir
create policy "Family members can view profiles"
  on public.profiles for select
  using (
    exists (
      select 1 from family_members
      where family_members.user_id = auth.uid()
        and family_members.family_id in (
          select family_id from family_members where user_id = profiles.id
        )
    )
  );
```

### 🔑 Kimlik Doğrulama

| Yöntem | Açıklama |
|--------|----------|
| **Email/Password** | JWT-based auth, auto-refresh |
| **Google Sign-In** | OAuth 2.0 via Firebase |
| **Apple Sign-In** | OAuth 2.0 (iOS required) |
| **Biometric** | Fingerprint / Face ID |
| **Child PIN** | SHA-256 hashed, server-side verification |

### 🌐 Ağ Güvenliği

- **TLS 1.2+** zorunlu
- **Certificate pinning** kritik endpoint'ler için
- **No HTTP fallback**
- **API key URL query param yerine header'da** gönderilir

### 📱 Cihaz Güvenliği

```dart
// Root/Jailbreak detection
if (await SecurityService.isDeviceCompromised()) {
  showDeviceCompromisedDialog();
  return;
}

// Screenshot prevention (sensitive screens)
SystemChrome.setEnabledSystemUIMode(
  SystemUiMode.manual,
  overlays: [SystemUiOverlay.top],
);
```

## Güvenlik Kontrol Listesi

### Geliştirme Aşaması

- [ ] `.env` dosyası `.gitignore`'da
- [ ] `*.g.dart` generated dosyaları `.gitignore`'da
- [ ] Hardcoded secret yok (`grep -r "sk-" lib/`)
- [ ] `print()` ile sensitive data loglanmıyor
- [ ] RLS policy'leri her yeni tablo için yazılıyor
- [ ] Input validation tüm form'larda
- [ ] File upload path traversal korumalı

### Release Aşaması

- [ ] `isMinifyEnabled = true`
- [ ] `isShrinkResources = true`
- [ ] `--obfuscate --split-debug-info`
- [ ] Release signing keystore korunmalı
- [ ] ProGuard/R8 rules test edilmiş
- [ ] SSL pinning aktif

## Sızıntı Taraması

```bash
# Hardcoded API key ara
rg -i "(api[_-]?key|secret|token|password)\s*[:=]\s*[\"']" lib/

# print() ile sensitive data
rg -r "print\(.*(password|token|secret|email)" lib/

# HTTP kullanımı
rg -r "http://" lib/

# .env dosyası tracking durumu
git ls-files | grep -E "\.env|google-services\.json"
```

## Incident Response

1. **Tespit**: Sentry / Crashlytics alert'leri izle
2. **İzolasyon**: Etkilenen kullanıcıları force logout yap
3. **Analiz**: Log'ları incele, RLS bypass kontrolü yap
4. **Düzeltme**: Patch deploy et
5. **Bildirim**: Etkilenen kullanıcılara bilgi ver
6. **Post-mortem**: Root cause analizi yap, süreci iyileştir

---

*Detaylı güvenlik politikası için [SECURITY.md](https://github.com/mcemkoca/familyhub/blob/main/SECURITY.md) dosyasına bakın.*
