-- ============================================
-- 059: User Settings Table
-- ============================================
CREATE TABLE IF NOT EXISTS public.settings (
  id            uuid        DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id       uuid        REFERENCES public.profiles(id) ON DELETE CASCADE UNIQUE NOT NULL,
  notifications jsonb       DEFAULT '{}',
  privacy       jsonb       DEFAULT '{}',
  security      jsonb       DEFAULT '{}',
  preferences   jsonb       DEFAULT '{}',
  updated_at    timestamptz DEFAULT now()
);

ALTER TABLE public.settings ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "settings_own" ON public.settings;
CREATE POLICY "settings_own" ON public.settings FOR ALL TO authenticated
  USING (user_id = auth.uid()) WITH CHECK (user_id = auth.uid());

CREATE INDEX IF NOT EXISTS idx_settings_user ON public.settings(user_id);

-- profiles: deleteAccount için eksik kolonlar
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS is_deleted boolean     DEFAULT false;
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS deleted_at timestamptz;
