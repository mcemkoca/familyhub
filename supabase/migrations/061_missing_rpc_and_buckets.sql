-- ============================================
-- 061: Eksik RPC + Storage Bucket'ları
-- ============================================

-- 1. notify_family_crash — crash_detection_service.dart:273 çağırıyor
CREATE OR REPLACE FUNCTION public.notify_family_crash(
  sender_id   uuid,
  family_id   uuid,
  latitude    numeric,
  longitude   numeric,
  confidence  numeric
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  -- Aile üyelerine Realtime kanalı üzerinden kaza bildirimi gönder
  PERFORM pg_notify(
    'family_crash_alert',
    json_build_object(
      'sender_id',  sender_id,
      'family_id',  family_id,
      'latitude',   latitude,
      'longitude',  longitude,
      'confidence', confidence,
      'timestamp',  now()
    )::text
  );
  -- crash_events kaydı 062 migration'dan sonra eklenecek (tablo orada yaratılıyor)
END;
$$;

-- 2. Storage Bucket'ları — Supabase'de yoksa oluştur
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES
  ('avatars',              'avatars',              true,  5242880,  ARRAY['image/jpeg','image/png','image/webp']),
  ('family-assets',        'family-assets',        false, 10485760, ARRAY['image/jpeg','image/png','image/webp','video/mp4']),
  ('family-gallery',       'family-gallery',       false, 52428800, ARRAY['image/jpeg','image/png','image/webp','video/mp4','video/quicktime']),
  ('family-documents',     'family-documents',     false, 26214400, ARRAY['application/pdf','image/jpeg','image/png','application/msword','application/vnd.openxmlformats-officedocument.wordprocessingml.document']),
  ('emergency-recordings', 'emergency-recordings', false, 104857600, ARRAY['audio/mpeg','audio/mp4','video/mp4','audio/wav'])
ON CONFLICT (id) DO NOTHING;

-- Bucket RLS Policies
-- avatars: herkes okuyabilir, sadece sahip yükleyebilir
DROP POLICY IF EXISTS "avatars_public_select" ON storage.objects;
CREATE POLICY "avatars_public_select" ON storage.objects FOR SELECT
  USING (bucket_id = 'avatars');

DROP POLICY IF EXISTS "avatars_auth_insert" ON storage.objects;
CREATE POLICY "avatars_auth_insert" ON storage.objects FOR INSERT TO authenticated
  WITH CHECK (bucket_id = 'avatars' AND auth.uid()::text = (storage.foldername(name))[1]);

DROP POLICY IF EXISTS "avatars_auth_update" ON storage.objects;
CREATE POLICY "avatars_auth_update" ON storage.objects FOR UPDATE TO authenticated
  USING (bucket_id = 'avatars' AND auth.uid()::text = (storage.foldername(name))[1]);

DROP POLICY IF EXISTS "avatars_auth_delete" ON storage.objects;
CREATE POLICY "avatars_auth_delete" ON storage.objects FOR DELETE TO authenticated
  USING (bucket_id = 'avatars' AND auth.uid()::text = (storage.foldername(name))[1]);

-- family-assets: aile üyeleri erişir
DROP POLICY IF EXISTS "family_assets_select" ON storage.objects;
CREATE POLICY "family_assets_select" ON storage.objects FOR SELECT TO authenticated
  USING (bucket_id = 'family-assets');

DROP POLICY IF EXISTS "family_assets_insert" ON storage.objects;
CREATE POLICY "family_assets_insert" ON storage.objects FOR INSERT TO authenticated
  WITH CHECK (bucket_id = 'family-assets');

DROP POLICY IF EXISTS "family_assets_delete" ON storage.objects;
CREATE POLICY "family_assets_delete" ON storage.objects FOR DELETE TO authenticated
  USING (bucket_id = 'family-assets');

-- family-gallery: aile üyeleri erişir
DROP POLICY IF EXISTS "family_gallery_select" ON storage.objects;
CREATE POLICY "family_gallery_select" ON storage.objects FOR SELECT TO authenticated
  USING (bucket_id = 'family-gallery');

DROP POLICY IF EXISTS "family_gallery_insert" ON storage.objects;
CREATE POLICY "family_gallery_insert" ON storage.objects FOR INSERT TO authenticated
  WITH CHECK (bucket_id = 'family-gallery');

DROP POLICY IF EXISTS "family_gallery_delete" ON storage.objects;
CREATE POLICY "family_gallery_delete" ON storage.objects FOR DELETE TO authenticated
  USING (bucket_id = 'family-gallery');

-- family-documents: aile üyeleri erişir
DROP POLICY IF EXISTS "family_documents_select" ON storage.objects;
CREATE POLICY "family_documents_select" ON storage.objects FOR SELECT TO authenticated
  USING (bucket_id = 'family-documents');

DROP POLICY IF EXISTS "family_documents_insert" ON storage.objects;
CREATE POLICY "family_documents_insert" ON storage.objects FOR INSERT TO authenticated
  WITH CHECK (bucket_id = 'family-documents');

DROP POLICY IF EXISTS "family_documents_delete" ON storage.objects;
CREATE POLICY "family_documents_delete" ON storage.objects FOR DELETE TO authenticated
  USING (bucket_id = 'family-documents');

-- emergency-recordings: sadece sahip erişir
DROP POLICY IF EXISTS "emergency_recordings_own" ON storage.objects;
CREATE POLICY "emergency_recordings_own" ON storage.objects FOR ALL TO authenticated
  USING (bucket_id = 'emergency-recordings' AND auth.uid()::text = (storage.foldername(name))[1])
  WITH CHECK (bucket_id = 'emergency-recordings' AND auth.uid()::text = (storage.foldername(name))[1]);

-- crash_events ALTER'ları 062'de yapılıyor (tablo orada yaratılıyor)

SELECT 'Migration 061 basarili!' AS result;
