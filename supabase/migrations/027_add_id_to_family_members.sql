-- Fix: family_members table needs an id column for foreign key references
-- Multiple migrations (011, 012, 013) reference family_members(id)

-- Add id column if not exists
ALTER TABLE public.family_members 
ADD COLUMN IF NOT EXISTS id UUID DEFAULT gen_random_uuid();

-- Backfill existing rows with generated UUIDs
UPDATE public.family_members 
SET id = gen_random_uuid() 
WHERE id IS NULL;

-- Ensure id is NOT NULL after backfill
ALTER TABLE public.family_members 
ALTER COLUMN id SET NOT NULL;

-- Create unique index on id for FK references
CREATE UNIQUE INDEX IF NOT EXISTS idx_family_members_id 
ON public.family_members(id);
