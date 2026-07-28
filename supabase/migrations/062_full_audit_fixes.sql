-- ============================================================
-- 062: Full Audit Fixes
-- Sorun 1-12 tüm bulgular SQL'e yansıtıldı
-- ============================================================

-- ── Sorun 1: mood_entries — emoji kolonu + CHECK kısıtı genişletme ──
ALTER TABLE public.mood_entries ADD COLUMN IF NOT EXISTS emoji text;
ALTER TABLE public.mood_entries ADD COLUMN IF NOT EXISTS mood text;
-- CHECK kısıtını güvenli blokla yeniden oluştur
DO $$
DECLARE v_con text;
BEGIN
  FOR v_con IN
    SELECT conname FROM pg_constraint
    WHERE conrelid = 'public.mood_entries'::regclass AND contype = 'c' AND conname LIKE '%mood%'
  LOOP
    EXECUTE 'ALTER TABLE public.mood_entries DROP CONSTRAINT IF EXISTS ' || quote_ident(v_con);
  END LOOP;
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conrelid = 'public.mood_entries'::regclass AND conname = 'mood_entries_mood_check'
  ) THEN
    ALTER TABLE public.mood_entries ADD CONSTRAINT mood_entries_mood_check
      CHECK (mood IN ('happy','sad','energetic','tired','stressed','calm','excited','angry') OR mood IS NULL);
  END IF;
END $$;

-- ── Sorun 2: emergency_actions — DB zaten flat kolonlarla doğru ──
--    Dart fromJson tarafı fixlendi, SQL değişikliği yok

-- ── Sorun 3: crash_events — önce tablo, sonra eksik kolonlar ──
CREATE TABLE IF NOT EXISTS public.crash_events (
  id                    uuid        DEFAULT gen_random_uuid() PRIMARY KEY,
  family_id             uuid        REFERENCES public.families(id) ON DELETE CASCADE,
  member_id             uuid,
  member_name           text,
  detection_timestamp   timestamptz NOT NULL DEFAULT now(),
  detection_confidence  numeric(3,2) NOT NULL DEFAULT 0
                        CHECK (detection_confidence BETWEEN 0 AND 1),
  trigger_type          text        NOT NULL DEFAULT 'high_impact',
  sensor_data           jsonb       NOT NULL DEFAULT '{}',
  context               jsonb       NOT NULL DEFAULT '{}',
  response_status       text        NOT NULL DEFAULT 'detected',
  confirmation_window   jsonb,
  sos_triggered         jsonb,
  notifications_sent    jsonb       DEFAULT '[]',
  outcome               jsonb,
  ml_features           jsonb,
  is_false_positive     boolean     NOT NULL DEFAULT false,
  created_at            timestamptz NOT NULL DEFAULT now(),
  resolved_at           timestamptz,
  location_lat          numeric,
  location_lng          numeric,
  confidence_score      numeric,
  status                text        DEFAULT 'detected',
  user_id               uuid        REFERENCES public.profiles(id) ON DELETE SET NULL
);

-- ÖNCE eksik kolonlar (tablo 011'den status'suz gelmis olabilir), SONRA index
ALTER TABLE public.crash_events ADD COLUMN IF NOT EXISTS location_lat     numeric;
ALTER TABLE public.crash_events ADD COLUMN IF NOT EXISTS location_lng     numeric;
ALTER TABLE public.crash_events ADD COLUMN IF NOT EXISTS confidence_score numeric;
ALTER TABLE public.crash_events ADD COLUMN IF NOT EXISTS status           text DEFAULT 'detected';
ALTER TABLE public.crash_events ADD COLUMN IF NOT EXISTS user_id          uuid REFERENCES public.profiles(id) ON DELETE SET NULL;

