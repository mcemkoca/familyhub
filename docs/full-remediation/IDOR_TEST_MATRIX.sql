-- ============================================================================
-- FH-02 — OBJECT-LEVEL AUTHORIZATION / IDOR TEST MATRİSİ
-- Supabase SQL Editor'da çalıştır. Her blok bir saldırı senaryosunu dener;
-- RLS doğruysa yetkisiz işlem 0 satır döndürür / hata verir.
--
-- ÖN KOŞUL: iki gerçek aile + kullanıcı olmalı. auth.uid() simülasyonu için
-- Supabase'de `set local role authenticated` + `request.jwt.claims` set edilir;
-- ancak en güvenilir test, iki cihazda gerçek oturumla uygulama üzerinden
-- yapılandır. Bu dosya SQL-seviyesi hızlı doğrulama içindir.
--
-- NOT: Bu testleri bu ortamdan çalıştıramadım (CLI DB erişimi asılıyor).
-- Durum: BLOCKED — kullanıcı SQL Editor'da çalıştırmalı.
-- ============================================================================

-- Hazırlık: iki aileden birer kullanıcı id'si al (elle doldur)
-- \set user_a '00000000-...-A'   (Aile 1 üyesi)
-- \set user_b '00000000-...-B'   (Aile 2 üyesi)
-- \set family_1 '...'
-- \set family_2 '...'

-- ── TEST 1: RLS aktif mi? (hepsi true olmalı) ──────────────────────────────
select relname,
       relrowsecurity as rls_aktif
from pg_class
where relnamespace = 'public'::regnamespace
  and relname in (
    'messages','message_reactions','chat_read_states','chat_polls',
    'chat_poll_votes','health_records','profiles','family_members',
    'shopping_items','budget_entries','calendar_events','geolocations'
  )
order by relname;

-- ── TEST 2: Kritik tablolarda "using(true)" / açık policy var mı? ───────────
-- Çıktıda qual='true' veya with_check='true' GÖRÜLMEMELİ (aile filtresi şart).
select tablename, policyname, cmd, qual, with_check
from pg_policies
where schemaname='public'
  and tablename in ('messages','health_records','geolocations','budget_entries',
                    'message_reactions','chat_poll_votes')
  and (qual = 'true' or with_check = 'true')
order by tablename;

-- ── TEST 3: messages INSERT policy user_id doğruluyor mu? ───────────────────
-- with_check içinde 'user_id = auth.uid()' GEÇMELİ (sender spoofing kapalı).
select policyname, with_check
from pg_policies
where schemaname='public' and tablename='messages' and cmd='INSERT';

-- ── TEST 4: health_records aile-kapsamlı mı? ────────────────────────────────
select policyname, cmd, qual
from pg_policies
where schemaname='public' and tablename='health_records'
order by cmd;

-- ── TEST 5 (uygulama seviyesi — iki cihaz): manuel doğrulama ───────────────
-- Aile A kullanıcısıyla giriş yap, Aile B'ye ait bir message_id / health_record
-- id'si ile:
--   select * from messages where id = '<AILE_B_MESAJ_ID>';        -> 0 satır
--   update messages set content='x' where id = '<AILE_B_MESAJ_ID>'; -> 0 satır
--   insert into messages(family_id,user_id,content,type)
--     values('<AILE_B>', auth.uid(), 'sızma', 'text');             -> RLS reddi
--   insert into messages(family_id,user_id,content,type)
--     values('<AILE_A>', '<BASKA_USER>', 'spoof', 'text');         -> RLS reddi
-- Hepsi engellenmelidir.

-- ── TEST 6: storage chat-media private ve aile-kapsamlı mı? ────────────────
select id, public from storage.buckets where id in ('chat-media','avatars','family-assets');
select policyname, cmd from pg_policies
where schemaname='storage' and tablename='objects'
  and policyname ilike '%chat_media%';
