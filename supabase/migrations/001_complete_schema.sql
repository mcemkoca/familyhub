-- ============================================
-- EXTENSIONS
-- ============================================
create extension if not exists "uuid-ossp";
create extension if not exists "pgcrypto";

-- ============================================
-- PROFILES (Auth users extension)
-- ============================================
create table if not exists public.profiles (
  id uuid references auth.users on delete cascade primary key,
  display_name text not null,
  avatar_url text,
  phone text unique,
  email text unique not null,
  date_of_birth date,
  blood_type text check (blood_type in ('A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', '0+', '0-')),
  allergies text[] default '{}',
  chronic_conditions text[] default '{}',
  medications jsonb default '[]',
  emergency_contact_name text,
  emergency_contact_phone text,
  emergency_contact_relation text,
  preferred_language text default 'tr',
  theme_preference text default 'system',
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

-- ============================================
-- FAMILIES
-- ============================================
create table if not exists public.families (
  id uuid default gen_random_uuid() primary key,
  name text not null,
  invite_code text unique not null,
  invite_code_expires_at timestamptz,
  created_by uuid references public.profiles(id) not null,
  subscription_tier text default 'free' check (subscription_tier in ('free', 'premium', 'family')),
  subscription_expires_at timestamptz,
  max_members int default 4,
  settings jsonb default '{
    "auto_approve_members": false,
    "default_reminders": [15],
    "location_sharing": true,
    "task_notifications": true,
    "event_notifications": true,
    "emergency_notifications": true
  }',
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

-- ============================================
-- FAMILY MEMBERS
-- ============================================
create table if not exists public.family_members (
  family_id uuid references public.families(id) on delete cascade,
  user_id uuid references public.profiles(id) on delete cascade,
  role text default 'member' check (role in ('admin', 'parent', 'teen', 'child', 'elder', 'guest', 'baby')),
  display_name text,
  color text default '#3B82F6',
  joined_at timestamptz default now(),
  last_active_at timestamptz,
  is_active boolean default true,
  primary key (family_id, user_id)
);

-- Safely add missing columns if table already existed without them
alter table public.family_members add column if not exists role text default 'member' check (role in ('admin', 'parent', 'teen', 'child', 'elder', 'guest', 'baby'));
alter table public.family_members add column if not exists display_name text;
alter table public.family_members add column if not exists color text default '#3B82F6';
alter table public.family_members add column if not exists joined_at timestamptz default now();
alter table public.family_members add column if not exists last_active_at timestamptz;
alter table public.family_members add column if not exists is_active boolean default true;

-- ============================================
-- EVENTS
-- ============================================
create table if not exists public.events (
  id uuid default gen_random_uuid() primary key,
  family_id uuid references public.families(id) on delete cascade not null,
  created_by uuid references public.profiles(id) not null,
  title text not null,
  description text,
  location text,
  location_lat numeric,
  location_lng numeric,
  category text default 'other' check (category in ('appointment', 'birthday', 'school', 'activity', 'work', 'family', 'travel', 'other')),
  start_time timestamptz not null,
  end_time timestamptz not null,
  is_all_day boolean default false,
  recurrence_rule text,
  reminders int[] default '{15}',
  status text default 'active' check (status in ('active', 'cancelled', 'completed')),
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

-- ============================================
-- EVENT ATTENDEES
-- ============================================
create table if not exists public.event_attendees (
  event_id uuid references public.events(id) on delete cascade,
  user_id uuid references public.profiles(id) on delete cascade,
  rsvp_status text default 'pending' check (rsvp_status in ('pending', 'accepted', 'declined', 'maybe')),
  notified boolean default false,
  primary key (event_id, user_id)
);

-- ============================================
-- TASKS
-- ============================================
create table if not exists public.tasks (
  id uuid default gen_random_uuid() primary key,
  family_id uuid references public.families(id) on delete cascade not null,
  title text not null,
  description text,
  assigned_to uuid references public.profiles(id),
  created_by uuid references public.profiles(id) not null,
  due_date timestamptz,
  priority text default 'medium' check (priority in ('low', 'medium', 'high', 'urgent')),
  status text default 'pending' check (status in ('pending', 'in_progress', 'completed', 'cancelled')),
  category text default 'other' check (category in ('shopping', 'chore', 'homework', 'appointment', 'other')),
  checklist jsonb default '[]',
  attachments jsonb default '[]',
  completed_at timestamptz,
  completed_by uuid references public.profiles(id),
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

-- ============================================
-- MESSAGES
-- ============================================
create table if not exists public.messages (
  id uuid default gen_random_uuid() primary key,
  family_id uuid references public.families(id) on delete cascade not null,
  user_id uuid references public.profiles(id) not null,
  text text,
  type text default 'text' check (type in ('text', 'image', 'video', 'audio', 'location', 'event_share', 'announcement', 'mood')),
  media_urls text[],
  reply_to uuid references public.messages(id),
  read_by uuid[] default '{}',
  reactions jsonb default '{}',
  pinned boolean default false,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

-- ============================================
-- GEOLOCATIONS (Live tracking)
-- ============================================
create table if not exists public.geolocations (
  id uuid default gen_random_uuid() primary key,
  user_id uuid references public.profiles(id) on delete cascade,
  family_id uuid references public.families(id) on delete cascade,
  lat numeric not null,
  lng numeric not null,
  accuracy numeric,
  altitude numeric,
  speed numeric,
  heading numeric,
  battery_level int,
  is_moving boolean default false,
  created_at timestamptz default now()
);

-- ============================================
-- BUDGET ENTRIES
-- ============================================
create table if not exists public.budget_entries (
  id uuid default gen_random_uuid() primary key,
  family_id uuid references public.families(id) on delete cascade,
  created_by uuid references public.profiles(id),
  amount numeric not null,
  currency text default 'TRY',
  category text,
  description text,
  receipt_url text,
  split_with uuid[],
  paid_by uuid references public.profiles(id),
  date timestamptz default now(),
  created_at timestamptz default now()
);

-- ============================================
-- ACTIVITY LOGS (Audit trail)
-- ============================================
create table if not exists public.activity_logs (
  id uuid default gen_random_uuid() primary key,
  user_id uuid references public.profiles(id),
  family_id uuid references public.families(id),
  action text not null,
  entity_type text,
  entity_id uuid,
  metadata jsonb,
  created_at timestamptz default now()
);

-- ============================================
-- FUNCTIONS
-- ============================================

-- Generate invite code
create or replace function public.generate_invite_code()
returns text as $$
declare
  code text;
  exists_check boolean;
begin
  loop
    code := upper(substring(md5(random()::text) from 1 for 8));
    select exists(select 1 from public.families where invite_code = code) into exists_check;
    exit when not exists_check;
  end loop;
  return code;
end;
$$ language plpgsql;

-- Auto-generate invite code on family creation
create or replace function public.handle_new_family()
returns trigger as $$
begin
  new.invite_code := public.generate_invite_code();
  new.invite_code_expires_at := now() + interval '7 days';
  return new;
end;
$$ language plpgsql security definer;

drop trigger if exists on_family_created on public.families;
create trigger on_family_created
  before insert on public.families
  for each row execute procedure public.handle_new_family();

-- New user profile creation
create or replace function public.handle_new_user()
returns trigger as $$
begin
  insert into public.profiles (id, display_name, email)
  values (
    new.id,
    coalesce(new.raw_user_meta_data->>'display_name', split_part(new.email, '@', 1)),
    new.email
  )
  on conflict (id) do nothing;
  return new;
end;
$$ language plpgsql security definer;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();

-- ============================================
-- ROW LEVEL SECURITY
-- ============================================

alter table if exists public.profiles enable row level security;
alter table if exists public.families enable row level security;
alter table if exists public.family_members enable row level security;
alter table if exists public.events enable row level security;
alter table if exists public.event_attendees enable row level security;
alter table if exists public.tasks enable row level security;
alter table if exists public.messages enable row level security;
alter table if exists public.geolocations enable row level security;
alter table if exists public.budget_entries enable row level security;
alter table if exists public.activity_logs enable row level security;

-- Profiles: own only
drop policy if exists "Users view own profile" on public.profiles;
create policy "Users view own profile"
  on public.profiles for select
  using (auth.uid() = id);

drop policy if exists "Users update own profile" on public.profiles;
create policy "Users update own profile"
  on public.profiles for update
  using (auth.uid() = id);

-- Families: members only
drop policy if exists "Family members view" on public.families;
create policy "Family members view"
  on public.families for select
  using (
    id in (select family_id from public.family_members where user_id = auth.uid())
  );

drop policy if exists "Admins update" on public.families;
create policy "Admins update"
  on public.families for update
  using (
    id in (
      select family_id from public.family_members
      where user_id = auth.uid() and role = 'admin'
    )
  );

-- Events: family members
drop policy if exists "Events view" on public.events;
create policy "Events view"
  on public.events for select
  using (
    family_id in (select family_id from public.family_members where user_id = auth.uid())
  );

drop policy if exists "Events create" on public.events;
create policy "Events create"
  on public.events for insert
  with check (
    family_id in (select family_id from public.family_members where user_id = auth.uid())
  );

-- Tasks: family members
drop policy if exists "Tasks view" on public.tasks;
create policy "Tasks view"
  on public.tasks for select
  using (
    family_id in (select family_id from public.family_members where user_id = auth.uid())
  );

-- Messages: family members
drop policy if exists "Messages view" on public.messages;
create policy "Messages view"
  on public.messages for select
  using (
    family_id in (select family_id from public.family_members where user_id = auth.uid())
  );

drop policy if exists "Messages insert" on public.messages;
create policy "Messages insert"
  on public.messages for insert
  with check (
    family_id in (select family_id from public.family_members where user_id = auth.uid())
  );

-- ============================================
-- REALTIME
-- ============================================

do $$
begin
  if not exists (
    select 1 from pg_publication_tables
    where pubname = 'supabase_realtime' and tablename = 'messages'
  ) then
    alter publication supabase_realtime add table public.messages;
  end if;
end $$;

do $$
begin
  if not exists (
    select 1 from pg_publication_tables
    where pubname = 'supabase_realtime' and tablename = 'events'
  ) then
    alter publication supabase_realtime add table public.events;
  end if;
end $$;

do $$
begin
  if not exists (
    select 1 from pg_publication_tables
    where pubname = 'supabase_realtime' and tablename = 'tasks'
  ) then
    alter publication supabase_realtime add table public.tasks;
  end if;
end $$;

do $$
begin
  if not exists (
    select 1 from pg_publication_tables
    where pubname = 'supabase_realtime' and tablename = 'geolocations'
  ) then
    alter publication supabase_realtime add table public.geolocations;
  end if;
end $$;

do $$
begin
  if not exists (
    select 1 from pg_publication_tables
    where pubname = 'supabase_realtime' and tablename = 'family_members'
  ) then
    alter publication supabase_realtime add table public.family_members;
  end if;
end $$;

-- ============================================
-- INDEXES
-- ============================================

create index if not exists idx_events_family_time on public.events(family_id, start_time);
create index if not exists idx_tasks_family_status on public.tasks(family_id, status);
create index if not exists idx_messages_family_time on public.messages(family_id, created_at);
create index if not exists idx_geolocations_user on public.geolocations(user_id, created_at desc);
create index if not exists idx_activity_logs_user on public.activity_logs(user_id, created_at);
create index if not exists idx_family_members_family on public.family_members(family_id);
