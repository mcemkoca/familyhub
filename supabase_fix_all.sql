-- ============================================
-- STEP 1: FULL 001_complete_schema.sql
-- ============================================
create extension if not exists "uuid-ossp";
create extension if not exists "pgcrypto";

create table public.profiles (
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

create table public.families (
  id uuid default uuid_generate_v4() primary key,
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

create table public.family_members (
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

create table public.events (
  id uuid default uuid_generate_v4() primary key,
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

create table public.event_attendees (
  event_id uuid references public.events(id) on delete cascade,
  user_id uuid references public.profiles(id) on delete cascade,
  rsvp_status text default 'pending' check (rsvp_status in ('pending', 'accepted', 'declined', 'maybe')),
  notified boolean default false,
  primary key (event_id, user_id)
);

create table public.tasks (
  id uuid default uuid_generate_v4() primary key,
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

create table public.messages (
  id uuid default uuid_generate_v4() primary key,
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

create table public.geolocations (
  id uuid default uuid_generate_v4() primary key,
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

create table public.budget_entries (
  id uuid default uuid_generate_v4() primary key,
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

create table public.activity_logs (
  id uuid default uuid_generate_v4() primary key,
  user_id uuid references public.profiles(id),
  family_id uuid references public.families(id),
  action text not null,
  entity_type text,
  entity_id uuid,
  metadata jsonb,
  created_at timestamptz default now()
);

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

create or replace function public.handle_new_family()
returns trigger as $$
begin
  new.invite_code := public.generate_invite_code();
  new.invite_code_expires_at := now() + interval '7 days';
  return new;
end;
$$ language plpgsql security definer;

create trigger on_family_created
  before insert on public.families
  for each row execute procedure public.handle_new_family();

create or replace function public.handle_new_user()
returns trigger as $$
begin
  insert into public.profiles (id, display_name, email)
  values (
    new.id,
    coalesce(new.raw_user_meta_data->>'display_name', split_part(new.email, '@', 1)),
    new.email
  );
  return new;
end;
$$ language plpgsql security definer;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();

alter table public.profiles enable row level security;
alter table public.families enable row level security;
alter table public.family_members enable row level security;
alter table public.events enable row level security;
alter table public.event_attendees enable row level security;
alter table public.tasks enable row level security;
alter table public.messages enable row level security;
alter table public.geolocations enable row level security;
alter table public.budget_entries enable row level security;
alter table public.activity_logs enable row level security;

create policy "Users view own profile"
  on public.profiles for select
  using (auth.uid() = id);

create policy "Users update own profile"
  on public.profiles for update
  using (auth.uid() = id);

create policy "Family members view"
  on public.families for select
  using (
    id in (select family_id from public.family_members where user_id = auth.uid())
  );

create policy "Admins update"
  on public.families for update
  using (
    id in (
      select family_id from public.family_members
      where user_id = auth.uid() and role = 'admin'
    )
  );

create policy "Events view"
  on public.events for select
  using (
    family_id in (select family_id from public.family_members where user_id = auth.uid())
  );

create policy "Events create"
  on public.events for insert
  with check (
    family_id in (select family_id from public.family_members where user_id = auth.uid())
  );

create policy "Tasks view"
  on public.tasks for select
  using (
    family_id in (select family_id from public.family_members where user_id = auth.uid())
  );

create policy "Messages view"
  on public.messages for select
  using (
    family_id in (select family_id from public.family_members where user_id = auth.uid())
  );

create policy "Messages insert"
  on public.messages for insert
  with check (
    family_id in (select family_id from public.family_members where user_id = auth.uid())
  );

alter publication supabase_realtime add table public.messages;
alter publication supabase_realtime add table public.events;
alter publication supabase_realtime add table public.tasks;
alter publication supabase_realtime add table public.geolocations;
alter publication supabase_realtime add table public.family_members;

create index idx_events_family_time on public.events(family_id, start_time);
create index idx_tasks_family_status on public.tasks(family_id, status);
create index idx_messages_family_time on public.messages(family_id, created_at);
create index idx_geolocations_user on public.geolocations(user_id, created_at desc);
create index idx_activity_logs_user on public.activity_logs(user_id, created_at);
create index idx_family_members_family on public.family_members(family_id);

-- ============================================
-- STEP 2: CREATE PROFILE FOR EXISTING USER
-- ============================================
insert into public.profiles (id, display_name, email)
select id, coalesce(raw_user_meta_data->>'display_name', split_part(email, '@', 1)), email
from auth.users
where email = 'mcemkoca0@gmail.com'
on conflict (id) do nothing;

-- ============================================
-- STEP 3: CREATE FAMILY
-- ============================================
insert into public.families (name, created_by)
select 'KOCA Family', id from public.profiles where email = 'mcemkoca0@gmail.com'
on conflict do nothing;

-- ============================================
-- STEP 4: ADD PARENT AS FAMILY MEMBER
-- ============================================
insert into public.family_members (family_id, user_id, role, display_name)
select f.id, p.id, 'admin', p.display_name
from public.families f
join public.profiles p on p.email = 'mcemkoca0@gmail.com'
on conflict do nothing;

-- ============================================
-- STEP 5: FULL 014_child_accounts.sql
-- ============================================
create table public.child_accounts (
  id uuid default uuid_generate_v4() primary key,
  family_id uuid references public.families(id) on delete cascade not null,
  name text not null,
  pin_hash text not null,
  avatar_url text,
  role text default 'child' check (role in ('child', 'teen', 'baby')),
  color text default '#3B82F6',
  created_by uuid references public.profiles(id) not null,
  created_at timestamptz default now(),
  updated_at timestamptz default now(),
  is_active boolean default true,
  last_active_at timestamptz,
  daily_screen_time_minutes int default 120,
  can_approve_tasks boolean default false,
  can_send_messages boolean default true,
  can_view_budget boolean default false
);

create table public.child_sessions (
  id uuid default uuid_generate_v4() primary key,
  child_id uuid references public.child_accounts(id) on delete cascade not null,
  family_id uuid references public.families(id) on delete cascade not null,
  token text unique not null,
  device_info text,
  expires_at timestamptz not null,
  created_at timestamptz default now(),
  last_used_at timestamptz default now()
);

create table public.child_activity_logs (
  id uuid default uuid_generate_v4() primary key,
  child_id uuid references public.child_accounts(id) on delete cascade not null,
  family_id uuid references public.families(id) on delete cascade not null,
  activity_type text not null check (activity_type in ('login', 'logout', 'task_completed', 'message_sent', 'location_shared', 'emergency_pressed', 'settings_changed')),
  details jsonb default '{}',
  created_at timestamptz default now()
);

create index idx_child_accounts_family on public.child_accounts(family_id);
create index idx_child_accounts_active on public.child_accounts(family_id, is_active);
create index idx_child_sessions_token on public.child_sessions(token);
create index idx_child_sessions_child on public.child_sessions(child_id);
create index idx_child_activity_logs_child on public.child_activity_logs(child_id, created_at desc);

create or replace function public.handle_child_account_update()
returns trigger as $$
begin
  new.updated_at = now();
  return new;
end;
$$ language plpgsql security definer;

create trigger child_accounts_updated_at
  before update on public.child_accounts
  for each row execute function public.handle_child_account_update();

create policy "Parents can manage children in their family"
  on public.child_accounts
  for all
  to authenticated
  using (
    exists (
      select 1 from public.family_members fm
      where fm.family_id = child_accounts.family_id
      and fm.user_id = auth.uid()
      and fm.role in ('admin', 'parent')
    )
  )
  with check (
    exists (
      select 1 from public.family_members fm
      where fm.family_id = child_accounts.family_id
      and fm.user_id = auth.uid()
      and fm.role in ('admin', 'parent')
    )
  );

create policy "Children can read their own account"
  on public.child_accounts
  for select
  to authenticated
  using (
    id::text = coalesce(current_setting('app.child_id', true), '')
  );

create policy "Parents can view child sessions"
  on public.child_sessions
  for select
  to authenticated
  using (
    exists (
      select 1 from public.family_members fm
      where fm.family_id = child_sessions.family_id
      and fm.user_id = auth.uid()
      and fm.role in ('admin', 'parent')
    )
  );

create policy "Parents can view child activity"
  on public.child_activity_logs
  for select
  to authenticated
  using (
    exists (
      select 1 from public.family_members fm
      where fm.family_id = child_activity_logs.family_id
      and fm.user_id = auth.uid()
      and fm.role in ('admin', 'parent')
    )
  );

create or replace function public.verify_child_pin(
  p_child_id uuid,
  p_pin text,
  p_device_info text default null
)
returns table (
  session_token text,
  expires_at timestamptz,
  child_name text,
  child_role text,
  family_id uuid
) as $$
declare
  v_child record;
  v_token text;
  v_expires timestamptz;
begin
  select * into v_child from public.child_accounts
  where id = p_child_id and is_active = true;

  if v_child is null then
    raise exception 'Child account not found';
  end if;

  if v_child.pin_hash != p_pin then
    raise exception 'Invalid PIN';
  end if;

  v_token := encode(gen_random_bytes(32), 'hex');
  v_expires := now() + interval '30 days';

  insert into public.child_sessions (child_id, family_id, token, device_info, expires_at)
  values (v_child.id, v_child.family_id, v_token, p_device_info, v_expires);

  update public.child_accounts set last_active_at = now() where id = v_child.id;

  insert into public.child_activity_logs (child_id, family_id, activity_type, details)
  values (v_child.id, v_child.family_id, 'login', jsonb_build_object('device', p_device_info));

  return query select v_token, v_expires, v_child.name, v_child.role, v_child.family_id;
end;
$$ language plpgsql security definer;

create or replace function public.validate_child_session(p_token text)
returns table (
  child_id uuid,
  family_id uuid,
  child_name text,
  child_role text,
  is_valid boolean
) as $$
begin
  return query
  select 
    cs.child_id,
    cs.family_id,
    ca.name as child_name,
    ca.role as child_role,
    (cs.expires_at > now()) as is_valid
  from public.child_sessions cs
  join public.child_accounts ca on ca.id = cs.child_id
  where cs.token = p_token;

  update public.child_sessions set last_used_at = now() where token = p_token;
end;
$$ language plpgsql security definer;

create or replace function public.revoke_child_session(p_token text)
returns void as $$
begin
  delete from public.child_sessions where token = p_token;
end;
$$ language plpgsql security definer;

create or replace function public.log_child_activity(
  p_child_id uuid,
  p_activity_type text,
  p_details jsonb default '{}'
)
returns void as $$
declare
  v_family_id uuid;
begin
  select family_id into v_family_id from public.child_accounts where id = p_child_id;
  
  insert into public.child_activity_logs (child_id, family_id, activity_type, details)
  values (p_child_id, v_family_id, p_activity_type, p_details);
end;
$$ language plpgsql security definer;

alter table public.child_accounts enable row level security;
alter table public.child_sessions enable row level security;
alter table public.child_activity_logs enable row level security;

-- ============================================
-- STEP 6: ADD MIRAC KOCA AS CHILD
-- ============================================
insert into public.child_accounts (family_id, name, pin_hash, role, color, created_by)
select f.id, 'Miraç', '1234', 'child', '#10B981', p.id
from public.families f
join public.profiles p on p.email = 'mcemkoca0@gmail.com'
on conflict do nothing;

-- ============================================
-- STEP 7: ANON POLICY FOR CHILD LOGIN SCREEN
-- ============================================
drop policy if exists "Anon can view child accounts for login" on public.child_accounts;
create policy "Anon can view child accounts for login"
  on public.child_accounts
  for select
  to anon
  using (true);
