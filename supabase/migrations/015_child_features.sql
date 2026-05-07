-- ============================================
-- CHILD FEATURES EXPANSION (Module 20 Extended)
-- Homeworks, schedules, development logs, location sharing
-- ============================================

-- ============================================
-- CHILD HOMEWORKS
-- ============================================
create table if not exists public.child_homeworks (
  id uuid default gen_random_uuid() primary key,
  family_id uuid references public.families(id) on delete cascade not null,
  child_id uuid references public.child_accounts(id) on delete cascade not null,
  subject text not null,
  title text not null,
  description text,
  due_date timestamptz,
  status text not null default 'pending' check (status in ('pending', 'in_progress', 'completed', 'late')),
  priority text not null default 'medium' check (priority in ('low', 'medium', 'high')),
  estimated_minutes int,
  completed_at timestamptz,
  created_by uuid references public.profiles(id),
  created_at timestamptz default now()
);

create index if not exists idx_child_homeworks_child on public.child_homeworks(child_id, status);
create index if not exists idx_child_homeworks_family on public.child_homeworks(family_id, due_date);

-- ============================================
-- CHILD SCHEDULES (Weekly Lesson Plan)
-- ============================================
create table if not exists public.child_schedules (
  id uuid default gen_random_uuid() primary key,
  family_id uuid references public.families(id) on delete cascade not null,
  child_id uuid references public.child_accounts(id) on delete cascade not null,
  day_of_week int not null check (day_of_week between 1 and 7),
  start_time time not null,
  end_time time not null,
  subject text not null,
  location text,
  teacher text,
  color text default '#3B82F6',
  is_active boolean default true,
  created_at timestamptz default now()
);

create index if not exists idx_child_schedules_child_day on public.child_schedules(child_id, day_of_week);

-- ============================================
-- CHILD DEVELOPMENT LOGS
-- ============================================
create table if not exists public.child_development_logs (
  id uuid default gen_random_uuid() primary key,
  family_id uuid references public.families(id) on delete cascade not null,
  child_id uuid references public.child_accounts(id) on delete cascade not null,
  log_type text not null check (log_type in ('height', 'weight', 'mood', 'milestone', 'note')),
  value text not null,
  unit text,
  logged_at date not null default current_date,
  notes text,
  created_by uuid references public.profiles(id),
  created_at timestamptz default now()
);

create index if not exists idx_child_dev_logs_child on public.child_development_logs(child_id, log_type, logged_at desc);

-- ============================================
-- GEOLOCATIONS — add child_id (nullable for backward compat)
-- ============================================
alter table public.geolocations add column if not exists child_id uuid references public.child_accounts(id) on delete cascade;
create index if not exists idx_geolocations_child on public.geolocations(child_id, created_at desc);

-- ============================================
-- MESSAGES — add sender_type to distinguish child messages
-- ============================================
alter table public.messages add column if not exists sender_type text default 'parent' check (sender_type in ('parent', 'child'));

-- ============================================
-- RLS POLICIES — Anon (child) access
-- ============================================

-- child_homeworks
alter table if exists public.child_homeworks enable row level security;

drop policy if exists "Anon child can view own homeworks" on public.child_homeworks;
create policy "Anon child can view own homeworks"
  on public.child_homeworks for select to anon
  using (child_id = coalesce(current_setting('app.current_child_id', true), '')::uuid);

drop policy if exists "Anon child can update own homework status" on public.child_homeworks;
create policy "Anon child can update own homework status"
  on public.child_homeworks for update to anon
  using (child_id = coalesce(current_setting('app.current_child_id', true), '')::uuid);

drop policy if exists "Parents can manage child homeworks" on public.child_homeworks;
create policy "Parents can manage child homeworks"
  on public.child_homeworks for all to authenticated
  using (
    exists (
      select 1 from public.family_members fm
      where fm.family_id = child_homeworks.family_id
      and fm.user_id = auth.uid()
      and fm.role in ('admin', 'parent')
    )
  )
  with check (
    exists (
      select 1 from public.family_members fm
      where fm.family_id = child_homeworks.family_id
      and fm.user_id = auth.uid()
      and fm.role in ('admin', 'parent')
    )
  );

-- child_schedules
alter table if exists public.child_schedules enable row level security;

drop policy if exists "Anon child can view own schedule" on public.child_schedules;
create policy "Anon child can view own schedule"
  on public.child_schedules for select to anon
  using (child_id = coalesce(current_setting('app.current_child_id', true), '')::uuid);

