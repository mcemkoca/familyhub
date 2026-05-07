-- Migration 029: Add remote screen lock columns to child_accounts
-- Enables parents to force-lock a child's device remotely

ALTER TABLE public.child_accounts
ADD COLUMN IF NOT EXISTS remote_lock_enabled boolean default false;

ALTER TABLE public.child_accounts
ADD COLUMN IF NOT EXISTS remote_lock_until timestamptz;

ALTER TABLE public.child_accounts
ADD COLUMN IF NOT EXISTS remote_lock_reason text;

-- Update RLS: allow parents to update remote_lock fields
-- The existing policy "Parents can manage children in their family" already covers this.
