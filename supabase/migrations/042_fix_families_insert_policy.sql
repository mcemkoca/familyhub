-- Migration 042: Fix families INSERT policy so users can create a family
-- Problem: existing policies require profiles.family_id IS NOT NULL,
-- which blocks creation of a NEW family (family_id is NULL before creation)

-- Allow any authenticated user to insert a new family
DROP POLICY IF EXISTS "Families insertable by authenticated" ON public.families;
CREATE POLICY "Families insertable by authenticated"
  ON public.families FOR INSERT TO authenticated
  WITH CHECK (true);

-- Also ensure profiles can update their family_id after joining/creating
-- The existing "Profiles editable by owner" already allows this, but
-- make sure there is no conflicting policy.
DROP POLICY IF EXISTS "Profiles set family_id" ON public.profiles;
CREATE POLICY "Profiles set family_id"
  ON public.profiles FOR UPDATE TO authenticated
  USING (id = auth.uid())
  WITH CHECK (id = auth.uid());
