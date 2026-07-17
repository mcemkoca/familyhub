# EXECUTION_STATUS — FamilyHub Üretime Hazırlık

Statü değerleri: `NOT_STARTED` · `IN_PROGRESS` · `IMPLEMENTED` · `TEST_FAILED` · `VERIFIED` · `BLOCKED_EXTERNAL`

> Kural: bir görev **yalnızca kod yazıldığı için `VERIFIED` yapılmaz**. VERIFIED = kod + test +
> analyze + (gerektiğinde) cihaz/backend doğrulaması.

## Baseline (ölçüldü)

| Kontrol | Sonuç |
|---|---|
| `flutter analyze` (lib) | 0 issue |
| `flutter test` | 295 geçti / 0 fail / 0 skip |
| Secret literal taraması (`sk-`, `AIza`, `apiKey=`) | 0 bulgu |
| `.env` git'te izleniyor mu | Hayır (iyi) |
| Hardcoded familyId/childId | 0 bulgu |
| Boş/sessiz `catch` | **78 tespit** (24 dosya) |
| TODO/FIXME/HACK | 193 (kullanıcıya görünen yok) |
| Supabase migration | 66 dosya (066 = health_records, **uygulanmadı**) |
| Ekran / route / repo / servis | 103 / 96 / 41 / 80 |

## Görev durumları

| ID | Görev | Öncelik | Statü | Not / kanıt |
|---|---|---|---|---|
| FH-01 | Migration 066 (health_records) uygulanması | P0 | `BLOCKED_EXTERNAL` | SQL idempotent (IF NOT EXISTS / DROP POLICY IF EXISTS). **Canlı Supabase proje erişimi yok** → uygulanamıyor. Kod hazır. |
| FH-02 | Object-level authorization / IDOR testi | P0 | `BLOCKED_EXTERNAL` | Statik RLS incelemesi yapıldı (messages, health_records aile-izole). **Canlı DB + 9 test hesabı gerekiyor** → çapraz-aile sorgu çalıştırılamıyor. |
| FH-03 | Sessiz catch temizliği + merkezi logger | P1 | `DONE` | **78 → 0 sessiz yutma** (boş `catch` + `onError: (_) {}`). `AppLogger` (sanitize eden, Sentry'yi genişletir) + 7 güvenlik testi. Gerçek kullanıcı hataları düzeltildi: sahte alarm başarısı, ölü medya butonu, hayalet bildirim, kayıp randevu hatırlatması, kaza anında gitmeyen acil SMS, sessizce sıfırlanan izin haritası. Best-effort olanlar gerekçeli yorumla ayrıldı. |
| FH-04 | AI intent→action→confirm→execute | P1 | `IMPLEMENTED` | Model çıktısı **güvenilmez girdi** olarak ayrıştırılıyor (`ai_action_parser`, 16 test): bilinmeyen tip reddedilir, `family_id`/`user_id`/`child_id` **soyulur**, allowlist dışı parametre düşer, harici route reddedilir. Sohbete bağlandı (`hub_ai_panel`): onay dialogu + idempotency + dürüst sonuç (`failed`/`invalid` gizlenmez). Kalan: canlı AI + cihaz doğrulaması. |
| FH-05 | Yasal Haklar günlük güncelleme job'ı | P1 | `NOT_STARTED` | Edge Function + cron **deploy erişimi yok**. İçerik şu an statik/kaynaklı — UI'da "günlük güncelleniyor" iddiası YOK (dürüst). |
| FH-06 | Sohbet typing/okundu/arama/push | P1 | `NOT_STARTED` | Realtime + RLS mevcut. Doğrulama 2 canlı oturum + backend gerektirir. |
| FH-07 | Konum granüler izin + gizlilik | P2 | `IMPLEMENTED` | Granüler durum enum'u + saf mapper (8 test). `checkPermissionStatus()` artık **yan etkisiz** (eski `checkPermission` adına rağmen dialog açıyordu). `whileInUse` ≠ arka plan takibi ayrımı görünür (`canTrackInBackground`). GPS koordinatı loglanmaz. |
| FH-08 | Merkezi child/family context yayılımı | P2 | `IMPLEMENTED` | `activeChildProvider` + kalıcı seçim; **3 ekran bağlandı** (gelişim, dashboard, çocuk-sağlık). 5 test geçiyor. Kalan ekranlar artımlı. |
| FH-09 | Release signing + build | P1 | `BLOCKED_EXTERNAL` | **Production keystore yok** — repoya key koyulamaz. Debug APK üretiliyor ve LDPlayer'a kuruluyor. |
| FH-10 | LDPlayer kapsamlı E2E | P1 | `BLOCKED_EXTERNAL` | Debug APK LDPlayer'a kuruldu (smoke). 15 senaryo E2E **canlı Supabase + 9 test hesabı + çalışan emülatör oturumu** gerektiriyor. |

## Bu oturumda VERIFIED olanlar (önceki turlardan, kanıtlı)

| İş | Kanıt |
|---|---|
| Tek AI merkezi (eski FamilyHub AI kaldırıldı) | analyze temiz, route redirect |
| Aşı takvimi bağımsız routing (`/health/vaccinations`) | 5 test |
| Hub gerçek aile streak'i (sahte `🔥 7` kaldırıldı) | 12 test |
| Sağlık Kayıtları CRUD + RLS migration | 3 test (kod); DB apply BLOCKED |
| Merkezi aktif-çocuk context | 5 test |
| Hatırlatma offline-fire fix (`NetworkType.notRequired`) | analyze + kod kanıtı |
| Makale yenileme takılması (18s timeout) | analyze |
| Günün önerisi cache fix (`weeklyList`→`dailyList`) | analyze |

## Gerçek dış blokajlar (§2.2 — tek maddelik gereksinimler)

1. **Supabase proje erişimi** (service role / DB URL) → FH-01 apply, FH-02 IDOR testleri, FH-05 Edge deploy, FH-06/FH-10 canlı doğrulama.
2. **Production keystore** (`.jks` + şifreler) → FH-09 imzalı release build.
3. **Çalışan LDPlayer oturumu + test hesapları** → FH-10 tam E2E.

Bu üçü sağlanmadan ilgili görevler dürüstçe `VERIFIED` işaretlenemez.
