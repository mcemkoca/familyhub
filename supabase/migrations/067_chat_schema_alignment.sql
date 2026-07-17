-- 067_chat_schema_alignment.sql
-- ============================================================================
-- KRİTİK P0: Aile Sohbeti sessizce tamamen bozuktu.
--
-- Kök neden: `messages` tablosu (001_complete_schema.sql) `text/media_urls/
-- pinned/reply_to` kolonlarına sahipti; ancak ChatRepository `content/
-- sender_name/image_url/audio_url/reply_to_id/...` kolonlarına yazıyordu.
-- Hiçbir migration bu kolonları eklemiyordu → her insert "column does not
-- exist" hatasıyla patlıyor, UI catch bloğunda mesajı local listeye ekleyip
-- kullanıcıya "gönderildi" gösteriyordu. İki aile üyesi birbirinin mesajını
-- HİÇ görmüyordu; uygulama kapanınca sohbet kayboluyordu.
--
-- Bu migration şemayı kodun gerçekten kullandığı yapıya hizalar, sender
-- spoofing açığını kapatır ve reaction/okundu için gerçek tablolar ekler.
-- Idempotent (IF NOT EXISTS / DROP ... IF EXISTS).
-- ============================================================================

-- ── 1. messages: eksik kolonları ekle ──────────────────────────────────────
-- Canlı şema migration 001'den farklı (text/type kolonları yoktu). Temel
-- kolonları da güvenceye al — hepsi IF NOT EXISTS.
alter table public.messages add column if not exists family_id uuid;
alter table public.messages add column if not exists user_id uuid;
alter table public.messages add column if not exists type text default 'text';
alter table public.messages add column if not exists content text;
alter table public.messages add column if not exists created_at timestamptz default now();
alter table public.messages add column if not exists sender_name text;
alter table public.messages add column if not exists sender_color text;
alter table public.messages add column if not exists image_url text;
alter table public.messages add column if not exists audio_url text;
alter table public.messages add column if not exists audio_duration int;
alter table public.messages add column if not exists video_url text;
alter table public.messages add column if not exists file_name text;
alter table public.messages add column if not exists file_size bigint;
alter table public.messages add column if not exists latitude double precision;
alter table public.messages add column if not exists longitude double precision;
alter table public.messages add column if not exists is_read boolean default false;
alter table public.messages add column if not exists is_pinned boolean default false;
alter table public.messages add column if not exists read_count int default 0;
alter table public.messages add column if not exists reply_to_id uuid;
alter table public.messages add column if not exists reply_to_content text;
alter table public.messages add column if not exists reply_to_sender text;
-- Offline idempotency: aynı client mesajı iki kez insert edilirse tek satır kalır.
alter table public.messages add column if not exists client_message_id text;
alter table public.messages add column if not exists edited_at timestamptz;
alter table public.messages add column if not exists deleted_at timestamptz;

