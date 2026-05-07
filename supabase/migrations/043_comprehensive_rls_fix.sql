-- 043_comprehensive_rls_fix.sql
-- Comprehensive RLS fix for family_id null scenarios and permission robustness
-- Apply this in Supabase SQL Editor to fix app-wide permission issues

-- =============================================================================
-- 1. PROFILES TABLE
-- =============================================================================
-- Ensure users can update their own profile (including family_id)
DROP POLICY IF EXISTS "Profiles update own" ON public.profiles;
CREATE POLICY "Profiles update own"
  ON public.profiles FOR UPDATE TO authenticated
  USING (id = auth.uid())
  WITH CHECK (id = auth.uid());

-- =============================================================================
-- 2. FAMILY_MEMBERS TABLE
-- =============================================================================
-- Ensure users can always see their OWN record.
-- This is critical during registration / join when profiles.family_id may be null.
DROP POLICY IF EXISTS "Family members viewable by self" ON public.family_members;
CREATE POLICY "Family members viewable by self"
  ON public.family_members FOR SELECT TO authenticated
  USING (user_id = auth.uid());

-- Ensure users can insert themselves into a family
DROP POLICY IF EXISTS "Family members insertable by self" ON public.family_members;
CREATE POLICY "Family members insertable by self"
  ON public.family_members FOR INSERT TO authenticated
  WITH CHECK (user_id = auth.uid());

-- Ensure users can update their own family_member record
DROP POLICY IF EXISTS "Family members updatable by self" ON public.family_members;
CREATE POLICY "Family members updatable by self"
  ON public.family_members FOR UPDATE TO authenticated
  USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());

-- =============================================================================
-- 3. FAMILIES TABLE
-- =============================================================================
-- Ensure authenticated users can create a family
DROP POLICY IF EXISTS "Families insertable by authenticated" ON public.families;
CREATE POLICY "Families insertable by authenticated"
  ON public.families FOR INSERT TO authenticated
  WITH CHECK (true);

-- =============================================================================
-- 4. CHILD_ACCOUNTS TABLE
-- =============================================================================
-- Ensure users can view child accounts linked to their family
DROP POLICY IF EXISTS "Child accounts viewable by family" ON public.child_accounts;
CREATE POLICY "Child accounts viewable by family"
  ON public.child_accounts FOR SELECT TO authenticated
  USING (
    family_id IN (
      SELECT family_id FROM public.profiles WHERE id = auth.uid() AND family_id IS NOT NULL
    )
  );

-- Ensure family members can insert child accounts
DROP POLICY IF EXISTS "Child accounts insertable by family" ON public.child_accounts;
CREATE POLICY "Child accounts insertable by family"
  ON public.child_accounts FOR INSERT TO authenticated
  WITH CHECK (
    family_id IN (
      SELECT family_id FROM public.profiles WHERE id = auth.uid() AND family_id IS NOT NULL
    )
  );

-- =============================================================================
-- 5. SAFE_ZONES TABLE
-- =============================================================================
-- Fix safe_zones RLS to use profiles.family_id instead of family_members subquery
DROP POLICY IF EXISTS "Safe zones viewable by family" ON public.safe_zones;
CREATE POLICY "Safe zones viewable by family"
  ON public.safe_zones FOR SELECT TO authenticated
  USING (
    family_id IN (
      SELECT family_id FROM public.profiles WHERE id = auth.uid() AND family_id IS NOT NULL
    )
  );

DROP POLICY IF EXISTS "Safe zones insertable by family" ON public.safe_zones;
CREATE POLICY "Safe zones insertable by family"
  ON public.safe_zones FOR INSERT TO authenticated
  WITH CHECK (
    family_id IN (
      SELECT family_id FROM public.profiles WHERE id = auth.uid() AND family_id IS NOT NULL
    )
  );

DROP POLICY IF EXISTS "Safe zones updatable by family" ON public.safe_zones;
CREATE POLICY "Safe zones updatable by family"
  ON public.safe_zones FOR UPDATE TO authenticated
  USING (
    family_id IN (
      SELECT family_id FROM public.profiles WHERE id = auth.uid() AND family_id IS NOT NULL
    )
  );

DROP POLICY IF EXISTS "Safe zones deletable by family" ON public.safe_zones;
CREATE POLICY "Safe zones deletable by family"
  ON public.safe_zones FOR DELETE TO authenticated
  USING (
    family_id IN (
      SELECT family_id FROM public.profiles WHERE id = auth.uid() AND family_id IS NOT NULL
    )
  );
