-- Migration 040: Fix remaining RLS policies that still reference family_members
-- This resolves infinite recursion for events, messages, moods, contacts, media, documents, etc.

-- Helper: all policies now use profiles.family_id instead of family_members

-- ============================================
-- 1. EVENTS
-- ============================================
DROP POLICY IF EXISTS "Events view" ON public.events;
DROP POLICY IF EXISTS "Events create" ON public.events;
DROP POLICY IF EXISTS "events_select" ON public.events;
DROP POLICY IF EXISTS "events_insert" ON public.events;
DROP POLICY IF EXISTS "events_update" ON public.events;
DROP POLICY IF EXISTS "events_delete" ON public.events;

CREATE POLICY "events_select_v2"
  ON public.events FOR SELECT TO authenticated
  USING (
    family_id IN (
      SELECT family_id FROM public.profiles
      WHERE id = auth.uid() AND family_id IS NOT NULL
    )
  );

CREATE POLICY "events_insert_v2"
  ON public.events FOR INSERT TO authenticated
  WITH CHECK (
    family_id IN (
      SELECT family_id FROM public.profiles
      WHERE id = auth.uid() AND family_id IS NOT NULL
    )
  );

CREATE POLICY "events_update_v2"
  ON public.events FOR UPDATE TO authenticated
  USING (
    family_id IN (
      SELECT family_id FROM public.profiles
      WHERE id = auth.uid() AND family_id IS NOT NULL
    )
  );

CREATE POLICY "events_delete_v2"
  ON public.events FOR DELETE TO authenticated
  USING (
    family_id IN (
      SELECT family_id FROM public.profiles
      WHERE id = auth.uid() AND family_id IS NOT NULL
    )
  );

-- ============================================
-- 2. MESSAGES
-- ============================================
DROP POLICY IF EXISTS "Messages view" ON public.messages;
DROP POLICY IF EXISTS "Messages insert" ON public.messages;
DROP POLICY IF EXISTS "messages_select" ON public.messages;
DROP POLICY IF EXISTS "messages_insert" ON public.messages;
DROP POLICY IF EXISTS "messages_update" ON public.messages;
DROP POLICY IF EXISTS "messages_delete" ON public.messages;

CREATE POLICY "messages_select_v2"
  ON public.messages FOR SELECT TO authenticated
  USING (
    family_id IN (
      SELECT family_id FROM public.profiles
      WHERE id = auth.uid() AND family_id IS NOT NULL
    )
  );

CREATE POLICY "messages_insert_v2"
  ON public.messages FOR INSERT TO authenticated
  WITH CHECK (
    family_id IN (
      SELECT family_id FROM public.profiles
      WHERE id = auth.uid() AND family_id IS NOT NULL
    )
  );

-- ============================================
-- 3. FAMILY MOODS
-- ============================================
DROP POLICY IF EXISTS "Family moods view" ON public.family_moods;
DROP POLICY IF EXISTS "Family moods insert" ON public.family_moods;
DROP POLICY IF EXISTS "Family moods update" ON public.family_moods;
DROP POLICY IF EXISTS "Family moods delete" ON public.family_moods;
DROP POLICY IF EXISTS "family_moods_select" ON public.family_moods;
DROP POLICY IF EXISTS "family_moods_insert" ON public.family_moods;
DROP POLICY IF EXISTS "family_moods_update" ON public.family_moods;
DROP POLICY IF EXISTS "family_moods_delete" ON public.family_moods;

CREATE POLICY "family_moods_select_v2"
  ON public.family_moods FOR SELECT TO authenticated
  USING (
    family_id IN (
      SELECT family_id FROM public.profiles
      WHERE id = auth.uid() AND family_id IS NOT NULL
    )
  );

CREATE POLICY "family_moods_insert_v2"
  ON public.family_moods FOR INSERT TO authenticated
  WITH CHECK (user_id = auth.uid());

CREATE POLICY "family_moods_update_v2"
  ON public.family_moods FOR UPDATE TO authenticated
  USING (user_id = auth.uid());

CREATE POLICY "family_moods_delete_v2"
  ON public.family_moods FOR DELETE TO authenticated
  USING (user_id = auth.uid());

-- ============================================
-- 4. WEATHER CACHE
-- ============================================
DROP POLICY IF EXISTS "Weather cache family" ON public.weather_cache;
DROP POLICY IF EXISTS "weather_cache_select" ON public.weather_cache;

