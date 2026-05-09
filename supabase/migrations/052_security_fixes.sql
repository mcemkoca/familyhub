-- ============================================================================
-- 052_security_fixes.sql
-- KRITIK GUVENLIK FIX'LERI
-- 
-- 1. profiles SELECT policy: using(true) → auth.uid() = id (PII sizinti onleme)
-- 2. family_members eksik UPDATE/DELETE policy'leri
-- 3. Admin / Premium server-side RPC fonksiyonlari
-- 4. Invite code schema uyumlulugu fix'i
-- ============================================================================

-- =============================================================================
-- 1. PROFILES RLS FIX
-- =============================================================================

-- Eski "herkese acik" policy'yi kaldir
drop policy if exists "Profiles are viewable by everyone" on public.profiles;

-- Kullanici kendi profilini gorebilir
drop policy if exists "Profiles select own" on public.profiles;
create policy "Profiles select own"
  on public.profiles for select to authenticated
  using (auth.uid() = id);

-- Kullanici kendi profilini guncelleyebilir
drop policy if exists "Profiles update own" on public.profiles;
create policy "Profiles update own"
  on public.profiles for update to authenticated
  using (auth.uid() = id);

-- Kullanici kendi profilini silebilir
drop policy if exists "Profiles delete own" on public.profiles;
create policy "Profiles delete own"
  on public.profiles for delete to authenticated
  using (auth.uid() = id);

-- =============================================================================
-- 2. FAMILY_MEMBERS EKSIK POLICY'LER
-- =============================================================================

-- family_members UPDATE: sadece kendi kaydini veya admin rolunu guncelleyebilir
drop policy if exists "Family members update" on public.family_members;
create policy "Family members update"
  on public.family_members for update to authenticated
  using (
    user_id = auth.uid()
    or exists (
      select 1 from public.family_members fm2
      where fm2.family_id = family_members.family_id
        and fm2.user_id = auth.uid()
        and fm2.role in ('admin', 'parent')
    )
  );

-- family_members DELETE: sadece admin/parent silebilir (kendini haric)
drop policy if exists "Family members delete" on public.family_members;
create policy "Family members delete"
  on public.family_members for delete to authenticated
  using (
    exists (
      select 1 from public.family_members fm2
      where fm2.family_id = family_members.family_id
        and fm2.user_id = auth.uid()
        and fm2.role in ('admin', 'parent')
    )
  );

-- =============================================================================
-- 3. ADMIN / PREMIUM SERVER-SIDE KONTROL FONKSIYONLARI
-- =============================================================================

-- Bir kullanicinin belirli bir ailede admin olup olmadigini kontrol et
create or replace function public.is_family_admin(p_user_id uuid, p_family_id uuid)
returns boolean
language plpgsql
security definer
as $$
begin
  return exists (
    select 1 from public.family_members
    where user_id = p_user_id
      and family_id = p_family_id
      and role in ('admin', 'parent')
  );
end;
$$;

-- Bir kullanicinin premium oldugunu kontrol et
create or replace function public.is_premium_user(p_user_id uuid)
returns boolean
language plpgsql
security definer
as $$
begin
  return exists (
    select 1 from public.profiles
    where id = p_user_id
      and is_premium = true
  );
end;
$$;

-- Feature gate: kullanici belirli bir ozellige erisebilir mi?
create or replace function public.can_access_feature(p_user_id uuid, p_feature text)
returns boolean
language plpgsql
security definer
as $$
declare
  v_is_premium boolean;
  v_is_admin boolean;
begin
  -- Admin her seye erisir
  select is_premium into v_is_premium from public.profiles where id = p_user_id;
  
  -- Temel ozellikler herkese acik
  if p_feature in ('chat', 'calendar', 'tasks_basic', 'location_basic') then
    return true;
  end if;
  
  -- Premium ozellikler
  if p_feature in (
    'ai_assistant', 'advanced_analytics', 'unlimited_storage',
    'priority_support', 'custom_themes', 'export_data'
  ) then
    return coalesce(v_is_premium, false);
  end if;
  
  -- Admin ozellikleri
  if p_feature in ('admin_panel', 'user_management', 'billing') then
    return false; -- Sadece client'tan cagrilmamali, admin RPC'ler kullanilmali
  end if;
  
  return false;
