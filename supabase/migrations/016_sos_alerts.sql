-- SOS Alerts Table: Realtime emergency alerts across family
CREATE TABLE IF NOT EXISTS sos_alerts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    family_id UUID NOT NULL REFERENCES families(id) ON DELETE CASCADE,
    sender_id TEXT NOT NULL, -- user id or child_account id
    sender_name TEXT NOT NULL,
    sender_type TEXT NOT NULL CHECK (sender_type IN ('parent', 'child')),
    lat DOUBLE PRECISION,
    lng DOUBLE PRECISION,
    accuracy DOUBLE PRECISION,
    message TEXT NOT NULL DEFAULT 'Acil durum!',
    status TEXT NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'resolved', 'false_alarm')),
    resolved_by TEXT,
    resolved_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT now()
);

-- RLS Policies
ALTER TABLE IF EXISTS sos_alerts ENABLE ROW LEVEL SECURITY;

-- Anon (child accounts) can insert SOS for their family
DROP POLICY IF EXISTS "Child can send SOS" ON sos_alerts;
CREATE POLICY "Child can send SOS" ON sos_alerts
    FOR INSERT TO anon
    WITH CHECK (family_id IN (
        SELECT family_id FROM child_accounts WHERE id = nullif(current_setting('app.current_child_id', true), '')::uuid
    ));

-- Anon can view SOS alerts for their family
DROP POLICY IF EXISTS "Child can view family SOS" ON sos_alerts;
CREATE POLICY "Child can view family SOS" ON sos_alerts
    FOR SELECT TO anon
    USING (family_id IN (
        SELECT family_id FROM child_accounts WHERE id = nullif(current_setting('app.current_child_id', true), '')::uuid
    ));

-- Authenticated parents can manage SOS for their family
DROP POLICY IF EXISTS "Parent can manage family SOS" ON sos_alerts;
CREATE POLICY "Parent can manage family SOS" ON sos_alerts
    FOR ALL TO authenticated
    USING (family_id IN (
        SELECT family_id FROM profiles WHERE id = auth.uid()
    ))
    WITH CHECK (family_id IN (
        SELECT family_id FROM profiles WHERE id = auth.uid()
    ));

-- Indexes
CREATE INDEX IF NOT EXISTS idx_sos_alerts_family ON sos_alerts(family_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_sos_alerts_active ON sos_alerts(family_id, status) WHERE status = 'active';

-- Realtime
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_publication_tables
    WHERE pubname = 'supabase_realtime'
      AND schemaname = 'public'
      AND tablename = 'sos_alerts'
  ) THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE sos_alerts;
  END IF;
END $$;