CREATE POLICY "weather_cache_select_v2"
  ON public.weather_cache FOR SELECT TO authenticated
  USING (
    family_id IN (
      SELECT family_id FROM public.profiles
      WHERE id = auth.uid() AND family_id IS NOT NULL
    )
  );

-- ============================================
-- 5. AI SUGGESTIONS CACHE
-- ============================================
DROP POLICY IF EXISTS "AI suggestions family view" ON public.ai_suggestions_cache;
DROP POLICY IF EXISTS "ai_suggestions_select" ON public.ai_suggestions_cache;

CREATE POLICY "ai_suggestions_select_v2"
  ON public.ai_suggestions_cache FOR SELECT TO authenticated
  USING (
    family_id IN (
      SELECT family_id FROM public.profiles
      WHERE id = auth.uid() AND family_id IS NOT NULL
    )
  );

-- ============================================
-- 6. SAFE ZONES
-- ============================================
DROP POLICY IF EXISTS safe_zones_select_family ON safe_zones;
DROP POLICY IF EXISTS safe_zones_write_family ON safe_zones;
DROP POLICY IF EXISTS "safe_zones_select" ON safe_zones;
DROP POLICY IF EXISTS "safe_zones_insert" ON safe_zones;
DROP POLICY IF EXISTS "safe_zones_update" ON safe_zones;
DROP POLICY IF EXISTS "safe_zones_delete" ON safe_zones;

CREATE POLICY "safe_zones_select_v2"
  ON safe_zones FOR SELECT TO authenticated
  USING (
    family_id IN (
      SELECT family_id FROM public.profiles
      WHERE id = auth.uid() AND family_id IS NOT NULL
    )
  );

CREATE POLICY "safe_zones_write_v2"
  ON safe_zones FOR ALL TO authenticated
  USING (
    family_id IN (
      SELECT family_id FROM public.profiles
      WHERE id = auth.uid() AND family_id IS NOT NULL
    )
  );

-- ============================================
-- 7. FAMILY CONTACTS
-- ============================================
DROP POLICY IF EXISTS "Family contacts view" ON public.family_contacts;
DROP POLICY IF EXISTS "Family contacts insert" ON public.family_contacts;
DROP POLICY IF EXISTS "Family contacts update" ON public.family_contacts;
DROP POLICY IF EXISTS "Family contacts delete" ON public.family_contacts;
DROP POLICY IF EXISTS "family_contacts_select" ON public.family_contacts;
DROP POLICY IF EXISTS "family_contacts_insert" ON public.family_contacts;
DROP POLICY IF EXISTS "family_contacts_update" ON public.family_contacts;
DROP POLICY IF EXISTS "family_contacts_delete" ON public.family_contacts;

CREATE POLICY "family_contacts_select_v2"
  ON public.family_contacts FOR SELECT TO authenticated
  USING (
    family_id IN (
      SELECT family_id FROM public.profiles
      WHERE id = auth.uid() AND family_id IS NOT NULL
    )
  );

CREATE POLICY "family_contacts_insert_v2"
  ON public.family_contacts FOR INSERT TO authenticated
  WITH CHECK (
    family_id IN (
      SELECT family_id FROM public.profiles
      WHERE id = auth.uid() AND family_id IS NOT NULL
    )
  );

CREATE POLICY "family_contacts_update_v2"
  ON public.family_contacts FOR UPDATE TO authenticated
  USING (
    family_id IN (
      SELECT family_id FROM public.profiles
      WHERE id = auth.uid() AND family_id IS NOT NULL
    )
  );

CREATE POLICY "family_contacts_delete_v2"
  ON public.family_contacts FOR DELETE TO authenticated
  USING (
    family_id IN (
      SELECT family_id FROM public.profiles
      WHERE id = auth.uid() AND family_id IS NOT NULL
    )
  );

-- ============================================
-- 8. FAMILY MEDIA
-- ============================================
DROP POLICY IF EXISTS "Family media view" ON public.family_media;
DROP POLICY IF EXISTS "Family media insert" ON public.family_media;
DROP POLICY IF EXISTS "Family media delete" ON public.family_media;
DROP POLICY IF EXISTS "family_media_select" ON public.family_media;
DROP POLICY IF EXISTS "family_media_insert" ON public.family_media;
DROP POLICY IF EXISTS "family_media_update" ON public.family_media;
DROP POLICY IF EXISTS "family_media_delete" ON public.family_media;

CREATE POLICY "family_media_select_v2"
  ON public.family_media FOR SELECT TO authenticated
  USING (
    family_id IN (
      SELECT family_id FROM public.profiles
      WHERE id = auth.uid() AND family_id IS NOT NULL
    )
  );

