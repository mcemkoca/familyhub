-- Fix remaining RLS policies that reference family_members causing infinite recursion

-- ============================================
-- 1. Fix call_sessions RLS
-- ============================================
DROP POLICY IF EXISTS "family_call_access" ON public.call_sessions;
DROP POLICY IF EXISTS "call_sessions_select" ON public.call_sessions;
DROP POLICY IF EXISTS "call_sessions_insert" ON public.call_sessions;
DROP POLICY IF EXISTS "call_sessions_update" ON public.call_sessions;
DROP POLICY IF EXISTS "call_sessions_delete" ON public.call_sessions;

CREATE POLICY "call_sessions_select_v2"
  ON public.call_sessions FOR SELECT TO authenticated
  USING (
    family_id IN (
      SELECT family_id FROM public.profiles
      WHERE id = auth.uid() AND family_id IS NOT NULL
    )
  );

CREATE POLICY "call_sessions_insert_v2"
  ON public.call_sessions FOR INSERT TO authenticated
  WITH CHECK (
    family_id IN (
      SELECT family_id FROM public.profiles
      WHERE id = auth.uid() AND family_id IS NOT NULL
    )
  );

CREATE POLICY "call_sessions_update_v2"
  ON public.call_sessions FOR UPDATE TO authenticated
  USING (
    family_id IN (
      SELECT family_id FROM public.profiles
      WHERE id = auth.uid() AND family_id IS NOT NULL
    )
  );

-- ============================================
-- 2. Fix tasks RLS
-- ============================================
DROP POLICY IF EXISTS "Tasks insert" ON public.tasks;
DROP POLICY IF EXISTS "tasks_select" ON public.tasks;
DROP POLICY IF EXISTS "tasks_insert" ON public.tasks;
DROP POLICY IF EXISTS "tasks_update" ON public.tasks;
DROP POLICY IF EXISTS "tasks_delete" ON public.tasks;

CREATE POLICY "tasks_select_v2"
  ON public.tasks FOR SELECT TO authenticated
  USING (
    family_id IN (
      SELECT family_id FROM public.profiles
      WHERE id = auth.uid() AND family_id IS NOT NULL
    )
  );

CREATE POLICY "tasks_insert_v2"
  ON public.tasks FOR INSERT TO authenticated
  WITH CHECK (
    family_id IN (
      SELECT family_id FROM public.profiles
      WHERE id = auth.uid() AND family_id IS NOT NULL
    )
  );

CREATE POLICY "tasks_update_v2"
  ON public.tasks FOR UPDATE TO authenticated
  USING (
    family_id IN (
      SELECT family_id FROM public.profiles
      WHERE id = auth.uid() AND family_id IS NOT NULL
    )
  );

CREATE POLICY "tasks_delete_v2"
  ON public.tasks FOR DELETE TO authenticated
  USING (
    family_id IN (
      SELECT family_id FROM public.profiles
      WHERE id = auth.uid() AND family_id IS NOT NULL
    )
  );

-- ============================================
-- 3. Fix family_members: drop any remaining old policies
-- ============================================
DROP POLICY IF EXISTS "family_members_select" ON public.family_members;
DROP POLICY IF EXISTS "family_members_insert" ON public.family_members;
DROP POLICY IF EXISTS "family_members_update" ON public.family_members;
DROP POLICY IF EXISTS "family_members_delete" ON public.family_members;
DROP POLICY IF EXISTS "Family members select" ON public.family_members;
DROP POLICY IF EXISTS "Family members insert" ON public.family_members;
DROP POLICY IF EXISTS "Family members update" ON public.family_members;
DROP POLICY IF EXISTS "Family members delete" ON public.family_members;
DROP POLICY IF EXISTS "Family members updatable by admin" ON public.family_members;
DROP POLICY IF EXISTS "Users can view family members" ON public.family_members;
DROP POLICY IF EXISTS "Users can insert family members" ON public.family_members;
DROP POLICY IF EXISTS "Users can update family members" ON public.family_members;
DROP POLICY IF EXISTS "Users can delete family members" ON public.family_members;
DROP POLICY IF EXISTS "Enable select for family members" ON public.family_members;
DROP POLICY IF EXISTS "Enable insert for family members" ON public.family_members;
DROP POLICY IF EXISTS "Enable update for family members" ON public.family_members;
DROP POLICY IF EXISTS "Enable delete for family members" ON public.family_members;

-- Recreate clean family_members policies
DROP POLICY IF EXISTS "family_members_select_v2" ON public.family_members;
DROP POLICY IF EXISTS "family_members_insert_v2" ON public.family_members;
DROP POLICY IF EXISTS "family_members_update_v2" ON public.family_members;
DROP POLICY IF EXISTS "family_members_delete_v2" ON public.family_members;

CREATE POLICY "family_members_select_v2"
  ON public.family_members FOR SELECT TO authenticated
  USING (
    family_id IN (
      SELECT family_id FROM public.profiles
      WHERE id = auth.uid() AND family_id IS NOT NULL
    )
  );

CREATE POLICY "family_members_insert_v2"
  ON public.family_members FOR INSERT TO authenticated
  WITH CHECK (user_id = auth.uid());

CREATE POLICY "family_members_update_v2"
  ON public.family_members FOR UPDATE TO authenticated
  USING (
    user_id = auth.uid()
    OR
    family_id IN (
      SELECT family_id FROM public.profiles
      WHERE id = auth.uid() AND family_id IS NOT NULL
    )
  );

CREATE POLICY "family_members_delete_v2"
  ON public.family_members FOR DELETE TO authenticated
  USING (user_id = auth.uid());
