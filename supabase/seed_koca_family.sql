-- ============================================================================
-- Koca Ailesi — çok cihazlı GERÇEK veri seed'i (İSTEĞE BAĞLI)
-- ----------------------------------------------------------------------------
-- Uygulama, aile adını ve üyeleri yerel olarak (Hive) zaten kurar (KocaSeed).
-- Bu betik, verileri Supabase'e de yazmak isteyenler içindir; böylece üyeler
-- tüm cihazlarda ve gerçek family_members tablosunda görünür.
--
-- KULLANIM (Supabase SQL Editor):
--   1) Aşağıdaki :FAMILY_ID ve :MUSTAFA_USER_ID değerlerini kendi
--      değerlerinizle değiştirin (aşağıdaki yardımcı sorgularla bulabilirsiniz).
--   2) Betiği çalıştırın.
--
-- Yardımcı sorgular (önce bunları çalıştırıp değerleri öğrenin):
--   select id, email, display_name from public.profiles order by created_at;
--   select id, family_id, user_id, display_name, role from public.family_members;
-- ============================================================================

-- 1) Hesap sahibinin profil adını "Mustafa Koca" yap (email'e göre).
update public.profiles
set display_name = 'Mustafa Koca',
    date_of_birth = date '1986-01-01'   -- ~40 yaş
where email = 'mcemkoca0@gmail.com';

-- 2) Mustafa'yı ailede 'parent' rolüne getir (mevcut üyeyse).
update public.family_members fm
set role = 'parent', display_name = 'Mustafa Koca', color = '#3B82F6'
from public.profiles p
where p.email = 'mcemkoca0@gmail.com' and fm.user_id = p.id;

-- 3) Anne "Hilal Şahbaz" — profili yoksa placeholder profil + aile üyesi ekle.
--    (Hilal gerçek hesap açtığında davet koduyla katılması önerilir; bu satır
--     yalnızca görüntüleme amaçlı bir üye kaydı oluşturur.)
-- :FAMILY_ID değerini Mustafa'nın family_id'siyle değiştirin.
insert into public.family_members (family_id, display_name, role, color, is_active)
select fm.family_id, 'Hilal Şahbaz', 'parent', '#EC4899', true
from public.family_members fm
join public.profiles p on p.id = fm.user_id
where p.email = 'mcemkoca0@gmail.com'
  and not exists (
    select 1 from public.family_members x
    where x.family_id = fm.family_id and x.display_name = 'Hilal Şahbaz'
  );

-- 4) Çocuk "Mirac Koca" (6 yaş) — aile üyesi kaydı (yoksa).
insert into public.family_members (family_id, display_name, role, color, is_active)
select fm.family_id, 'Mirac Koca', 'child', '#10B981', true
from public.family_members fm
join public.profiles p on p.id = fm.user_id
where p.email = 'mcemkoca0@gmail.com'
  and not exists (
    select 1 from public.family_members x
    where x.family_id = fm.family_id and x.display_name = 'Mirac Koca'
  );

-- Doğrulama:
--   select display_name, role from public.family_members
--   where family_id = (select fm.family_id from public.family_members fm
--     join public.profiles p on p.id = fm.user_id
--     where p.email = 'mcemkoca0@gmail.com' limit 1);
