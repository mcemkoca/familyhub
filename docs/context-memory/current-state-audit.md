# Context Memory — Faz 0: Mevcut Durum Denetimi

Tarih: 2026-07-18 · Dal: `feat/productization-session`

## 1. Kimlik ve kapsam çözümleme (KANITLI)

| Soru | Cevap | Kanıt |
|---|---|---|
| Kullanıcı kimliği | Supabase Auth (`auth.uid()`), `AuthService.currentUserId` | `lib/services/auth_service.dart` |
| `family_id` kaynağı | **`family_members(family_id, user_id, role)`** — `profiles`'ta `family_id` YOK (canlı şema doğrulandı) | 21 dosyada kullanılıyor |
| Çocuk profilleri | Ayrı entity: `ChildAccount` (`child_accounts`), authenticated user değil | `lib/domain/models/child_account.dart` |
| Merkezi child context | ✅ VAR: `activeChildProvider` + `resolveActiveChild` (saf, test edilmiş) | `lib/presentation/providers/child_context_provider.dart` |

> **Kritik**: Memory sistemi `family_id`'yi ASLA client payload'undan almamalı;
> `family_members` üzerinden server-side doğrulanmalı (RLS'te de bu kullanılıyor).

## 2. Depolama envanteri

**Hive box'ları (mevcut):** `tasks, transactions, chat, streaks, settings, calendar, shopping, family, moods`

- Hepsi `Box<String>` + JSON — **generic cache**, tip güvenli değil.
- **Şifreleme yok**; hassas memory için yetersiz (prompt §12 ile uyumsuz).
- `flutter_secure_storage` **mevcut** (`auth_service`, `biometric_service`, `supabase_client`) → memory encryption key için altyapı hazır.

**Supabase:** 69 migration. Chat/health/poll/legal tabloları RLS'li ve `family_members` bazlı (066-069 canlıya uygulandı).

## 3. AI katmanı

- `ai_engine.dart` — çok sağlayıcılı LLM motoru; Gemini artık **`family-ai` Edge Function** üzerinden (key sunucuda).
- **Memory kullanımı: SIFIR** (`grep memory` → 0 eşleşme). AI şu an kalıcı bağlam kullanmıyor.
- `ai_action_parser` + `ai_action_executor` mevcut: model çıktısı güvenilmez girdi olarak ayrıştırılıyor, `family_id/user_id/child_id` soyuluyor, gerçek repo sonucu olmadan başarı gösterilmiyor (`AIExecResult`).
- `family_ai_response.dart`: `hasCompletedAction` YALNIZCA `status=success && persisted=true` → prompt §3.3 kuralı **zaten uygulanmış**.

## 4. Locale / bölge (prompt §17)

- `EUR` 17 dosyada kullanılıyor ✅
- **`₺` hâlâ 5 yerde**: `country_config.dart`, `market_catalog.dart`, `app_format.dart` → locale-aware olmalı (bunlar çok-ülke config'i olabilir; körlemesine silinmemeli, incelenmeli).
- Diller: tr/nl/fr/en ARB ile ✅ · Timezone: Europe/Brussels bağlamı mevcut.

## 5. Boşluklar (Context Memory için yapılacaklar)

| Eksik | Etki | Faz |
|---|---|---|
| Tip güvenli memory modeli | Generic JSON → çelişki/dedup imkânsız | 1 ✅ |
| Şifreli memory box'ları | Hassas veri düz JSON | 2 |
| `context_memories` + RLS | Cihazlar arası senkron yok | 3 |
| Ingestion pipeline | Otomatik bilgi çıkarımı yok | 4 |
| Retrieval + context builder | AI bağlam kullanmıyor | 5 |
| Modül adapter'ları | Modüller memory event üretmiyor | 7 |
| Memory Center UI | Kullanıcı kontrolü yok (GDPR) | 8 |

## 6. Riskler

1. **Hassas veri şifresiz**: sağlık/konum/finans Hive'da düz JSON.
2. **Kullanıcı izolasyonu**: box'lar `userId` ile namespace'lenmiyor → aynı cihazda hesap değişiminde sızıntı riski (chat outbox'ta `ownerId` ile çözüldü, genel değil).
3. **Consent yok**: GDPR için memory izin modeli gerekli.
4. `₺` kalıntıları — Belçika bağlamıyla çelişebilir.
