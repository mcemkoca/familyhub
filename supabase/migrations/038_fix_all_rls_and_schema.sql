-- Migration 038: Comprehensive RLS & Schema Fix
-- Fixes infinite recursion, missing columns, and conflicting policies

-- ============================================
-- 1. CLEAN SLATE: Drop ALL existing family_members policies
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

-- ============================================
-- 2. Add missing columns to profiles
-- ============================================
ALTER TABLE public.profiles 
  ADD COLUMN IF NOT EXISTS full_name text,
  ADD COLUMN IF NOT EXISTS fcm_token text,
  ADD COLUMN IF NOT EXISTS accent_color text DEFAULT 'cobalt';

-- ============================================
-- 3. Fix profiles RLS: avoid recursion via family_members
-- ============================================
DROP POLICY IF EXISTS "Profiles are viewable by owner" ON public.profiles;
DROP POLICY IF EXISTS "Profiles are viewable by family" ON public.profiles;
DROP POLICY IF EXISTS "Profiles viewable by user" ON public.profiles;
DROP POLICY IF EXISTS "Profiles viewable by authenticated" ON public.profiles;

CREATE POLICY "Profiles viewable by authenticated"
  ON public.profiles FOR SELECT TO authenticated
  USING (true);  -- All authenticated users can read all profiles (needed for family display)

CREATE POLICY "Profiles editable by owner"
  ON public.profiles FOR UPDATE TO authenticated
  USING (id = auth.uid())
  WITH CHECK (id = auth.uid());

CREATE POLICY "Profiles insertable by owner"
  ON public.profiles FOR INSERT TO authenticated
  WITH CHECK (id = auth.uid());

-- ============================================
-- 4. Fix families RLS
-- ============================================
DROP POLICY IF EXISTS "Families viewable by members" ON public.families;
DROP POLICY IF EXISTS "Families editable by admin" ON public.families;

CREATE POLICY "Families viewable by members"
  ON public.families FOR SELECT TO authenticated
  USING (
    id IN (
      SELECT family_id FROM public.profiles
      WHERE id = auth.uid() AND family_id IS NOT NULL
    )
  );

CREATE POLICY "Families editable by admin"
  ON public.families FOR ALL TO authenticated
  USING (
    id IN (
      SELECT family_id FROM public.profiles
      WHERE id = auth.uid() AND family_id IS NOT NULL
    )
  );

-- ============================================
-- 5. Create clean family_members policies (NO recursion)
-- ============================================
ALTER TABLE public.family_members ENABLE ROW LEVEL SECURITY;

-- Users can see any family member whose family_id matches THEIR profile.family_id
CREATE POLICY "family_members_select_v2"
  ON public.family_members FOR SELECT TO authenticated
  USING (
    family_id IN (
      SELECT family_id FROM public.profiles
      WHERE id = auth.uid() AND family_id IS NOT NULL
    )
  );

-- Users can insert themselves into a family
CREATE POLICY "family_members_insert_v2"
  ON public.family_members FOR INSERT TO authenticated
  WITH CHECK (user_id = auth.uid());

-- Users can update their own record OR admins can update any in their family
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

-- Users can delete their own record
CREATE POLICY "family_members_delete_v2"
  ON public.family_members FOR DELETE TO authenticated
  USING (user_id = auth.uid());

-- ============================================
-- 6. Ensure daily_recommendations has proper RLS (if table exists)
-- ============================================
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'daily_recommendations') THEN
    ALTER TABLE public.daily_recommendations ENABLE ROW LEVEL SECURITY;
    
    DROP POLICY IF EXISTS "daily_recommendations_select" ON public.daily_recommendations;
    CREATE POLICY "daily_recommendations_select"
      ON public.daily_recommendations FOR SELECT TO authenticated
      USING (
        family_id IN (
          SELECT family_id FROM public.profiles
          WHERE id = auth.uid() AND family_id IS NOT NULL
        )
      );
  END IF;
END $$;

-- ============================================
-- 7. Backfill missing full_name from display_name
-- ============================================
UPDATE public.profiles 
SET full_name = COALESCE(full_name, display_name, 'Kullanıcı')
WHERE full_name IS NULL;
