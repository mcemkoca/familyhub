-- Auto Routine Builder Migration
-- Tables: routines, routine_templates, routine_history, routine_suggestions

-- ── ROUTINES ───────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS routines (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  family_id UUID NOT NULL REFERENCES families(id) ON DELETE CASCADE,
  created_by UUID REFERENCES profiles(id) ON DELETE SET NULL,
  name TEXT NOT NULL,
  description TEXT,
  icon TEXT DEFAULT 'sunrise',
  color TEXT DEFAULT '#FF9800',
  type TEXT NOT NULL DEFAULT 'morning',
  trigger JSONB NOT NULL DEFAULT '{}',
  steps JSONB NOT NULL DEFAULT '[]',
  status JSONB NOT NULL DEFAULT '{"state": "scheduled", "progress": 0, "current_step": 0}',
  recurrence JSONB NOT NULL DEFAULT '{"enabled": false, "pattern": "daily"}',
  participants JSONB NOT NULL DEFAULT '[]',
  ai_profile JSONB NOT NULL DEFAULT '{}',
  is_template BOOLEAN DEFAULT false,
  template_id UUID REFERENCES routines(id) ON DELETE SET NULL,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now(),
  version INTEGER DEFAULT 1
);

COMMENT ON TABLE routines IS 'Auto routine builder: morning/evening/weekly/custom routines';

ALTER TABLE IF EXISTS routines ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "family_members_can_view_routines" ON routines;
CREATE POLICY "family_members_can_view_routines"
  ON routines FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM family_members fm
      WHERE fm.family_id = routines.family_id
      AND fm.user_id = auth.uid()
    )
  );

DROP POLICY IF EXISTS "family_members_can_create_routines" ON routines;
CREATE POLICY "family_members_can_create_routines"
  ON routines FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM family_members fm
      WHERE fm.family_id = routines.family_id
      AND fm.user_id = auth.uid()
    )
  );

DROP POLICY IF EXISTS "creators_can_update_routines" ON routines;
CREATE POLICY "creators_can_update_routines"
  ON routines FOR UPDATE
  USING (created_by = auth.uid())
  WITH CHECK (created_by = auth.uid());

DROP POLICY IF EXISTS "creators_can_delete_routines" ON routines;
CREATE POLICY "creators_can_delete_routines"
  ON routines FOR DELETE
  USING (created_by = auth.uid());

CREATE INDEX IF NOT EXISTS idx_routines_family ON routines(family_id);
CREATE INDEX IF NOT EXISTS idx_routines_type ON routines(type);

-- ── ROUTINE TEMPLATES ──────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS routine_templates (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  description TEXT,
  category TEXT DEFAULT 'family',
  difficulty TEXT DEFAULT 'medium',
  estimated_total_duration INTEGER DEFAULT 30,
  steps JSONB NOT NULL DEFAULT '[]',
  suitability JSONB NOT NULL DEFAULT '{}',
  usage_count INTEGER DEFAULT 0,
  average_rating NUMERIC DEFAULT 0,
  user_reviews JSONB NOT NULL DEFAULT '[]',
  created_at TIMESTAMPTZ DEFAULT now()
);

COMMENT ON TABLE routine_templates IS 'Pre-built routine templates';

-- Public read access for templates
ALTER TABLE IF EXISTS routine_templates ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "anyone_can_view_templates" ON routine_templates;
CREATE POLICY "anyone_can_view_templates"
  ON routine_templates FOR SELECT
  TO authenticated
  USING (true);

-- ── ROUTINE HISTORY ────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS routine_history (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  routine_id UUID NOT NULL REFERENCES routines(id) ON DELETE CASCADE,
  family_id UUID NOT NULL REFERENCES families(id) ON DELETE CASCADE,
  date TIMESTAMPTZ DEFAULT now(),
  execution JSONB NOT NULL DEFAULT '{}',
  steps JSONB NOT NULL DEFAULT '[]',
  feedback JSONB,
  context JSONB,
  created_at TIMESTAMPTZ DEFAULT now()
);

ALTER TABLE IF EXISTS routine_history ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "family_members_can_view_history" ON routine_history;
CREATE POLICY "family_members_can_view_history"
  ON routine_history FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM family_members fm
      WHERE fm.family_id = routine_history.family_id
      AND fm.user_id = auth.uid()
    )
  );

CREATE INDEX IF NOT EXISTS idx_routine_history_routine ON routine_history(routine_id);
CREATE INDEX IF NOT EXISTS idx_routine_history_family ON routine_history(family_id);

-- ── ROUTINE SUGGESTIONS ────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS routine_suggestions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  family_id UUID NOT NULL REFERENCES families(id) ON DELETE CASCADE,
  type TEXT DEFAULT 'new_routine',
  reason TEXT,
  confidence NUMERIC DEFAULT 0,
  based_on JSONB NOT NULL DEFAULT '[]',
  suggested_routine JSONB,
  status TEXT DEFAULT 'pending',
  created_at TIMESTAMPTZ DEFAULT now()
);

ALTER TABLE IF EXISTS routine_suggestions ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "family_members_can_view_suggestions" ON routine_suggestions;
CREATE POLICY "family_members_can_view_suggestions"
  ON routine_suggestions FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM family_members fm
      WHERE fm.family_id = routine_suggestions.family_id
      AND fm.user_id = auth.uid()
    )
  );

CREATE INDEX IF NOT EXISTS idx_routine_suggestions_family ON routine_suggestions(family_id);

-- ── UPDATE TRIGGER ─────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION update_routines_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_routines_updated_at ON routines;
CREATE TRIGGER trg_routines_updated_at
  BEFORE UPDATE ON routines
  FOR EACH ROW
  EXECUTE FUNCTION update_routines_updated_at();
