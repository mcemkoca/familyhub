-- 070_context_memories.sql
-- ============================================================================
-- Context Memory — Faz 3: kalıcı bağlam belleği + RLS.
--
-- TASARIM KURALLARI (prompt §13):
--  - Hassas içerik SUNUCUDA düz metin tutulmaz: `content_encrypted` istemcide
--    şifrelenmiş yükü taşır. `search_text` yalnızca hassas OLMAYAN kayıtlar
--    için doldurulur (arama kolaylığı ↔ gizlilik dengesi).
--  - `family_id` istemciden körlemesine kabul EDİLMEZ: RLS `family_members`
--    üzerinden doğrular (canlı şemada profiles.family_id YOKTUR).
--  - deviceLocal / session kapsamları BU TABLOYA HİÇ gönderilmez (client kuralı).
--  - Silme tombstone ile senkronize edilir → silinen kayıt geri gelmez.
-- Idempotent.
-- ============================================================================

create table if not exists public.context_memories (
  id uuid primary key default gen_random_uuid(),

  user_id uuid not null,
  family_id uuid,
  member_id uuid,
  child_id uuid,
  conversation_id uuid,

  scope text not null,
  kind text not null,
  sensitivity text not null,
  source_type text not null,
  status text not null default 'active',

  module text not null,
  memory_key text not null,
  title text,
  content_encrypted text,          -- istemcide şifreli yük (hassas kayıtlar)
  structured_data jsonb not null default '{}'::jsonb,
  search_text text,                -- yalnızca hassas OLMAYAN kayıtlarda dolu

  keywords text[] default '{}',
  related_memory_ids uuid[] default '{}',
  supersedes_memory_ids uuid[] default '{}',

  allowed_user_ids uuid[] default '{}',
  denied_user_ids uuid[] default '{}',

  confidence double precision not null default 1.0,
  importance double precision not null default 0.5,

  is_explicit boolean not null default false,
  is_confirmed boolean not null default false,
  is_pinned boolean not null default false,

  occurred_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  last_accessed_at timestamptz,
  expires_at timestamptz,
  deleted_at timestamptz,

  access_count integer not null default 0,
  schema_version integer not null default 1,
  source_id text,
  device_id text,
  sync_version bigint not null default 1,

  constraint context_memories_scope_check check (
    scope in ('userPrivate','memberPrivate','childPrivate','familyShared','module')
  ),
  constraint context_memories_status_check check (
    status in ('candidate','active','superseded','disputed','rejected','archived','expired','deleted')
  ),
  -- credential/prohibited SUNUCUYA HİÇ yazılamaz (istemci de engeller).
  constraint context_memories_sensitivity_check check (
    sensitivity in ('normal','private','confidential','financial','health',
                    'minorData','preciseLocation','legal')
  )
);

-- ── Index'ler ───────────────────────────────────────────────────────────────
create index if not exists idx_ctx_mem_user      on public.context_memories(user_id, updated_at desc);
create index if not exists idx_ctx_mem_family    on public.context_memories(family_id) where family_id is not null;
create index if not exists idx_ctx_mem_module    on public.context_memories(module, memory_key);
create index if not exists idx_ctx_mem_child     on public.context_memories(child_id) where child_id is not null;
create index if not exists idx_ctx_mem_active    on public.context_memories(user_id, status) where status = 'active';
create index if not exists idx_ctx_mem_expires   on public.context_memories(expires_at) where expires_at is not null;
-- Aynı özne için aynı kanonik anahtar tek aktif kayıt (dedup, prompt §7).
create unique index if not exists uq_ctx_mem_active_key
  on public.context_memories(user_id, module, memory_key, coalesce(child_id, member_id, user_id))
  where status = 'active' and deleted_at is null;

-- ── Tombstone: silinen kayıt senkron sonrası GERİ GELMEZ (prompt §8) ────────
create table if not exists public.context_memory_tombstones (
  memory_id uuid primary key,
  user_id uuid not null,
  family_id uuid,
  deleted_at timestamptz not null default now(),
  reason text
);
create index if not exists idx_ctx_tomb_user on public.context_memory_tombstones(user_id, deleted_at desc);

