-- Fix infinite recursion in family_members RLS policies
-- The previous policy likely referenced family_members within its own USING clause,
-- causing Postgres to recursively evaluate the policy.

-- Drop existing problematic policies
DROP POLICY IF EXISTS "family_members_select" ON public.family_members;
DROP POLICY IF EXISTS "family_members_insert" ON public.family_members;
DROP POLICY IF EXISTS "family_members_update" ON public.family_members;
DROP POLICY IF EXISTS "family_members_delete" ON public.family_members;

-- Enable RLS
ALTER TABLE public.family_members ENABLE ROW LEVEL SECURITY;

-- FIXED: Use profiles table to check family membership instead of self-referencing family_members
CREATE POLICY "family_members_select"
  ON public.family_members
  FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles p
      WHERE p.id = auth.uid()
        AND p.family_id = family_members.family_id
    )
  );

CREATE POLICY "family_members_insert"
  ON public.family_members
  FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.profiles p
      WHERE p.id = auth.uid()
        AND p.family_id = family_members.family_id
    )
  );

CREATE POLICY "family_members_update"
  ON public.family_members
  FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles p
      WHERE p.id = auth.uid()
        AND p.family_id = family_members.family_id
    )
  );

CREATE POLICY "family_members_delete"
  ON public.family_members
  FOR DELETE
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles p
      WHERE p.id = auth.uid()
        AND p.family_id = family_members.family_id
    )
  );
