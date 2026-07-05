-- ============================================
-- 058: Fix Missing Tables and Columns
-- ============================================
-- Tables used in the app but missing from migrations:
--   1. activity_log          (app uses 'activity_log', migrations created 'activity_logs')
--   2. weather_prefs         (WeatherPrefsService)
--   3. location_segments     (BatteryAwareLocationTracker)
--   4. premium_subscriptions (PaymentService)
--   5. rotation_rules        (SmartRotationScreen)
-- Column fixes:
--   6. ai_suggestions_cache  (missing 'provider' column; upsert needs conflict target)
--   7. profiles              (payment_service updates 'is_premium', 'subscription_tier')

-- ============================================
-- 1. activity_log (app queries this name, not activity_logs)
-- ============================================
CREATE TABLE IF NOT EXISTS public.activity_log (
  id          uuid         DEFAULT gen_random_uuid() PRIMARY KEY,
  family_id   uuid         REFERENCES public.families(id) ON DELETE CASCADE,
  user_id     uuid         REFERENCES public.profiles(id) ON DELETE SET NULL,
  actor_name  text,
  actor_color text         DEFAULT '#6366F1',
  action      text         NOT NULL,
  target      text,
  created_at  timestamptz  DEFAULT now()
);

ALTER TABLE public.activity_log ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "activity_log_select" ON public.activity_log;
CREATE POLICY "activity_log_select"
  ON public.activity_log FOR SELECT
  TO authenticated
  USING (
    family_id IN (
      SELECT family_id FROM public.family_members WHERE user_id = auth.uid()
    )
  );

DROP POLICY IF EXISTS "activity_log_insert" ON public.activity_log;
CREATE POLICY "activity_log_insert"
  ON public.activity_log FOR INSERT
  TO authenticated
  WITH CHECK (
    family_id IN (
      SELECT family_id FROM public.family_members WHERE user_id = auth.uid()
    )
  );

CREATE INDEX IF NOT EXISTS idx_activity_log_family_time
  ON public.activity_log(family_id, created_at DESC);

-- ============================================
-- 2. weather_prefs
-- ============================================
CREATE TABLE IF NOT EXISTS public.weather_prefs (
  id          uuid         DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id     uuid         REFERENCES public.profiles(id) ON DELETE CASCADE UNIQUE,
  city        text,
  unit        text         DEFAULT 'celsius' CHECK (unit IN ('celsius', 'fahrenheit')),
  updated_at  timestamptz  DEFAULT now()
);

ALTER TABLE public.weather_prefs ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "weather_prefs_select" ON public.weather_prefs;
CREATE POLICY "weather_prefs_select"
  ON public.weather_prefs FOR SELECT
  TO authenticated
  USING (user_id = auth.uid());

DROP POLICY IF EXISTS "weather_prefs_upsert" ON public.weather_prefs;
CREATE POLICY "weather_prefs_upsert"
  ON public.weather_prefs FOR INSERT
  TO authenticated
  WITH CHECK (user_id = auth.uid());

DROP POLICY IF EXISTS "weather_prefs_update" ON public.weather_prefs;
CREATE POLICY "weather_prefs_update"
  ON public.weather_prefs FOR UPDATE
  TO authenticated
  USING (user_id = auth.uid());

CREATE INDEX IF NOT EXISTS idx_weather_prefs_user
  ON public.weather_prefs(user_id);

-- ============================================
-- 3. location_segments
-- ============================================
CREATE TABLE IF NOT EXISTS public.location_segments (
  id                uuid         DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id           uuid         REFERENCES public.profiles(id) ON DELETE CASCADE,
  start_time        timestamptz  NOT NULL,
  end_time          timestamptz  NOT NULL,
  distance          numeric,
  duration_seconds  int,
  average_speed     numeric,
  max_speed         numeric,
  transport_mode    text,
  confidence        numeric,
  created_at        timestamptz  DEFAULT now()
);

ALTER TABLE public.location_segments ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "location_segments_select" ON public.location_segments;
CREATE POLICY "location_segments_select"
  ON public.location_segments FOR SELECT
  TO authenticated
  USING (user_id = auth.uid());

DROP POLICY IF EXISTS "location_segments_insert" ON public.location_segments;
CREATE POLICY "location_segments_insert"
  ON public.location_segments FOR INSERT
  TO authenticated
  WITH CHECK (user_id = auth.uid());

CREATE INDEX IF NOT EXISTS idx_location_segments_user_time
  ON public.location_segments(user_id, start_time DESC);

