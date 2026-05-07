-- Migration 022: Create safe_zones table for persistent geofence storage

CREATE TABLE IF NOT EXISTS safe_zones (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  family_id UUID NOT NULL REFERENCES families(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  type TEXT NOT NULL CHECK (type IN ('home', 'work', 'school', 'custom')),
  latitude DOUBLE PRECISION NOT NULL,
  longitude DOUBLE PRECISION NOT NULL,
  radius_meters INTEGER NOT NULL DEFAULT 100,
  address TEXT,
  created_by UUID REFERENCES profiles(id),
  created_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_safe_zones_family_id ON safe_zones(family_id);

-- Enable RLS
ALTER TABLE safe_zones ENABLE ROW LEVEL SECURITY;

-- Policy: family members can read their family's safe zones
DROP POLICY IF EXISTS safe_zones_select_family ON safe_zones;
CREATE POLICY safe_zones_select_family
  ON safe_zones
  FOR SELECT
  USING (
    family_id IN (
      SELECT family_id FROM family_members WHERE user_id = auth.uid()
    )
  );

-- Policy: family admins/parents can insert/update/delete
DROP POLICY IF EXISTS safe_zones_write_family ON safe_zones;
CREATE POLICY safe_zones_write_family
  ON safe_zones
  FOR ALL
  USING (
    family_id IN (
      SELECT family_id FROM family_members 
      WHERE user_id = auth.uid() 
      AND role IN ('admin', 'parent')
    )
  )
  WITH CHECK (
    family_id IN (
      SELECT family_id FROM family_members 
      WHERE user_id = auth.uid() 
      AND role IN ('admin', 'parent')
    )
  );