-- ── Consent: GDPR izin kaydı (versiyonlu) ──────────────────────────────────
create table if not exists public.context_memory_consents (
  user_id uuid primary key,
  family_id uuid,
  policy_version text not null default 'v1',
  memory_enabled boolean not null default true,
  conversation_extraction_enabled boolean not null default true,
  family_shared_memory_enabled boolean not null default true,
  sensitive_memory_enabled boolean not null default false,  -- VARSAYILAN KAPALI
  cloud_sync_enabled boolean not null default true,
  enabled_modules text[] default '{}',
  accepted_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- ── RLS ─────────────────────────────────────────────────────────────────────
alter table public.context_memories enable row level security;
alter table public.context_memory_tombstones enable row level security;
alter table public.context_memory_consents enable row level security;

-- SELECT: kendi kaydı VEYA (familyShared/module ve aile üyesi) VEYA açıkça izinli.
-- Başka yetişkinin userPrivate kaydı GÖRÜNMEZ (prompt §10.2).
drop policy if exists "ctx_mem_select" on public.context_memories;
create policy "ctx_mem_select" on public.context_memories
  for select to authenticated
  using (
    not (auth.uid() = any(denied_user_ids))
    and (
      user_id = auth.uid()
      or auth.uid() = any(allowed_user_ids)
      or (
        scope in ('familyShared','module')
        and family_id in (
          select family_id from public.family_members where user_id = auth.uid()
        )
      )
      or (
        -- Çocuk kaydını aynı ailedeki ebeveyn/admin görebilir.
        scope = 'childPrivate'
        and family_id in (
          select family_id from public.family_members
          where user_id = auth.uid() and role in ('parent','admin','owner')
        )
      )
    )
  );

-- INSERT: yalnızca kendi adına; family_id üyelikten doğrulanır (spoofing yok).
drop policy if exists "ctx_mem_insert" on public.context_memories;
create policy "ctx_mem_insert" on public.context_memories
  for insert to authenticated
  with check (
    user_id = auth.uid()
    and (
      family_id is null
      or family_id in (
        select family_id from public.family_members where user_id = auth.uid()
      )
    )
  );

-- UPDATE/DELETE: yalnızca kendi kaydı.
drop policy if exists "ctx_mem_update" on public.context_memories;
create policy "ctx_mem_update" on public.context_memories
  for update to authenticated using (user_id = auth.uid());

drop policy if exists "ctx_mem_delete" on public.context_memories;
create policy "ctx_mem_delete" on public.context_memories
  for delete to authenticated using (user_id = auth.uid());

-- Tombstones: kendi silme kayıtları.
drop policy if exists "ctx_tomb_select" on public.context_memory_tombstones;
create policy "ctx_tomb_select" on public.context_memory_tombstones
  for select to authenticated using (user_id = auth.uid());

drop policy if exists "ctx_tomb_insert" on public.context_memory_tombstones;
create policy "ctx_tomb_insert" on public.context_memory_tombstones
  for insert to authenticated with check (user_id = auth.uid());

-- Consent: yalnızca kendi izinleri.
drop policy if exists "ctx_consent_select" on public.context_memory_consents;
create policy "ctx_consent_select" on public.context_memory_consents
  for select to authenticated using (user_id = auth.uid());

drop policy if exists "ctx_consent_upsert" on public.context_memory_consents;
create policy "ctx_consent_upsert" on public.context_memory_consents
  for insert to authenticated with check (user_id = auth.uid());

drop policy if exists "ctx_consent_update" on public.context_memory_consents;
create policy "ctx_consent_update" on public.context_memory_consents
  for update to authenticated using (user_id = auth.uid());

-- ── Hesap silinince tüm memory temizlenir (GDPR) ───────────────────────────
create or replace function public.purge_context_memory(target_user uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if target_user <> auth.uid() then
    raise exception 'not_authorized';
  end if;
  delete from public.context_memories where user_id = target_user;
  delete from public.context_memory_tombstones where user_id = target_user;
  delete from public.context_memory_consents where user_id = target_user;
end $$;