-- ============================================
-- 4. premium_subscriptions
-- ============================================
CREATE TABLE IF NOT EXISTS public.premium_subscriptions (
  id          uuid         DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id     uuid         REFERENCES public.profiles(id) ON DELETE CASCADE,
  tier        text         DEFAULT 'premium' CHECK (tier IN ('premium', 'family', 'pro')),
  provider    text         DEFAULT 'stripe',
  status      text         DEFAULT 'active' CHECK (status IN ('active', 'cancelled', 'expired', 'trialing')),
  expires_at  timestamptz,
  created_at  timestamptz  DEFAULT now(),
  updated_at  timestamptz  DEFAULT now()
);

ALTER TABLE public.premium_subscriptions ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "premium_subscriptions_select" ON public.premium_subscriptions;
CREATE POLICY "premium_subscriptions_select"
  ON public.premium_subscriptions FOR SELECT
  TO authenticated
  USING (user_id = auth.uid());

DROP POLICY IF EXISTS "premium_subscriptions_insert" ON public.premium_subscriptions;
CREATE POLICY "premium_subscriptions_insert"
  ON public.premium_subscriptions FOR INSERT
  TO authenticated
  WITH CHECK (user_id = auth.uid());

CREATE INDEX IF NOT EXISTS idx_premium_subscriptions_user
  ON public.premium_subscriptions(user_id, status);

-- ============================================
-- 5. rotation_rules
-- ============================================
CREATE TABLE IF NOT EXISTS public.rotation_rules (
  id              uuid    DEFAULT gen_random_uuid() PRIMARY KEY,
  family_id       uuid    REFERENCES public.families(id) ON DELETE CASCADE UNIQUE,
  equal_time      int     DEFAULT 40,
  skill_match     int     DEFAULT 20,
  energy_aware    int     DEFAULT 20,
  preference      int     DEFAULT 10,
  streak_balance  int     DEFAULT 10,
  created_at      timestamptz DEFAULT now(),
  updated_at      timestamptz DEFAULT now()
);

ALTER TABLE public.rotation_rules ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "rotation_rules_select" ON public.rotation_rules;
CREATE POLICY "rotation_rules_select"
  ON public.rotation_rules FOR SELECT
  TO authenticated
  USING (
    family_id IN (
      SELECT family_id FROM public.family_members WHERE user_id = auth.uid()
    )
  );

DROP POLICY IF EXISTS "rotation_rules_upsert" ON public.rotation_rules;
CREATE POLICY "rotation_rules_upsert"
  ON public.rotation_rules FOR ALL
  TO authenticated
  USING (
    family_id IN (
      SELECT family_id FROM public.family_members
      WHERE user_id = auth.uid() AND role IN ('admin', 'parent')
    )
  )
  WITH CHECK (
    family_id IN (
      SELECT family_id FROM public.family_members
      WHERE user_id = auth.uid() AND role IN ('admin', 'parent')
    )
  );

CREATE INDEX IF NOT EXISTS idx_rotation_rules_family
  ON public.rotation_rules(family_id);

-- ============================================
-- 6. ai_suggestions_cache: add missing columns
-- ============================================
-- Add 'provider' column (used in hub_repository cacheSuggestions)
ALTER TABLE public.ai_suggestions_cache
  ADD COLUMN IF NOT EXISTS provider    text,
  ADD COLUMN IF NOT EXISTS created_at  timestamptz DEFAULT now();

-- Add unique constraint on family_id so upsert works
-- (drop first in case a broken one already exists)
ALTER TABLE public.ai_suggestions_cache
  DROP CONSTRAINT IF EXISTS ai_suggestions_cache_family_id_key;
ALTER TABLE public.ai_suggestions_cache
  ADD CONSTRAINT ai_suggestions_cache_family_id_key UNIQUE (family_id);

-- Ensure INSERT policy exists
DROP POLICY IF EXISTS "ai_suggestions_insert" ON public.ai_suggestions_cache;
CREATE POLICY "ai_suggestions_insert"
  ON public.ai_suggestions_cache FOR INSERT
  TO authenticated
  WITH CHECK (
    family_id IN (
      SELECT family_id FROM public.family_members WHERE user_id = auth.uid()
    )
  );

DROP POLICY IF EXISTS "ai_suggestions_update" ON public.ai_suggestions_cache;
CREATE POLICY "ai_suggestions_update"
  ON public.ai_suggestions_cache FOR UPDATE
  TO authenticated
  USING (
    family_id IN (
      SELECT family_id FROM public.family_members WHERE user_id = auth.uid()
    )
  );

-- ============================================
-- 7. profiles: add columns used by payment_service
-- ============================================
ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS is_premium             boolean     DEFAULT false,
  ADD COLUMN IF NOT EXISTS subscription_tier      text        DEFAULT 'free',
  ADD COLUMN IF NOT EXISTS subscription_expires_at timestamptz;
