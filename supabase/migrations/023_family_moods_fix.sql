-- ============================================
-- FAMILY MOODS TABLE (Safe re-create if missing)
-- ============================================

CREATE TABLE IF NOT EXISTS public.family_moods (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  family_id UUID REFERENCES public.families(id) ON DELETE CASCADE,
  user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
  mood_emoji TEXT NOT NULL,
  mood_note TEXT,
  energy_level INT CHECK (energy_level BETWEEN 1 AND 10),
  is_shared BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Enable RLS
ALTER TABLE public.family_moods ENABLE ROW LEVEL SECURITY;

-- Drop existing policies to avoid conflicts
DROP POLICY IF EXISTS "Family moods view" ON public.family_moods;
DROP POLICY IF EXISTS "Family moods insert" ON public.family_moods;
DROP POLICY IF EXISTS "Family moods update" ON public.family_moods;
DROP POLICY IF EXISTS "Family moods delete" ON public.family_moods;

-- Select: family members can view moods in their family
CREATE POLICY "Family moods view"
  ON public.family_moods FOR SELECT
  USING (family_id IN (
    SELECT family_id FROM public.family_members WHERE user_id = auth.uid()
  ));

-- Insert: any authenticated user can insert their own mood
CREATE POLICY "Family moods insert"
  ON public.family_moods FOR INSERT
  WITH CHECK (user_id = auth.uid());

-- Update: users can only update their own moods
CREATE POLICY "Family moods update"
  ON public.family_moods FOR UPDATE
  USING (user_id = auth.uid());

-- Delete: users can only delete their own moods
CREATE POLICY "Family moods delete"
  ON public.family_moods FOR DELETE
  USING (user_id = auth.uid());

-- Realtime (safe add)
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_publication_tables
    WHERE pubname = 'supabase_realtime'
      AND schemaname = 'public'
      AND tablename = 'family_moods'
  ) THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.family_moods;
  END IF;
END $$;

-- Index
CREATE INDEX IF NOT EXISTS idx_family_moods_family ON public.family_moods(family_id, created_at DESC);
