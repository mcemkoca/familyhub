-- ============================================================================
-- 044_fix_everything.sql
-- MASTER RLS FIX - Tek seferde tüm izin sorunlarını çöz
-- Çalıştırma: Supabase Dashboard > SQL Editor > New Query > Run
-- ============================================================================
-- BU DOSYA:
-- 1. Tüm bozuk/eski RLS policy'lerini düşürür
-- 2. family_members için kritik SELECT policy'si ekler
-- 3. Tüm tablolar için profiles.family_id tabanlı, rekürsiyonsuz policy'ler oluşturur
-- 4. Yeni kullanıcıların aile oluşturabilmesi için families INSERT policy'si ekler
-- ============================================================================

-- =============================================================================
-- PHASE 1: DROP ALL EXISTING POLICIES (clean slate)
-- =============================================================================

-- profiles
DROP POLICY IF EXISTS "Profiles are viewable by everyone" ON public.profiles;
DROP POLICY IF EXISTS "Profiles updatable by owner" ON public.profiles;
DROP POLICY IF EXISTS "Profiles update own" ON public.profiles;
DROP POLICY IF EXISTS "Profiles update own family_id" ON public.profiles;
DROP POLICY IF EXISTS "profiles_select" ON public.profiles;
DROP POLICY IF EXISTS "profiles_update" ON public.profiles;
DROP POLICY IF EXISTS "profiles_insert" ON public.profiles;

-- families
DROP POLICY IF EXISTS "Families viewable by members" ON public.families;
DROP POLICY IF EXISTS "Families updatable by admin" ON public.families;
DROP POLICY IF EXISTS "Families insertable by authenticated" ON public.families;
DROP POLICY IF EXISTS "families_select" ON public.families;
DROP POLICY IF EXISTS "families_insert" ON public.families;
DROP POLICY IF EXISTS "families_update" ON public.families;

-- family_members
DROP POLICY IF EXISTS "Family members viewable by family" ON public.family_members;
DROP POLICY IF EXISTS "Family members insertable by admin" ON public.family_members;
DROP POLICY IF EXISTS "Family members updatable by admin" ON public.family_members;
DROP POLICY IF EXISTS "Family members deletable by admin" ON public.family_members;
DROP POLICY IF EXISTS "Family members viewable by self" ON public.family_members;
DROP POLICY IF EXISTS "Family members insertable by self" ON public.family_members;
DROP POLICY IF EXISTS "Family members updatable by self" ON public.family_members;
DROP POLICY IF EXISTS "family_members_select" ON public.family_members;
DROP POLICY IF EXISTS "family_members_insert" ON public.family_members;
DROP POLICY IF EXISTS "family_members_update" ON public.family_members;
DROP POLICY IF EXISTS "family_members_delete" ON public.family_members;

-- events
DROP POLICY IF EXISTS "Events viewable by family" ON public.events;
DROP POLICY IF EXISTS "Events insertable by family" ON public.events;
DROP POLICY IF EXISTS "Events updatable by family" ON public.events;
DROP POLICY IF EXISTS "Events deletable by creator" ON public.events;
DROP POLICY IF EXISTS "events_select" ON public.events;
DROP POLICY IF EXISTS "events_insert" ON public.events;
DROP POLICY IF EXISTS "events_update" ON public.events;
DROP POLICY IF EXISTS "events_delete" ON public.events;

-- tasks
DROP POLICY IF EXISTS "Tasks viewable by family" ON public.tasks;
DROP POLICY IF EXISTS "Tasks insertable by family" ON public.tasks;
DROP POLICY IF EXISTS "Tasks updatable by family" ON public.tasks;
DROP POLICY IF EXISTS "Tasks deletable by family" ON public.tasks;
DROP POLICY IF EXISTS "tasks_select" ON public.tasks;
DROP POLICY IF EXISTS "tasks_insert" ON public.tasks;
DROP POLICY IF EXISTS "tasks_update" ON public.tasks;
DROP POLICY IF EXISTS "tasks_delete" ON public.tasks;

-- messages
DROP POLICY IF EXISTS "Messages viewable by family" ON public.messages;
DROP POLICY IF EXISTS "Messages insertable by family" ON public.messages;
DROP POLICY IF EXISTS "Messages updatable by sender" ON public.messages;
DROP POLICY IF EXISTS "messages_select" ON public.messages;
DROP POLICY IF EXISTS "messages_insert" ON public.messages;
DROP POLICY IF EXISTS "messages_update" ON public.messages;
DROP POLICY IF EXISTS "messages_delete" ON public.messages;

