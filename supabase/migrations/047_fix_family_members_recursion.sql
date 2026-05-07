-- Fix infinite recursion in family_members RLS policy
-- Problem: family_members_select_by_family queries profiles,
--          but families policy queries family_members -> circular dependency

-- Drop the problematic policy
DROP POLICY IF EXISTS "family_members_select_by_family" ON public.family_members;

-- Re-create using family_members itself (self-reference is safe because
-- family_members_select_self does NOT query family_members again)
CREATE POLICY "family_members_select_by_family"
  ON public.family_members FOR SELECT TO authenticated
  USING (
    family_id IN (SELECT family_id FROM public.family_members WHERE user_id = auth.uid())
  );

-- Also clean up any leftover old families policies that reference family_members
DROP POLICY IF EXISTS "Family members view" ON public.families;
