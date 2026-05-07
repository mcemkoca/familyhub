-- Migration 021: Add family_id to profiles table
-- Fixes PostgrestException: column profiles.family_id does not exist

-- 1. Add the column
ALTER TABLE profiles 
ADD COLUMN IF NOT EXISTS family_id UUID REFERENCES families(id) ON DELETE SET NULL;

-- 2. Create index for performance
CREATE INDEX IF NOT EXISTS idx_profiles_family_id ON profiles(family_id);

-- 3. Backfill existing users from family_members junction table
UPDATE profiles p
SET family_id = fm.family_id
FROM family_members fm
WHERE p.id = fm.user_id
  AND p.family_id IS NULL;

-- 4. Create trigger to keep profiles.family_id in sync with family_members
CREATE OR REPLACE FUNCTION sync_profile_family_id()
RETURNS TRIGGER AS $$
BEGIN
  IF TG_OP = 'INSERT' OR (TG_OP = 'UPDATE' AND NEW.family_id IS DISTINCT FROM OLD.family_id) THEN
    UPDATE profiles SET family_id = NEW.family_id WHERE id = NEW.user_id;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS family_members_insert_update ON family_members;
CREATE TRIGGER family_members_insert_update
AFTER INSERT OR UPDATE OF family_id ON family_members
FOR EACH ROW
EXECUTE FUNCTION sync_profile_family_id();