-- family_moods
DROP POLICY IF EXISTS "Moods viewable by family" ON public.family_moods;
DROP POLICY IF EXISTS "Moods insertable by family" ON public.family_moods;
DROP POLICY IF EXISTS "family_moods_select" ON public.family_moods;
DROP POLICY IF EXISTS "family_moods_insert" ON public.family_moods;
DROP POLICY IF EXISTS "family_moods_update" ON public.family_moods;
DROP POLICY IF EXISTS "family_moods_delete" ON public.family_moods;

-- shopping_items
DROP POLICY IF EXISTS "Shopping viewable by family" ON public.shopping_items;
DROP POLICY IF EXISTS "Shopping insertable by family" ON public.shopping_items;
DROP POLICY IF EXISTS "Shopping updatable by family" ON public.shopping_items;
DROP POLICY IF EXISTS "Shopping deletable by family" ON public.shopping_items;
DROP POLICY IF EXISTS "shopping_items_select" ON public.shopping_items;
DROP POLICY IF EXISTS "shopping_items_insert" ON public.shopping_items;
DROP POLICY IF EXISTS "shopping_items_update" ON public.shopping_items;
DROP POLICY IF EXISTS "shopping_items_delete" ON public.shopping_items;

-- family_contacts
DROP POLICY IF EXISTS "Contacts viewable by family" ON public.family_contacts;
DROP POLICY IF EXISTS "Contacts insertable by family" ON public.family_contacts;
DROP POLICY IF EXISTS "Contacts updatable by family" ON public.family_contacts;
DROP POLICY IF EXISTS "Contacts deletable by family" ON public.family_contacts;
DROP POLICY IF EXISTS "family_contacts_select" ON public.family_contacts;
DROP POLICY IF EXISTS "family_contacts_insert" ON public.family_contacts;
DROP POLICY IF EXISTS "family_contacts_update" ON public.family_contacts;
DROP POLICY IF EXISTS "family_contacts_delete" ON public.family_contacts;

-- family_media
DROP POLICY IF EXISTS "Media viewable by family" ON public.family_media;
DROP POLICY IF EXISTS "Media insertable by family" ON public.family_media;
DROP POLICY IF EXISTS "family_media_select" ON public.family_media;
DROP POLICY IF EXISTS "family_media_insert" ON public.family_media;
DROP POLICY IF EXISTS "family_media_update" ON public.family_media;
DROP POLICY IF EXISTS "family_media_delete" ON public.family_media;

-- family_documents
DROP POLICY IF EXISTS "Documents viewable by family" ON public.family_documents;
DROP POLICY IF EXISTS "Documents insertable by family" ON public.family_documents;
DROP POLICY IF EXISTS "Documents updatable by uploader" ON public.family_documents;
DROP POLICY IF EXISTS "family_documents_select" ON public.family_documents;
DROP POLICY IF EXISTS "family_documents_insert" ON public.family_documents;
DROP POLICY IF EXISTS "family_documents_update" ON public.family_documents;
DROP POLICY IF EXISTS "family_documents_delete" ON public.family_documents;

-- safe_zones
DROP POLICY IF EXISTS "Safe zones viewable by family" ON public.safe_zones;
DROP POLICY IF EXISTS "Safe zones insertable by family" ON public.safe_zones;
DROP POLICY IF EXISTS "Safe zones updatable by family" ON public.safe_zones;
DROP POLICY IF EXISTS "Safe zones deletable by family" ON public.safe_zones;
DROP POLICY IF EXISTS "safe_zones_select" ON public.safe_zones;
DROP POLICY IF EXISTS "safe_zones_insert" ON public.safe_zones;
DROP POLICY IF EXISTS "safe_zones_update" ON public.safe_zones;
DROP POLICY IF EXISTS "safe_zones_delete" ON public.safe_zones;

