-- Add admin and subscription fields to profiles

alter table public.profiles
  add column if not exists is_admin boolean default false,
  add column if not exists subscription_tier text default 'free',
  add column if not exists subscription_expires_at timestamptz;

-- Update existing mcemkoca0@gmail.com user to admin + premium
-- NOTE: Run this after the user has signed up at least once
-- so the trigger creates their profile row first.

-- update public.profiles
-- set is_admin = true,
--     is_premium = true,
--     subscription_tier = 'premium'
-- where id = (
--   select id from auth.users where email = 'mcemkoca0@gmail.com'
-- );
