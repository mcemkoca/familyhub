-- ============================================================================
-- 064 — family-assets Storage bucket + RLS politikaları (kapak fotoğrafı 403 fix)
-- ----------------------------------------------------------------------------
-- SORUN: Hub kapak fotoğrafı yüklemesi "family-assets" bucket'ına yazarken 403
--        alıyordu; bucket yok veya storage.objects üzerinde INSERT politikası
--        tanımlı değildi.
-- ÇÖZÜM: Public okunur bucket + kimliği doğrulanmış kullanıcıların yalnızca
--        kendi klasörlerine (cover_photos/{uid}/...) yazmasına izin veren
--        RLS politikaları.
-- ============================================================================

-- 1) Bucket'ı oluştur (public okuma; yoksa ekle).
insert into storage.buckets (id, name, public)
values ('family-assets', 'family-assets', true)
on conflict (id) do update set public = true;

-- 2) Eski politikaları temizle (idempotent).
drop policy if exists "family_assets_read" on storage.objects;
drop policy if exists "family_assets_insert_own" on storage.objects;
drop policy if exists "family_assets_update_own" on storage.objects;
drop policy if exists "family_assets_delete_own" on storage.objects;

-- 3) Herkes okuyabilir (public bucket).
create policy "family_assets_read"
  on storage.objects for select
  using (bucket_id = 'family-assets');

-- 4) Kullanıcı yalnızca cover_photos/{kendi-uid}/ altına yazabilir.
create policy "family_assets_insert_own"
  on storage.objects for insert to authenticated
  with check (
    bucket_id = 'family-assets'
    and (storage.foldername(name))[1] = 'cover_photos'
    and (storage.foldername(name))[2] = auth.uid()::text
  );

create policy "family_assets_update_own"
  on storage.objects for update to authenticated
  using (
    bucket_id = 'family-assets'
    and (storage.foldername(name))[1] = 'cover_photos'
    and (storage.foldername(name))[2] = auth.uid()::text
  );

create policy "family_assets_delete_own"
  on storage.objects for delete to authenticated
  using (
    bucket_id = 'family-assets'
    and (storage.foldername(name))[1] = 'cover_photos'
    and (storage.foldername(name))[2] = auth.uid()::text
  );