-- child_accounts
DROP POLICY IF EXISTS "Child accounts viewable by family" ON public.child_accounts;
DROP POLICY IF EXISTS "Child accounts insertable by family" ON public.child_accounts;
DROP POLICY IF EXISTS "child_accounts_select" ON public.child_accounts;
DROP POLICY IF EXISTS "child_accounts_insert" ON public.child_accounts;
DROP POLICY IF EXISTS "child_accounts_update" ON public.child_accounts;
DROP POLICY IF EXISTS "child_accounts_delete" ON public.child_accounts;

-- ai_suggestions_cache
DROP POLICY IF EXISTS "AI suggestions viewable by family" ON public.ai_suggestions_cache;
DROP POLICY IF EXISTS "AI suggestions insertable by family" ON public.ai_suggestions_cache;
DROP POLICY IF EXISTS "ai_suggestions_select" ON public.ai_suggestions_cache;
DROP POLICY IF EXISTS "ai_suggestions_insert" ON public.ai_suggestions_cache;
DROP POLICY IF EXISTS "ai_suggestions_update" ON public.ai_suggestions_cache;
DROP POLICY IF EXISTS "ai_suggestions_delete" ON public.ai_suggestions_cache;

-- weather_cache
DROP POLICY IF EXISTS "Weather viewable by family" ON public.weather_cache;
DROP POLICY IF EXISTS "weather_cache_select" ON public.weather_cache;
DROP POLICY IF EXISTS "weather_cache_insert" ON public.weather_cache;

-- crash_events
CREATE TABLE IF NOT EXISTS public.crash_events (
  id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  family_id uuid REFERENCES public.families(id) ON DELETE CASCADE,
  user_id uuid REFERENCES public.profiles(id) ON DELETE SET NULL,
  error_message text,
  stack_trace text,
  app_version text,
  device_info text,
  created_at timestamptz DEFAULT now()
);
DROP POLICY IF EXISTS "Crash events viewable by family" ON public.crash_events;
DROP POLICY IF EXISTS "crash_events_select" ON public.crash_events;
DROP POLICY IF EXISTS "crash_events_insert" ON public.crash_events;

-- =============================================================================
-- PHASE 2: CREATE CLEAN POLICIES
-- =============================================================================

-- -----------------------------------------------------------------------------
-- PROFILES
-- -----------------------------------------------------------------------------
CREATE POLICY "profiles_select_all"
  ON public.profiles FOR SELECT TO authenticated
  USING (true);

CREATE POLICY "profiles_update_own"
  ON public.profiles FOR UPDATE TO authenticated
  USING (id = auth.uid())
  WITH CHECK (id = auth.uid());

-- -----------------------------------------------------------------------------
-- FAMILIES
-- -----------------------------------------------------------------------------
CREATE POLICY "families_select"
  ON public.families FOR SELECT TO authenticated
  USING (
    id IN (SELECT family_id FROM public.profiles WHERE id = auth.uid() AND family_id IS NOT NULL)
  );

CREATE POLICY "families_insert"
  ON public.families FOR INSERT TO authenticated
  WITH CHECK (true);

CREATE POLICY "families_update"
  ON public.families FOR UPDATE TO authenticated
  USING (
    id IN (SELECT family_id FROM public.profiles WHERE id = auth.uid() AND family_id IS NOT NULL)
  );

-- -----------------------------------------------------------------------------
-- FAMILY_MEMBERS  (CRITICAL - the root cause of 0/0/0/0 data)
-- -----------------------------------------------------------------------------
CREATE POLICY "family_members_select_self"
  ON public.family_members FOR SELECT TO authenticated
  USING (user_id = auth.uid());

CREATE POLICY "family_members_select_by_family"
  ON public.family_members FOR SELECT TO authenticated
  USING (
    family_id IN (SELECT family_id FROM public.profiles WHERE id = auth.uid() AND family_id IS NOT NULL)
  );

CREATE POLICY "family_members_insert"
  ON public.family_members FOR INSERT TO authenticated
  WITH CHECK (
    family_id IN (SELECT family_id FROM public.profiles WHERE id = auth.uid() AND family_id IS NOT NULL)
    OR user_id = auth.uid()
  );

CREATE POLICY "family_members_update"
  ON public.family_members FOR UPDATE TO authenticated
  USING (
    family_id IN (SELECT family_id FROM public.profiles WHERE id = auth.uid() AND family_id IS NOT NULL)
  );

