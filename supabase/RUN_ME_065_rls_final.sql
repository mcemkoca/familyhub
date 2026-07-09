-- ============================================================================
-- 065 — family_members / families RLS SONSUZ ÖZYİNELEME KESİN ÇÖZÜM
-- ----------------------------------------------------------------------------
-- SORUN: Cihaz logcat'inde HÂLÂ:
--   "infinite recursion detected in policy for relation family_members" (42P17)
-- NEDEN: 037–063 arası migration'lar family_members ve families üzerinde çok
--   sayıda politika bıraktı (family_members_select, _v2, _by_family,
--   viewable_by_self...). 063 yalnızca 3 isim varyantını DROP ediyor; DB'de
--   kalan ESKİ, kendine-referanslı politikalar özyinelemeyi sürdürüyor.
-- ÇÖZÜM: Bu tabloların TÜM politikalarını dinamik olarak sil, RLS'i baypas eden
--   SECURITY DEFINER fonksiyonla temiz (özyinelemesiz) politikalar kur.
--
-- Supabase Dashboard → SQL Editor'e yapıştır → RUN. İdempotent, tekrar
-- çalıştırılabilir.
-- ============================================================================

-- 1) RLS'i baypas ederek kullanıcının aile id'lerini döndüren yardımcı.
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

-- 2) family_members üzerindeki TÜM politikaları kaldır (isim ne olursa olsun).
do $$
declare r record;
begin
  for r in
    select policyname from pg_policies
    where schemaname = 'public' and tablename = 'family_members'
  loop
    execute format('drop policy if exists %I on public.family_members', r.policyname);
  end loop;
end $$;

-- 3) families üzerindeki TÜM politikaları kaldır (döngüyü besleyenler dahil).
do $$
declare r record;
begin
  for r in
    select policyname from pg_policies
    where schemaname = 'public' and tablename = 'families'
  loop
    execute format('drop policy if exists %I on public.families', r.policyname);
  end loop;
end $$;

-- 4) family_members — TEMİZ, özyinelemesiz politikalar.
alter table public.family_members enable row level security;

create policy "fm_select_self"
  on public.family_members for select to authenticated
  using (user_id = auth.uid());

create policy "fm_select_family"
  on public.family_members for select to authenticated
  using (family_id in (select public.my_family_ids()));

create policy "fm_insert"
  on public.family_members for insert to authenticated
  with check (
    user_id = auth.uid()
    or family_id in (select public.my_family_ids())
  );

create policy "fm_update"
  on public.family_members for update to authenticated
  using (family_id in (select public.my_family_ids()));

create policy "fm_delete"
  on public.family_members for delete to authenticated
  using (family_id in (select public.my_family_ids()));

-- 5) families — TEMİZ politikalar (my_family_ids ile, family_members'a bakmaz).
alter table public.families enable row level security;

create policy "fam_select"
  on public.families for select to authenticated
  using (
    created_by = auth.uid()
    or id in (select public.my_family_ids())
  );

create policy "fam_insert"
  on public.families for insert to authenticated
  with check (created_by = auth.uid());

create policy "fam_update"
  on public.families for update to authenticated
  using (
    created_by = auth.uid()
    or id in (select public.my_family_ids())
  );

-- 6) Doğrulama (opsiyonel — SQL Editor'de çalıştırıp kontrol edebilirsin):
--   select public.my_family_ids();
--   select * from public.family_members where family_id in (select public.my_family_ids());
--   select * from public.families where id in (select public.my_family_ids());
-- Artık "infinite recursion" hatası GELMEMELİ.