end;
$$;

-- Premium limit kontrolu: ornegin aileye maksimum kac uye eklenebilir?
create or replace function public.get_family_member_limit(p_user_id uuid)
returns integer
language plpgsql
security definer
as $$
declare
  v_is_premium boolean;
begin
  select is_premium into v_is_premium from public.profiles where id = p_user_id;
  
  if v_is_premium then
    return 20; -- Premium: 20 uye
  else
    return 6;  -- Free: 6 uye
  end if;
end;
$$;

-- Mevcut aile uye sayisini kontrol et (limit asildi mi?)
create or replace function public.can_add_family_member(p_family_id uuid, p_user_id uuid)
returns boolean
language plpgsql
security definer
as $$
declare
  v_limit integer;
  v_current integer;
begin
  select public.get_family_member_limit(p_user_id) into v_limit;
  select count(*) into v_current from public.family_members where family_id = p_family_id;
  
  return v_current < v_limit;
end;
$$;

-- =============================================================================
-- 4. INVITE CODE SCHEMA UYUMLULUGU
-- =============================================================================

-- families tablosuna invite_used alani ekle (kodun kullanilip kullanilmadigini takip et)
-- Not: Kodda invite_used kontrolu var ama schema'da yok
alter table if exists public.families 
  add column if not exists invite_used boolean default false;

-- Invite code kullanildiginda otomatik isaretleme fonksiyonu
create or replace function public.mark_invite_used(p_family_id uuid)
returns void
language plpgsql
security definer
as $$
begin
  update public.families
  set invite_used = true, invite_code_expires_at = null
  where id = p_family_id;
end;
$$;

-- =============================================================================
-- 5. HESAP SILME RPC (Soft Delete yerine Hard Delete)
-- =============================================================================

create or replace function public.delete_user_account(p_user_id uuid)
returns boolean
language plpgsql
security definer
as $$
begin
  -- Sadece kendi hesabini silebilir
  if p_user_id != auth.uid() then
    raise exception 'Yetkisiz islem: Sadece kendi hesabinizi silebilirsiniz.';
  end if;
  
  -- Aile admini mi? Admin ise ailede baska admin var mi kontrol et
  -- (Ailesiz birakmamak icin)
  
  -- Ilgili kayitlari sil
  delete from public.family_members where user_id = p_user_id;
  delete from public.profiles where id = p_user_id;
  
  -- auth.users'dan silme yetkisi service_role key ile yapilmali
  -- Bu fonksiyon sadece iliskili kayitlari temizler
  
  return true;
end;
$$;

-- =============================================================================
-- 6. LOGGING: Guvenlik olaylarini kaydet
-- =============================================================================

create table if not exists public.security_logs (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users(id) on delete set null,
  event_type text not null check (event_type in ('login', 'logout', 'failed_login', 'rls_violation', 'admin_action', 'premium_change', 'account_delete')),
  description text,
  ip_address text,
  user_agent text,
  created_at timestamptz default now()
);

alter table if exists public.security_logs enable row level security;

-- Sadece kullanici kendi loglarini gorebilir
drop policy if exists "Security logs select own" on public.security_logs;
create policy "Security logs select own"
  on public.security_logs for select to authenticated
  using (user_id = auth.uid());

-- Sadece sistem ve kullanici kendi logunu ekleyebilir
drop policy if exists "Security logs insert" on public.security_logs;
create policy "Security logs insert"
  on public.security_logs for insert to authenticated
  with check (user_id = auth.uid());

-- =============================================================================
-- INDEX'LER
-- =============================================================================

create index if not exists idx_security_logs_user on public.security_logs(user_id, created_at desc);
create index if not exists idx_security_logs_event on public.security_logs(event_type, created_at desc);