drop policy if exists "Parents can manage child schedules" on public.child_schedules;
create policy "Parents can manage child schedules"
  on public.child_schedules for all to authenticated
  using (
    exists (
      select 1 from public.family_members fm
      where fm.family_id = child_schedules.family_id
      and fm.user_id = auth.uid()
      and fm.role in ('admin', 'parent')
    )
  )
  with check (
    exists (
      select 1 from public.family_members fm
      where fm.family_id = child_schedules.family_id
      and fm.user_id = auth.uid()
      and fm.role in ('admin', 'parent')
    )
  );

-- child_development_logs
alter table if exists public.child_development_logs enable row level security;

drop policy if exists "Anon child can view own development logs" on public.child_development_logs;
create policy "Anon child can view own development logs"
  on public.child_development_logs for select to anon
  using (child_id = coalesce(current_setting('app.current_child_id', true), '')::uuid);

drop policy if exists "Parents can manage child development logs" on public.child_development_logs;
create policy "Parents can manage child development logs"
  on public.child_development_logs for all to authenticated
  using (
    exists (
      select 1 from public.family_members fm
      where fm.family_id = child_development_logs.family_id
      and fm.user_id = auth.uid()
      and fm.role in ('admin', 'parent')
    )
  )
  with check (
    exists (
      select 1 from public.family_members fm
      where fm.family_id = child_development_logs.family_id
      and fm.user_id = auth.uid()
      and fm.role in ('admin', 'parent')
    )
  );

-- tasks — anon child access (existing table, add child policies)
drop policy if exists "Anon child can view assigned tasks" on public.tasks;
create policy "Anon child can view assigned tasks"
  on public.tasks for select to anon
  using (assigned_to = coalesce(current_setting('app.current_child_id', true), '')::uuid);

drop policy if exists "Anon child can update own tasks" on public.tasks;
create policy "Anon child can update own tasks"
  on public.tasks for update to anon
  using (assigned_to = coalesce(current_setting('app.current_child_id', true), '')::uuid);

-- messages — anon child access
drop policy if exists "Anon child can view family messages" on public.messages;
create policy "Anon child can view family messages"
  on public.messages for select to anon
  using (family_id in (
    select family_id from public.child_accounts
    where id = coalesce(current_setting('app.current_child_id', true), '')::uuid
  ));

drop policy if exists "Anon child can send family messages" on public.messages;
create policy "Anon child can send family messages"
  on public.messages for insert to anon
  with check (family_id in (
    select family_id from public.child_accounts
    where id = coalesce(current_setting('app.current_child_id', true), '')::uuid
  ));

-- geolocations — anon child can insert own location, view family locations
drop policy if exists "Anon child can share location" on public.geolocations;
create policy "Anon child can share location"
  on public.geolocations for insert to anon
  with check (child_id = coalesce(current_setting('app.current_child_id', true), '')::uuid);

drop policy if exists "Anon child can view family geolocations" on public.geolocations;
create policy "Anon child can view family geolocations"
  on public.geolocations for select to anon
  using (family_id in (
    select family_id from public.child_accounts
    where id = coalesce(current_setting('app.current_child_id', true), '')::uuid
  ));

-- child_activity_logs — anon child can view own logs (for AI analysis)
drop policy if exists "Anon child can view own activity logs" on public.child_activity_logs;
create policy "Anon child can view own activity logs"
  on public.child_activity_logs for select to anon
  using (child_id = coalesce(current_setting('app.current_child_id', true), '')::uuid);

-- ============================================
-- REALTIME
-- ============================================
do $$
begin
  if not exists (select 1 from pg_publication_tables where pubname = 'supabase_realtime' and tablename = 'child_homeworks') then
    alter publication supabase_realtime add table public.child_homeworks;
  end if;
end $$;

do $$
begin
  if not exists (select 1 from pg_publication_tables where pubname = 'supabase_realtime' and tablename = 'child_schedules') then
    alter publication supabase_realtime add table public.child_schedules;
  end if;
end $$;

do $$
begin
  if not exists (select 1 from pg_publication_tables where pubname = 'supabase_realtime' and tablename = 'child_development_logs') then
    alter publication supabase_realtime add table public.child_development_logs;
  end if;
end $$;

-- ============================================
-- SEED DATA — Sample homeworks, schedules, development for Mirac
-- ============================================
-- Note: child_id must be replaced with actual Mirac's UUID after migration
-- This will be handled by the app or a separate seed script