-- -----------------------------------------------------------------------------
-- EVENTS
-- -----------------------------------------------------------------------------
CREATE POLICY "events_select"
  ON public.events FOR SELECT TO authenticated
  USING (
    family_id IN (SELECT family_id FROM public.profiles WHERE id = auth.uid() AND family_id IS NOT NULL)
  );

CREATE POLICY "events_insert"
  ON public.events FOR INSERT TO authenticated
  WITH CHECK (
    family_id IN (SELECT family_id FROM public.profiles WHERE id = auth.uid() AND family_id IS NOT NULL)
  );

CREATE POLICY "events_update"
  ON public.events FOR UPDATE TO authenticated
  USING (
    family_id IN (SELECT family_id FROM public.profiles WHERE id = auth.uid() AND family_id IS NOT NULL)
  );

CREATE POLICY "events_delete"
  ON public.events FOR DELETE TO authenticated
  USING (
    family_id IN (SELECT family_id FROM public.profiles WHERE id = auth.uid() AND family_id IS NOT NULL)
  );

-- -----------------------------------------------------------------------------
-- TASKS
-- -----------------------------------------------------------------------------
CREATE POLICY "tasks_select"
  ON public.tasks FOR SELECT TO authenticated
  USING (
    family_id IN (SELECT family_id FROM public.profiles WHERE id = auth.uid() AND family_id IS NOT NULL)
  );

CREATE POLICY "tasks_insert"
  ON public.tasks FOR INSERT TO authenticated
  WITH CHECK (
    family_id IN (SELECT family_id FROM public.profiles WHERE id = auth.uid() AND family_id IS NOT NULL)
  );

CREATE POLICY "tasks_update"
  ON public.tasks FOR UPDATE TO authenticated
  USING (
    family_id IN (SELECT family_id FROM public.profiles WHERE id = auth.uid() AND family_id IS NOT NULL)
  );

CREATE POLICY "tasks_delete"
  ON public.tasks FOR DELETE TO authenticated
  USING (
    family_id IN (SELECT family_id FROM public.profiles WHERE id = auth.uid() AND family_id IS NOT NULL)
  );

-- -----------------------------------------------------------------------------
-- MESSAGES
-- -----------------------------------------------------------------------------
CREATE POLICY "messages_select"
  ON public.messages FOR SELECT TO authenticated
  USING (
    family_id IN (SELECT family_id FROM public.profiles WHERE id = auth.uid() AND family_id IS NOT NULL)
  );

CREATE POLICY "messages_insert"
  ON public.messages FOR INSERT TO authenticated
  WITH CHECK (
    family_id IN (SELECT family_id FROM public.profiles WHERE id = auth.uid() AND family_id IS NOT NULL)
  );

CREATE POLICY "messages_update"
  ON public.messages FOR UPDATE TO authenticated
  USING (user_id = auth.uid());

CREATE POLICY "messages_delete"
  ON public.messages FOR DELETE TO authenticated
  USING (user_id = auth.uid());

-- -----------------------------------------------------------------------------
-- FAMILY_MOODS
-- -----------------------------------------------------------------------------
CREATE POLICY "family_moods_select"
  ON public.family_moods FOR SELECT TO authenticated
  USING (
    family_id IN (SELECT family_id FROM public.profiles WHERE id = auth.uid() AND family_id IS NOT NULL)
  );

CREATE POLICY "family_moods_insert"
  ON public.family_moods FOR INSERT TO authenticated
  WITH CHECK (
    family_id IN (SELECT family_id FROM public.profiles WHERE id = auth.uid() AND family_id IS NOT NULL)
  );

CREATE POLICY "family_moods_update"
  ON public.family_moods FOR UPDATE TO authenticated
  USING (user_id = auth.uid());

CREATE POLICY "family_moods_delete"
  ON public.family_moods FOR DELETE TO authenticated
  USING (user_id = auth.uid());

-- -----------------------------------------------------------------------------
-- SHOPPING_ITEMS
-- -----------------------------------------------------------------------------
CREATE POLICY "shopping_items_select"
  ON public.shopping_items FOR SELECT TO authenticated
  USING (
    family_id IN (SELECT family_id FROM public.profiles WHERE id = auth.uid() AND family_id IS NOT NULL)
  );

