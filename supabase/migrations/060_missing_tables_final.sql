-- ============================================
-- 060: Missing Tables Final
-- family_history, error_logs + routine_history RLS fix
-- ============================================

-- 1. family_history
CREATE TABLE IF NOT EXISTS public.family_history (
  id          uuid        DEFAULT gen_random_uuid() PRIMARY KEY,
  family_id   uuid        REFERENCES public.families(id) ON DELETE CASCADE NOT NULL,
  created_by  uuid        REFERENCES public.profiles(id) ON DELETE SET NULL,
  title       text        NOT NULL,
  content     text,
  event_date  timestamptz,
  type        text        DEFAULT 'memory' CHECK (type IN ('memory', 'milestone', 'photo', 'document', 'announcement')),
  photo_url   text,
  created_at  timestamptz DEFAULT now(),
  updated_at  timestamptz DEFAULT now()
);

ALTER TABLE public.family_history ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "family_history_select" ON public.family_history;
CREATE POLICY "family_history_select" ON public.family_history FOR SELECT TO authenticated
  USING (family_id IN (SELECT family_id FROM public.family_members WHERE user_id = auth.uid()));

DROP POLICY IF EXISTS "family_history_insert" ON public.family_history;
CREATE POLICY "family_history_insert" ON public.family_history FOR INSERT TO authenticated
  WITH CHECK (family_id IN (SELECT family_id FROM public.family_members WHERE user_id = auth.uid()));

DROP POLICY IF EXISTS "family_history_update" ON public.family_history;
CREATE POLICY "family_history_update" ON public.family_history FOR UPDATE TO authenticated
  USING (created_by = auth.uid());

DROP POLICY IF EXISTS "family_history_delete" ON public.family_history;
CREATE POLICY "family_history_delete" ON public.family_history FOR DELETE TO authenticated
  USING (created_by = auth.uid() OR family_id IN (
    SELECT family_id FROM public.family_members WHERE user_id = auth.uid() AND role IN ('admin', 'parent')
  ));

CREATE INDEX IF NOT EXISTS idx_family_history_family ON public.family_history(family_id, event_date DESC);

-- 2. error_logs
CREATE TABLE IF NOT EXISTS public.error_logs (
  id          uuid        DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id     uuid        REFERENCES public.profiles(id) ON DELETE SET NULL,
  error       text        NOT NULL,
  stack       text,
  source      text,
  app_version text,
  timestamp   timestamptz DEFAULT now()
);

ALTER TABLE public.error_logs ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "error_logs_insert" ON public.error_logs;
CREATE POLICY "error_logs_insert" ON public.error_logs FOR INSERT TO authenticated
  WITH CHECK (true);

DROP POLICY IF EXISTS "error_logs_own_select" ON public.error_logs;
CREATE POLICY "error_logs_own_select" ON public.error_logs FOR SELECT TO authenticated
  USING (user_id = auth.uid());

CREATE INDEX IF NOT EXISTS idx_error_logs_user ON public.error_logs(user_id, timestamp DESC);

-- 3a. routines (routine_history FK için gerekli)
CREATE TABLE IF NOT EXISTS public.routines (
  id          uuid        DEFAULT gen_random_uuid() PRIMARY KEY,
  family_id   uuid        NOT NULL REFERENCES public.families(id) ON DELETE CASCADE,
  title       text        NOT NULL,
  description text,
  category    text        DEFAULT 'chore',
  frequency   text        DEFAULT 'daily',
  assigned_to uuid[]      DEFAULT '{}',
  is_active   boolean     DEFAULT true,
  created_by  uuid        REFERENCES public.profiles(id) ON DELETE SET NULL,
  created_at  timestamptz DEFAULT now(),
  updated_at  timestamptz DEFAULT now()
);

