-- Smart Reminders System Migration
-- Tables: smart_reminders, context_snapshots, reminder_interactions

-- ── SMART REMINDERS ────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS smart_reminders (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  family_id UUID NOT NULL REFERENCES families(id) ON DELETE CASCADE,
  created_by UUID REFERENCES profiles(id) ON DELETE SET NULL,
  title TEXT NOT NULL,
  description TEXT,
  triggers JSONB NOT NULL DEFAULT '{}',
  context_sensitivity JSONB NOT NULL DEFAULT '{}',
  personalization JSONB NOT NULL DEFAULT '{}',
  target_audience JSONB NOT NULL DEFAULT '{}',
  status JSONB NOT NULL DEFAULT '{"state": "active", "trigger_count": 0, "completion_rate": 0}',
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now(),
  version INTEGER DEFAULT 1
);

COMMENT ON TABLE smart_reminders IS 'Context-aware smart reminders with location/time/behavior triggers';

-- RLS
ALTER TABLE IF EXISTS smart_reminders ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "family_members_can_view_reminders" ON smart_reminders;
CREATE POLICY "family_members_can_view_reminders"
  ON smart_reminders FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM family_members fm
      WHERE fm.family_id = smart_reminders.family_id
      AND fm.user_id = auth.uid()
    )
  );

DROP POLICY IF EXISTS "family_members_can_create_reminders" ON smart_reminders;
CREATE POLICY "family_members_can_create_reminders"
  ON smart_reminders FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM family_members fm
      WHERE fm.family_id = smart_reminders.family_id
      AND fm.user_id = auth.uid()
    )
  );

DROP POLICY IF EXISTS "creators_can_update_reminders" ON smart_reminders;
CREATE POLICY "creators_can_update_reminders"
  ON smart_reminders FOR UPDATE
  USING (created_by = auth.uid())
  WITH CHECK (created_by = auth.uid());

DROP POLICY IF EXISTS "creators_can_delete_reminders" ON smart_reminders;
CREATE POLICY "creators_can_delete_reminders"
  ON smart_reminders FOR DELETE
  USING (created_by = auth.uid());

-- Index
CREATE INDEX IF NOT EXISTS idx_smart_reminders_family ON smart_reminders(family_id);
CREATE INDEX IF NOT EXISTS idx_smart_reminders_created_by ON smart_reminders(created_by);

-- ── CONTEXT SNAPSHOTS ──────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS context_snapshots (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  member_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  family_id UUID NOT NULL REFERENCES families(id) ON DELETE CASCADE,
  location JSONB,
  time_context JSONB,
  activity JSONB,
  device JSONB,
  environment JSONB,
  cognitive JSONB,
  social JSONB,
  created_at TIMESTAMPTZ DEFAULT now()
);

COMMENT ON TABLE context_snapshots IS 'Periodic context snapshots for ML/trigger evaluation';

ALTER TABLE IF EXISTS context_snapshots ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "members_can_view_own_context" ON context_snapshots;
CREATE POLICY "members_can_view_own_context"
  ON context_snapshots FOR SELECT
  USING (member_id = auth.uid());

DROP POLICY IF EXISTS "members_can_insert_own_context" ON context_snapshots;
CREATE POLICY "members_can_insert_own_context"
  ON context_snapshots FOR INSERT
  WITH CHECK (member_id = auth.uid());

CREATE INDEX IF NOT EXISTS idx_context_snapshots_member ON context_snapshots(member_id);
CREATE INDEX IF NOT EXISTS idx_context_snapshots_family ON context_snapshots(family_id);
CREATE INDEX IF NOT EXISTS idx_context_snapshots_created ON context_snapshots(created_at);

-- Auto cleanup old snapshots (keep 30 days)
-- Run periodically via pg_cron or external scheduler

-- ── REMINDER INTERACTIONS ──────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS reminder_interactions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  reminder_id UUID NOT NULL REFERENCES smart_reminders(id) ON DELETE CASCADE,
  member_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  action TEXT NOT NULL,
  snooze_duration INTEGER,
  feedback JSONB,
  context JSONB,
  created_at TIMESTAMPTZ DEFAULT now()
);

COMMENT ON TABLE reminder_interactions IS 'User interactions with smart reminders for analytics & learning';

ALTER TABLE IF EXISTS reminder_interactions ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "members_can_view_own_interactions" ON reminder_interactions;
CREATE POLICY "members_can_view_own_interactions"
  ON reminder_interactions FOR SELECT
  USING (member_id = auth.uid());

DROP POLICY IF EXISTS "members_can_insert_own_interactions" ON reminder_interactions;
CREATE POLICY "members_can_insert_own_interactions"
  ON reminder_interactions FOR INSERT
  WITH CHECK (member_id = auth.uid());

CREATE INDEX IF NOT EXISTS idx_reminder_interactions_reminder ON reminder_interactions(reminder_id);
CREATE INDEX IF NOT EXISTS idx_reminder_interactions_member ON reminder_interactions(member_id);
CREATE INDEX IF NOT EXISTS idx_reminder_interactions_created ON reminder_interactions(created_at);

-- ── FUNCTIONS ──────────────────────────────────────────────────────────

-- Update updated_at trigger for smart_reminders
CREATE OR REPLACE FUNCTION update_smart_reminders_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_smart_reminders_updated_at ON smart_reminders;
CREATE TRIGGER trg_smart_reminders_updated_at
  BEFORE UPDATE ON smart_reminders
  FOR EACH ROW
  EXECUTE FUNCTION update_smart_reminders_updated_at();

-- Get reminder analytics
CREATE OR REPLACE FUNCTION get_reminder_analytics(p_reminder_id UUID)
RETURNS TABLE (
  total_triggers BIGINT,
  completions BIGINT,
  snoozes BIGINT,
  dismisses BIGINT,
  completion_rate NUMERIC,
  avg_response_minutes NUMERIC
) AS $$
BEGIN
  RETURN QUERY
  SELECT
    COUNT(*)::BIGINT AS total_triggers,
    COUNT(*) FILTER (WHERE action = 'completed')::BIGINT AS completions,
    COUNT(*) FILTER (WHERE action = 'snoozed')::BIGINT AS snoozes,
    COUNT(*) FILTER (WHERE action = 'dismissed')::BIGINT AS dismisses,
    CASE 
      WHEN COUNT(*) > 0 THEN 
        ROUND((COUNT(*) FILTER (WHERE action = 'completed')::NUMERIC / COUNT(*)::NUMERIC) * 100, 1)
      ELSE 0
    END AS completion_rate,
    0::NUMERIC AS avg_response_minutes
  FROM reminder_interactions
  WHERE reminder_id = p_reminder_id;
END;
$$ LANGUAGE plpgsql;
