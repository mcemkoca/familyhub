# Aile Sohbeti — Denetim ve Düzeltme Raporu

Tarih: 2026-07-17 · Dal: `Deuterium12/vibrant-feynman-c113df`

## Yönetici özeti

**Başlangıç durumu: NOT_READY — sohbet sessizce tamamen bozuktu.**

Kök neden: `messages` tablosu şeması ([001_complete_schema.sql:136](../../supabase/migrations/001_complete_schema.sql))
`text/media_urls/pinned/reply_to` kolonlarına sahipti; ancak `ChatRepository`
`content/sender_name/image_url/audio_url/reply_to_id/...` kolonlarına yazıyordu.
66 migration'ın hiçbiri bu kolonları eklemiyordu → her `sendMessage` insert'i
`column "content" does not exist` ile patlıyor, UI catch bloğu mesajı **local
listeye** ekleyip kullanıcıya "gönderildi" gösteriyordu. Sonuç: iki aile üyesi
birbirinin mesajını **hiç görmüyordu**, uygulama kapanınca sohbet siliniyordu.

## Bulgular ve çözümler

| ID | Bulgu | Kanıt | Çözüm | Sonuç |
|----|-------|-------|-------|-------|
| CHAT-000 | Şema/kod kolon uyuşmazlığı → tüm mesajlar patlıyor | repo insert vs 001 şeması | migration 067 kolon hizalama | DÜZELTİLDİ (uygulama bekliyor) |
| CHAT-001 | Backend hatasında sahte "gönderildi" local fallback | chat_screen.dart eski 109-126 | fallback kaldırıldı, hata+retry | DÜZELTİLDİ |
| CHAT-002 | `isMe = senderId == 'm1'` → tüm mesajlar yanlış tarafta | 793, 936, bubble 132 | `AuthService.currentUserId` | DÜZELTİLDİ + test |
| CHAT-002b | 11 yerde `senderId:'m1'`, `senderName:'Ben'`, `msg${len+1}` | 507/537/644... | gerçek session + backend | DÜZELTİLDİ |
| CHAT-003 | Reaction local-only, sabit 'm1' | eski _addReaction | `message_reactions` tablosu + toggle | DÜZELTİLDİ |
| CHAT-004 | Pin local-only | eski _pinMessage | `setPinned` (tek aktif pin) backend | DÜZELTİLDİ |
| CHAT-005/6/7 | `picked.path` medya URL'si (yalnız gönderen cihaz) | 203/224/287/315 | `ChatStorageService` → private bucket → imzalı URL | DÜZELTİLDİ |
| CHAT-008 | GIF local-only | eski _sendGif | uzak URL gerçek mesaj olarak insert | DÜZELTİLDİ |
| CHAT-009 | Konum local-only | eski _shareLocation | gerçek GPS + backend insert | DÜZELTİLDİ |
| CHAT-010 | Dosya `picked.path` local | eski _pickFile | storage upload + boyut limiti | DÜZELTİLDİ |
| CHAT-013 | "Mesajlarda Ara" sadece `Navigator.pop` | eski menü 953 | gerçek `SearchDelegate` | DÜZELTİLDİ |
| CHAT-014 | "Bildirim Ayarları" ölü | eski menü 957 | route'a bağlandı | DÜZELTİLDİ |
| CHAT-015 | "Arşivle" ölü | eski menü 961 | dürüstçe kaldırıldı (backend gerekli) | KALDIRILDI |
| CHAT-016 | "Temizle" ölü/tehlikeli | eski menü 965 | güvenli "bu cihazdan" modeli | DÜZELTİLDİ |
| CHAT-SEC | INSERT policy `user_id` doğrulamıyordu (spoofing) | 040/044 | 067 `user_id=auth.uid()` | DÜZELTİLDİ |
| CHAT-READ | Tek `is_read` boolean grup için yetersiz | model | `chat_read_states` (kullanıcı-bazlı) | ALTYAPI HAZIR |
| CHAT-TEST | Modülün hiç testi yok | test/ | chat_message_test (7 test) | DÜZELTİLDİ |

## Yanlış-pozitif (bilinçli raporlanmadı)

- `onTap: () {}` (modal içi, satır ~1096): modal sheet'e dokunmayı yutan
  standart pattern — ölü buton değil. Dokunulmadı.

## Migration 067 — uygulanması gereken

`supabase/migrations/067_chat_schema_alignment.sql` idempotenttir. Uygula:
Supabase SQL Editor'a dosyayı yapıştır → çalıştır. Doğrulama:
```sql
select relrowsecurity from pg_class where relname='messages';           -- true
select count(*) from information_schema.columns
  where table_name='messages' and column_name='content';                -- 1
select count(*) from pg_tables where tablename='message_reactions';     -- 1
select id from storage.buckets where id='chat-media';                   -- chat-media
```

## Henüz tam olmayan (dürüst durum)

- **Typing / Presence**: yok. (Realtime Broadcast gerekir — sonraki iş.)
- **Read receipt UI**: `chat_read_states` tablosu + `markRead` var; ekran
  entegrasyonu (kimin okuduğu göstergesi) bağlanmadı.
- **Anket oyları**: anket mesajı gerçek gider ama oylar kalıcı değil
  (poll_options/poll_votes tabloları yok). Kod bunu yorumla belirtir.
- **Push/deep link**: `053_fcm_push_trigger` mevcut; sohbet için uçtan uca
  doğrulanmadı.
- **Offline pending kuyruğu**: `client_message_id` idempotency altyapısı hazır;
  kuyruk/otomatik retry UI bağlanmadı (şu an manuel retry snackbar var).

## Karar

**READY_WITH_EXTERNAL_REQUIREMENTS** (metin + medya çekirdeği için).

- Kod tarafı: `flutter analyze lib/` temiz, 332 test geçiyor.
- Dış gereksinim: (1) migration 067 canlı DB'ye uygulanmalı, (2) iki cihaz +
  test hesaplarıyla E2E doğrulama (elimde çalışan emülatör/hesap yok).
- Migration uygulanana kadar sohbet çalışmaya başlamaz — bu **bloklayıcı** ve
  yalnızca kullanıcı tarafından (SQL Editor) yapılabilir.