CREATE INDEX IF NOT EXISTS idx_crash_events_family  ON public.crash_events(family_id);
CREATE INDEX IF NOT EXISTS idx_crash_events_created ON public.crash_events(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_crash_events_status  ON public.crash_events(status);

ALTER TABLE public.crash_events ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "crash_events_family_select" ON public.crash_events;
CREATE POLICY "crash_events_family_select" ON public.crash_events FOR SELECT TO authenticated
  USING (family_id IN (SELECT family_id FROM public.family_members WHERE user_id = auth.uid()));
DROP POLICY IF EXISTS "crash_events_insert" ON public.crash_events;
CREATE POLICY "crash_events_insert" ON public.crash_events FOR INSERT TO authenticated
  WITH CHECK (true);

-- ── Sorun 4: budget_entries — RLS policy yoktu ──
DROP POLICY IF EXISTS "budget_entries_select" ON public.budget_entries;
CREATE POLICY "budget_entries_select" ON public.budget_entries FOR SELECT TO authenticated
  USING (family_id IN (SELECT family_id FROM public.family_members WHERE user_id = auth.uid()));

DROP POLICY IF EXISTS "budget_entries_insert" ON public.budget_entries;
CREATE POLICY "budget_entries_insert" ON public.budget_entries FOR INSERT TO authenticated
  WITH CHECK (family_id IN (SELECT family_id FROM public.family_members WHERE user_id = auth.uid()));

DROP POLICY IF EXISTS "budget_entries_update" ON public.budget_entries;
CREATE POLICY "budget_entries_update" ON public.budget_entries FOR UPDATE TO authenticated
  USING (family_id IN (SELECT family_id FROM public.family_members WHERE user_id = auth.uid()));

DROP POLICY IF EXISTS "budget_entries_delete" ON public.budget_entries;
CREATE POLICY "budget_entries_delete" ON public.budget_entries FOR DELETE TO authenticated
  USING (created_by = auth.uid());

-- ── Sorun 5: safe_zones — type kolonu + CHECK güvenli blok ──
DO $$
DECLARE
  v_con text;
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public' AND table_name = 'safe_zones' AND column_name = 'type'
  ) THEN
    ALTER TABLE public.safe_zones ADD COLUMN type TEXT NOT NULL DEFAULT 'custom';
  END IF;

  FOR v_con IN
    SELECT conname FROM pg_constraint
    WHERE conrelid = 'public.safe_zones'::regclass AND contype = 'c' AND conname LIKE '%type%'
  LOOP
    EXECUTE 'ALTER TABLE public.safe_zones DROP CONSTRAINT IF EXISTS ' || quote_ident(v_con);
  END LOOP;

  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conrelid = 'public.safe_zones'::regclass AND conname = 'safe_zones_type_check'
  ) THEN
    ALTER TABLE public.safe_zones ADD CONSTRAINT safe_zones_type_check
      CHECK (type IN ('home','work','school','custom','danger'));
  END IF;
END $$;

-- ── Sorun 6: tasks — UPDATE/DELETE/INSERT policy eksikti ──
DROP POLICY IF EXISTS "tasks_insert" ON public.tasks;
CREATE POLICY "tasks_insert" ON public.tasks FOR INSERT TO authenticated
  WITH CHECK (family_id IN (SELECT family_id FROM public.family_members WHERE user_id = auth.uid()));

DROP POLICY IF EXISTS "tasks_update" ON public.tasks;
CREATE POLICY "tasks_update" ON public.tasks FOR UPDATE TO authenticated
  USING (family_id IN (SELECT family_id FROM public.family_members WHERE user_id = auth.uid()));

DROP POLICY IF EXISTS "tasks_delete" ON public.tasks;
CREATE POLICY "tasks_delete" ON public.tasks FOR DELETE TO authenticated
  USING (family_id IN (SELECT family_id FROM public.family_members WHERE user_id = auth.uid()));

-- ── Sorun 7: events — UPDATE/DELETE policy eksikti ──
DROP POLICY IF EXISTS "events_update" ON public.events;
CREATE POLICY "events_update" ON public.events FOR UPDATE TO authenticated
  USING (family_id IN (SELECT family_id FROM public.family_members WHERE user_id = auth.uid()));

DROP POLICY IF EXISTS "events_delete" ON public.events;
CREATE POLICY "events_delete" ON public.events FOR DELETE TO authenticated
  USING (family_id IN (SELECT family_id FROM public.family_members WHERE user_id = auth.uid()));

-- ── Sorun 8: profiles — xp, badges, FCM push kolonları ──
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS xp     integer DEFAULT 0;
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS badges text[]  DEFAULT '{}';
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS fcm_token            text;
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS fcm_token_updated_at timestamptz;
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS cover_photo_url      text;

-- ── Sorun 9: emergency_contacts — DELETE policy ──
DROP POLICY IF EXISTS "emergency_contacts_delete" ON public.emergency_contacts;
CREATE POLICY "emergency_contacts_delete" ON public.emergency_contacts FOR DELETE TO authenticated
  USING (family_id IN (SELECT family_id FROM public.family_members WHERE user_id = auth.uid()));

-- ── Sorun 10-11: Eksik index'ler ──
CREATE INDEX IF NOT EXISTS idx_profiles_family_id        ON public.profiles(family_id);
CREATE INDEX IF NOT EXISTS idx_budget_entries_family_date ON public.budget_entries(family_id, date DESC);
CREATE INDEX IF NOT EXISTS idx_safe_zones_family          ON public.safe_zones(family_id);
CREATE INDEX IF NOT EXISTS idx_events_family_status       ON public.events(family_id, status);
CREATE INDEX IF NOT EXISTS idx_tasks_assigned             ON public.tasks(assigned_to, status);
CREATE INDEX IF NOT EXISTS idx_messages_family_created    ON public.messages(family_id, created_at DESC);