CREATE POLICY "shopping_items_insert"
  ON public.shopping_items FOR INSERT TO authenticated
  WITH CHECK (
    family_id IN (SELECT family_id FROM public.profiles WHERE id = auth.uid() AND family_id IS NOT NULL)
  );

CREATE POLICY "shopping_items_update"
  ON public.shopping_items FOR UPDATE TO authenticated
  USING (
    family_id IN (SELECT family_id FROM public.profiles WHERE id = auth.uid() AND family_id IS NOT NULL)
  );

CREATE POLICY "shopping_items_delete"
  ON public.shopping_items FOR DELETE TO authenticated
  USING (
    family_id IN (SELECT family_id FROM public.profiles WHERE id = auth.uid() AND family_id IS NOT NULL)
  );

-- -----------------------------------------------------------------------------
-- FAMILY_CONTACTS
-- -----------------------------------------------------------------------------
CREATE POLICY "family_contacts_select"
  ON public.family_contacts FOR SELECT TO authenticated
  USING (
    family_id IN (SELECT family_id FROM public.profiles WHERE id = auth.uid() AND family_id IS NOT NULL)
  );

CREATE POLICY "family_contacts_insert"
  ON public.family_contacts FOR INSERT TO authenticated
  WITH CHECK (
    family_id IN (SELECT family_id FROM public.profiles WHERE id = auth.uid() AND family_id IS NOT NULL)
  );

CREATE POLICY "family_contacts_update"
  ON public.family_contacts FOR UPDATE TO authenticated
  USING (
    family_id IN (SELECT family_id FROM public.profiles WHERE id = auth.uid() AND family_id IS NOT NULL)
  );

CREATE POLICY "family_contacts_delete"
  ON public.family_contacts FOR DELETE TO authenticated
  USING (
    family_id IN (SELECT family_id FROM public.profiles WHERE id = auth.uid() AND family_id IS NOT NULL)
  );

-- -----------------------------------------------------------------------------
-- FAMILY_MEDIA
-- -----------------------------------------------------------------------------
CREATE POLICY "family_media_select"
  ON public.family_media FOR SELECT TO authenticated
  USING (
    family_id IN (SELECT family_id FROM public.profiles WHERE id = auth.uid() AND family_id IS NOT NULL)
  );

CREATE POLICY "family_media_insert"
  ON public.family_media FOR INSERT TO authenticated
  WITH CHECK (
    family_id IN (SELECT family_id FROM public.profiles WHERE id = auth.uid() AND family_id IS NOT NULL)
  );

-- -----------------------------------------------------------------------------
-- FAMILY_DOCUMENTS
-- -----------------------------------------------------------------------------
CREATE POLICY "family_documents_select"
  ON public.family_documents FOR SELECT TO authenticated
  USING (
    family_id IN (SELECT family_id FROM public.profiles WHERE id = auth.uid() AND family_id IS NOT NULL)
  );

CREATE POLICY "family_documents_insert"
  ON public.family_documents FOR INSERT TO authenticated
  WITH CHECK (
    family_id IN (SELECT family_id FROM public.profiles WHERE id = auth.uid() AND family_id IS NOT NULL)
  );

CREATE POLICY "family_documents_update"
  ON public.family_documents FOR UPDATE TO authenticated
  USING (
    family_id IN (SELECT family_id FROM public.profiles WHERE id = auth.uid() AND family_id IS NOT NULL)
  );

CREATE POLICY "family_documents_delete"
  ON public.family_documents FOR DELETE TO authenticated
  USING (
    family_id IN (SELECT family_id FROM public.profiles WHERE id = auth.uid() AND family_id IS NOT NULL)
  );

-- -----------------------------------------------------------------------------
-- SAFE_ZONES
-- -----------------------------------------------------------------------------
CREATE POLICY "safe_zones_select"
  ON public.safe_zones FOR SELECT TO authenticated
  USING (
    family_id IN (SELECT family_id FROM public.profiles WHERE id = auth.uid() AND family_id IS NOT NULL)
  );

CREATE POLICY "safe_zones_insert"
  ON public.safe_zones FOR INSERT TO authenticated
  WITH CHECK (
    family_id IN (SELECT family_id FROM public.profiles WHERE id = auth.uid() AND family_id IS NOT NULL)
  );

CREATE POLICY "safe_zones_update"
  ON public.safe_zones FOR UPDATE TO authenticated
  USING (
    family_id IN (SELECT family_id FROM public.profiles WHERE id = auth.uid() AND family_id IS NOT NULL)
  );

