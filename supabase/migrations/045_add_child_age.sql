-- Migration 045: Add age column to child_accounts for age-based suggestions
ALTER TABLE public.child_accounts ADD COLUMN IF NOT EXISTS age int;

-- Update existing children with estimated ages based on role
UPDATE public.child_accounts SET age = 1 WHERE age IS NULL AND role = 'baby';
UPDATE public.child_accounts SET age = 6 WHERE age IS NULL AND role = 'child';
UPDATE public.child_accounts SET age = 12 WHERE age IS NULL AND role = 'teen';
