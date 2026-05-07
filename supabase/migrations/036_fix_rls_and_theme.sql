-- Fix RLS recursion, missing policies, and add profile accent color
-- (Consolidates fixes from edited 032 + 034 + 035 into a single new migration)

-- 1. Helper function to check admin status without RLS recursion
CREATE OR REPLACE FUNCTION public.is_family_admin(p_family_id uuid)
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM public.family_members fm
    WHERE fm.family_id = p_family_id
      AND fm.user_id = auth.uid()
      AND fm.role = 'admin'
  );
END;
$$;

-- 2. Fix UPDATE policy on family_members to use the helper (avoids infinite recursion)
DROP POLICY IF EXISTS "Family members updatable by admin" ON public.family_members;
CREATE POLICY "Family members updatable by admin"
  ON public.family_members FOR UPDATE TO authenticated
  USING (public.is_family_admin(family_members.family_id));

-- 3. Add SELECT policy for family_members so other policies can query it safely
DROP POLICY IF EXISTS "Family members select" ON public.family_members;
CREATE POLICY "Family members select"
  ON public.family_members FOR SELECT TO authenticated
  USING (
    family_id IN (
      SELECT family_id FROM public.profiles
      WHERE id = auth.uid() AND family_id IS NOT NULL
    )
  );

-- 4. Add INSERT policy for family_members
DROP POLICY IF EXISTS "Family members insert" ON public.family_members;
CREATE POLICY "Family members insert"
  ON public.family_members FOR INSERT TO authenticated
  WITH CHECK (user_id = auth.uid());

-- 5. Add missing INSERT policy for tasks
DROP POLICY IF EXISTS "Tasks insert" ON public.tasks;
CREATE POLICY "Tasks insert"
  ON public.tasks FOR INSERT TO authenticated
  WITH CHECK (
    family_id IN (
      SELECT family_id FROM public.profiles
      WHERE id = auth.uid() AND family_id IS NOT NULL
    )
  );

-- 6. Add accent_color to profiles so theme preferences persist per-profile
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS accent_color TEXT DEFAULT 'cobalt';
