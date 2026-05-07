-- ============================================================================
-- 046_final_rls_and_users.sql
-- NET COZUM: RLS fix + profiles insert policy + kullanici ekleme
-- Calistirma: Supabase Dashboard > SQL Editor > New Query > Run
-- ============================================================================

-- =============================================================================
-- PHASE 1: FIX BROKEN POLICIES (045 bozdu, 044 duzeltiyoruz)
-- =============================================================================

-- 1a. profiles INSERT policy EKSIKTI — signUp'ta profiles.upsert basarisiz oluyordu
DROP POLICY IF EXISTS "profiles_insert_own" ON public.profiles;
CREATE POLICY "profiles_insert_own"
  ON public.profiles FOR INSERT TO authenticated
  WITH CHECK (id = auth.uid());

-- 1b. family_members_select_by_family 045'te recursive yapilmisti, duzelt
DROP POLICY IF EXISTS "family_members_select_by_family" ON public.family_members;
CREATE POLICY "family_members_select_by_family"
  ON public.family_members FOR SELECT TO authenticated
  USING (
    family_id IN (SELECT family_id FROM public.profiles WHERE id = auth.uid() AND family_id IS NOT NULL)
  );

-- 1c. family_members viewable by self (kayit sirasinda family_id null iken gerekli)
DROP POLICY IF EXISTS "family_members_viewable_by_self" ON public.family_members;
CREATE POLICY "family_members_viewable_by_self"
  ON public.family_members FOR SELECT TO authenticated
  USING (user_id = auth.uid());

-- 1d. families SELECT policy (aileye katilanlar gorebilsin)
DROP POLICY IF EXISTS "families_select_by_member" ON public.families;
CREATE POLICY "families_select_by_member"
  ON public.families FOR SELECT TO authenticated
  USING (
    id IN (SELECT family_id FROM public.profiles WHERE id = auth.uid() AND family_id IS NOT NULL)
    OR id IN (SELECT family_id FROM public.family_members WHERE user_id = auth.uid())
  );

-- =============================================================================
-- PHASE 2: CHILD ACCOUNTS age kolonu (eksikse ekle)
-- =============================================================================
ALTER TABLE public.child_accounts ADD COLUMN IF NOT EXISTS age int;

-- =============================================================================
-- PHASE 3: KULLANICI EKLEME (SQL Editor'da RLS bypass edilir)
-- =============================================================================

-- 3a. Ebeveyn kullanicisini auth.users'tan bul
DO $$
DECLARE
  v_parent_id uuid;
  v_family_id uuid := '3816dedb-c232-493a-b8f5-eccf326f0d3c';
  v_existing_family_id uuid;
BEGIN
  -- Ebeveyn kullanici ID'sini auth.users'tan al
  SELECT id INTO v_parent_id FROM auth.users WHERE email = 'hilalsahbaz2018@gmail.com' LIMIT 1;
  
  IF v_parent_id IS NULL THEN
    RAISE NOTICE 'Ebeveyn kullanici auth.users tablosunda bulunamadi. Once uygulamadan kayit olunmalidir.';
  ELSE
    -- profiles tablosunda var mi kontrol et, yoksa ekle
    IF NOT EXISTS (SELECT 1 FROM public.profiles WHERE id = v_parent_id) THEN
      INSERT INTO public.profiles (id, display_name, email, family_id, created_at, updated_at)
      VALUES (v_parent_id, 'Hilal', 'hilalsahbaz2018@gmail.com', v_family_id, now(), now());
      RAISE NOTICE 'Ebeveyn profili olusturuldu.';
    ELSE
      -- family_id guncelle (eger null veya farkliysa)
      UPDATE public.profiles SET family_id = v_family_id, updated_at = now() WHERE id = v_parent_id AND (family_id IS NULL OR family_id != v_family_id);
      RAISE NOTICE 'Ebeveyn profili guncellendi.';
    END IF;
    
    -- family_members tablosunda var mi kontrol et, yoksa ekle
    IF NOT EXISTS (SELECT 1 FROM public.family_members WHERE user_id = v_parent_id AND family_id = v_family_id) THEN
      INSERT INTO public.family_members (family_id, user_id, role, display_name, joined_at)
      VALUES (v_family_id, v_parent_id, 'parent', 'Hilal', now());
      RAISE NOTICE 'Ebeveyn aileye eklendi (rol: parent).';
    ELSE
      RAISE NOTICE 'Ebeveyn zaten ailede.';
    END IF;
  END IF;
END $$;

-- 3b. Cocuk ekleme (child_accounts)
DO $$
DECLARE
  v_family_id uuid := '3816dedb-c232-493a-b8f5-eccf326f0d3c';
  v_creator_id uuid;
  v_child_id uuid;
BEGIN
  -- Aileyi olusturan kullaniciyi bul (created_by)
  SELECT created_by INTO v_creator_id FROM public.families WHERE id = v_family_id LIMIT 1;
  IF v_creator_id IS NULL THEN
    -- Fallback: ilk admin/parent'i bul
    SELECT user_id INTO v_creator_id FROM public.family_members WHERE family_id = v_family_id AND role IN ('admin','parent') LIMIT 1;
  END IF;
  
  -- Mevcut Mirac kaydi var mi kontrol et
  SELECT id INTO v_child_id FROM public.child_accounts WHERE family_id = v_family_id AND name = 'Mirac' LIMIT 1;
  
  IF v_child_id IS NULL THEN
    INSERT INTO public.child_accounts (
      family_id, name, age, pin_hash, role, color, 
      created_by, is_active, daily_screen_time_minutes, 
      can_approve_tasks, can_send_messages, can_view_budget
    ) VALUES (
      v_family_id, 'Mirac', 6, '2704', 'child', '#3B82F6',
      v_creator_id, true, 120,
      false, true, false
    );
    RAISE NOTICE 'Cocuk (Mirac) eklendi.';
  ELSE
    UPDATE public.child_accounts SET 
      age = 6, pin_hash = '2704', role = 'child', 
      is_active = true, updated_at = now()
    WHERE id = v_child_id;
    RAISE NOTICE 'Cocuk (Mirac) guncellendi.';
  END IF;
END $$;

-- =============================================================================
-- PHASE 4: FORCE POLICY RELOAD
-- =============================================================================
NOTIFY pgrst, 'reload schema';

-- ============================================
-- TAMAMLANDI
-- 1. RLS politikalari duzeltildi
-- 2. Ebeveyn (hilalsahbaz2018@gmail.com) aileye eklendi
-- 3. Cocuk (Mirac, 6 yas) eklendi/guncellendi
-- Uygulamayi kapatip acin.
-- ============================================
++++++++++2.01Q