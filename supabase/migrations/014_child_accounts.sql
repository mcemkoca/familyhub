-- ============================================
-- CHILD ACCOUNTS (Module 20)
-- PIN-based accounts for children without email
-- ============================================

-- Ensure pgcrypto is available for crypt()
create extension if not exists "pgcrypto";

-- Child accounts table (no auth.users link - managed independently)
create table if not exists public.child_accounts (
  id uuid default gen_random_uuid() primary key,
  family_id uuid references public.families(id) on delete cascade not null,
  name text not null,
  pin_hash text not null, -- bcrypt hash of 4-6 digit PIN
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

-- Child sessions for token-based auth
create table if not exists public.child_sessions (
  id uuid default gen_random_uuid() primary key,
  child_id uuid references public.child_accounts(id) on delete cascade not null,
  family_id uuid references public.families(id) on delete cascade not null,
  token text unique not null,
  device_info text,
  expires_at timestamptz not null,
  created_at timestamptz default now(),
  last_used_at timestamptz default now()
);

-- Child activity log (for parents to monitor)
create table if not exists public.child_activity_logs (
  id uuid default gen_random_uuid() primary key,
  child_id uuid references public.child_accounts(id) on delete cascade not null,
  family_id uuid references public.families(id) on delete cascade not null,
  activity_type text not null check (activity_type in ('login', 'logout', 'task_completed', 'message_sent', 'location_shared', 'emergency_pressed', 'settings_changed')),
  details jsonb default '{}',
  created_at timestamptz default now()
);

-- Indexes
create index if not exists idx_child_accounts_family on public.child_accounts(family_id);
create index if not exists idx_child_accounts_active on public.child_accounts(family_id, is_active);
create index if not exists idx_child_sessions_token on public.child_sessions(token);
create index if not exists idx_child_sessions_child on public.child_sessions(child_id);
create index if not exists idx_child_activity_logs_child on public.child_activity_logs(child_id, created_at desc);

-- Updated at triggers
create or replace function public.handle_child_account_update()
returns trigger as $$
begin
  new.updated_at = now();
  return new;
end;
$$ language plpgsql security definer;

drop trigger if exists child_accounts_updated_at on public.child_accounts;
create trigger child_accounts_updated_at
  before update on public.child_accounts
  for each row execute function public.handle_child_account_update();

-- RLS Policies for child_accounts
drop policy if exists "Parents can manage children in their family" on public.child_accounts;
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

drop policy if exists "Children can read their own account" on public.child_accounts;
create policy "Children can read their own account"
  on public.child_accounts
  for select
  to authenticated
  using (
    id::text = coalesce(current_setting('app.child_id', true), '')
  );

-- RLS Policies for child_sessions (managed via RPC mostly)
drop policy if exists "Parents can view child sessions" on public.child_sessions;
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

-- RLS Policies for child_activity_logs
drop policy if exists "Parents can view child activity" on public.child_activity_logs;
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

-- Function to verify child PIN and create session
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
  -- Get child account
  select * into v_child from public.child_accounts
  where id = p_child_id and is_active = true;

  if v_child is null then
    raise exception 'Child account not found';
  end if;

  -- Secure PIN comparison using pgcrypto crypt()
  if v_child.pin_hash is null or not crypt(p_pin, v_child.pin_hash) = v_child.pin_hash then
    raise exception 'Invalid PIN';
  end if;

  -- Generate session token
  v_token := encode(gen_random_bytes(32), 'hex');
  v_expires := now() + interval '30 days';

  -- Create session
  insert into public.child_sessions (child_id, family_id, token, device_info, expires_at)
  values (v_child.id, v_child.family_id, v_token, p_device_info, v_expires);

  -- Update last active
  update public.child_accounts set last_active_at = now() where id = v_child.id;

  -- Log activity
  insert into public.child_activity_logs (child_id, family_id, activity_type, details)
  values (v_child.id, v_child.family_id, 'login', jsonb_build_object('device', p_device_info));

  return query select v_token, v_expires, v_child.name, v_child.role, v_child.family_id;
end;
$$ language plpgsql security definer;

-- Function to validate child session token
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

  -- Update last used
  update public.child_sessions set last_used_at = now() where token = p_token;
end;
$$ language plpgsql security definer;

-- Function to revoke child session
create or replace function public.revoke_child_session(p_token text)
returns void as $$
begin
  delete from public.child_sessions where token = p_token;
end;
$$ language plpgsql security definer;

-- Function to log child activity
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

-- Enable RLS
alter table if exists public.child_accounts enable row level security;
alter table if exists public.child_sessions enable row level security;
alter table if exists public.child_activity_logs enable row level security;
