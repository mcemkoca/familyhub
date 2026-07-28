-- Quick fix: Allow anonymous users to view child accounts for the login screen
-- Run this in Supabase SQL Editor (new query) to avoid "relation already exists" errors

drop policy if exists "Anon can view child accounts for login" on public.child_accounts;

create policy "Anon can view child accounts for login"
  on public.child_accounts
  for select
  to anon
  using (true);
