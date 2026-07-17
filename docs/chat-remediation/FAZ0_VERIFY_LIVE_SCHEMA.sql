-- ============================================================================
-- FAZ 0 — CANLI STAGING ŞEMA DOĞRULAMA
-- Supabase Dashboard → SQL Editor'a yapıştır, çalıştır, çıktıyı paylaş.
--
-- AMAÇ: "sohbet bozuk" sonucumu migration dosyalarından çıkardım. Bu, kod
-- (ChatRepository `content` yazıyor) + migration (hiçbiri `content` eklemiyor)
-- kanıtına dayalı GÜÇLÜ bir hipotez; ancak biri dashboard'dan elle kolon
-- eklemiş olabilir. Aşağıdaki sorgular gerçek durumu kanıtlar.
-- ============================================================================

-- 1) messages tablosunun GERÇEK kolonları
--    Beklenen kritik kontrol: 'content' kolonu VAR MI?
--    Yoksa → sohbet gerçekten bozuktu, migration 067 ŞART.
--    Varsa → biri elle eklemiş; yine de 067 idempotenttir, güvenle uygulanır.
select column_name, data_type, is_nullable
from information_schema.columns
where table_schema = 'public' and table_name = 'messages'
order by ordinal_position;

-- 2) 067 sonrası olması gereken kritik kolonların varlığı (tek satır özet)
select
  bool_or(column_name = 'content')          as has_content,
  bool_or(column_name = 'sender_name')      as has_sender_name,
  bool_or(column_name = 'image_url')        as has_image_url,
  bool_or(column_name = 'is_pinned')        as has_is_pinned,
  bool_or(column_name = 'reply_to_id')      as has_reply_to_id,
  bool_or(column_name = 'client_message_id') as has_client_msg_id
from information_schema.columns
where table_schema = 'public' and table_name = 'messages';

-- 3) RLS aktif mi + policy'ler (özellikle INSERT'in user_id kontrolü)
select relrowsecurity as messages_rls_aktif
from pg_class where relname = 'messages' and relnamespace = 'public'::regnamespace;

select policyname, cmd, with_check
from pg_policies
where schemaname = 'public' and tablename = 'messages'
order by cmd, policyname;

-- 4) 067'nin eklediği tablolar var mı?
select
  (select count(*) from pg_tables where schemaname='public' and tablename='message_reactions') as reactions_tbl,
  (select count(*) from pg_tables where schemaname='public' and tablename='chat_read_states')  as read_states_tbl;

-- 5) chat-media bucket var mı ve private mı?
select id, public from storage.buckets where id = 'chat-media';

-- 6) type CHECK kısıtı gif/video/file/poll içeriyor mu?
select con.conname, pg_get_constraintdef(con.oid) as def
from pg_constraint con
join pg_class rel on rel.oid = con.conrelid
where rel.relname = 'messages' and con.contype = 'c'
  and pg_get_constraintdef(con.oid) ilike '%type%';

-- 7) Mevcut mesaj metadata'sı (içerik DÖKMEDEN — gizlilik)
select count(*) as mesaj_sayisi,
       min(created_at) as ilk, max(created_at) as son
from public.messages;

select type, count(*) from public.messages group by type order by count(*) desc;