-- Eski satırlarda content boşsa legacy `text` kolonundan doldur (veri kaybı yok).
-- KOŞULLU: canlı şemada `text` kolonu olmayabilir (migration 001'den farklı).
-- Kolon yoksa backfill atlanır — hata vermez.
do $$
begin
  if exists (
    select 1 from information_schema.columns
    where table_schema = 'public' and table_name = 'messages'
      and column_name = 'text'
  ) then
    execute 'update public.messages set content = text
             where content is null and text is not null';
  end if;
end $$;

-- ── 2. type CHECK kısıtını genişlet ─────────────────────────────────────────
-- Eski kısıt gif/video/file/poll/event/system değerlerini reddediyordu.
do $$
declare
  c_name text;
begin
  select con.conname into c_name
  from pg_constraint con
  join pg_class rel on rel.oid = con.conrelid
  join pg_namespace ns on ns.oid = rel.relnamespace
  where ns.nspname = 'public' and rel.relname = 'messages'
    and con.contype = 'c'
    and pg_get_constraintdef(con.oid) ilike '%type%';
  if c_name is not null then
    execute format('alter table public.messages drop constraint %I', c_name);
  end if;
end $$;

alter table public.messages
  add constraint messages_type_check
  check (type in ('text','image','audio','video','file','gif',
                  'location','event','poll','system',
                  'event_share','announcement','mood'));

-- ── 3. INSERT policy sertleştir: sender spoofing kapat ──────────────────────
-- Eski policy yalnızca family_id kontrol ediyordu; user_id başkasınınkiyle
-- doldurulabiliyordu (başka üye adına mesaj). Artık user_id = auth.uid() şart.
drop policy if exists "messages_insert" on public.messages;
drop policy if exists "messages_insert_v2" on public.messages;
drop policy if exists "Messages insert" on public.messages;
create policy "messages_insert_v3"
  on public.messages for insert to authenticated
  with check (
    user_id = auth.uid()
    and family_id in (
      select family_id from public.profiles
      where id = auth.uid() and family_id is not null
    )
  );

-- ── 4. Index'ler ────────────────────────────────────────────────────────────
create index if not exists idx_messages_family_created
  on public.messages(family_id, created_at desc);
create index if not exists idx_messages_reply_to
  on public.messages(reply_to_id);
create unique index if not exists uq_messages_client_id
  on public.messages(family_id, client_message_id)
  where client_message_id is not null;

-- ── 5. message_reactions tablosu ────────────────────────────────────────────
create table if not exists public.message_reactions (
  id uuid default gen_random_uuid() primary key,
  message_id uuid not null references public.messages(id) on delete cascade,
  family_id uuid not null references public.families(id) on delete cascade,
  user_id uuid not null references public.profiles(id) on delete cascade,
  emoji text not null,
  created_at timestamptz default now(),
  unique(message_id, user_id, emoji)
);
create index if not exists idx_reactions_message
  on public.message_reactions(message_id);

alter table public.message_reactions enable row level security;

drop policy if exists "reactions_select" on public.message_reactions;
create policy "reactions_select"
  on public.message_reactions for select to authenticated
  using (
    family_id in (select family_id from public.profiles
                  where id = auth.uid() and family_id is not null)
  );

drop policy if exists "reactions_insert" on public.message_reactions;
create policy "reactions_insert"
  on public.message_reactions for insert to authenticated
  with check (
    user_id = auth.uid()
    and family_id in (select family_id from public.profiles
                      where id = auth.uid() and family_id is not null)
  );

drop policy if exists "reactions_delete" on public.message_reactions;
create policy "reactions_delete"
  on public.message_reactions for delete to authenticated
  using (user_id = auth.uid());

-- ── 6. chat_read_states (grup sohbeti için kullanıcı-bazlı okundu) ──────────
-- Tek messages.is_read boolean grup sohbeti için yetersizdi (kimin okuduğu
-- bilinmiyordu). Conversation-level model: her üye için son okunan mesaj.
create table if not exists public.chat_read_states (
  family_id uuid not null references public.families(id) on delete cascade,
  user_id uuid not null references public.profiles(id) on delete cascade,
  last_read_message_id uuid references public.messages(id) on delete set null,
  last_read_at timestamptz default now(),
  primary key (family_id, user_id)
);

alter table public.chat_read_states enable row level security;

drop policy if exists "read_states_select" on public.chat_read_states;
create policy "read_states_select"
  on public.chat_read_states for select to authenticated
  using (
    family_id in (select family_id from public.profiles
                  where id = auth.uid() and family_id is not null)
  );

drop policy if exists "read_states_upsert" on public.chat_read_states;
create policy "read_states_upsert"
  on public.chat_read_states for insert to authenticated
  with check (user_id = auth.uid());

drop policy if exists "read_states_update" on public.chat_read_states;
create policy "read_states_update"
  on public.chat_read_states for update to authenticated
  using (user_id = auth.uid());

-- ── 6b. chat-media private bucket + aile-kapsamlı storage RLS ───────────────
-- picked.path yerine gerçek upload. Private bucket; path: chat/{familyId}/...
-- Böylece başka cihaz açabilir, başka aile erişemez (tahmin edilebilir URL yok).
insert into storage.buckets (id, name, public, file_size_limit)
values ('chat-media', 'chat-media', false, 52428800)  -- 50 MB
on conflict (id) do nothing;

drop policy if exists "chat_media_select" on storage.objects;
create policy "chat_media_select"
  on storage.objects for select to authenticated
  using (
    bucket_id = 'chat-media'
    and (storage.foldername(name))[2] in (
      select family_id::text from public.profiles
      where id = auth.uid() and family_id is not null
    )
  );

drop policy if exists "chat_media_insert" on storage.objects;
create policy "chat_media_insert"
  on storage.objects for insert to authenticated
  with check (
    bucket_id = 'chat-media'
    and (storage.foldername(name))[2] in (
      select family_id::text from public.profiles
      where id = auth.uid() and family_id is not null
    )
  );

drop policy if exists "chat_media_delete" on storage.objects;
create policy "chat_media_delete"
  on storage.objects for delete to authenticated
  using (
    bucket_id = 'chat-media'
    and (storage.foldername(name))[2] in (
      select family_id::text from public.profiles
      where id = auth.uid() and family_id is not null
    )
  );

-- ── 7. Realtime publication ─────────────────────────────────────────────────
do $$
begin
  if not exists (
    select 1 from pg_publication_tables
    where pubname = 'supabase_realtime' and tablename = 'message_reactions'
  ) then
    alter publication supabase_realtime add table public.message_reactions;
  end if;
end $$;
