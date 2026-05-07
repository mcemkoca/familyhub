-- ============================================
-- FAMILY DOCUMENTS (Doküman + OCR)
-- ============================================

CREATE TABLE IF NOT EXISTS public.family_documents (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  family_id UUID NOT NULL REFERENCES public.families(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  file_url TEXT NOT NULL,
  file_type TEXT DEFAULT 'pdf' CHECK (file_type IN ('pdf', 'image', 'doc', 'other')),
  ocr_text TEXT,
  extracted_data JSONB DEFAULT '{}',
  status TEXT DEFAULT 'active' CHECK (status IN ('active', 'archived')),
  related_task_id UUID REFERENCES public.tasks(id) ON DELETE SET NULL,
  uploaded_by UUID REFERENCES public.profiles(id),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.family_documents ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Family documents view" ON public.family_documents;
DROP POLICY IF EXISTS "Family documents insert" ON public.family_documents;
DROP POLICY IF EXISTS "Family documents update" ON public.family_documents;
DROP POLICY IF EXISTS "Family documents delete" ON public.family_documents;

CREATE POLICY "Family documents view"
  ON public.family_documents FOR SELECT
  USING (family_id IN (
    SELECT family_id FROM public.family_members WHERE user_id = auth.uid()
  ));

CREATE POLICY "Family documents insert"
  ON public.family_documents FOR INSERT
  WITH CHECK (family_id IN (
    SELECT family_id FROM public.family_members WHERE user_id = auth.uid()
  ));

CREATE POLICY "Family documents update"
  ON public.family_documents FOR UPDATE
  USING (family_id IN (
    SELECT family_id FROM public.family_members WHERE user_id = auth.uid()
  ));

CREATE POLICY "Family documents delete"
  ON public.family_documents FOR DELETE
  USING (uploaded_by = auth.uid() OR family_id IN (
    SELECT family_id FROM public.family_members WHERE user_id = auth.uid() AND role IN ('admin','parent')
  ));

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_publication_tables
    WHERE pubname = 'supabase_realtime'
      AND schemaname = 'public'
      AND tablename = 'family_documents'
  ) THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.family_documents;
  END IF;
END $$;

CREATE INDEX IF NOT EXISTS idx_family_documents_family ON public.family_documents(family_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_family_documents_ocr ON public.family_documents USING gin(to_tsvector('simple', coalesce(ocr_text,'') || ' ' || coalesce(title,'')));
