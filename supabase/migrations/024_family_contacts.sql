-- ============================================
-- FAMILY CONTACTS (Rehber)
-- ============================================

CREATE TABLE IF NOT EXISTS public.family_contacts (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  family_id UUID NOT NULL REFERENCES public.families(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  phone TEXT,
  email TEXT,
  type TEXT DEFAULT 'other' CHECK (type IN ('family', 'friend', 'work', 'school', 'doctor', 'emergency', 'other')),
  avatar_url TEXT,
  notes TEXT,
  created_by UUID REFERENCES public.profiles(id),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.family_contacts ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Family contacts view" ON public.family_contacts;
DROP POLICY IF EXISTS "Family contacts insert" ON public.family_contacts;
DROP POLICY IF EXISTS "Family contacts update" ON public.family_contacts;
DROP POLICY IF EXISTS "Family contacts delete" ON public.family_contacts;

CREATE POLICY "Family contacts view"
  ON public.family_contacts FOR SELECT
  USING (family_id IN (
    SELECT family_id FROM public.family_members WHERE user_id = auth.uid()
  ));

CREATE POLICY "Family contacts insert"
  ON public.family_contacts FOR INSERT
  WITH CHECK (family_id IN (
    SELECT family_id FROM public.family_members WHERE user_id = auth.uid()
  ));

CREATE POLICY "Family contacts update"
  ON public.family_contacts FOR UPDATE
  USING (family_id IN (
    SELECT family_id FROM public.family_members WHERE user_id = auth.uid()
  ));

CREATE POLICY "Family contacts delete"
  ON public.family_contacts FOR DELETE
  USING (family_id IN (
    SELECT family_id FROM public.family_members WHERE user_id = auth.uid()
  ));

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_publication_tables
    WHERE pubname = 'supabase_realtime'
      AND schemaname = 'public'
      AND tablename = 'family_contacts'
  ) THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.family_contacts;
  END IF;
END $$;

CREATE INDEX IF NOT EXISTS idx_family_contacts_family ON public.family_contacts(family_id);
CREATE INDEX IF NOT EXISTS idx_family_contacts_search ON public.family_contacts USING gin(to_tsvector('simple', coalesce(name,'') || ' ' || coalesce(phone,'')));
