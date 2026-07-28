# Aile Zekâsı — Gemini Güvenli Geçit (family-ai)

## P0 Güvenlik Bulgusu

`lib/services/ai/ai_engine.dart:336` Gemini'yi Flutter client'tan DOĞRUDAN
çağırıyor:
```dart
'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent?key=$_geminiKey'
```
`_geminiKey = String.fromEnvironment('GEMINI_API_KEY')` (dart-define) → key
release APK'ye gömülü, tersine mühendislikle çıkarılabilir. **Bu bir sır sızıntısıdır.**

## Çözüm (hazırlandı)

`supabase/functions/family-ai/index.ts` — Gemini'yi SUNUCUDA çağıran geçit:
- JWT doğrular (`auth.getUser`), `auth.uid` çıkarır
- `family_members` ile aile üyeliği doğrular
- `GEMINI_API_KEY`'i **Supabase secret**'tan okur (client görmez)
- fast → fallback model yönlendirmesi (429 kotasında geçiş)
- structured response döner (§13); `executed_actions` gerçek repo sonucu
  olmadan ASLA doldurulmaz (sahte başarı yok, §12)

Dart tarafı: `lib/features/familyhub_ai/domain/family_ai_response.dart` +
9 test (`test/unit/family_ai_response_test.dart`) — exhaustive tip, bilinmeyen
tip crash yok, `hasCompletedAction` yalnızca `status=success && persisted=true`.

## Deploy (kullanıcı yapar — bu ortamda BLOCKED)

```bash
supabase secrets set GEMINI_API_KEY=<key>          # değeri commit ETME
supabase functions deploy family-ai
```

## Client rewiring (deploy SONRASI)

`ai_engine.dart`'ın doğrudan Gemini çağrısı, `family-ai` fonksiyonuna POST ile
değiştirilmelidir (`supabase.functions.invoke('family-ai', body: {message})`).
**Deploy edilmeden rewiring YAPILMADI** — çünkü fonksiyon canlıda yokken client'ı
ona bağlamak çalışan AI'ı bozardı. Sıra: (1) secret set, (2) deploy, (3) rewiring.

## Durum

| Parça | Durum |
|---|---|
| Edge Function scaffold (JWT + Gemini proxy) | ✅ HAZIR |
| Structured response Dart parser + testler | ✅ HAZIR (9 test) |
| Secret dokümantasyonu | ✅ (GEMINI_API_KEY Supabase secret) |
| **Deploy** | ⛔ BLOCKED — Supabase deploy CLI bu ortamda asılıyor |
| **Client rewiring** | ⏳ deploy sonrası (çalışan AI'ı bozmamak için beklendi) |
| Canlı Gemini testi | ⛔ BLOCKED — key erişimi yok |
| Tam tool registry / intent router / agentic write | ⏳ deploy+test altyapısı gerektiren çok-fazlı iş |
