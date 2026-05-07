-- Safe Arrivals Table: Family-shared ETA monitoring
CREATE TABLE IF NOT EXISTS safe_arrivals (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    family_id UUID NOT NULL REFERENCES families(id) ON DELETE CASCADE,
    member_id TEXT NOT NULL, -- profiles.id or child_accounts.id
    member_name TEXT NOT NULL,
    destination TEXT NOT NULL,
    started_at TIMESTAMPTZ DEFAULT now(),
    estimated_arrival TIMESTAMPTZ NOT NULL,
    actual_arrival TIMESTAMPTZ,
    duration_minutes INT NOT NULL,
    progress NUMERIC DEFAULT 0,
    status TEXT DEFAULT 'active' CHECK (status IN ('active', 'arrived', 'delayed', 'cancelled')),
    delay_minutes INT,
    created_by TEXT,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

-- RLS Policies
ALTER TABLE IF EXISTS safe_arrivals ENABLE ROW LEVEL SECURITY;

-- Anon (child accounts) can view family arrivals
DROP POLICY IF EXISTS "Child can view family arrivals" ON safe_arrivals;
CREATE POLICY "Child can view family arrivals" ON safe_arrivals
    FOR SELECT TO anon
    USING (family_id IN (
        SELECT family_id FROM child_accounts WHERE id = nullif(current_setting('app.current_child_id', true), '')::uuid
    ));

-- Anon child can insert their own arrival plan
DROP POLICY IF EXISTS "Child can insert own arrival" ON safe_arrivals;
CREATE POLICY "Child can insert own arrival" ON safe_arrivals
    FOR INSERT TO anon
    WITH CHECK (family_id IN (
        SELECT family_id FROM child_accounts WHERE id = nullif(current_setting('app.current_child_id', true), '')::uuid
    ));

-- Anon child can update their own arrival
DROP POLICY IF EXISTS "Child can update own arrival" ON safe_arrivals;
CREATE POLICY "Child can update own arrival" ON safe_arrivals
    FOR UPDATE TO anon
    USING (member_id IN (
        SELECT id::text FROM child_accounts WHERE id = nullif(current_setting('app.current_child_id', true), '')::uuid
    ))
    WITH CHECK (family_id IN (
        SELECT family_id FROM child_accounts WHERE id = nullif(current_setting('app.current_child_id', true), '')::uuid
    ));

-- Authenticated parents can manage all family arrivals
DROP POLICY IF EXISTS "Parent can manage family arrivals" ON safe_arrivals;
CREATE POLICY "Parent can manage family arrivals" ON safe_arrivals
    FOR ALL TO authenticated
    USING (family_id IN (
        SELECT family_id FROM profiles WHERE id = auth.uid()
    ))
    WITH CHECK (family_id IN (
        SELECT family_id FROM profiles WHERE id = auth.uid()
    ));

-- Indexes
CREATE INDEX IF NOT EXISTS idx_safe_arrivals_family ON safe_arrivals(family_id, status, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_safe_arrivals_active ON safe_arrivals(family_id, status) WHERE status = 'active';

-- Realtime
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_publication_tables
    WHERE pubname = 'supabase_realtime'
      AND schemaname = 'public'
      AND tablename = 'safe_arrivals'
  ) THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE safe_arrivals;
  END IF;
END $$;
