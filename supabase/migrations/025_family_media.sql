-- ============================================
-- FAMILY MEDIA (Galeri)
-- ============================================

CREATE TABLE IF NOT EXISTS public.family_media (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  family_id UUID NOT NULL REFERENCES public.families(id) ON DELETE CASCADE,
  url TEXT NOT NULL,
  thumbnail_url TEXT,
  type TEXT DEFAULT 'image' CHECK (type IN ('image', 'video')),
  caption TEXT,
  uploaded_by UUID REFERENCES public.profiles(id),
  created_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.family_media ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Family media view" ON public.family_media;
DROP POLICY IF EXISTS "Family media insert" ON public.family_media;
DROP POLICY IF EXISTS "Family media delete" ON public.family_media;

CREATE POLICY "Family media view"
  ON public.family_media FOR SELECT
  USING (family_id IN (
    SELECT family_id FROM public.family_members WHERE user_id = auth.uid()
  ));

CREATE POLICY "Family media insert"
  ON public.family_media FOR INSERT
  WITH CHECK (family_id IN (
    SELECT family_id FROM public.family_members WHERE user_id = auth.uid()
  ));

CREATE POLICY "Family media delete"
  ON public.family_media FOR DELETE
  USING (uploaded_by = auth.uid() OR family_id IN (
    SELECT family_id FROM public.family_members WHERE user_id = auth.uid() AND role IN ('admin','parent')
  ));

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_publication_tables
    WHERE pubname = 'supabase_realtime'
      AND schemaname = 'public'
      AND tablename = 'family_media'
  ) THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.family_media;
  END IF;
END $$;

CREATE INDEX IF NOT EXISTS idx_family_media_family ON public.family_media(family_id, created_at DESC);