CREATE POLICY "family_media_insert_v2"
  ON public.family_media FOR INSERT TO authenticated
  WITH CHECK (
    family_id IN (
      SELECT family_id FROM public.profiles
      WHERE id = auth.uid() AND family_id IS NOT NULL
    )
  );

CREATE POLICY "family_media_delete_v2"
  ON public.family_media FOR DELETE TO authenticated
  USING (
    uploaded_by = auth.uid()
    OR
    family_id IN (
      SELECT family_id FROM public.profiles
      WHERE id = auth.uid() AND family_id IS NOT NULL
    )
  );

-- ============================================
-- 9. FAMILY DOCUMENTS
-- ============================================
DROP POLICY IF EXISTS "Family documents view" ON public.family_documents;
DROP POLICY IF EXISTS "Family documents insert" ON public.family_documents;
DROP POLICY IF EXISTS "Family documents update" ON public.family_documents;
DROP POLICY IF EXISTS "Family documents delete" ON public.family_documents;
DROP POLICY IF EXISTS "family_documents_select" ON public.family_documents;
DROP POLICY IF EXISTS "family_documents_insert" ON public.family_documents;
DROP POLICY IF EXISTS "family_documents_update" ON public.family_documents;
DROP POLICY IF EXISTS "family_documents_delete" ON public.family_documents;

CREATE POLICY "family_documents_select_v2"
  ON public.family_documents FOR SELECT TO authenticated
  USING (
    family_id IN (
      SELECT family_id FROM public.profiles
      WHERE id = auth.uid() AND family_id IS NOT NULL
    )
  );

CREATE POLICY "family_documents_insert_v2"
  ON public.family_documents FOR INSERT TO authenticated
  WITH CHECK (
    family_id IN (
      SELECT family_id FROM public.profiles
      WHERE id = auth.uid() AND family_id IS NOT NULL
    )
  );

CREATE POLICY "family_documents_update_v2"
  ON public.family_documents FOR UPDATE TO authenticated
  USING (
    family_id IN (
      SELECT family_id FROM public.profiles
      WHERE id = auth.uid() AND family_id IS NOT NULL
    )
  );

CREATE POLICY "family_documents_delete_v2"
  ON public.family_documents FOR DELETE TO authenticated
  USING (
    uploaded_by = auth.uid()
    OR
    family_id IN (
      SELECT family_id FROM public.profiles
      WHERE id = auth.uid() AND family_id IS NOT NULL
    )
  );

-- ============================================
-- 10. SHOPPING ITEMS (if exists)
-- ============================================
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'shopping_items') THEN
    DROP POLICY IF EXISTS "Shopping items view" ON public.shopping_items;
    DROP POLICY IF EXISTS "Shopping items insert" ON public.shopping_items;
    DROP POLICY IF EXISTS "Shopping items update" ON public.shopping_items;
    DROP POLICY IF EXISTS "Shopping items delete" ON public.shopping_items;
    DROP POLICY IF EXISTS "shopping_items_select" ON public.shopping_items;
    DROP POLICY IF EXISTS "shopping_items_insert" ON public.shopping_items;
    DROP POLICY IF EXISTS "shopping_items_update" ON public.shopping_items;
    DROP POLICY IF EXISTS "shopping_items_delete" ON public.shopping_items;

    CREATE POLICY "shopping_items_select_v2"
      ON public.shopping_items FOR SELECT TO authenticated
      USING (
        family_id IN (
          SELECT family_id FROM public.profiles
          WHERE id = auth.uid() AND family_id IS NOT NULL
        )
      );

    CREATE POLICY "shopping_items_insert_v2"
      ON public.shopping_items FOR INSERT TO authenticated
      WITH CHECK (
        family_id IN (
          SELECT family_id FROM public.profiles
          WHERE id = auth.uid() AND family_id IS NOT NULL
        )
      );

    CREATE POLICY "shopping_items_update_v2"
      ON public.shopping_items FOR UPDATE TO authenticated
      USING (
        family_id IN (
          SELECT family_id FROM public.profiles
          WHERE id = auth.uid() AND family_id IS NOT NULL
        )
      );

    CREATE POLICY "shopping_items_delete_v2"
      ON public.shopping_items FOR DELETE TO authenticated
      USING (
        family_id IN (
          SELECT family_id FROM public.profiles
          WHERE id = auth.uid() AND family_id IS NOT NULL
        )
      );
  END IF;
END $$;
