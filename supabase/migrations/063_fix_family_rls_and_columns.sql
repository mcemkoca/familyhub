-- ============================================================================
-- 063 — family_members RLS sonsuz özyineleme kesin düzeltmesi + eksik kolonlar
-- ----------------------------------------------------------------------------
-- SORUN: family_members SELECT politikası, alt sorguda yine family_members'a
--        baktığı için Postgres RLS'i sonsuz özyinelemeye giriyordu
--        ("infinite recursion detected in policy for relation family_members").
--        047 bunu düzeltmeye çalıştı ama yine kendine-referanslı kaldı.
-- ÇÖZÜM: RLS'i baypas eden SECURITY DEFINER yardımcı fonksiyon.
-- ============================================================================

-- 1) Eksik profил kolonları (uygulama fcm_token güncellemesi için gerekli).
alter table public.profiles add column if not exists cover_photo_url text;
alter table public.profiles add column if not exists fcm_token text;
alter table public.profiles add column if not exists fcm_token_updated_at timestamptz;

-- 2) Kullanıcının ait olduğu family_id'leri RLS'siz döndüren yardımcı fonksiyon.
create or replace function public.my_family_ids()
returns setof uuid
language sql
security definer
stable
set search_path = public
as $$
  select family_id
  from public.family_members
  where user_id = auth.uid()
$$;

grant execute on function public.my_family_ids() to authenticated;

-- 3) family_members üzerindeki özyinelemeli SELECT politikalarını kaldır.
drop policy if exists "family_members_select_by_family" on public.family_members;
drop policy if exists "family_members_select_self" on public.family_members;
drop policy if exists "family_members_select_family" on public.family_members;

-- 4) Temiz politikalar: kullanıcı kendi satırını + aynı ailedeki satırları görür.
--    Aile kontrolü SECURITY DEFINER fonksiyondan gelir → özyineleme yok.
create policy "family_members_select_self"
  on public.family_members for select to authenticated
  using (user_id = auth.uid());

create policy "family_members_select_family"
  on public.family_members for select to authenticated
  using (family_id in (select public.my_family_ids()));

-- 5) INSERT/UPDATE/DELETE için de özyinelemesiz politikalar (varsa değiştir).
drop policy if exists "family_members_insert" on public.family_members;
create policy "family_members_insert"
  on public.family_members for insert to authenticated
  with check (
    user_id = auth.uid()
    or family_id in (select public.my_family_ids())
  );

drop policy if exists "family_members_update" on public.family_members;
create policy "family_members_update"
  on public.family_members for update to authenticated
  using (family_id in (select public.my_family_ids()));

-- Doğrulama:
--   select public.my_family_ids();
--   select display_name, role from public.family_members
--     where family_id in (select public.my_family_ids());
