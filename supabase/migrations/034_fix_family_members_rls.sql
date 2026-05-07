-- Fix infinite recursion in family_members RLS policies
-- and add missing policies for tasks / family_members access

-- 1. Allow authenticated users to read their own family_members records.
-- Uses profiles.family_id (maintained by trigger in 021) to avoid recursion.
DROP POLICY IF EXISTS "Family members select" ON public.family_members;
CREATE POLICY "Family members select"
  ON public.family_members FOR SELECT TO authenticated
  USING (
    family_id IN (
      SELECT family_id FROM public.profiles
      WHERE id = auth.uid() AND family_id IS NOT NULL
    )
  );

-- 2. Allow authenticated users to insert their own family_members records.
DROP POLICY IF EXISTS "Family members insert" ON public.family_members;
CREATE POLICY "Family members insert"
  ON public.family_members FOR INSERT TO authenticated
  WITH CHECK (user_id = auth.uid());

-- 3. Add missing INSERT policy for tasks so family members can create tasks.
DROP POLICY IF EXISTS "Tasks insert" ON public.tasks;
CREATE POLICY "Tasks insert"
  ON public.tasks FOR INSERT TO authenticated
  WITH CHECK (
    family_id IN (
      SELECT family_id FROM public.profiles
      WHERE id = auth.uid() AND family_id IS NOT NULL
    )
  );