-- ── Sorun 12: families INSERT policy ──
DROP POLICY IF EXISTS "families_insert" ON public.families;
CREATE POLICY "families_insert" ON public.families FOR INSERT TO authenticated
  WITH CHECK (created_by = auth.uid());

-- ── geolocations: INSERT/UPDATE policy ──
DROP POLICY IF EXISTS "geolocations_insert" ON public.geolocations;
CREATE POLICY "geolocations_insert" ON public.geolocations FOR INSERT TO authenticated
  WITH CHECK (user_id = auth.uid());

DROP POLICY IF EXISTS "geolocations_update" ON public.geolocations;
CREATE POLICY "geolocations_update" ON public.geolocations FOR UPDATE TO authenticated
  USING (user_id = auth.uid());

-- ── messages: UPDATE/DELETE policy ──
DROP POLICY IF EXISTS "messages_update" ON public.messages;
CREATE POLICY "messages_update" ON public.messages FOR UPDATE TO authenticated
  USING (user_id = auth.uid());

DROP POLICY IF EXISTS "messages_delete" ON public.messages;
CREATE POLICY "messages_delete" ON public.messages FOR DELETE TO authenticated
  USING (user_id = auth.uid());

-- ── shopping_items: tam RLS ──
ALTER TABLE public.shopping_items ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "shopping_items_select" ON public.shopping_items;
CREATE POLICY "shopping_items_select" ON public.shopping_items FOR SELECT TO authenticated
  USING (family_id IN (SELECT family_id FROM public.family_members WHERE user_id = auth.uid()));
DROP POLICY IF EXISTS "shopping_items_insert" ON public.shopping_items;
CREATE POLICY "shopping_items_insert" ON public.shopping_items FOR INSERT TO authenticated
  WITH CHECK (family_id IN (SELECT family_id FROM public.family_members WHERE user_id = auth.uid()));
DROP POLICY IF EXISTS "shopping_items_update" ON public.shopping_items;
CREATE POLICY "shopping_items_update" ON public.shopping_items FOR UPDATE TO authenticated
  USING (family_id IN (SELECT family_id FROM public.family_members WHERE user_id = auth.uid()));
DROP POLICY IF EXISTS "shopping_items_delete" ON public.shopping_items;
CREATE POLICY "shopping_items_delete" ON public.shopping_items FOR DELETE TO authenticated
  USING (family_id IN (SELECT family_id FROM public.family_members WHERE user_id = auth.uid()));

-- ── health_cards: tam RLS ──
ALTER TABLE public.health_cards ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "health_cards_own" ON public.health_cards;
CREATE POLICY "health_cards_own" ON public.health_cards FOR ALL TO authenticated
  USING (user_id = auth.uid()) WITH CHECK (user_id = auth.uid());

-- ── sos_alerts: INSERT/UPDATE policy (sos_alerts'te user_id yok, sender_id/family_id var) ──
DROP POLICY IF EXISTS "sos_alerts_insert" ON public.sos_alerts;
CREATE POLICY "sos_alerts_insert" ON public.sos_alerts FOR INSERT TO authenticated
  WITH CHECK (family_id IN (SELECT family_id FROM public.family_members WHERE user_id = auth.uid()));
DROP POLICY IF EXISTS "sos_alerts_update" ON public.sos_alerts;
CREATE POLICY "sos_alerts_update" ON public.sos_alerts FOR UPDATE TO authenticated
  USING (family_id IN (SELECT family_id FROM public.family_members WHERE user_id = auth.uid()));

-- ── notify_family_crash — crash_events tablosu artık mevcut, INSERT ekle ──
CREATE OR REPLACE FUNCTION public.notify_family_crash(
  sender_id   uuid,
  family_id   uuid,
  latitude    numeric,
  longitude   numeric,
  confidence  numeric
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  PERFORM pg_notify(
    'family_crash_alert',
    json_build_object(
      'sender_id',  sender_id,
      'family_id',  family_id,
      'latitude',   latitude,
      'longitude',  longitude,
      'confidence', confidence,
      'timestamp',  now()
    )::text
  );

  INSERT INTO public.crash_events (
    user_id, family_id, location_lat, location_lng,
    confidence_score, status, created_at
  )
  VALUES (
    sender_id, family_id, latitude, longitude,
    confidence, 'notified', now()
  );
END;
$$;

SELECT '062 migration basarili — tum audit bulgulari fixlendi!' AS result;
