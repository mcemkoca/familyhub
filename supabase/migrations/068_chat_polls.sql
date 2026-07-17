-- 068_chat_polls.sql
-- ============================================================================
-- Aile sohbeti anketleri — kalıcı oylar (spec CHAT-012).
-- Önceden anket mesajı gönderiliyordu ama oylar yalnızca yereldi.
-- Idempotent (IF NOT EXISTS / DROP POLICY IF EXISTS).
-- ============================================================================

-- ── polls: bir mesaja bağlı anket ──────────────────────────────────────────
create table if not exists public.chat_polls (
  id uuid primary key default gen_random_uuid(),
  message_id uuid not null references public.messages(id) on delete cascade,
  family_id uuid not null references public.families(id) on delete cascade,
  created_by uuid not null references public.profiles(id) on delete cascade,
  question text not null,
  options jsonb not null,          -- ["Seçenek 1","Seçenek 2",...]
  allow_multiple boolean not null default false,
  closes_at timestamptz,
  created_at timestamptz not null default now()
);
create index if not exists idx_chat_polls_message on public.chat_polls(message_id);
create index if not exists idx_chat_polls_family on public.chat_polls(family_id);

-- ── votes: kullanıcı başına oy (option_index) ──────────────────────────────
create table if not exists public.chat_poll_votes (
  poll_id uuid not null references public.chat_polls(id) on delete cascade,
  family_id uuid not null references public.families(id) on delete cascade,
  user_id uuid not null references public.profiles(id) on delete cascade,
  option_index int not null,
  created_at timestamptz not null default now(),
  primary key (poll_id, user_id, option_index)
);
create index if not exists idx_poll_votes_poll on public.chat_poll_votes(poll_id);

-- ── RLS: aile-kapsamlı ──────────────────────────────────────────────────────
alter table public.chat_polls enable row level security;
alter table public.chat_poll_votes enable row level security;

drop policy if exists "polls_select" on public.chat_polls;
create policy "polls_select" on public.chat_polls for select to authenticated
  using (family_id in (select family_id from public.profiles
                       where id = auth.uid() and family_id is not null));

drop policy if exists "polls_insert" on public.chat_polls;
create policy "polls_insert" on public.chat_polls for insert to authenticated
  with check (created_by = auth.uid()
    and family_id in (select family_id from public.profiles
                      where id = auth.uid() and family_id is not null));

drop policy if exists "poll_votes_select" on public.chat_poll_votes;
create policy "poll_votes_select" on public.chat_poll_votes for select to authenticated
  using (family_id in (select family_id from public.profiles
                       where id = auth.uid() and family_id is not null));

drop policy if exists "poll_votes_insert" on public.chat_poll_votes;
create policy "poll_votes_insert" on public.chat_poll_votes for insert to authenticated
  with check (user_id = auth.uid()
    and family_id in (select family_id from public.profiles
                      where id = auth.uid() and family_id is not null));

drop policy if exists "poll_votes_delete" on public.chat_poll_votes;
create policy "poll_votes_delete" on public.chat_poll_votes for delete to authenticated
  using (user_id = auth.uid());

-- ── Realtime ────────────────────────────────────────────────────────────────
do $$
begin
  if not exists (select 1 from pg_publication_tables
                 where pubname='supabase_realtime' and tablename='chat_poll_votes') then
    alter publication supabase_realtime add table public.chat_poll_votes;
  end if;
end $$;