CREATE POLICY "safe_zones_delete"
  ON public.safe_zones FOR DELETE TO authenticated
  USING (
    family_id IN (SELECT family_id FROM public.profiles WHERE id = auth.uid() AND family_id IS NOT NULL)
  );

-- -----------------------------------------------------------------------------
-- CHILD_ACCOUNTS
-- -----------------------------------------------------------------------------
CREATE POLICY "child_accounts_select"
  ON public.child_accounts FOR SELECT TO authenticated
  USING (
    family_id IN (SELECT family_id FROM public.profiles WHERE id = auth.uid() AND family_id IS NOT NULL)
  );

CREATE POLICY "child_accounts_insert"
  ON public.child_accounts FOR INSERT TO authenticated
  WITH CHECK (
    family_id IN (SELECT family_id FROM public.profiles WHERE id = auth.uid() AND family_id IS NOT NULL)
  );

CREATE POLICY "child_accounts_update"
  ON public.child_accounts FOR UPDATE TO authenticated
  USING (
    family_id IN (SELECT family_id FROM public.profiles WHERE id = auth.uid() AND family_id IS NOT NULL)
  );

CREATE POLICY "child_accounts_delete"
  ON public.child_accounts FOR DELETE TO authenticated
  USING (
    family_id IN (SELECT family_id FROM public.profiles WHERE id = auth.uid() AND family_id IS NOT NULL)
  );

-- -----------------------------------------------------------------------------
-- AI_SUGGESTIONS_CACHE
-- -----------------------------------------------------------------------------
CREATE POLICY "ai_suggestions_select"
  ON public.ai_suggestions_cache FOR SELECT TO authenticated
  USING (
    family_id IN (SELECT family_id FROM public.profiles WHERE id = auth.uid() AND family_id IS NOT NULL)
  );

CREATE POLICY "ai_suggestions_insert"
  ON public.ai_suggestions_cache FOR INSERT TO authenticated
  WITH CHECK (
    family_id IN (SELECT family_id FROM public.profiles WHERE id = auth.uid() AND family_id IS NOT NULL)
  );

-- -----------------------------------------------------------------------------
-- WEATHER_CACHE
-- -----------------------------------------------------------------------------
CREATE POLICY "weather_cache_select"
  ON public.weather_cache FOR SELECT TO authenticated
  USING (
    family_id IN (SELECT family_id FROM public.profiles WHERE id = auth.uid() AND family_id IS NOT NULL)
  );

CREATE POLICY "weather_cache_insert"
  ON public.weather_cache FOR INSERT TO authenticated
  WITH CHECK (
    family_id IN (SELECT family_id FROM public.profiles WHERE id = auth.uid() AND family_id IS NOT NULL)
  );

-- -----------------------------------------------------------------------------
-- CRASH_EVENTS
-- -----------------------------------------------------------------------------
CREATE POLICY "crash_events_select"
  ON public.crash_events FOR SELECT TO authenticated
  USING (
    family_id IN (SELECT family_id FROM public.profiles WHERE id = auth.uid() AND family_id IS NOT NULL)
  );

CREATE POLICY "crash_events_insert"
  ON public.crash_events FOR INSERT TO authenticated
  WITH CHECK (
    family_id IN (SELECT family_id FROM public.profiles WHERE id = auth.uid() AND family_id IS NOT NULL)
  );

-- =============================================================================
-- PHASE 3: ENABLE RLS ON TABLES (if not already enabled)
-- =============================================================================
ALTER TABLE IF EXISTS public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.families ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.family_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.events ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.tasks ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.family_moods ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.shopping_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.family_contacts ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.family_media ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.family_documents ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.safe_zones ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.child_accounts ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.ai_suggestions_cache ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.weather_cache ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.crash_events ENABLE ROW LEVEL SECURITY;

-- =============================================================================
-- PHASE 4: FORCE POLICY RELOAD (Supabase cache clear)
-- =============================================================================
NOTIFY pgrst, 'reload schema';

-- ============================================
-- RLS POLICY FIX TAMAMLANDI
-- Tum tablolar icin policyler yeniden olusturuldu.
-- Lutfen uygulamayi tamamen kapatip yeniden acin.
-- ============================================
