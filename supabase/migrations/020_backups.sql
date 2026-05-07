-- Family Backups Table: Real backup storage for all family data
CREATE TABLE IF NOT EXISTS family_backups (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    family_id UUID NOT NULL REFERENCES families(id) ON DELETE CASCADE,
    created_by TEXT NOT NULL, -- profiles.id or child_accounts.id
    creator_name TEXT NOT NULL,
    creator_email TEXT,
    data_json JSONB NOT NULL, -- Encrypted/compressed family data dump
    size_bytes INT,
    record_count INT,
    backup_type TEXT DEFAULT 'manual' CHECK (backup_type IN ('manual', 'auto')),
    created_at TIMESTAMPTZ DEFAULT now()
);

-- RLS Policies
ALTER TABLE IF EXISTS family_backups ENABLE ROW LEVEL SECURITY;

-- Anon (child accounts) can view family backups
DROP POLICY IF EXISTS "Child can view family backups" ON family_backups;
CREATE POLICY "Child can view family backups" ON family_backups
    FOR SELECT TO anon
    USING (family_id IN (
        SELECT family_id FROM child_accounts
        WHERE id = coalesce(current_setting('app.current_child_id', true), '')::uuid
          AND is_active = true
    ));

-- Authenticated parents can manage family backups
DROP POLICY IF EXISTS "Parent can manage family backups" ON family_backups;
CREATE POLICY "Parent can manage family backups" ON family_backups
    FOR ALL TO authenticated
    USING (family_id IN (
        SELECT family_id FROM profiles WHERE id = auth.uid()
    ))
    WITH CHECK (family_id IN (
        SELECT family_id FROM profiles WHERE id = auth.uid()
    ));

-- Indexes
CREATE INDEX IF NOT EXISTS idx_family_backups_family ON family_backups(family_id, created_at DESC);

-- Realtime
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_publication_tables
    WHERE pubname = 'supabase_realtime'
      AND schemaname = 'public'
      AND tablename = 'family_backups'
  ) THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE family_backups;
  END IF;
END $$;