-- 010'dan gelen kolonlar eksikse ekle
ALTER TABLE public.routines ADD COLUMN IF NOT EXISTS name        text;
ALTER TABLE public.routines ADD COLUMN IF NOT EXISTS type        text        NOT NULL DEFAULT 'morning';
ALTER TABLE public.routines ADD COLUMN IF NOT EXISTS icon        text        DEFAULT 'sunrise';
ALTER TABLE public.routines ADD COLUMN IF NOT EXISTS color       text        DEFAULT '#FF9800';
ALTER TABLE public.routines ADD COLUMN IF NOT EXISTS trigger     jsonb       DEFAULT '{}';
ALTER TABLE public.routines ADD COLUMN IF NOT EXISTS steps       jsonb       DEFAULT '[]';
ALTER TABLE public.routines ADD COLUMN IF NOT EXISTS status      jsonb       DEFAULT '{"state":"scheduled","progress":0,"current_step":0}';
ALTER TABLE public.routines ADD COLUMN IF NOT EXISTS recurrence  jsonb       DEFAULT '{"enabled":false,"pattern":"daily"}';
ALTER TABLE public.routines ADD COLUMN IF NOT EXISTS participants jsonb      DEFAULT '[]';
ALTER TABLE public.routines ADD COLUMN IF NOT EXISTS ai_profile  jsonb       DEFAULT '{}';
ALTER TABLE public.routines ADD COLUMN IF NOT EXISTS is_template boolean     DEFAULT false;
ALTER TABLE public.routines ADD COLUMN IF NOT EXISTS version     integer     DEFAULT 1;

ALTER TABLE public.routines ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "routines_select" ON public.routines;
CREATE POLICY "routines_select" ON public.routines FOR SELECT TO authenticated
  USING (family_id IN (SELECT family_id FROM public.family_members WHERE user_id = auth.uid()));

DROP POLICY IF EXISTS "routines_insert" ON public.routines;
CREATE POLICY "routines_insert" ON public.routines FOR INSERT TO authenticated
  WITH CHECK (family_id IN (SELECT family_id FROM public.family_members WHERE user_id = auth.uid()));

DROP POLICY IF EXISTS "routines_update" ON public.routines;
CREATE POLICY "routines_update" ON public.routines FOR UPDATE TO authenticated
  USING (family_id IN (SELECT family_id FROM public.family_members WHERE user_id = auth.uid()));

DROP POLICY IF EXISTS "routines_delete" ON public.routines;
CREATE POLICY "routines_delete" ON public.routines FOR DELETE TO authenticated
  USING (created_by = auth.uid());

-- 3b. routine_history (tablo varsa INSERT policy ekle, yoksa olustur)
CREATE TABLE IF NOT EXISTS public.routine_history (
  id          uuid        DEFAULT gen_random_uuid() PRIMARY KEY,
  routine_id  uuid        NOT NULL REFERENCES public.routines(id) ON DELETE CASCADE,
  family_id   uuid        NOT NULL REFERENCES public.families(id) ON DELETE CASCADE,
  completed_by uuid       REFERENCES public.profiles(id) ON DELETE SET NULL,
  note        text,
  completed_at timestamptz DEFAULT now(),
  created_at  timestamptz DEFAULT now()
);

ALTER TABLE public.routine_history ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "routine_history_select" ON public.routine_history;
CREATE POLICY "routine_history_select" ON public.routine_history FOR SELECT TO authenticated
  USING (family_id IN (SELECT family_id FROM public.family_members WHERE user_id = auth.uid()));

DROP POLICY IF EXISTS "routine_history_insert" ON public.routine_history;
CREATE POLICY "routine_history_insert" ON public.routine_history FOR INSERT TO authenticated
  WITH CHECK (family_id IN (SELECT family_id FROM public.family_members WHERE user_id = auth.uid()));

-- 4. families: upsert için missing INSERT policy
DROP POLICY IF EXISTS "families_insert" ON public.families;
CREATE POLICY "families_insert" ON public.families FOR INSERT TO authenticated
  WITH CHECK (created_by = auth.uid());

-- 5. profiles: INSERT policy (trigger dışında direkt insert için)
DROP POLICY IF EXISTS "profiles_insert" ON public.profiles;
CREATE POLICY "profiles_insert" ON public.profiles FOR INSERT TO authenticated
  WITH CHECK (id = auth.uid());

SELECT 'Migration 060 basarili!' AS result;
