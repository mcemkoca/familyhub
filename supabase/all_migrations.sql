\n-- ============================================\n-- FILE: 001_complete_schema.sql\n-- ============================================\n-- ============================================-- EXTENSIONS-- ============================================create extension if not exists "uuid-ossp";create extension if not exists "pgcrypto";-- ============================================-- PROFILES (Auth users extension)-- ============================================create table if not exists public.profiles (  id uuid references auth.users on delete cascade primary key,  display_name text not null,  avatar_url text,  phone text unique,  email text unique not null,  date_of_birth date,  blood_type text check (blood_type in ('A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', '0+', '0-')),  allergies text[] default '{}',  chronic_conditions text[] default '{}',  medications jsonb default '[]',  emergency_contact_name text,  emergency_contact_phone text,  emergency_contact_relation text,  preferred_language text default 'tr',  theme_preference text default 'system',  created_at timestamptz default now(),  updated_at timestamptz default now());-- ============================================-- FAMILIES-- ============================================create table if not exists public.families (  id uuid default uuid_generate_v4() primary key,  name text not null,  invite_code text unique not null,  invite_code_expires_at timestamptz,  created_by uuid references public.profiles(id) not null,  subscription_tier text default 'free' check (subscription_tier in ('free', 'premium', 'family')),  subscription_expires_at timestamptz,  max_members int default 4,  settings jsonb default '{    "auto_approve_members": false,    "default_reminders": [15],    "location_sharing": true,    "task_notifications": true,    "event_notifications": true,    "emergency_notifications": true  }',  created_at timestamptz default now(),  updated_at timestamptz default now());-- ============================================-- FAMILY MEMBERS-- ============================================create table if not exists public.family_members (  family_id uuid references public.families(id) on delete cascade,  user_id uuid references public.profiles(id) on delete cascade,  role text default 'member' check (role in ('admin', 'parent', 'teen', 'child', 'elder', 'guest', 'baby')),  display_name text,  color text default '#3B82F6',  joined_at timestamptz default now(),  last_active_at timestamptz,  is_active boolean default true,  primary key (family_id, user_id));-- Safely add missing columns if table already existed without themalter table public.family_members add column if not exists role text default 'member' check (role in ('admin', 'parent', 'teen', 'child', 'elder', 'guest', 'baby'));alter table public.family_members add column if not exists display_name text;alter table public.family_members add column if not exists color text default '#3B82F6';alter table public.family_members add column if not exists joined_at timestamptz default now();alter table public.family_members add column if not exists last_active_at timestamptz;alter table public.family_members add column if not exists is_active boolean default true;-- ============================================-- EVENTS-- ============================================create table if not exists public.events (  id uuid default uuid_generate_v4() primary key,  family_id uuid references public.families(id) on delete cascade not null,  created_by uuid references public.profiles(id) not null,  title text not null,  description text,  location text,  location_lat numeric,  location_lng numeric,  category text default 'other' check (category in ('appointment', 'birthday', 'school', 'activity', 'work', 'family', 'travel', 'other')),  start_time timestamptz not null,  end_time timestamptz not null,  is_all_day boolean default false,  recurrence_rule text,  reminders int[] default '{15}',  status text default 'active' check (status in ('active', 'cancelled', 'completed')),  created_at timestamptz default now(),  updated_at timestamptz default now());-- ============================================-- EVENT ATTENDEES-- ============================================create table if not exists public.event_attendees (  event_id uuid references public.events(id) on delete cascade,  user_id uuid references public.profiles(id) on delete cascade,  rsvp_status text default 'pending' check (rsvp_status in ('pending', 'accepted', 'declined', 'maybe')),  notified boolean default false,  primary key (event_id, user_id));-- ============================================-- TASKS-- ============================================create table if not exists public.tasks (  id uuid default uuid_generate_v4() primary key,  family_id uuid references public.families(id) on delete cascade not null,  title text not null,  description text,  assigned_to uuid references public.profiles(id),  created_by uuid references public.profiles(id) not null,  due_date timestamptz,  priority text default 'medium' check (priority in ('low', 'medium', 'high', 'urgent')),  status text default 'pending' check (status in ('pending', 'in_progress', 'completed', 'cancelled')),  category text default 'other' check (category in ('shopping', 'chore', 'homework', 'appointment', 'other')),  checklist jsonb default '[]',  attachments jsonb default '[]',  completed_at timestamptz,  completed_by uuid references public.profiles(id),  created_at timestamptz default now(),  updated_at timestamptz default now());-- ============================================-- MESSAGES-- ============================================create table if not exists public.messages (  id uuid default uuid_generate_v4() primary key,  family_id uuid references public.families(id) on delete cascade not null,  user_id uuid references public.profiles(id) not null,  text text,  type text default 'text' check (type in ('text', 'image', 'video', 'audio', 'location', 'event_share', 'announcement', 'mood')),  media_urls text[],  reply_to uuid references public.messages(id),  read_by uuid[] default '{}',  reactions jsonb default '{}',  pinned boolean default false,  created_at timestamptz default now(),  updated_at timestamptz default now());-- ============================================-- GEOLOCATIONS (Live tracking)-- ============================================create table if not exists public.geolocations (  id uuid default uuid_generate_v4() primary key,  user_id uuid references public.profiles(id) on delete cascade,  family_id uuid references public.families(id) on delete cascade,  lat numeric not null,  lng numeric not null,  accuracy numeric,  altitude numeric,  speed numeric,  heading numeric,  battery_level int,  is_moving boolean default false,  created_at timestamptz default now());-- ============================================-- BUDGET ENTRIES-- ============================================create table if not exists public.budget_entries (  id uuid default uuid_generate_v4() primary key,  family_id uuid references public.families(id) on delete cascade,  created_by uuid references public.profiles(id),  amount numeric not null,  currency text default 'TRY',  category text,  description text,  receipt_url text,  split_with uuid[],  paid_by uuid references public.profiles(id),  date timestamptz default now(),  created_at timestamptz default now());-- ============================================-- ACTIVITY LOGS (Audit trail)-- ============================================create table if not exists public.activity_logs (  id uuid default uuid_generate_v4() primary key,  user_id uuid references public.profiles(id),  family_id uuid references public.families(id),  action text not null,  entity_type text,  entity_id uuid,  metadata jsonb,  created_at timestamptz default now());-- ============================================-- FUNCTIONS-- ============================================-- Generate invite codecreate or replace function public.generate_invite_code()returns text as $$declare  code text;  exists_check boolean;begin  loop    code := upper(substring(md5(random()::text) from 1 for 8));    select exists(select 1 from public.families where invite_code = code) into exists_check;    exit when not exists_check;  end loop;  return code;end;$$ language plpgsql;-- Auto-generate invite code on family creationcreate or replace function public.handle_new_family()returns trigger as $$begin  new.invite_code := public.generate_invite_code();  new.invite_code_expires_at := now() + interval '7 days';  return new;end;$$ language plpgsql security definer;drop trigger if exists on_family_created on public.families;create trigger on_family_created  before insert on public.families  for each row execute procedure public.handle_new_family();-- New user profile creationcreate or replace function public.handle_new_user()returns trigger as $$begin  insert into public.profiles (id, display_name, email)  values (    new.id,    coalesce(new.raw_user_meta_data->>'display_name', split_part(new.email, '@', 1)),    new.email  )  on conflict (id) do nothing;  return new;end;$$ language plpgsql security definer;drop trigger if exists on_auth_user_created on auth.users;create trigger on_auth_user_created  after insert on auth.users  for each row execute procedure public.handle_new_user();-- ============================================-- ROW LEVEL SECURITY-- ============================================alter table if exists public.profiles enable row level security;alter table if exists public.families enable row level security;alter table if exists public.family_members enable row level security;alter table if exists public.events enable row level security;alter table if exists public.event_attendees enable row level security;alter table if exists public.tasks enable row level security;alter table if exists public.messages enable row level security;alter table if exists public.geolocations enable row level security;alter table if exists public.budget_entries enable row level security;alter table if exists public.activity_logs enable row level security;-- Profiles: own onlydrop policy if exists "Users view own profile" on public.profiles;create policy "Users view own profile"  on public.profiles for select  using (auth.uid() = id);drop policy if exists "Users update own profile" on public.profiles;create policy "Users update own profile"  on public.profiles for update  using (auth.uid() = id);-- Families: members onlydrop policy if exists "Family members view" on public.families;create policy "Family members view"  on public.families for select  using (    id in (select family_id from public.family_members where user_id = auth.uid())  );drop policy if exists "Admins update" on public.families;create policy "Admins update"  on public.families for update  using (    id in (      select family_id from public.family_members      where user_id = auth.uid() and role = 'admin'    )  );-- Events: family membersdrop policy if exists "Events view" on public.events;create policy "Events view"  on public.events for select  using (    family_id in (select family_id from public.family_members where user_id = auth.uid())  );drop policy if exists "Events create" on public.events;create policy "Events create"  on public.events for insert  with check (    family_id in (select family_id from public.family_members where user_id = auth.uid())  );-- Tasks: family membersdrop policy if exists "Tasks view" on public.tasks;create policy "Tasks view"  on public.tasks for select  using (    family_id in (select family_id from public.family_members where user_id = auth.uid())  );-- Messages: family membersdrop policy if exists "Messages view" on public.messages;create policy "Messages view"  on public.messages for select  using (    family_id in (select family_id from public.family_members where user_id = auth.uid())  );drop policy if exists "Messages insert" on public.messages;create policy "Messages insert"  on public.messages for insert  with check (    family_id in (select family_id from public.family_members where user_id = auth.uid())  );-- ============================================-- REALTIME-- ============================================do $$begin  if not exists (    select 1 from pg_publication_tables    where pubname = 'supabase_realtime' and tablename = 'messages'  ) then    alter publication supabase_realtime add table public.messages;  end if;end $$;do $$begin  if not exists (    select 1 from pg_publication_tables    where pubname = 'supabase_realtime' and tablename = 'events'  ) then    alter publication supabase_realtime add table public.events;  end if;end $$;do $$begin  if not exists (    select 1 from pg_publication_tables    where pubname = 'supabase_realtime' and tablename = 'tasks'  ) then    alter publication supabase_realtime add table public.tasks;  end if;end $$;do $$begin  if not exists (    select 1 from pg_publication_tables    where pubname = 'supabase_realtime' and tablename = 'geolocations'  ) then    alter publication supabase_realtime add table public.geolocations;  end if;end $$;do $$begin  if not exists (    select 1 from pg_publication_tables    where pubname = 'supabase_realtime' and tablename = 'family_members'  ) then    alter publication supabase_realtime add table public.family_members;  end if;end $$;-- ============================================-- INDEXES-- ============================================create index if not exists idx_events_family_time on public.events(family_id, start_time);create index if not exists idx_tasks_family_status on public.tasks(family_id, status);create index if not exists idx_messages_family_time on public.messages(family_id, created_at);create index if not exists idx_geolocations_user on public.geolocations(user_id, created_at desc);create index if not exists idx_activity_logs_user on public.activity_logs(user_id, created_at);create index if not exists idx_family_members_family on public.family_members(family_id);\n-- ============================================\n-- FILE: 002_hub_tables.sql\n-- ============================================\n-- ============================================-- HUB TABLES (Extension to 001_complete_schema)-- ============================================-- ============================================-- HUB WIDGET STATE (User widget preferences)-- ============================================create table if not exists public.hub_widgets (  id uuid default uuid_generate_v4() primary key,  user_id uuid references public.profiles(id) on delete cascade,  family_id uuid references public.families(id) on delete cascade,  widget_type text not null check (widget_type in (    'today_summary', 'upcoming_events', 'my_tasks',    'family_mood', 'weather', 'quick_actions'  )),  is_visible boolean default true,  sort_order int default 0,  config jsonb default '{}',  updated_at timestamptz default now(),  unique(user_id, family_id, widget_type));-- ============================================-- FAMILY MOOD (Mood sharing)-- ============================================create table if not exists public.family_moods (  id uuid default uuid_generate_v4() primary key,  family_id uuid references public.families(id) on delete cascade,  user_id uuid references public.profiles(id) on delete cascade,  mood_emoji text not null,  mood_note text,  energy_level int check (energy_level between 1 and 10),  is_shared boolean default true,  created_at timestamptz default now());-- ============================================-- WEATHER CACHE-- ============================================create table if not exists public.weather_cache (  id uuid default uuid_generate_v4() primary key,  family_id uuid references public.families(id) on delete cascade,  location_lat numeric,  location_lng numeric,  location_name text,  current_temp numeric,  condition text,  icon_code text,  humidity int,  wind_speed numeric,  forecast jsonb,  cached_at timestamptz default now(),  expires_at timestamptz default (now() + interval '1 hour'),  unique(family_id, location_lat, location_lng));-- ============================================-- RLS POLICIES FOR HUB TABLES-- ============================================alter table if exists public.hub_widgets enable row level security;alter table if exists public.family_moods enable row level security;alter table if exists public.weather_cache enable row level security;drop policy if exists "Hub widgets own" on public.hub_widgets;create policy "Hub widgets own"  on public.hub_widgets for all  using (user_id = auth.uid());drop policy if exists "Family moods view" on public.family_moods;create policy "Family moods view"  on public.family_moods for select  using (family_id in (    select family_id from public.family_members where user_id = auth.uid()  ));drop policy if exists "Family moods insert" on public.family_moods;create policy "Family moods insert"  on public.family_moods for insert  with check (user_id = auth.uid());drop policy if exists "Weather cache family" on public.weather_cache;create policy "Weather cache family"  on public.weather_cache for select  using (family_id in (    select family_id from public.family_members where user_id = auth.uid()  ));-- ============================================-- REALTIME-- ============================================do $$begin  if not exists (    select 1 from pg_publication_tables    where pubname = 'supabase_realtime' and tablename = 'family_moods'  ) then    alter publication supabase_realtime add table public.family_moods;  end if;end $$;-- ============================================-- INDEXES-- ============================================create index if not exists idx_family_moods_family on public.family_moods(family_id, created_at desc);create index if not exists idx_weather_cache_family on public.weather_cache(family_id);\n-- ============================================\n-- FILE: 003_analytics_and_billing.sql\n-- ============================================\n-- ============================================================-- Migration 003: Analytics, Billing, Referrals, Enterprise-- ============================================================-- Ensure is_admin column exists before policies reference itALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS is_admin boolean default false;-- Analytics events tableCREATE TABLE IF NOT EXISTS public.analytics_events (  id uuid DEFAULT gen_random_uuid() PRIMARY KEY,  event text NOT NULL,  properties jsonb DEFAULT '{}',  user_id uuid REFERENCES public.profiles(id) ON DELETE SET NULL,  created_at timestamptz DEFAULT now());ALTER TABLE IF EXISTS public.analytics_events ENABLE ROW LEVEL SECURITY;DROP POLICY IF EXISTS "Analytics events are insertable by authenticated users" ON public.analytics_events;CREATE POLICY "Analytics events are insertable by authenticated users"  ON public.analytics_events FOR INSERT TO authenticated WITH CHECK (true);DROP POLICY IF EXISTS "Analytics events are viewable by admins" ON public.analytics_events;CREATE POLICY "Analytics events are viewable by admins"  ON public.analytics_events FOR SELECT TO authenticated USING (    EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND is_admin = true)  );-- Heatmap tracking tableCREATE TABLE IF NOT EXISTS public.heatmaps (  id uuid DEFAULT gen_random_uuid() PRIMARY KEY,  type text NOT NULL CHECK (type IN ('tap', 'scroll')),  screen text NOT NULL,  element_id text,  x numeric,  y numeric,  scroll_depth numeric,  user_id uuid REFERENCES public.profiles(id) ON DELETE SET NULL,  created_at timestamptz DEFAULT now());ALTER TABLE IF EXISTS public.heatmaps ENABLE ROW LEVEL SECURITY;DROP POLICY IF EXISTS "Heatmaps are insertable by authenticated users" ON public.heatmaps;CREATE POLICY "Heatmaps are insertable by authenticated users"  ON public.heatmaps FOR INSERT TO authenticated WITH CHECK (true);DROP POLICY IF EXISTS "Heatmaps are viewable by admins" ON public.heatmaps;CREATE POLICY "Heatmaps are viewable by admins"  ON public.heatmaps FOR SELECT TO authenticated USING (    EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND is_admin = true)  );-- Referrals tableCREATE TABLE IF NOT EXISTS public.referrals (  id uuid DEFAULT gen_random_uuid() PRIMARY KEY,  code text NOT NULL UNIQUE,  inviter_id uuid REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,  invited_id uuid REFERENCES public.profiles(id) ON DELETE SET NULL,  family_id uuid REFERENCES public.families(id) ON DELETE CASCADE NOT NULL,  status text DEFAULT 'active' CHECK (status IN ('active', 'completed', 'expired')),  created_at timestamptz DEFAULT now(),  completed_at timestamptz);ALTER TABLE IF EXISTS public.referrals ENABLE ROW LEVEL SECURITY;DROP POLICY IF EXISTS "Referrals are viewable by inviter or invited" ON public.referrals;CREATE POLICY "Referrals are viewable by inviter or invited"  ON public.referrals FOR SELECT TO authenticated USING (    inviter_id = auth.uid() OR invited_id = auth.uid()  );DROP POLICY IF EXISTS "Referrals are insertable by authenticated users" ON public.referrals;CREATE POLICY "Referrals are insertable by authenticated users"  ON public.referrals FOR INSERT TO authenticated WITH CHECK (inviter_id = auth.uid());-- Subscriptions tableCREATE TABLE IF NOT EXISTS public.subscriptions (  id uuid DEFAULT gen_random_uuid() PRIMARY KEY,  user_id uuid REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,  subscription_tier text NOT NULL CHECK (subscription_tier IN ('free', 'premium', 'family')),  amount numeric,  currency text DEFAULT 'USD',  status text DEFAULT 'active' CHECK (status IN ('active', 'cancelled', 'expired')),  expires_at timestamptz,  created_at timestamptz DEFAULT now());ALTER TABLE IF EXISTS public.subscriptions ENABLE ROW LEVEL SECURITY;DROP POLICY IF EXISTS "Users can view own subscriptions" ON public.subscriptions;CREATE POLICY "Users can view own subscriptions"  ON public.subscriptions FOR SELECT TO authenticated USING (user_id = auth.uid());-- Organizations table (Enterprise)CREATE TABLE IF NOT EXISTS public.organizations (  id uuid DEFAULT gen_random_uuid() PRIMARY KEY,  name text NOT NULL,  domain text NOT NULL UNIQUE,  employee_count integer,  admin_email text NOT NULL,  status text DEFAULT 'pending_verification' CHECK (status IN ('pending_verification', 'verified', 'suspended')),  verified_at timestamptz,  created_at timestamptz DEFAULT now());ALTER TABLE IF EXISTS public.organizations ENABLE ROW LEVEL SECURITY;DROP POLICY IF EXISTS "Organizations are viewable by admin members" ON public.organizations;CREATE POLICY "Organizations are viewable by admin members"  ON public.organizations FOR SELECT TO authenticated USING (    EXISTS (      SELECT 1 FROM public.profiles      WHERE id = auth.uid() AND (is_admin = true OR email = organizations.admin_email)    )  );-- SSO configs tableCREATE TABLE IF NOT EXISTS public.sso_configs (  id uuid DEFAULT gen_random_uuid() PRIMARY KEY,  org_id uuid REFERENCES public.organizations(id) ON DELETE CASCADE NOT NULL,  provider text NOT NULL,  metadata_xml text,  status text DEFAULT 'pending_setup' CHECK (status IN ('pending_setup', 'active', 'disabled')),  created_at timestamptz DEFAULT now());ALTER TABLE IF EXISTS public.sso_configs ENABLE ROW LEVEL SECURITY;DROP POLICY IF EXISTS "SSO configs are viewable by org admins" ON public.sso_configs;CREATE POLICY "SSO configs are viewable by org admins"  ON public.sso_configs FOR SELECT TO authenticated USING (    EXISTS (      SELECT 1 FROM public.organizations      WHERE id = sso_configs.org_id AND admin_email = auth.email()    )  );-- Add premium fields to profilesALTER TABLE public.profiles  ADD COLUMN IF NOT EXISTS subscription_tier text DEFAULT 'free' CHECK (subscription_tier IN ('free', 'premium', 'family')),  ADD COLUMN IF NOT EXISTS subscription_expires_at timestamptz,  ADD COLUMN IF NOT EXISTS referral_code text;-- ============================================================-- Admin Analytics Views-- ============================================================CREATE OR REPLACE VIEW public.daily_active_users ASSELECT  date_trunc('day', created_at)::date AS date,  count(DISTINCT user_id) AS dauFROM public.analytics_eventsWHERE created_at > now() - interval '30 days'GROUP BY 1ORDER BY 1 DESC;CREATE OR REPLACE VIEW public.retention_cohort ASWITH first_seen AS (  SELECT    user_id,    min(date_trunc('day', created_at)::date) AS first_day  FROM public.analytics_events  GROUP BY 1)SELECT  fs.first_day AS cohort,  (date_trunc('day', ae.created_at)::date - fs.first_day) AS day_offset,  count(DISTINCT ae.user_id) AS retained_usersFROM first_seen fsJOIN public.analytics_events ae ON fs.user_id = ae.user_idGROUP BY 1, 2ORDER BY 1 DESC, 2;CREATE OR REPLACE VIEW public.revenue_metrics ASSELECT  date_trunc('month', created_at)::date AS month,  count(*) AS new_subscriptions,  coalesce(sum(amount), 0) AS revenue,  currency,  subscription_tierFROM public.subscriptionsWHERE status = 'active'GROUP BY 1, 4, 5ORDER BY 1 DESC;-- ============================================================-- RPC Functions-- ============================================================CREATE OR REPLACE FUNCTION public.add_premium_days(user_id uuid, days integer)RETURNS voidLANGUAGE plpgsqlSECURITY DEFINERAS $$BEGIN  UPDATE public.profiles  SET    subscription_tier = 'premium',    subscription_expires_at = coalesce(subscription_expires_at, now()) + (days || ' days')::interval  WHERE id = user_id;END;$$;CREATE OR REPLACE FUNCTION public.get_org_stats(org_id uuid)RETURNS jsonbLANGUAGE plpgsqlSECURITY DEFINERAS $$DECLARE  result jsonb;BEGIN  SELECT jsonb_build_object(    'total_employees', o.employee_count,    'active_families', (SELECT count(*) FROM public.families WHERE created_at > now() - interval '30 days'),    'engagement_rate', 0.75, -- Placeholder: compute from analytics_events    'health_score', 82,      -- Placeholder: compute from family_moods    'reduced_sick_days', 12,    'retention_improvement', 0.18,    'productivity_gain', 0.23  ) INTO result  FROM public.organizations o  WHERE o.id = org_id;  RETURN result;END;$$;CREATE OR REPLACE FUNCTION public.send_verification_email(to_email text, org_id uuid)RETURNS voidLANGUAGE plpgsqlSECURITY DEFINERAS $$BEGIN  -- Placeholder: integrate with Supabase Edge Functions or external email provider  PERFORM pg_notify('verification_email', json_build_object('email', to_email, 'org_id', org_id)::text);END;$$;\n-- ============================================\n-- FILE: 005_hub_enhancements.sql\n-- ============================================\n-- ============================================-- HUB ENHANCEMENTS (AI Suggestions + Realtime + Widget Types)-- ============================================-- ============================================-- AI SUGGESTIONS CACHE-- ============================================create table if not exists public.ai_suggestions_cache (  id uuid default gen_random_uuid() primary key,  family_id uuid references public.families(id) on delete cascade,  suggestions jsonb not null,  context_hash text,  generated_at timestamptz default now(),  expires_at timestamptz default (now() + interval '30 minutes'));-- ============================================-- RLS FOR AI SUGGESTIONS-- ============================================alter table if exists public.ai_suggestions_cache enable row level security;drop policy if exists "AI suggestions family view" on public.ai_suggestions_cache;create policy "AI suggestions family view"  on public.ai_suggestions_cache for select  using (family_id in (    select family_id from public.family_members where user_id = auth.uid()  ));-- ============================================-- HUB WIDGETS: Expand widget_type constraint-- Drop old check constraint and recreate with expanded list-- ============================================alter table public.hub_widgets drop constraint if exists hub_widgets_widget_type_check;alter table public.hub_widgets add constraint hub_widgets_widget_type_check  check (widget_type in (    'today_summary', 'upcoming_events', 'my_tasks',    'family_mood', 'weather', 'quick_actions',    'ai_suggestions', 'smart_home', 'health_summary'  ));-- ============================================-- REALTIME: Enable for events and tasks-- ============================================do $$begin  if not exists (    select 1 from pg_publication_tables    where pubname = 'supabase_realtime' and tablename = 'events'  ) then    alter publication supabase_realtime add table public.events;  end if;end $$;do $$begin  if not exists (    select 1 from pg_publication_tables    where pubname = 'supabase_realtime' and tablename = 'tasks'  ) then    alter publication supabase_realtime add table public.tasks;  end if;end $$;-- ============================================-- INDEXES-- ============================================create index if not exists idx_ai_suggestions_family on public.ai_suggestions_cache(family_id, expires_at desc);create index if not exists idx_hub_widgets_user on public.hub_widgets(user_id, family_id);\n-- ============================================\n-- FILE: 006_profiles_and_premium.sql\n-- ============================================\n-- Profiles table with premium statuscreate table if not exists public.profiles (  id uuid references auth.users on delete cascade primary key,  display_name text,  family_name text,  is_premium boolean default false,  created_at timestamptz default now(),  updated_at timestamptz default now());-- Enable RLSalter table if exists public.profiles enable row level security;-- RLS Policiesdrop policy if exists "Profiles are viewable by everyone" on public.profiles;create policy "Profiles are viewable by everyone"  on public.profiles for select  using (true);drop policy if exists "Users can insert their own profile" on public.profiles;create policy "Users can insert their own profile"  on public.profiles for insert  with check (auth.uid() = id);drop policy if exists "Users can update own profile" on public.profiles;create policy "Users can update own profile"  on public.profiles for update  using (auth.uid() = id);-- Function to create profile on signupcreate or replace function public.handle_new_user()returns trigger as $$begin  insert into public.profiles (id, display_name, family_name)  values (    new.id,    new.raw_user_meta_data->>'display_name',    new.raw_user_meta_data->>'family_name'  )  on conflict (id) do nothing;  return new;end;$$ language plpgsql security definer;-- Trigger to auto-create profiledrop trigger if exists on_auth_user_created on auth.users;create trigger on_auth_user_created  after insert on auth.users  for each row execute procedure public.handle_new_user();\n-- ============================================\n-- FILE: 007_admin_and_subscription.sql\n-- ============================================\n-- Add admin and subscription fields to profilesalter table public.profiles  add column if not exists is_admin boolean default false,  add column if not exists subscription_tier text default 'free',  add column if not exists subscription_expires_at timestamptz;-- Update existing mcemkoca0@gmail.com user to admin + premium-- NOTE: Run this after the user has signed up at least once-- so the trigger creates their profile row first.-- update public.profiles-- set is_admin = true,--     is_premium = true,--     subscription_tier = 'premium'-- where id = (--   select id from auth.users where email = 'mcemkoca0@gmail.com'-- );\n-- ============================================\n-- FILE: 008_auto_confirm_email.sql\n-- ============================================\n-- Auto-confirm new users to bypass email verification-- This allows immediate signIn after signUp-- 1. Create function to auto-confirm email on user creationcreate or replace function public.auto_confirm_email()returns trigger as $$begin  update auth.users set email_confirmed_at = now() where id = new.id;  return new;end;$$ language plpgsql security definer;-- 2. Drop existing trigger if presentdrop trigger if exists on_auth_user_created on auth.users;-- 3. Attach trigger to auth.userscreate trigger on_auth_user_created  after insert on auth.users  for each row execute procedure public.auto_confirm_email();-- 4. Confirm existing demo user (if already created without confirmation)update auth.users set email_confirmed_at = now() where email = 'mcemkoca0@gmail.com';-- 5. Optional: also update metadata to mark as confirmedupdate auth.usersset raw_user_meta_data = coalesce(raw_user_meta_data, '{}'::jsonb) || '{"email_confirmed": true}'::jsonbwhere email = 'mcemkoca0@gmail.com';\n-- ============================================\n-- FILE: 009_smart_reminders.sql\n-- ============================================\n-- Smart Reminders System Migration-- Tables: smart_reminders, context_snapshots, reminder_interactions-- ── SMART REMINDERS ────────────────────────────────────────────────────CREATE TABLE IF NOT EXISTS smart_reminders (  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),  family_id UUID NOT NULL REFERENCES families(id) ON DELETE CASCADE,  created_by UUID REFERENCES profiles(id) ON DELETE SET NULL,  title TEXT NOT NULL,  description TEXT,  triggers JSONB NOT NULL DEFAULT '{}',  context_sensitivity JSONB NOT NULL DEFAULT '{}',  personalization JSONB NOT NULL DEFAULT '{}',  target_audience JSONB NOT NULL DEFAULT '{}',  status JSONB NOT NULL DEFAULT '{"state": "active", "trigger_count": 0, "completion_rate": 0}',  created_at TIMESTAMPTZ DEFAULT now(),  updated_at TIMESTAMPTZ DEFAULT now(),  version INTEGER DEFAULT 1);COMMENT ON TABLE smart_reminders IS 'Context-aware smart reminders with location/time/behavior triggers';-- RLSALTER TABLE IF EXISTS smart_reminders ENABLE ROW LEVEL SECURITY;DROP POLICY IF EXISTS "family_members_can_view_reminders" ON smart_reminders;CREATE POLICY "family_members_can_view_reminders"  ON smart_reminders FOR SELECT  USING (    EXISTS (      SELECT 1 FROM family_members fm      WHERE fm.family_id = smart_reminders.family_id      AND fm.user_id = auth.uid()    )  );DROP POLICY IF EXISTS "family_members_can_create_reminders" ON smart_reminders;CREATE POLICY "family_members_can_create_reminders"  ON smart_reminders FOR INSERT  WITH CHECK (    EXISTS (      SELECT 1 FROM family_members fm      WHERE fm.family_id = smart_reminders.family_id      AND fm.user_id = auth.uid()    )  );DROP POLICY IF EXISTS "creators_can_update_reminders" ON smart_reminders;CREATE POLICY "creators_can_update_reminders"  ON smart_reminders FOR UPDATE  USING (created_by = auth.uid())  WITH CHECK (created_by = auth.uid());DROP POLICY IF EXISTS "creators_can_delete_reminders" ON smart_reminders;CREATE POLICY "creators_can_delete_reminders"  ON smart_reminders FOR DELETE  USING (created_by = auth.uid());-- IndexCREATE INDEX IF NOT EXISTS idx_smart_reminders_family ON smart_reminders(family_id);CREATE INDEX IF NOT EXISTS idx_smart_reminders_created_by ON smart_reminders(created_by);-- ── CONTEXT SNAPSHOTS ──────────────────────────────────────────────────CREATE TABLE IF NOT EXISTS context_snapshots (  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),  member_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,  family_id UUID NOT NULL REFERENCES families(id) ON DELETE CASCADE,  location JSONB,  time_context JSONB,  activity JSONB,  device JSONB,  environment JSONB,  cognitive JSONB,  social JSONB,  created_at TIMESTAMPTZ DEFAULT now());COMMENT ON TABLE context_snapshots IS 'Periodic context snapshots for ML/trigger evaluation';ALTER TABLE IF EXISTS context_snapshots ENABLE ROW LEVEL SECURITY;DROP POLICY IF EXISTS "members_can_view_own_context" ON context_snapshots;CREATE POLICY "members_can_view_own_context"  ON context_snapshots FOR SELECT  USING (member_id = auth.uid());DROP POLICY IF EXISTS "members_can_insert_own_context" ON context_snapshots;CREATE POLICY "members_can_insert_own_context"  ON context_snapshots FOR INSERT  WITH CHECK (member_id = auth.uid());CREATE INDEX IF NOT EXISTS idx_context_snapshots_member ON context_snapshots(member_id);CREATE INDEX IF NOT EXISTS idx_context_snapshots_family ON context_snapshots(family_id);CREATE INDEX IF NOT EXISTS idx_context_snapshots_created ON context_snapshots(created_at);-- Auto cleanup old snapshots (keep 30 days)-- Run periodically via pg_cron or external scheduler-- ── REMINDER INTERACTIONS ──────────────────────────────────────────────CREATE TABLE IF NOT EXISTS reminder_interactions (  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),  reminder_id UUID NOT NULL REFERENCES smart_reminders(id) ON DELETE CASCADE,  member_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,  action TEXT NOT NULL,  snooze_duration INTEGER,  feedback JSONB,  context JSONB,  created_at TIMESTAMPTZ DEFAULT now());COMMENT ON TABLE reminder_interactions IS 'User interactions with smart reminders for analytics & learning';ALTER TABLE IF EXISTS reminder_interactions ENABLE ROW LEVEL SECURITY;DROP POLICY IF EXISTS "members_can_view_own_interactions" ON reminder_interactions;CREATE POLICY "members_can_view_own_interactions"  ON reminder_interactions FOR SELECT  USING (member_id = auth.uid());DROP POLICY IF EXISTS "members_can_insert_own_interactions" ON reminder_interactions;CREATE POLICY "members_can_insert_own_interactions"  ON reminder_interactions FOR INSERT  WITH CHECK (member_id = auth.uid());CREATE INDEX IF NOT EXISTS idx_reminder_interactions_reminder ON reminder_interactions(reminder_id);CREATE INDEX IF NOT EXISTS idx_reminder_interactions_member ON reminder_interactions(member_id);CREATE INDEX IF NOT EXISTS idx_reminder_interactions_created ON reminder_interactions(created_at);-- ── FUNCTIONS ──────────────────────────────────────────────────────────-- Update updated_at trigger for smart_remindersCREATE OR REPLACE FUNCTION update_smart_reminders_updated_at()RETURNS TRIGGER AS $$BEGIN  NEW.updated_at = now();  RETURN NEW;END;$$ LANGUAGE plpgsql;DROP TRIGGER IF EXISTS trg_smart_reminders_updated_at ON smart_reminders;CREATE TRIGGER trg_smart_reminders_updated_at  BEFORE UPDATE ON smart_reminders  FOR EACH ROW  EXECUTE FUNCTION update_smart_reminders_updated_at();-- Get reminder analyticsCREATE OR REPLACE FUNCTION get_reminder_analytics(p_reminder_id UUID)RETURNS TABLE (  total_triggers BIGINT,  completions BIGINT,  snoozes BIGINT,  dismisses BIGINT,  completion_rate NUMERIC,  avg_response_minutes NUMERIC) AS $$BEGIN  RETURN QUERY  SELECT    COUNT(*)::BIGINT AS total_triggers,    COUNT(*) FILTER (WHERE action = 'completed')::BIGINT AS completions,    COUNT(*) FILTER (WHERE action = 'snoozed')::BIGINT AS snoozes,    COUNT(*) FILTER (WHERE action = 'dismissed')::BIGINT AS dismisses,    CASE       WHEN COUNT(*) > 0 THEN         ROUND((COUNT(*) FILTER (WHERE action = 'completed')::NUMERIC / COUNT(*)::NUMERIC) * 100, 1)      ELSE 0    END AS completion_rate,    0::NUMERIC AS avg_response_minutes  FROM reminder_interactions  WHERE reminder_id = p_reminder_id;END;$$ LANGUAGE plpgsql;\n-- ============================================\n-- FILE: 010_auto_routines.sql\n-- ============================================\n-- Auto Routine Builder Migration-- Tables: routines, routine_templates, routine_history, routine_suggestions-- ── ROUTINES ───────────────────────────────────────────────────────────CREATE TABLE IF NOT EXISTS routines (  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),  family_id UUID NOT NULL REFERENCES families(id) ON DELETE CASCADE,  created_by UUID REFERENCES profiles(id) ON DELETE SET NULL,  name TEXT NOT NULL,  description TEXT,  icon TEXT DEFAULT 'sunrise',  color TEXT DEFAULT '#FF9800',  type TEXT NOT NULL DEFAULT 'morning',  trigger JSONB NOT NULL DEFAULT '{}',  steps JSONB NOT NULL DEFAULT '[]',  status JSONB NOT NULL DEFAULT '{"state": "scheduled", "progress": 0, "current_step": 0}',  recurrence JSONB NOT NULL DEFAULT '{"enabled": false, "pattern": "daily"}',  participants JSONB NOT NULL DEFAULT '[]',  ai_profile JSONB NOT NULL DEFAULT '{}',  is_template BOOLEAN DEFAULT false,  template_id UUID REFERENCES routines(id) ON DELETE SET NULL,  created_at TIMESTAMPTZ DEFAULT now(),  updated_at TIMESTAMPTZ DEFAULT now(),  version INTEGER DEFAULT 1);COMMENT ON TABLE routines IS 'Auto routine builder: morning/evening/weekly/custom routines';ALTER TABLE IF EXISTS routines ENABLE ROW LEVEL SECURITY;DROP POLICY IF EXISTS "family_members_can_view_routines" ON routines;CREATE POLICY "family_members_can_view_routines"  ON routines FOR SELECT  USING (    EXISTS (      SELECT 1 FROM family_members fm      WHERE fm.family_id = routines.family_id      AND fm.user_id = auth.uid()    )  );DROP POLICY IF EXISTS "family_members_can_create_routines" ON routines;CREATE POLICY "family_members_can_create_routines"  ON routines FOR INSERT  WITH CHECK (    EXISTS (      SELECT 1 FROM family_members fm      WHERE fm.family_id = routines.family_id      AND fm.user_id = auth.uid()    )  );DROP POLICY IF EXISTS "creators_can_update_routines" ON routines;CREATE POLICY "creators_can_update_routines"  ON routines FOR UPDATE  USING (created_by = auth.uid())  WITH CHECK (created_by = auth.uid());DROP POLICY IF EXISTS "creators_can_delete_routines" ON routines;CREATE POLICY "creators_can_delete_routines"  ON routines FOR DELETE  USING (created_by = auth.uid());CREATE INDEX IF NOT EXISTS idx_routines_family ON routines(family_id);CREATE INDEX IF NOT EXISTS idx_routines_type ON routines(type);-- ── ROUTINE TEMPLATES ──────────────────────────────────────────────────CREATE TABLE IF NOT EXISTS routine_templates (  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),  name TEXT NOT NULL,  description TEXT,  category TEXT DEFAULT 'family',  difficulty TEXT DEFAULT 'medium',  estimated_total_duration INTEGER DEFAULT 30,  steps JSONB NOT NULL DEFAULT '[]',  suitability JSONB NOT NULL DEFAULT '{}',  usage_count INTEGER DEFAULT 0,  average_rating NUMERIC DEFAULT 0,  user_reviews JSONB NOT NULL DEFAULT '[]',  created_at TIMESTAMPTZ DEFAULT now());COMMENT ON TABLE routine_templates IS 'Pre-built routine templates';-- Public read access for templatesALTER TABLE IF EXISTS routine_templates ENABLE ROW LEVEL SECURITY;DROP POLICY IF EXISTS "anyone_can_view_templates" ON routine_templates;CREATE POLICY "anyone_can_view_templates"  ON routine_templates FOR SELECT  TO authenticated  USING (true);-- ── ROUTINE HISTORY ────────────────────────────────────────────────────CREATE TABLE IF NOT EXISTS routine_history (  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),  routine_id UUID NOT NULL REFERENCES routines(id) ON DELETE CASCADE,  family_id UUID NOT NULL REFERENCES families(id) ON DELETE CASCADE,  date TIMESTAMPTZ DEFAULT now(),  execution JSONB NOT NULL DEFAULT '{}',  steps JSONB NOT NULL DEFAULT '[]',  feedback JSONB,  context JSONB,  created_at TIMESTAMPTZ DEFAULT now());ALTER TABLE IF EXISTS routine_history ENABLE ROW LEVEL SECURITY;DROP POLICY IF EXISTS "family_members_can_view_history" ON routine_history;CREATE POLICY "family_members_can_view_history"  ON routine_history FOR SELECT  USING (    EXISTS (      SELECT 1 FROM family_members fm      WHERE fm.family_id = routine_history.family_id      AND fm.user_id = auth.uid()    )  );CREATE INDEX IF NOT EXISTS idx_routine_history_routine ON routine_history(routine_id);CREATE INDEX IF NOT EXISTS idx_routine_history_family ON routine_history(family_id);-- ── ROUTINE SUGGESTIONS ────────────────────────────────────────────────CREATE TABLE IF NOT EXISTS routine_suggestions (  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),  family_id UUID NOT NULL REFERENCES families(id) ON DELETE CASCADE,  type TEXT DEFAULT 'new_routine',  reason TEXT,  confidence NUMERIC DEFAULT 0,  based_on JSONB NOT NULL DEFAULT '[]',  suggested_routine JSONB,  status TEXT DEFAULT 'pending',  created_at TIMESTAMPTZ DEFAULT now());ALTER TABLE IF EXISTS routine_suggestions ENABLE ROW LEVEL SECURITY;DROP POLICY IF EXISTS "family_members_can_view_suggestions" ON routine_suggestions;CREATE POLICY "family_members_can_view_suggestions"  ON routine_suggestions FOR SELECT  USING (    EXISTS (      SELECT 1 FROM family_members fm      WHERE fm.family_id = routine_suggestions.family_id      AND fm.user_id = auth.uid()    )  );CREATE INDEX IF NOT EXISTS idx_routine_suggestions_family ON routine_suggestions(family_id);-- ── UPDATE TRIGGER ─────────────────────────────────────────────────────CREATE OR REPLACE FUNCTION update_routines_updated_at()RETURNS TRIGGER AS $$BEGIN  NEW.updated_at = now();  RETURN NEW;END;$$ LANGUAGE plpgsql;DROP TRIGGER IF EXISTS trg_routines_updated_at ON routines;CREATE TRIGGER trg_routines_updated_at  BEFORE UPDATE ON routines  FOR EACH ROW  EXECUTE FUNCTION update_routines_updated_at();\n-- ============================================\n-- FILE: 011_crash_detection.sql\n-- ============================================\n-- Migration: 011_crash_detection.sql-- Crash Detection System tables-- ─────────────────────────────────────────────-- CRASH EVENTS-- ─────────────────────────────────────────────create table if not exists crash_events (    id uuid primary key default gen_random_uuid(),    family_id uuid references families(id) on delete cascade,    member_id uuid references family_members(id) on delete cascade,    member_name text,    -- Detection info    detection_timestamp timestamptz not null default now(),    detection_confidence decimal(3,2) not null default 0,    trigger_type text not null default 'high_impact',    -- Sensor data (JSONB for flexibility)    sensor_data jsonb not null default '{}',    -- Context    context jsonb not null default '{}',    -- Response    response_status text not null default 'detected',    confirmation_window jsonb,    sos_triggered jsonb,    notifications_sent jsonb default '[]',    -- Outcome    outcome jsonb,    -- ML features    ml_features jsonb,    -- Meta    created_at timestamptz not null default now(),    resolved_at timestamptz,    reviewed_by uuid references family_members(id),    is_false_positive boolean not null default false,    -- Indexes    constraint valid_confidence check (detection_confidence between 0 and 1));-- Indexes for crash_eventscreate index if not exists idx_crash_events_family on crash_events(family_id);create index if not exists idx_crash_events_member on crash_events(member_id);create index if not exists idx_crash_events_created on crash_events(created_at desc);create index if not exists idx_crash_events_status on crash_events(response_status);create index if not exists idx_crash_events_false_positive on crash_events(is_false_positive);-- ─────────────────────────────────────────────-- CRASH DETECTION SETTINGS-- ─────────────────────────────────────────────create table if not exists crash_detection_settings (    id uuid primary key default gen_random_uuid(),    member_id uuid references family_members(id) on delete cascade unique,    enabled boolean not null default true,    sensitivity text not null default 'medium',    custom_thresholds jsonb not null default '{        "minImpactG": 4.0,        "minSpeedChange": 8.0,        "rolloverThreshold": 5.0,        "confirmationWindowSeconds": 30    }',    sos_config jsonb not null default '{        "autoCallEmergency": false,        "autoNotifyFamily": true,        "autoNotifyContacts": true,        "shareLocation": true,        "shareMedicalInfo": true    }',    emergency_contacts jsonb default '[]',    notifications jsonb not null default '{        "soundAlert": true,        "soundType": "crash_alarm",        "vibration": true,        "vibrationPattern": "sos",        "screenFlash": true,        "maxVolume": true,        "bypassDnd": false    }',    test_mode jsonb not null default '{        "enabled": false    }',    updated_at timestamptz not null default now());-- ─────────────────────────────────────────────-- SENSOR LOGS (short-lived, TTL-like cleanup)-- ─────────────────────────────────────────────create table if not exists sensor_logs (    id uuid primary key default gen_random_uuid(),    member_id uuid references family_members(id) on delete cascade,    timestamp timestamptz not null default now(),    accelerometer jsonb,    gyroscope jsonb,    gps jsonb,    -- Auto-cleanup: recommend running a cron job to delete older than 24h    created_at timestamptz not null default now());create index if not exists idx_sensor_logs_member on sensor_logs(member_id);create index if not exists idx_sensor_logs_timestamp on sensor_logs(timestamp desc);-- ─────────────────────────────────────────────-- RLS POLICIES-- ─────────────────────────────────────────────-- Crash events: family members can view their own family's eventsalter table if exists crash_events enable row level security;drop policy if exists crash_events_select_family on crash_events;create policy crash_events_select_family    on crash_events    for select    using (        family_id in (            select family_id from family_members            where auth.uid() = user_id        )    );drop policy if exists crash_events_insert_own on crash_events;create policy crash_events_insert_own    on crash_events    for insert    with check (        member_id in (            select id from family_members            where auth.uid() = user_id        )    );drop policy if exists crash_events_update_own on crash_events;create policy crash_events_update_own    on crash_events    for update    using (        member_id in (            select id from family_members            where auth.uid() = user_id        )    );-- Settings: members can only manage their own settingsalter table if exists crash_detection_settings enable row level security;drop policy if exists crash_settings_select_own on crash_detection_settings;create policy crash_settings_select_own    on crash_detection_settings    for select    using (        member_id in (            select id from family_members            where auth.uid() = user_id        )    );drop policy if exists crash_settings_insert_own on crash_detection_settings;create policy crash_settings_insert_own    on crash_detection_settings    for insert    with check (        member_id in (            select id from family_members            where auth.uid() = user_id        )    );drop policy if exists crash_settings_update_own on crash_detection_settings;create policy crash_settings_update_own    on crash_detection_settings    for update    using (        member_id in (            select id from family_members            where auth.uid() = user_id        )    );-- Sensor logs: members can only see their ownalter table if exists sensor_logs enable row level security;drop policy if exists sensor_logs_select_own on sensor_logs;create policy sensor_logs_select_own    on sensor_logs    for select    using (        member_id in (            select id from family_members            where auth.uid() = user_id        )    );drop policy if exists sensor_logs_insert_own on sensor_logs;create policy sensor_logs_insert_own    on sensor_logs    for insert    with check (        member_id in (            select id from family_members            where auth.uid() = user_id        )    );-- ─────────────────────────────────────────────-- FUNCTIONS-- ─────────────────────────────────────────────-- Auto-update updated_atcreate or replace function update_crash_settings_timestamp()returns trigger as $$begin    new.updated_at = now();    return new;end;$$ language plpgsql;drop trigger if exists tr_crash_settings_updated on crash_detection_settings;create trigger tr_crash_settings_updated    before update on crash_detection_settings    for each row    execute function update_crash_settings_timestamp();-- Get crash summary for a familyCREATE OR REPLACE FUNCTION get_family_crash_summary(p_family_id uuid)RETURNS jsonbLANGUAGE plpgsqlSECURITY DEFINERAS $$DECLARE    result jsonb;BEGIN    SELECT jsonb_build_object(        'totalEvents', count(*),        'falseAlarms', count(*) filter (where is_false_positive = true),        'realCrashes', count(*) filter (where is_false_positive = false and response_status = 'auto_sos'),        'last30Days', count(*) filter (where created_at > now() - interval '30 days'),        'avgConfidence', coalesce(avg(detection_confidence), 0)::numeric(3,2)    )    INTO result    FROM crash_events    WHERE family_id = p_family_id;    RETURN result;END;$$;\n-- ============================================\n-- FILE: 012_location_tracking.sql\n-- ============================================\n-- Migration: 012_location_tracking.sql-- Battery-aware location tracking system tables-- ─────────────────────────────────────────────-- LOCATION TRACKING SETTINGS-- ─────────────────────────────────────────────create table if not exists location_tracking_settings (    id uuid primary key default gen_random_uuid(),    member_id uuid references family_members(id) on delete cascade unique,    family_id uuid references families(id) on delete cascade,    enabled boolean not null default true,    priority text not null default 'balanced',    battery_thresholds jsonb not null default '{        "critical": 10,        "low": 20,        "medium": 50,        "high": 80,        "full": 100    }',    motion_profiles jsonb not null default '{        "stationary": {"updateInterval": 300, "accuracy": "low", "providers": ["wifi", "cellular"], "useGeofence": true, "geofenceRadius": 100},        "walking": {"updateInterval": 60, "accuracy": "medium", "providers": ["wifi", "cellular", "gps"]},        "running": {"updateInterval": 30, "accuracy": "medium", "providers": ["gps", "cellular"]},        "cycling": {"updateInterval": 15, "accuracy": "high", "providers": ["gps"]},        "driving": {"updateInterval": 10, "accuracy": "high", "providers": ["gps"]},        "highSpeed": {"updateInterval": 5, "accuracy": "best", "providers": ["gps"]},        "emergency": {"updateInterval": 3, "accuracy": "best", "providers": ["gps", "wifi", "cellular"], "maxAccuracyMode": true}    }',    transition_rules jsonb default '[]',    power_optimization jsonb not null default '{        "adaptiveBrightness": true,        "backgroundRefresh": true,        "networkBatching": true,        "locationCache": true,        "motionCoProcessor": true    }',    time_rules jsonb default '[]',    location_rules jsonb default '[]',    notify_profile_changes boolean not null default false,    updated_at timestamptz not null default now());-- ─────────────────────────────────────────────-- LOCATION HISTORY (BATCHED)-- ─────────────────────────────────────────────create table if not exists location_history (    id uuid primary key default gen_random_uuid(),    batch_id text not null,    member_id uuid references family_members(id) on delete cascade,    family_id uuid references families(id) on delete cascade,    recorded_at timestamptz not null,    uploaded_at timestamptz not null default now(),    batch_size int not null default 0,    battery_at_start int,    power_profile text not null default 'balanced',    locations jsonb not null default '[]',    segment jsonb,    created_at timestamptz not null default now());create index if not exists idx_location_history_member on location_history(member_id);create index if not exists idx_location_history_family on location_history(family_id);create index if not exists idx_location_history_recorded on location_history(recorded_at desc);create index if not exists idx_location_history_batch on location_history(batch_id);-- ─────────────────────────────────────────────-- BATTERY LOGS-- ─────────────────────────────────────────────create table if not exists battery_logs (    id uuid primary key default gen_random_uuid(),    member_id uuid references family_members(id) on delete cascade,    timestamp timestamptz not null default now(),    battery_level int not null,    temperature decimal(4,1),    voltage decimal(5,3),    health text,    is_charging boolean not null default false,    charge_type text,    tracking_profile text not null default 'balanced',    update_interval int not null default 60,    accuracy text not null default 'medium',    provider text not null default 'gps',    locations_recorded int not null default 0,    estimated_drain decimal(5,2),    created_at timestamptz not null default now());create index if not exists idx_battery_logs_member on battery_logs(member_id);create index if not exists idx_battery_logs_timestamp on battery_logs(timestamp desc);-- ─────────────────────────────────────────────-- TRACKING ANALYTICS (DAILY AGGREGATE)-- ─────────────────────────────────────────────create table if not exists tracking_analytics (    id uuid primary key default gen_random_uuid(),    member_id uuid references family_members(id) on delete cascade,    date date not null,    total_locations int not null default 0,    total_distance decimal(10,2) not null default 0,    active_time_minutes int not null default 0,    stationary_time_minutes int not null default 0,    battery_used decimal(5,2) not null default 0,    profile_usage jsonb not null default '{}',    locations_per_battery_percent decimal(5,2),    accuracy_achieved decimal(5,2),    optimal_profile_percentage decimal(5,2),    ai_recommendations jsonb default '[]',    created_at timestamptz not null default now(),    unique(member_id, date));create index if not exists idx_tracking_analytics_member on tracking_analytics(member_id);create index if not exists idx_tracking_analytics_date on tracking_analytics(date desc);-- ─────────────────────────────────────────────-- RLS POLICIES-- ─────────────────────────────────────────────alter table if exists location_tracking_settings enable row level security;drop policy if exists location_tracking_settings_select_own on location_tracking_settings;create policy location_tracking_settings_select_own    on location_tracking_settings for select    using (member_id in (select id from family_members where auth.uid() = user_id));drop policy if exists location_tracking_settings_insert_own on location_tracking_settings;create policy location_tracking_settings_insert_own    on location_tracking_settings for insert    with check (member_id in (select id from family_members where auth.uid() = user_id));drop policy if exists location_tracking_settings_update_own on location_tracking_settings;create policy location_tracking_settings_update_own    on location_tracking_settings for update    using (member_id in (select id from family_members where auth.uid() = user_id));alter table if exists location_history enable row level security;drop policy if exists location_history_select_family on location_history;create policy location_history_select_family    on location_history for select    using (family_id in (select family_id from family_members where auth.uid() = user_id));drop policy if exists location_history_insert_own on location_history;create policy location_history_insert_own    on location_history for insert    with check (member_id in (select id from family_members where auth.uid() = user_id));alter table if exists battery_logs enable row level security;drop policy if exists battery_logs_select_own on battery_logs;create policy battery_logs_select_own    on battery_logs for select    using (member_id in (select id from family_members where auth.uid() = user_id));drop policy if exists battery_logs_insert_own on battery_logs;create policy battery_logs_insert_own    on battery_logs for insert    with check (member_id in (select id from family_members where auth.uid() = user_id));alter table if exists tracking_analytics enable row level security;drop policy if exists tracking_analytics_select_family on tracking_analytics;create policy tracking_analytics_select_family    on tracking_analytics for select    using (member_id in (select id from family_members where auth.uid() = user_id));drop policy if exists tracking_analytics_insert_own on tracking_analytics;create policy tracking_analytics_insert_own    on tracking_analytics for insert    with check (member_id in (select id from family_members where auth.uid() = user_id));-- ─────────────────────────────────────────────-- FUNCTIONS-- ─────────────────────────────────────────────-- Auto-update timestampcreate or replace function update_location_tracking_timestamp()returns trigger as $$begin    new.updated_at = now();    return new;end;$$ language plpgsql;drop trigger if exists tr_location_tracking_updated on location_tracking_settings;create trigger tr_location_tracking_updated    before update on location_tracking_settings    for each row    execute function update_location_tracking_timestamp();-- Get daily tracking summary for a memberCREATE OR REPLACE FUNCTION get_member_tracking_summary(p_member_id uuid, p_days int default 7)RETURNS jsonbLANGUAGE plpgsqlSECURITY DEFINERAS $$DECLARE    result jsonb;BEGIN    SELECT jsonb_build_object(        'totalLocations', coalesce(sum(total_locations), 0),        'totalDistance', coalesce(sum(total_distance), 0)::numeric(10,2),        'avgBatteryUsed', coalesce(avg(battery_used), 0)::numeric(5,2),        'avgAccuracy', coalesce(avg(accuracy_achieved), 0)::numeric(5,2),        'optimalProfileRate', coalesce(avg(optimal_profile_percentage), 0)::numeric(5,2)    )    INTO result    FROM tracking_analytics    WHERE member_id = p_member_id      AND date >= current_date - (p_days || ' days')::interval;    RETURN result;END;$$;\n-- ============================================\n-- FILE: 013_emergency_actions.sql\n-- ============================================\n-- Migration: 013_emergency_actions.sql-- Emergency auto-actions system tables-- ─────────────────────────────────────────────-- EMERGENCY ACTIONS-- ─────────────────────────────────────────────create table if not exists emergency_actions (    id uuid primary key default gen_random_uuid(),    family_id uuid references families(id) on delete cascade,    triggered_by uuid references family_members(id) on delete set null,    trigger_type text not null default 'manual_sos',    trigger_timestamp timestamptz not null default now(),    trigger_latitude decimal(10,8),    trigger_longitude decimal(11,8),    trigger_confidence decimal(3,2) default 1.0,    severity text not null default 'high',    category text not null default 'other',    description text,    is_confirmed boolean not null default false,    confirmation_method text,    auto_actions jsonb not null default '{}',    escalation_chain jsonb not null default '{"steps": []}',    status_state text not null default 'triggered',    current_step int not null default 0,    started_at timestamptz not null default now(),    last_action_at timestamptz,    resolved_at timestamptz,    resolved_by uuid references family_members(id),    response_log jsonb default '[]',    created_at timestamptz not null default now(),    updated_at timestamptz not null default now());create index if not exists idx_emergency_actions_family on emergency_actions(family_id);create index if not exists idx_emergency_actions_status on emergency_actions(status_state);create index if not exists idx_emergency_actions_created on emergency_actions(created_at desc);-- ─────────────────────────────────────────────-- EMERGENCY TEMPLATES-- ─────────────────────────────────────────────create table if not exists emergency_templates (    id uuid primary key default gen_random_uuid(),    template_id text unique not null,    name text not null,    language text not null default 'tr',    content jsonb not null default '{}',    variables jsonb default '[]',    usage_count int not null default 0,    average_response_time decimal(6,2),    created_at timestamptz not null default now());-- Insert default templateinsert into emergency_templates (template_id, name, language, content, variables)values (    'default',    'Varsayılan Acil Durum',    'tr',    '{        "sms": "🆘 ACİL: {name} yardım istiyor! Konum: {location} Saat: {time}",        "push": "Yardım çağrısı! Konum: {location}",        "pushTitle": "🆘 {name} - ACİL DURUM",        "voice": "Bu otomatik bir acil durum çağrısıdır. {name} yardım istiyor.",        "email": "Acil durum yardım çağrısı. {name} konum: {location}"    }',    '[        {"name": "name", "source": "user_profile", "required": true},        {"name": "location", "source": "location", "required": true},        {"name": "time", "source": "time", "required": true}    ]')on conflict (template_id) do nothing;-- ─────────────────────────────────────────────-- EMERGENCY CONTACTS-- ─────────────────────────────────────────────create table if not exists emergency_contacts (    id uuid primary key default gen_random_uuid(),    contact_id text unique not null,    family_id uuid references families(id) on delete cascade,    name text not null,    phone text not null,    email text,    relation text,    priority int not null default 1,    availability jsonb default '{}',    capabilities jsonb default '{}',    roles jsonb default '[]',    is_active boolean not null default true,    verified_at timestamptz);create index if not exists idx_emergency_contacts_family on emergency_contacts(family_id);-- ─────────────────────────────────────────────-- ESCALATION POLICIES-- ─────────────────────────────────────────────create table if not exists escalation_policies (    id uuid primary key default gen_random_uuid(),    policy_id text unique not null,    family_id uuid references families(id) on delete cascade,    name text not null,    triggers jsonb default '[]',    steps jsonb not null default '[]',    conditions jsonb default '{}',    created_at timestamptz not null default now(),    updated_at timestamptz not null default now());-- ─────────────────────────────────────────────-- RLS POLICIES-- ─────────────────────────────────────────────alter table if exists emergency_actions enable row level security;drop policy if exists emergency_actions_select_family on emergency_actions;create policy emergency_actions_select_family    on emergency_actions for select    using (family_id in (select family_id from family_members where auth.uid() = user_id));drop policy if exists emergency_actions_insert_own on emergency_actions;create policy emergency_actions_insert_own    on emergency_actions for insert    with check (triggered_by in (select id from family_members where auth.uid() = user_id));drop policy if exists emergency_actions_update_family on emergency_actions;create policy emergency_actions_update_family    on emergency_actions for update    using (family_id in (select family_id from family_members where auth.uid() = user_id));alter table if exists emergency_templates enable row level security;drop policy if exists emergency_templates_select_all on emergency_templates;create policy emergency_templates_select_all    on emergency_templates for select    using (true);alter table if exists emergency_contacts enable row level security;drop policy if exists emergency_contacts_select_family on emergency_contacts;create policy emergency_contacts_select_family    on emergency_contacts for select    using (family_id in (select family_id from family_members where auth.uid() = user_id));drop policy if exists emergency_contacts_insert_family on emergency_contacts;create policy emergency_contacts_insert_family    on emergency_contacts for insert    with check (family_id in (select family_id from family_members where auth.uid() = user_id));drop policy if exists emergency_contacts_update_family on emergency_contacts;create policy emergency_contacts_update_family    on emergency_contacts for update    using (family_id in (select family_id from family_members where auth.uid() = user_id));alter table if exists escalation_policies enable row level security;drop policy if exists escalation_policies_select_family on escalation_policies;create policy escalation_policies_select_family    on escalation_policies for select    using (family_id in (select family_id from family_members where auth.uid() = user_id));drop policy if exists escalation_policies_insert_family on escalation_policies;create policy escalation_policies_insert_family    on escalation_policies for insert    with check (family_id in (select family_id from family_members where auth.uid() = user_id));-- ─────────────────────────────────────────────-- FUNCTIONS-- ─────────────────────────────────────────────-- Get active emergency count for a familyCREATE OR REPLACE FUNCTION get_family_active_emergencies(p_family_id uuid)RETURNS intLANGUAGE plpgsqlSECURITY DEFINERAS $$DECLARE    count int;BEGIN    SELECT count(*) INTO count    FROM emergency_actions    WHERE family_id = p_family_id      AND status_state in ('triggered', 'active', 'escalating');    RETURN count;END;$$;\n-- ============================================\n-- FILE: 014_child_accounts.sql\n-- ============================================\n-- ============================================-- CHILD ACCOUNTS (Module 20)-- PIN-based accounts for children without email-- ============================================-- Child accounts table (no auth.users link - managed independently)create table if not exists public.child_accounts (  id uuid default uuid_generate_v4() primary key,  family_id uuid references public.families(id) on delete cascade not null,  name text not null,  pin_hash text not null, -- bcrypt hash of 4-6 digit PIN  avatar_url text,  role text default 'child' check (role in ('child', 'teen', 'baby')),  color text default '#3B82F6',  created_by uuid references public.profiles(id) not null,  created_at timestamptz default now(),  updated_at timestamptz default now(),  is_active boolean default true,  last_active_at timestamptz,  daily_screen_time_minutes int default 120,  can_approve_tasks boolean default false,  can_send_messages boolean default true,  can_view_budget boolean default false);-- Child sessions for token-based authcreate table if not exists public.child_sessions (  id uuid default uuid_generate_v4() primary key,  child_id uuid references public.child_accounts(id) on delete cascade not null,  family_id uuid references public.families(id) on delete cascade not null,  token text unique not null,  device_info text,  expires_at timestamptz not null,  created_at timestamptz default now(),  last_used_at timestamptz default now());-- Child activity log (for parents to monitor)create table if not exists public.child_activity_logs (  id uuid default uuid_generate_v4() primary key,  child_id uuid references public.child_accounts(id) on delete cascade not null,  family_id uuid references public.families(id) on delete cascade not null,  activity_type text not null check (activity_type in ('login', 'logout', 'task_completed', 'message_sent', 'location_shared', 'emergency_pressed', 'settings_changed')),  details jsonb default '{}',  created_at timestamptz default now());-- Indexescreate index if not exists idx_child_accounts_family on public.child_accounts(family_id);create index if not exists idx_child_accounts_active on public.child_accounts(family_id, is_active);create index if not exists idx_child_sessions_token on public.child_sessions(token);create index if not exists idx_child_sessions_child on public.child_sessions(child_id);create index if not exists idx_child_activity_logs_child on public.child_activity_logs(child_id, created_at desc);-- Updated at triggerscreate or replace function public.handle_child_account_update()returns trigger as $$begin  new.updated_at = now();  return new;end;$$ language plpgsql security definer;drop trigger if exists child_accounts_updated_at on public.child_accounts;create trigger child_accounts_updated_at  before update on public.child_accounts  for each row execute function public.handle_child_account_update();-- RLS Policies for child_accountsdrop policy if exists "Parents can manage children in their family" on public.child_accounts;create policy "Parents can manage children in their family"  on public.child_accounts  for all  to authenticated  using (    exists (      select 1 from public.family_members fm      where fm.family_id = child_accounts.family_id      and fm.user_id = auth.uid()      and fm.role in ('admin', 'parent')    )  )  with check (    exists (      select 1 from public.family_members fm      where fm.family_id = child_accounts.family_id      and fm.user_id = auth.uid()      and fm.role in ('admin', 'parent')    )  );drop policy if exists "Children can read their own account" on public.child_accounts;create policy "Children can read their own account"  on public.child_accounts  for select  to authenticated  using (    id::text = coalesce(current_setting('app.child_id', true), '')  );-- RLS Policies for child_sessions (managed via RPC mostly)drop policy if exists "Parents can view child sessions" on public.child_sessions;create policy "Parents can view child sessions"  on public.child_sessions  for select  to authenticated  using (    exists (      select 1 from public.family_members fm      where fm.family_id = child_sessions.family_id      and fm.user_id = auth.uid()      and fm.role in ('admin', 'parent')    )  );-- RLS Policies for child_activity_logsdrop policy if exists "Parents can view child activity" on public.child_activity_logs;create policy "Parents can view child activity"  on public.child_activity_logs  for select  to authenticated  using (    exists (      select 1 from public.family_members fm      where fm.family_id = child_activity_logs.family_id      and fm.user_id = auth.uid()      and fm.role in ('admin', 'parent')    )  );-- Function to verify child PIN and create sessioncreate or replace function public.verify_child_pin(  p_child_id uuid,  p_pin text,  p_device_info text default null)returns table (  session_token text,  expires_at timestamptz,  child_name text,  child_role text,  family_id uuid) as $$declare  v_child record;  v_token text;  v_expires timestamptz;begin  -- Get child account  select * into v_child from public.child_accounts  where id = p_child_id and is_active = true;  if v_child is null then    raise exception 'Child account not found';  end if;  -- Simple PIN comparison (in production use pgcrypto crypt())  -- For Flutter app: we hash PIN with bcrypt on client or use a simpler approach  -- Here we do direct comparison for flexibility; recommend bcrypt in production  if v_child.pin_hash != p_pin then    raise exception 'Invalid PIN';  end if;  -- Generate session token  v_token := encode(gen_random_bytes(32), 'hex');  v_expires := now() + interval '30 days';  -- Create session  insert into public.child_sessions (child_id, family_id, token, device_info, expires_at)  values (v_child.id, v_child.family_id, v_token, p_device_info, v_expires);  -- Update last active  update public.child_accounts set last_active_at = now() where id = v_child.id;  -- Log activity  insert into public.child_activity_logs (child_id, family_id, activity_type, details)  values (v_child.id, v_child.family_id, 'login', jsonb_build_object('device', p_device_info));  return query select v_token, v_expires, v_child.name, v_child.role, v_child.family_id;end;$$ language plpgsql security definer;-- Function to validate child session tokencreate or replace function public.validate_child_session(p_token text)returns table (  child_id uuid,  family_id uuid,  child_name text,  child_role text,  is_valid boolean) as $$begin  return query  select     cs.child_id,    cs.family_id,    ca.name as child_name,    ca.role as child_role,    (cs.expires_at > now()) as is_valid  from public.child_sessions cs  join public.child_accounts ca on ca.id = cs.child_id  where cs.token = p_token;  -- Update last used  update public.child_sessions set last_used_at = now() where token = p_token;end;$$ language plpgsql security definer;-- Function to revoke child sessioncreate or replace function public.revoke_child_session(p_token text)returns void as $$begin  delete from public.child_sessions where token = p_token;end;$$ language plpgsql security definer;-- Function to log child activitycreate or replace function public.log_child_activity(  p_child_id uuid,  p_activity_type text,  p_details jsonb default '{}')returns void as $$declare  v_family_id uuid;begin  select family_id into v_family_id from public.child_accounts where id = p_child_id;    insert into public.child_activity_logs (child_id, family_id, activity_type, details)  values (p_child_id, v_family_id, p_activity_type, p_details);end;$$ language plpgsql security definer;-- Enable RLSalter table if exists public.child_accounts enable row level security;alter table if exists public.child_sessions enable row level security;alter table if exists public.child_activity_logs enable row level security;\n-- ============================================\n-- FILE: 015_child_features.sql\n-- ============================================\n-- ============================================-- CHILD FEATURES EXPANSION (Module 20 Extended)-- Homeworks, schedules, development logs, location sharing-- ============================================-- ============================================-- CHILD HOMEWORKS-- ============================================create table if not exists public.child_homeworks (  id uuid default uuid_generate_v4() primary key,  family_id uuid references public.families(id) on delete cascade not null,  child_id uuid references public.child_accounts(id) on delete cascade not null,  subject text not null,  title text not null,  description text,  due_date timestamptz,  status text not null default 'pending' check (status in ('pending', 'in_progress', 'completed', 'late')),  priority text not null default 'medium' check (priority in ('low', 'medium', 'high')),  estimated_minutes int,  completed_at timestamptz,  created_by uuid references public.profiles(id),  created_at timestamptz default now());create index if not exists idx_child_homeworks_child on public.child_homeworks(child_id, status);create index if not exists idx_child_homeworks_family on public.child_homeworks(family_id, due_date);-- ============================================-- CHILD SCHEDULES (Weekly Lesson Plan)-- ============================================create table if not exists public.child_schedules (  id uuid default uuid_generate_v4() primary key,  family_id uuid references public.families(id) on delete cascade not null,  child_id uuid references public.child_accounts(id) on delete cascade not null,  day_of_week int not null check (day_of_week between 1 and 7),  start_time time not null,  end_time time not null,  subject text not null,  location text,  teacher text,  color text default '#3B82F6',  is_active boolean default true,  created_at timestamptz default now());create index if not exists idx_child_schedules_child_day on public.child_schedules(child_id, day_of_week);-- ============================================-- CHILD DEVELOPMENT LOGS-- ============================================create table if not exists public.child_development_logs (  id uuid default uuid_generate_v4() primary key,  family_id uuid references public.families(id) on delete cascade not null,  child_id uuid references public.child_accounts(id) on delete cascade not null,  log_type text not null check (log_type in ('height', 'weight', 'mood', 'milestone', 'note')),  value text not null,  unit text,  logged_at date not null default current_date,  notes text,  created_by uuid references public.profiles(id),  created_at timestamptz default now());create index if not exists idx_child_dev_logs_child on public.child_development_logs(child_id, log_type, logged_at desc);-- ============================================-- GEOLOCATIONS — add child_id (nullable for backward compat)-- ============================================alter table public.geolocations add column if not exists child_id uuid references public.child_accounts(id) on delete cascade;create index if not exists idx_geolocations_child on public.geolocations(child_id, created_at desc);-- ============================================-- MESSAGES — add sender_type to distinguish child messages-- ============================================alter table public.messages add column if not exists sender_type text default 'parent' check (sender_type in ('parent', 'child'));-- ============================================-- RLS POLICIES — Anon (child) access-- ============================================-- child_homeworksalter table if exists public.child_homeworks enable row level security;drop policy if exists "Anon child can view own homeworks" on public.child_homeworks;create policy "Anon child can view own homeworks"  on public.child_homeworks for select to anon  using (child_id in (select id from public.child_accounts where is_active = true));drop policy if exists "Anon child can update own homework status" on public.child_homeworks;create policy "Anon child can update own homework status"  on public.child_homeworks for update to anon  using (child_id in (select id from public.child_accounts where is_active = true));drop policy if exists "Parents can manage child homeworks" on public.child_homeworks;create policy "Parents can manage child homeworks"  on public.child_homeworks for all to authenticated  using (    exists (      select 1 from public.family_members fm      where fm.family_id = child_homeworks.family_id      and fm.user_id = auth.uid()      and fm.role in ('admin', 'parent')    )  )  with check (    exists (      select 1 from public.family_members fm      where fm.family_id = child_homeworks.family_id      and fm.user_id = auth.uid()      and fm.role in ('admin', 'parent')    )  );-- child_schedulesalter table if exists public.child_schedules enable row level security;drop policy if exists "Anon child can view own schedule" on public.child_schedules;create policy "Anon child can view own schedule"  on public.child_schedules for select to anon  using (child_id in (select id from public.child_accounts where is_active = true));drop policy if exists "Parents can manage child schedules" on public.child_schedules;create policy "Parents can manage child schedules"  on public.child_schedules for all to authenticated  using (    exists (      select 1 from public.family_members fm      where fm.family_id = child_schedules.family_id      and fm.user_id = auth.uid()      and fm.role in ('admin', 'parent')    )  )  with check (    exists (      select 1 from public.family_members fm      where fm.family_id = child_schedules.family_id      and fm.user_id = auth.uid()      and fm.role in ('admin', 'parent')    )  );-- child_development_logsalter table if exists public.child_development_logs enable row level security;drop policy if exists "Anon child can view own development logs" on public.child_development_logs;create policy "Anon child can view own development logs"  on public.child_development_logs for select to anon  using (child_id in (select id from public.child_accounts where is_active = true));drop policy if exists "Parents can manage child development logs" on public.child_development_logs;create policy "Parents can manage child development logs"  on public.child_development_logs for all to authenticated  using (    exists (      select 1 from public.family_members fm      where fm.family_id = child_development_logs.family_id      and fm.user_id = auth.uid()      and fm.role in ('admin', 'parent')    )  )  with check (    exists (      select 1 from public.family_members fm      where fm.family_id = child_development_logs.family_id      and fm.user_id = auth.uid()      and fm.role in ('admin', 'parent')    )  );-- tasks — anon child access (existing table, add child policies)drop policy if exists "Anon child can view assigned tasks" on public.tasks;create policy "Anon child can view assigned tasks"  on public.tasks for select to anon  using (assigned_to in (select id from public.child_accounts where is_active = true));drop policy if exists "Anon child can update own tasks" on public.tasks;create policy "Anon child can update own tasks"  on public.tasks for update to anon  using (assigned_to in (select id from public.child_accounts where is_active = true));-- messages — anon child accessdrop policy if exists "Anon child can view family messages" on public.messages;create policy "Anon child can view family messages"  on public.messages for select to anon  using (family_id in (select family_id from public.child_accounts where is_active = true));drop policy if exists "Anon child can send family messages" on public.messages;create policy "Anon child can send family messages"  on public.messages for insert to anon  with check (family_id in (select family_id from public.child_accounts where is_active = true));-- geolocations — anon child can insert own location, view family locationsdrop policy if exists "Anon child can share location" on public.geolocations;create policy "Anon child can share location"  on public.geolocations for insert to anon  with check (child_id in (select id from public.child_accounts where is_active = true));drop policy if exists "Anon child can view family geolocations" on public.geolocations;create policy "Anon child can view family geolocations"  on public.geolocations for select to anon  using (family_id in (select family_id from public.child_accounts where is_active = true));-- child_activity_logs — anon child can view own logs (for AI analysis)drop policy if exists "Anon child can view own activity logs" on public.child_activity_logs;create policy "Anon child can view own activity logs"  on public.child_activity_logs for select to anon  using (child_id in (select id from public.child_accounts where is_active = true));-- ============================================-- REALTIME-- ============================================do $$begin  if not exists (select 1 from pg_publication_tables where pubname = 'supabase_realtime' and tablename = 'child_homeworks') then    alter publication supabase_realtime add table public.child_homeworks;  end if;end $$;do $$begin  if not exists (select 1 from pg_publication_tables where pubname = 'supabase_realtime' and tablename = 'child_schedules') then    alter publication supabase_realtime add table public.child_schedules;  end if;end $$;do $$begin  if not exists (select 1 from pg_publication_tables where pubname = 'supabase_realtime' and tablename = 'child_development_logs') then    alter publication supabase_realtime add table public.child_development_logs;  end if;end $$;-- ============================================-- SEED DATA — Sample homeworks, schedules, development for Mirac-- ============================================-- Note: child_id must be replaced with actual Mirac's UUID after migration-- This will be handled by the app or a separate seed script\n-- ============================================\n-- FILE: 016_sos_alerts.sql\n-- ============================================\n-- SOS Alerts Table: Realtime emergency alerts across familyCREATE TABLE IF NOT EXISTS sos_alerts (    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),    family_id UUID NOT NULL REFERENCES families(id) ON DELETE CASCADE,    sender_id TEXT NOT NULL, -- user id or child_account id    sender_name TEXT NOT NULL,    sender_type TEXT NOT NULL CHECK (sender_type IN ('parent', 'child')),    lat DOUBLE PRECISION,    lng DOUBLE PRECISION,    accuracy DOUBLE PRECISION,    message TEXT NOT NULL DEFAULT 'Acil durum!',    status TEXT NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'resolved', 'false_alarm')),    resolved_by TEXT,    resolved_at TIMESTAMPTZ,    created_at TIMESTAMPTZ DEFAULT now());-- RLS PoliciesALTER TABLE IF EXISTS sos_alerts ENABLE ROW LEVEL SECURITY;-- Anon (child accounts) can insert SOS for their familyDROP POLICY IF EXISTS "Child can send SOS" ON sos_alerts;CREATE POLICY "Child can send SOS" ON sos_alerts    FOR INSERT TO anon    WITH CHECK (family_id IN (        SELECT family_id FROM child_accounts WHERE id = nullif(current_setting('app.current_child_id', true), '')::uuid    ));-- Anon can view SOS alerts for their familyDROP POLICY IF EXISTS "Child can view family SOS" ON sos_alerts;CREATE POLICY "Child can view family SOS" ON sos_alerts    FOR SELECT TO anon    USING (family_id IN (        SELECT family_id FROM child_accounts WHERE id = nullif(current_setting('app.current_child_id', true), '')::uuid    ));-- Authenticated parents can manage SOS for their familyDROP POLICY IF EXISTS "Parent can manage family SOS" ON sos_alerts;CREATE POLICY "Parent can manage family SOS" ON sos_alerts    FOR ALL TO authenticated    USING (family_id IN (        SELECT family_id FROM profiles WHERE id = auth.uid()    ))    WITH CHECK (family_id IN (        SELECT family_id FROM profiles WHERE id = auth.uid()    ));-- IndexesCREATE INDEX IF NOT EXISTS idx_sos_alerts_family ON sos_alerts(family_id, created_at DESC);CREATE INDEX IF NOT EXISTS idx_sos_alerts_active ON sos_alerts(family_id, status) WHERE status = 'active';-- RealtimeDO $$BEGIN  IF NOT EXISTS (    SELECT 1 FROM pg_publication_tables    WHERE pubname = 'supabase_realtime'      AND schemaname = 'public'      AND tablename = 'sos_alerts'  ) THEN    ALTER PUBLICATION supabase_realtime ADD TABLE sos_alerts;  END IF;END $$;\n-- ============================================\n-- FILE: 017_shopping_items.sql\n-- ============================================\n-- Shopping Items Table: Family-shared shopping listCREATE TABLE IF NOT EXISTS shopping_items (    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),    family_id UUID NOT NULL REFERENCES families(id) ON DELETE CASCADE,    name TEXT NOT NULL,    category TEXT DEFAULT 'other' CHECK (category IN ('grocery', 'pharmacy', 'stationery', 'household', 'other')),    quantity INTEGER DEFAULT 1,    is_completed BOOLEAN DEFAULT false,    completed_by TEXT,    requested_by TEXT,    created_at TIMESTAMPTZ DEFAULT now(),    updated_at TIMESTAMPTZ DEFAULT now());-- RLS PoliciesALTER TABLE IF EXISTS shopping_items ENABLE ROW LEVEL SECURITY;-- Anon (child accounts) can view and manage shopping items for their familyDROP POLICY IF EXISTS "Child can view family shopping" ON shopping_items;CREATE POLICY "Child can view family shopping" ON shopping_items    FOR SELECT TO anon    USING (family_id IN (        SELECT family_id FROM child_accounts WHERE id = nullif(current_setting('app.current_child_id', true), '')::uuid    ));DROP POLICY IF EXISTS "Child can update shopping items" ON shopping_items;CREATE POLICY "Child can update shopping items" ON shopping_items    FOR UPDATE TO anon    USING (family_id IN (        SELECT family_id FROM child_accounts WHERE id = nullif(current_setting('app.current_child_id', true), '')::uuid    ))    WITH CHECK (family_id IN (        SELECT family_id FROM child_accounts WHERE id = nullif(current_setting('app.current_child_id', true), '')::uuid    ));DROP POLICY IF EXISTS "Child can insert shopping items" ON shopping_items;CREATE POLICY "Child can insert shopping items" ON shopping_items    FOR INSERT TO anon    WITH CHECK (family_id IN (        SELECT family_id FROM child_accounts WHERE id = nullif(current_setting('app.current_child_id', true), '')::uuid    ));-- Authenticated parents can manage shopping items for their familyDROP POLICY IF EXISTS "Parent can manage family shopping" ON shopping_items;CREATE POLICY "Parent can manage family shopping" ON shopping_items    FOR ALL TO authenticated    USING (family_id IN (        SELECT family_id FROM profiles WHERE id = auth.uid()    ))    WITH CHECK (family_id IN (        SELECT family_id FROM profiles WHERE id = auth.uid()    ));-- IndexesCREATE INDEX IF NOT EXISTS idx_shopping_items_family ON shopping_items(family_id, is_completed, created_at DESC);-- RealtimeDO $$BEGIN  IF NOT EXISTS (    SELECT 1 FROM pg_publication_tables    WHERE pubname = 'supabase_realtime'      AND schemaname = 'public'      AND tablename = 'shopping_items'  ) THEN    ALTER PUBLICATION supabase_realtime ADD TABLE shopping_items;  END IF;END $$;\n-- ============================================\n-- FILE: 018_geolocations_policies.sql\n-- ============================================\n-- Geolocations RLS Policies: Fix missing authenticated policies + child_id support-- Authenticated parents can view all family geolocationsDROP POLICY IF EXISTS "Parent can view family geolocations" ON public.geolocations;CREATE POLICY "Parent can view family geolocations"  ON public.geolocations FOR SELECT TO authenticated  USING (family_id IN (    SELECT family_id FROM public.profiles WHERE id = auth.uid()  ));-- Authenticated parents can insert geolocations for their familyDROP POLICY IF EXISTS "Parent can insert family geolocations" ON public.geolocations;CREATE POLICY "Parent can insert family geolocations"  ON public.geolocations FOR INSERT TO authenticated  WITH CHECK (family_id IN (    SELECT family_id FROM public.profiles WHERE id = auth.uid()  ));-- Authenticated parents can update their own geolocationsDROP POLICY IF EXISTS "Parent can update own geolocations" ON public.geolocations;CREATE POLICY "Parent can update own geolocations"  ON public.geolocations FOR UPDATE TO authenticated  USING (user_id = auth.uid())  WITH CHECK (user_id = auth.uid());-- Authenticated parents can delete their own geolocationsDROP POLICY IF EXISTS "Parent can delete own geolocations" ON public.geolocations;CREATE POLICY "Parent can delete own geolocations"  ON public.geolocations FOR DELETE TO authenticated  USING (user_id = auth.uid());-- Anon child can insert with child_id (already in 015, but ensure it exists)DROP POLICY IF EXISTS "Anon child can share location" ON public.geolocations;CREATE POLICY "Anon child can share location"  ON public.geolocations FOR INSERT TO anon  WITH CHECK (child_id IN (    SELECT id FROM public.child_accounts WHERE id = nullif(current_setting('app.current_child_id', true), '')::uuid  ));-- Anon child can view family geolocations (already in 015, but ensure it exists)DROP POLICY IF EXISTS "Anon child can view family geolocations" ON public.geolocations;CREATE POLICY "Anon child can view family geolocations"  ON public.geolocations FOR SELECT TO anon  USING (family_id IN (    SELECT family_id FROM public.child_accounts WHERE id = nullif(current_setting('app.current_child_id', true), '')::uuid  ));\n-- ============================================\n-- FILE: 019_safe_arrivals.sql\n-- ============================================\n-- Safe Arrivals Table: Family-shared ETA monitoringCREATE TABLE IF NOT EXISTS safe_arrivals (    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),    family_id UUID NOT NULL REFERENCES families(id) ON DELETE CASCADE,    member_id TEXT NOT NULL, -- profiles.id or child_accounts.id    member_name TEXT NOT NULL,    destination TEXT NOT NULL,    started_at TIMESTAMPTZ DEFAULT now(),    estimated_arrival TIMESTAMPTZ NOT NULL,    actual_arrival TIMESTAMPTZ,    duration_minutes INT NOT NULL,    progress NUMERIC DEFAULT 0,    status TEXT DEFAULT 'active' CHECK (status IN ('active', 'arrived', 'delayed', 'cancelled')),    delay_minutes INT,    created_by TEXT,    created_at TIMESTAMPTZ DEFAULT now(),    updated_at TIMESTAMPTZ DEFAULT now());-- RLS PoliciesALTER TABLE IF EXISTS safe_arrivals ENABLE ROW LEVEL SECURITY;-- Anon (child accounts) can view family arrivalsDROP POLICY IF EXISTS "Child can view family arrivals" ON safe_arrivals;CREATE POLICY "Child can view family arrivals" ON safe_arrivals    FOR SELECT TO anon    USING (family_id IN (        SELECT family_id FROM child_accounts WHERE id = nullif(current_setting('app.current_child_id', true), '')::uuid    ));-- Anon child can insert their own arrival planDROP POLICY IF EXISTS "Child can insert own arrival" ON safe_arrivals;CREATE POLICY "Child can insert own arrival" ON safe_arrivals    FOR INSERT TO anon    WITH CHECK (family_id IN (        SELECT family_id FROM child_accounts WHERE id = nullif(current_setting('app.current_child_id', true), '')::uuid    ));-- Anon child can update their own arrivalDROP POLICY IF EXISTS "Child can update own arrival" ON safe_arrivals;CREATE POLICY "Child can update own arrival" ON safe_arrivals    FOR UPDATE TO anon    USING (member_id IN (        SELECT id::text FROM child_accounts WHERE id = nullif(current_setting('app.current_child_id', true), '')::uuid    ))    WITH CHECK (family_id IN (        SELECT family_id FROM child_accounts WHERE id = nullif(current_setting('app.current_child_id', true), '')::uuid    ));-- Authenticated parents can manage all family arrivalsDROP POLICY IF EXISTS "Parent can manage family arrivals" ON safe_arrivals;CREATE POLICY "Parent can manage family arrivals" ON safe_arrivals    FOR ALL TO authenticated    USING (family_id IN (        SELECT family_id FROM profiles WHERE id = auth.uid()    ))    WITH CHECK (family_id IN (        SELECT family_id FROM profiles WHERE id = auth.uid()    ));-- IndexesCREATE INDEX IF NOT EXISTS idx_safe_arrivals_family ON safe_arrivals(family_id, status, created_at DESC);CREATE INDEX IF NOT EXISTS idx_safe_arrivals_active ON safe_arrivals(family_id, status) WHERE status = 'active';-- RealtimeDO $$BEGIN  IF NOT EXISTS (    SELECT 1 FROM pg_publication_tables    WHERE pubname = 'supabase_realtime'      AND schemaname = 'public'      AND tablename = 'safe_arrivals'  ) THEN    ALTER PUBLICATION supabase_realtime ADD TABLE safe_arrivals;  END IF;END $$;\n-- ============================================\n-- FILE: 020_backups.sql\n-- ============================================\n-- Family Backups Table: Real backup storage for all family dataCREATE TABLE IF NOT EXISTS family_backups (    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),    family_id UUID NOT NULL REFERENCES families(id) ON DELETE CASCADE,    created_by TEXT NOT NULL, -- profiles.id or child_accounts.id    creator_name TEXT NOT NULL,    creator_email TEXT,    data_json JSONB NOT NULL, -- Encrypted/compressed family data dump    size_bytes INT,    record_count INT,    backup_type TEXT DEFAULT 'manual' CHECK (backup_type IN ('manual', 'auto')),    created_at TIMESTAMPTZ DEFAULT now());-- RLS PoliciesALTER TABLE IF EXISTS family_backups ENABLE ROW LEVEL SECURITY;-- Anon (child accounts) can view family backupsDROP POLICY IF EXISTS "Child can view family backups" ON family_backups;CREATE POLICY "Child can view family backups" ON family_backups    FOR SELECT TO anon    USING (family_id IN (        SELECT family_id FROM child_accounts WHERE id = nullif(current_setting('app.current_child_id', true), '')::uuid    ));-- Authenticated parents can manage family backupsDROP POLICY IF EXISTS "Parent can manage family backups" ON family_backups;CREATE POLICY "Parent can manage family backups" ON family_backups    FOR ALL TO authenticated    USING (family_id IN (        SELECT family_id FROM profiles WHERE id = auth.uid()    ))    WITH CHECK (family_id IN (        SELECT family_id FROM profiles WHERE id = auth.uid()    ));-- IndexesCREATE INDEX IF NOT EXISTS idx_family_backups_family ON family_backups(family_id, created_at DESC);-- RealtimeDO $$BEGIN  IF NOT EXISTS (    SELECT 1 FROM pg_publication_tables    WHERE pubname = 'supabase_realtime'      AND schemaname = 'public'      AND tablename = 'family_backups'  ) THEN    ALTER PUBLICATION supabase_realtime ADD TABLE family_backups;  END IF;END $$;\n-- ============================================\n-- FILE: 021_add_family_id_to_profiles.sql\n-- ============================================\n-- Migration 021: Add family_id to profiles table-- Fixes PostgrestException: column profiles.family_id does not exist-- 1. Add the columnALTER TABLE profiles ADD COLUMN IF NOT EXISTS family_id UUID REFERENCES families(id) ON DELETE SET NULL;-- 2. Create index for performanceCREATE INDEX IF NOT EXISTS idx_profiles_family_id ON profiles(family_id);-- 3. Backfill existing users from family_members junction tableUPDATE profiles pSET family_id = fm.family_idFROM family_members fmWHERE p.id = fm.user_id  AND p.family_id IS NULL;-- 4. Create trigger to keep profiles.family_id in sync with family_membersCREATE OR REPLACE FUNCTION sync_profile_family_id()RETURNS TRIGGER AS $$BEGIN  IF TG_OP = 'INSERT' OR (TG_OP = 'UPDATE' AND NEW.family_id IS DISTINCT FROM OLD.family_id) THEN    UPDATE profiles SET family_id = NEW.family_id WHERE id = NEW.user_id;  END IF;  RETURN NEW;END;$$ LANGUAGE plpgsql;DROP TRIGGER IF EXISTS family_members_insert_update ON family_members;CREATE TRIGGER family_members_insert_updateAFTER INSERT OR UPDATE OF family_id ON family_membersFOR EACH ROWEXECUTE FUNCTION sync_profile_family_id();\n-- ============================================\n-- FILE: 022_safe_zones_table.sql\n-- ============================================\n-- Migration 022: Create safe_zones table for persistent geofence storageCREATE TABLE IF NOT EXISTS safe_zones (  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),  family_id UUID NOT NULL REFERENCES families(id) ON DELETE CASCADE,  name TEXT NOT NULL,  type TEXT NOT NULL CHECK (type IN ('home', 'work', 'school', 'custom')),  latitude DOUBLE PRECISION NOT NULL,  longitude DOUBLE PRECISION NOT NULL,  radius_meters INTEGER NOT NULL DEFAULT 100,  address TEXT,  created_by UUID REFERENCES profiles(id),  created_at TIMESTAMPTZ DEFAULT now());CREATE INDEX IF NOT EXISTS idx_safe_zones_family_id ON safe_zones(family_id);-- Enable RLSALTER TABLE safe_zones ENABLE ROW LEVEL SECURITY;-- Policy: family members can read their family's safe zonesDROP POLICY IF EXISTS safe_zones_select_family ON safe_zones;CREATE POLICY safe_zones_select_family  ON safe_zones  FOR SELECT  USING (    family_id IN (      SELECT family_id FROM family_members WHERE user_id = auth.uid()    )  );-- Policy: family admins/parents can insert/update/deleteDROP POLICY IF EXISTS safe_zones_write_family ON safe_zones;CREATE POLICY safe_zones_write_family  ON safe_zones  FOR ALL  USING (    family_id IN (      SELECT family_id FROM family_members       WHERE user_id = auth.uid()       AND role IN ('admin', 'parent')    )  )  WITH CHECK (    family_id IN (      SELECT family_id FROM family_members       WHERE user_id = auth.uid()       AND role IN ('admin', 'parent')    )  );\n-- ============================================\n-- FILE: 023_family_moods_fix.sql\n-- ============================================\n-- ============================================-- FAMILY MOODS TABLE (Safe re-create if missing)-- ============================================CREATE TABLE IF NOT EXISTS public.family_moods (  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,  family_id UUID REFERENCES public.families(id) ON DELETE CASCADE,  user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,  mood_emoji TEXT NOT NULL,  mood_note TEXT,  energy_level INT CHECK (energy_level BETWEEN 1 AND 10),  is_shared BOOLEAN DEFAULT TRUE,  created_at TIMESTAMPTZ DEFAULT NOW());-- Enable RLSALTER TABLE public.family_moods ENABLE ROW LEVEL SECURITY;-- Drop existing policies to avoid conflictsDROP POLICY IF EXISTS "Family moods view" ON public.family_moods;DROP POLICY IF EXISTS "Family moods insert" ON public.family_moods;DROP POLICY IF EXISTS "Family moods update" ON public.family_moods;DROP POLICY IF EXISTS "Family moods delete" ON public.family_moods;-- Select: family members can view moods in their familyCREATE POLICY "Family moods view"  ON public.family_moods FOR SELECT  USING (family_id IN (    SELECT family_id FROM public.family_members WHERE user_id = auth.uid()  ));-- Insert: any authenticated user can insert their own moodCREATE POLICY "Family moods insert"  ON public.family_moods FOR INSERT  WITH CHECK (user_id = auth.uid());-- Update: users can only update their own moodsCREATE POLICY "Family moods update"  ON public.family_moods FOR UPDATE  USING (user_id = auth.uid());-- Delete: users can only delete their own moodsCREATE POLICY "Family moods delete"  ON public.family_moods FOR DELETE  USING (user_id = auth.uid());-- Realtime (safe add)DO $$BEGIN  IF NOT EXISTS (    SELECT 1 FROM pg_publication_tables    WHERE pubname = 'supabase_realtime'      AND schemaname = 'public'      AND tablename = 'family_moods'  ) THEN    ALTER PUBLICATION supabase_realtime ADD TABLE public.family_moods;  END IF;END $$;-- IndexCREATE INDEX IF NOT EXISTS idx_family_moods_family ON public.family_moods(family_id, created_at DESC);\n-- ============================================\n-- FILE: 024_family_contacts.sql\n-- ============================================\n-- ============================================-- FAMILY CONTACTS (Rehber)-- ============================================CREATE TABLE IF NOT EXISTS public.family_contacts (  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,  family_id UUID NOT NULL REFERENCES public.families(id) ON DELETE CASCADE,  name TEXT NOT NULL,  phone TEXT,  email TEXT,  type TEXT DEFAULT 'other' CHECK (type IN ('family', 'friend', 'work', 'school', 'doctor', 'emergency', 'other')),  avatar_url TEXT,  notes TEXT,  created_by UUID REFERENCES public.profiles(id),  created_at TIMESTAMPTZ DEFAULT NOW(),  updated_at TIMESTAMPTZ DEFAULT NOW());ALTER TABLE public.family_contacts ENABLE ROW LEVEL SECURITY;DROP POLICY IF EXISTS "Family contacts view" ON public.family_contacts;DROP POLICY IF EXISTS "Family contacts insert" ON public.family_contacts;DROP POLICY IF EXISTS "Family contacts update" ON public.family_contacts;DROP POLICY IF EXISTS "Family contacts delete" ON public.family_contacts;CREATE POLICY "Family contacts view"  ON public.family_contacts FOR SELECT  USING (family_id IN (    SELECT family_id FROM public.family_members WHERE user_id = auth.uid()  ));CREATE POLICY "Family contacts insert"  ON public.family_contacts FOR INSERT  WITH CHECK (family_id IN (    SELECT family_id FROM public.family_members WHERE user_id = auth.uid()  ));CREATE POLICY "Family contacts update"  ON public.family_contacts FOR UPDATE  USING (family_id IN (    SELECT family_id FROM public.family_members WHERE user_id = auth.uid()  ));CREATE POLICY "Family contacts delete"  ON public.family_contacts FOR DELETE  USING (family_id IN (    SELECT family_id FROM public.family_members WHERE user_id = auth.uid()  ));DO $$BEGIN  IF NOT EXISTS (    SELECT 1 FROM pg_publication_tables    WHERE pubname = 'supabase_realtime'      AND schemaname = 'public'      AND tablename = 'family_contacts'  ) THEN    ALTER PUBLICATION supabase_realtime ADD TABLE public.family_contacts;  END IF;END $$;CREATE INDEX IF NOT EXISTS idx_family_contacts_family ON public.family_contacts(family_id);CREATE INDEX IF NOT EXISTS idx_family_contacts_search ON public.family_contacts USING gin(to_tsvector('simple', coalesce(name,'') || ' ' || coalesce(phone,'')));\n-- ============================================\n-- FILE: 025_family_media.sql\n-- ============================================\n-- ============================================-- FAMILY MEDIA (Galeri)-- ============================================CREATE TABLE IF NOT EXISTS public.family_media (  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,  family_id UUID NOT NULL REFERENCES public.families(id) ON DELETE CASCADE,  url TEXT NOT NULL,  thumbnail_url TEXT,  type TEXT DEFAULT 'image' CHECK (type IN ('image', 'video')),  caption TEXT,  uploaded_by UUID REFERENCES public.profiles(id),  created_at TIMESTAMPTZ DEFAULT NOW());ALTER TABLE public.family_media ENABLE ROW LEVEL SECURITY;DROP POLICY IF EXISTS "Family media view" ON public.family_media;DROP POLICY IF EXISTS "Family media insert" ON public.family_media;DROP POLICY IF EXISTS "Family media delete" ON public.family_media;CREATE POLICY "Family media view"  ON public.family_media FOR SELECT  USING (family_id IN (    SELECT family_id FROM public.family_members WHERE user_id = auth.uid()  ));CREATE POLICY "Family media insert"  ON public.family_media FOR INSERT  WITH CHECK (family_id IN (    SELECT family_id FROM public.family_members WHERE user_id = auth.uid()  ));CREATE POLICY "Family media delete"  ON public.family_media FOR DELETE  USING (uploaded_by = auth.uid() OR family_id IN (    SELECT family_id FROM public.family_members WHERE user_id = auth.uid() AND role IN ('admin','parent')  ));DO $$BEGIN  IF NOT EXISTS (    SELECT 1 FROM pg_publication_tables    WHERE pubname = 'supabase_realtime'      AND schemaname = 'public'      AND tablename = 'family_media'  ) THEN    ALTER PUBLICATION supabase_realtime ADD TABLE public.family_media;  END IF;END $$;CREATE INDEX IF NOT EXISTS idx_family_media_family ON public.family_media(family_id, created_at DESC);\n-- ============================================\n-- FILE: 026_family_documents.sql\n-- ============================================\n-- ============================================-- FAMILY DOCUMENTS (Doküman + OCR)-- ============================================CREATE TABLE IF NOT EXISTS public.family_documents (  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,  family_id UUID NOT NULL REFERENCES public.families(id) ON DELETE CASCADE,  title TEXT NOT NULL,  file_url TEXT NOT NULL,  file_type TEXT DEFAULT 'pdf' CHECK (file_type IN ('pdf', 'image', 'doc', 'other')),  ocr_text TEXT,  extracted_data JSONB DEFAULT '{}',  status TEXT DEFAULT 'active' CHECK (status IN ('active', 'archived')),  related_task_id UUID REFERENCES public.tasks(id) ON DELETE SET NULL,  uploaded_by UUID REFERENCES public.profiles(id),  created_at TIMESTAMPTZ DEFAULT NOW(),  updated_at TIMESTAMPTZ DEFAULT NOW());ALTER TABLE public.family_documents ENABLE ROW LEVEL SECURITY;DROP POLICY IF EXISTS "Family documents view" ON public.family_documents;DROP POLICY IF EXISTS "Family documents insert" ON public.family_documents;DROP POLICY IF EXISTS "Family documents update" ON public.family_documents;DROP POLICY IF EXISTS "Family documents delete" ON public.family_documents;CREATE POLICY "Family documents view"  ON public.family_documents FOR SELECT  USING (family_id IN (    SELECT family_id FROM public.family_members WHERE user_id = auth.uid()  ));CREATE POLICY "Family documents insert"  ON public.family_documents FOR INSERT  WITH CHECK (family_id IN (    SELECT family_id FROM public.family_members WHERE user_id = auth.uid()  ));CREATE POLICY "Family documents update"  ON public.family_documents FOR UPDATE  USING (family_id IN (    SELECT family_id FROM public.family_members WHERE user_id = auth.uid()  ));CREATE POLICY "Family documents delete"  ON public.family_documents FOR DELETE  USING (uploaded_by = auth.uid() OR family_id IN (    SELECT family_id FROM public.family_members WHERE user_id = auth.uid() AND role IN ('admin','parent')  ));DO $$BEGIN  IF NOT EXISTS (    SELECT 1 FROM pg_publication_tables    WHERE pubname = 'supabase_realtime'      AND schemaname = 'public'      AND tablename = 'family_documents'  ) THEN    ALTER PUBLICATION supabase_realtime ADD TABLE public.family_documents;  END IF;END $$;CREATE INDEX IF NOT EXISTS idx_family_documents_family ON public.family_documents(family_id, created_at DESC);CREATE INDEX IF NOT EXISTS idx_family_documents_ocr ON public.family_documents USING gin(to_tsvector('simple', coalesce(ocr_text,'') || ' ' || coalesce(title,'')));\n-- ============================================\n-- FILE: 027_add_id_to_family_members.sql\n-- ============================================\n-- Fix: family_members table needs an id column for foreign key references-- Multiple migrations (011, 012, 013) reference family_members(id)-- Add id column if not existsALTER TABLE public.family_members ADD COLUMN IF NOT EXISTS id UUID DEFAULT gen_random_uuid();-- Backfill existing rows with generated UUIDsUPDATE public.family_members SET id = gen_random_uuid() WHERE id IS NULL;-- Ensure id is NOT NULL after backfillALTER TABLE public.family_members ALTER COLUMN id SET NOT NULL;-- Create unique index on id for FK referencesCREATE UNIQUE INDEX IF NOT EXISTS idx_family_members_id ON public.family_members(id);\n-- ============================================\n-- FILE: 028_security_questions.sql\n-- ============================================\n-- Migration 028: Add security questions and email to profiles table-- Enables in-app password reset with security question verification-- 1. Ensure email column exists (app inserts it but schema may not declare it)ALTER TABLE public.profilesADD COLUMN IF NOT EXISTS email TEXT;-- 2. Add security question columnsALTER TABLE public.profilesADD COLUMN IF NOT EXISTS security_question_1 TEXT;ALTER TABLE public.profilesADD COLUMN IF NOT EXISTS security_answer_1 TEXT;ALTER TABLE public.profilesADD COLUMN IF NOT EXISTS security_question_2 TEXT;ALTER TABLE public.profilesADD COLUMN IF NOT EXISTS security_answer_2 TEXT;-- 3. Create index on email for forgot-password lookupsCREATE INDEX IF NOT EXISTS idx_profiles_email ON public.profiles(email);-- 4. Update RLS: allow anyone to read security questions by email (needed for forgot-password flow)-- The existing "Profiles are viewable by everyone" SELECT policy already handles this.-- Ensure update policy allows users to update their own security questions.DROP POLICY IF EXISTS "Users can update own profile" ON public.profiles;CREATE POLICY "Users can update own profile"  ON public.profiles FOR UPDATE  USING (auth.uid() = id);\n-- ============================================\n-- FILE: 029_remote_screen_lock.sql\n-- ============================================\n-- Migration 029: Add remote screen lock columns to child_accounts-- Enables parents to force-lock a child's device remotelyALTER TABLE public.child_accountsADD COLUMN IF NOT EXISTS remote_lock_enabled boolean default false;ALTER TABLE public.child_accountsADD COLUMN IF NOT EXISTS remote_lock_until timestamptz;ALTER TABLE public.child_accountsADD COLUMN IF NOT EXISTS remote_lock_reason text;-- Update RLS: allow parents to update remote_lock fields-- The existing policy "Parents can manage children in their family" already covers this.
-- ============================================
-- FILE: 030_call_sessions.sql
-- ============================================
-- Sesli arama oturumları tablosu
CREATE TABLE IF NOT EXISTS call_sessions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  family_id uuid REFERENCES families(id) ON DELETE CASCADE NOT NULL,
  caller_id uuid REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
  callee_id uuid REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
  agora_channel_name text NOT NULL,
  status text NOT NULL DEFAULT 'ringing' CHECK (status IN ('ringing', 'connected', 'ended', 'rejected', 'missed', 'busy')),
  started_at timestamptz DEFAULT now(),
  ended_at timestamptz,
  duration_seconds int,
  caller_joined_at timestamptz,
  callee_joined_at timestamptz,
  created_at timestamptz DEFAULT now()
);

-- Hızlı sorgular için indeksler
CREATE INDEX IF NOT EXISTS idx_call_sessions_family ON call_sessions(family_id);
CREATE INDEX IF NOT EXISTS idx_call_sessions_callee ON call_sessions(callee_id, status);
CREATE INDEX IF NOT EXISTS idx_call_sessions_caller ON call_sessions(caller_id, status);

-- RLS: kullanıcı sadece kendi ailesinin aramalarını görebilir
ALTER TABLE call_sessions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "family_call_access" ON call_sessions
FOR ALL USING (
  family_id IN (
    SELECT family_id FROM family_members WHERE user_id = auth.uid()
  )
);

-- Uygulama çökmesi veya kapanması durumunda missed olarak işaretlemek için yardımcı fonksiyon
CREATE OR REPLACE FUNCTION mark_stale_calls_as_missed()
RETURNS void AS $$
BEGIN
  UPDATE call_sessions
  SET status = 'missed',
      ended_at = COALESCE(ended_at, now())
  WHERE status = 'ringing'
    AND started_at < now() - interval '60 seconds';
END;
$$ LANGUAGE plpgsql;

-- ============================================
-- FILE: 031_call_signaling.sql
-- ============================================
-- WebRTC signaling tablosu (ücretsiz peer-to-peer sesli arama için)
CREATE TABLE IF NOT EXISTS call_signaling (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  session_id uuid REFERENCES call_sessions(id) ON DELETE CASCADE NOT NULL,
  sender_id uuid NOT NULL,
  type text NOT NULL CHECK (type IN ('offer', 'answer', 'ice_candidate')),
  payload jsonb NOT NULL,
  created_at timestamptz DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_call_signaling_session ON call_signaling(session_id);

-- RLS: kullanıcı sadece kendi ailesinin signaling mesajlarını görebilir
ALTER TABLE call_signaling ENABLE ROW LEVEL SECURITY;

CREATE POLICY "family_call_signaling_access" ON call_signaling
FOR ALL USING (
  session_id IN (
    SELECT id FROM call_sessions WHERE family_id IN (
      SELECT family_id FROM family_members WHERE user_id = auth.uid()
    )
  )
);

-- ============================================
-- FILE: 032_family_member_permissions.sql
-- ============================================
-- Add permissions JSONB column to family_members
ALTER TABLE public.family_members ADD COLUMN IF NOT EXISTS permissions jsonb DEFAULT '{}';

-- Helper function to check admin status without RLS recursion
CREATE OR REPLACE FUNCTION public.is_family_admin(p_family_id uuid)
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM public.family_members fm
    WHERE fm.family_id = p_family_id
      AND fm.user_id = auth.uid()
      AND fm.role = 'admin'
  );
END;
$$;

-- Update RLS to allow admins to update permissions
DROP POLICY IF EXISTS "Family members updatable by admin" ON public.family_members;
CREATE POLICY "Family members updatable by admin"
  ON public.family_members FOR UPDATE TO authenticated
  USING (public.is_family_admin(family_members.family_id));

-- ============================================
-- FILE: 033_gamification.sql
-- ============================================
-- Görev oyunlaştırması (XP, rozet, lider tablosu)

-- XP ve rozet bilgileri profiles tablosuna eklendi
ALTER TABLE profiles
ADD COLUMN IF NOT EXISTS xp INTEGER DEFAULT 0,
ADD COLUMN IF NOT EXISTS badges JSONB DEFAULT '[]';

-- Rozet tanımları
CREATE TABLE IF NOT EXISTS badges (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  description TEXT NOT NULL,
  icon TEXT NOT NULL,
  threshold_xp INTEGER NOT NULL,
  color TEXT DEFAULT '#3B82F6',
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Varsayılan rozetler
INSERT INTO badges (id, name, description, icon, threshold_xp, color) VALUES
  ('first_task', 'İlk Adım', 'İlk görevi tamamla', 'emoji_events', 0, '#10B981'),
  ('task_master_10', 'Görev Ustası', '10 görev tamamla', 'emoji_events', 100, '#3B82F6'),
  ('task_master_50', 'Görev Kahramanı', '50 görev tamamla', 'emoji_events', 500, '#8B5CF6'),
  ('streak_7', '7 Gün Seri', '7 gün üst üste görev tamamla', 'local_fire_department', 200, '#F59E0B'),
  ('streak_30', 'Aylık Şampiyon', '30 gün üst üste görev tamamla', 'local_fire_department', 1000, '#EF4444'),
  ('helper', 'Yardımsever', '5 arkadaşını davet et', 'group', 150, '#EC4899')
ON CONFLICT (id) DO NOTHING;

-- XP ekleme fonksiyonu
CREATE OR REPLACE FUNCTION add_user_xp(p_user_id UUID, p_amount INTEGER)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  UPDATE profiles
  SET xp = COALESCE(xp, 0) + p_amount
  WHERE id = p_user_id;
END;
$$;

-- ============================================
-- FILE: 034_fix_family_members_rls.sql
-- ============================================
-- Fix infinite recursion in family_members RLS policies
-- and add missing policies for tasks / family_members access

-- 1. Allow authenticated users to read their own family_members records.
-- Uses profiles.family_id (maintained by trigger in 021) to avoid recursion.
DROP POLICY IF EXISTS "Family members select" ON public.family_members;
CREATE POLICY "Family members select"
  ON public.family_members FOR SELECT TO authenticated
  USING (
    family_id IN (
      SELECT family_id FROM public.profiles
      WHERE id = auth.uid() AND family_id IS NOT NULL
    )
  );

-- 2. Allow authenticated users to insert their own family_members records.
DROP POLICY IF EXISTS "Family members insert" ON public.family_members;
CREATE POLICY "Family members insert"
  ON public.family_members FOR INSERT TO authenticated
  WITH CHECK (user_id = auth.uid());

-- 3. Add missing INSERT policy for tasks so family members can create tasks.
DROP POLICY IF EXISTS "Tasks insert" ON public.tasks;
CREATE POLICY "Tasks insert"
  ON public.tasks FOR INSERT TO authenticated
  WITH CHECK (
    family_id IN (
      SELECT family_id FROM public.profiles
      WHERE id = auth.uid() AND family_id IS NOT NULL
    )
  );

-- ============================================
-- FILE: 035_add_accent_color_to_profiles.sql
-- ============================================
-- Add accent_color to profiles so theme preferences persist per-profile
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS accent_color TEXT DEFAULT 'cobalt';

-- ============================================
-- FILE: 036_fix_rls_and_theme.sql
-- ============================================
-- Fix RLS recursion, missing policies, and add profile accent color
-- (Consolidates fixes from edited 032 + 034 + 035 into a single new migration)

-- 1. Helper function to check admin status without RLS recursion
CREATE OR REPLACE FUNCTION public.is_family_admin(p_family_id uuid)
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM public.family_members fm
    WHERE fm.family_id = p_family_id
      AND fm.user_id = auth.uid()
      AND fm.role = 'admin'
  );
END;
$$;

-- 2. Fix UPDATE policy on family_members to use the helper (avoids infinite recursion)
DROP POLICY IF EXISTS "Family members updatable by admin" ON public.family_members;
CREATE POLICY "Family members updatable by admin"
  ON public.family_members FOR UPDATE TO authenticated
  USING (public.is_family_admin(family_members.family_id));

-- 3. Add SELECT policy for family_members so other policies can query it safely
DROP POLICY IF EXISTS "Family members select" ON public.family_members;
CREATE POLICY "Family members select"
  ON public.family_members FOR SELECT TO authenticated
  USING (
    family_id IN (
      SELECT family_id FROM public.profiles
      WHERE id = auth.uid() AND family_id IS NOT NULL
    )
  );

-- 4. Add INSERT policy for family_members
DROP POLICY IF EXISTS "Family members insert" ON public.family_members;
CREATE POLICY "Family members insert"
  ON public.family_members FOR INSERT TO authenticated
  WITH CHECK (user_id = auth.uid());

-- 5. Add missing INSERT policy for tasks
DROP POLICY IF EXISTS "Tasks insert" ON public.tasks;
CREATE POLICY "Tasks insert"
  ON public.tasks FOR INSERT TO authenticated
  WITH CHECK (
    family_id IN (
      SELECT family_id FROM public.profiles
      WHERE id = auth.uid() AND family_id IS NOT NULL
    )
  );

-- 6. Add accent_color to profiles so theme preferences persist per-profile
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS accent_color TEXT DEFAULT 'cobalt';
-- ============================================================================
-- 044_fix_everything.sql
-- MASTER RLS FIX - Tek seferde tüm izin sorunlarını çöz
-- Çalıştırma: Supabase Dashboard > SQL Editor > New Query > Run
-- ============================================================================
-- BU DOSYA:
-- 1. Tüm bozuk/eski RLS policy'lerini düşürür
-- 2. family_members için kritik SELECT policy'si ekler
-- 3. Tüm tablolar için profiles.family_id tabanlı, rekürsiyonsuz policy'ler oluşturur
-- 4. Yeni kullanıcıların aile oluşturabilmesi için families INSERT policy'si ekler
-- ============================================================================

-- =============================================================================
-- PHASE 1: DROP ALL EXISTING POLICIES (clean slate)
-- =============================================================================

-- profiles
DROP POLICY IF EXISTS "Profiles are viewable by everyone" ON public.profiles;
DROP POLICY IF EXISTS "Profiles updatable by owner" ON public.profiles;
DROP POLICY IF EXISTS "Profiles update own" ON public.profiles;
DROP POLICY IF EXISTS "Profiles update own family_id" ON public.profiles;
DROP POLICY IF EXISTS "profiles_select" ON public.profiles;
DROP POLICY IF EXISTS "profiles_update" ON public.profiles;
DROP POLICY IF EXISTS "profiles_insert" ON public.profiles;

-- families
DROP POLICY IF EXISTS "Families viewable by members" ON public.families;
DROP POLICY IF EXISTS "Families updatable by admin" ON public.families;
DROP POLICY IF EXISTS "Families insertable by authenticated" ON public.families;
DROP POLICY IF EXISTS "families_select" ON public.families;
DROP POLICY IF EXISTS "families_insert" ON public.families;
DROP POLICY IF EXISTS "families_update" ON public.families;

-- family_members
DROP POLICY IF EXISTS "Family members viewable by family" ON public.family_members;
DROP POLICY IF EXISTS "Family members insertable by admin" ON public.family_members;
DROP POLICY IF EXISTS "Family members updatable by admin" ON public.family_members;
DROP POLICY IF EXISTS "Family members deletable by admin" ON public.family_members;
DROP POLICY IF EXISTS "Family members viewable by self" ON public.family_members;
DROP POLICY IF EXISTS "Family members insertable by self" ON public.family_members;
DROP POLICY IF EXISTS "Family members updatable by self" ON public.family_members;
DROP POLICY IF EXISTS "family_members_select" ON public.family_members;
DROP POLICY IF EXISTS "family_members_insert" ON public.family_members;
DROP POLICY IF EXISTS "family_members_update" ON public.family_members;
DROP POLICY IF EXISTS "family_members_delete" ON public.family_members;

-- events
DROP POLICY IF EXISTS "Events viewable by family" ON public.events;
DROP POLICY IF EXISTS "Events insertable by family" ON public.events;
DROP POLICY IF EXISTS "Events updatable by family" ON public.events;
DROP POLICY IF EXISTS "Events deletable by creator" ON public.events;
DROP POLICY IF EXISTS "events_select" ON public.events;
DROP POLICY IF EXISTS "events_insert" ON public.events;
DROP POLICY IF EXISTS "events_update" ON public.events;
DROP POLICY IF EXISTS "events_delete" ON public.events;

-- tasks
DROP POLICY IF EXISTS "Tasks viewable by family" ON public.tasks;
DROP POLICY IF EXISTS "Tasks insertable by family" ON public.tasks;
DROP POLICY IF EXISTS "Tasks updatable by family" ON public.tasks;
DROP POLICY IF EXISTS "Tasks deletable by family" ON public.tasks;
DROP POLICY IF EXISTS "tasks_select" ON public.tasks;
DROP POLICY IF EXISTS "tasks_insert" ON public.tasks;
DROP POLICY IF EXISTS "tasks_update" ON public.tasks;
DROP POLICY IF EXISTS "tasks_delete" ON public.tasks;

-- messages
DROP POLICY IF EXISTS "Messages viewable by family" ON public.messages;
DROP POLICY IF EXISTS "Messages insertable by family" ON public.messages;
DROP POLICY IF EXISTS "Messages updatable by sender" ON public.messages;
DROP POLICY IF EXISTS "messages_select" ON public.messages;
DROP POLICY IF EXISTS "messages_insert" ON public.messages;
DROP POLICY IF EXISTS "messages_update" ON public.messages;
DROP POLICY IF EXISTS "messages_delete" ON public.messages;

-- family_moods
DROP POLICY IF EXISTS "Moods viewable by family" ON public.family_moods;
DROP POLICY IF EXISTS "Moods insertable by family" ON public.family_moods;
DROP POLICY IF EXISTS "family_moods_select" ON public.family_moods;
DROP POLICY IF EXISTS "family_moods_insert" ON public.family_moods;
DROP POLICY IF EXISTS "family_moods_update" ON public.family_moods;
DROP POLICY IF EXISTS "family_moods_delete" ON public.family_moods;

-- shopping_items
DROP POLICY IF EXISTS "Shopping viewable by family" ON public.shopping_items;
DROP POLICY IF EXISTS "Shopping insertable by family" ON public.shopping_items;
DROP POLICY IF EXISTS "Shopping updatable by family" ON public.shopping_items;
DROP POLICY IF EXISTS "Shopping deletable by family" ON public.shopping_items;
DROP POLICY IF EXISTS "shopping_items_select" ON public.shopping_items;
DROP POLICY IF EXISTS "shopping_items_insert" ON public.shopping_items;
DROP POLICY IF EXISTS "shopping_items_update" ON public.shopping_items;
DROP POLICY IF EXISTS "shopping_items_delete" ON public.shopping_items;

-- family_contacts
DROP POLICY IF EXISTS "Contacts viewable by family" ON public.family_contacts;
DROP POLICY IF EXISTS "Contacts insertable by family" ON public.family_contacts;
DROP POLICY IF EXISTS "Contacts updatable by family" ON public.family_contacts;
DROP POLICY IF EXISTS "Contacts deletable by family" ON public.family_contacts;
DROP POLICY IF EXISTS "family_contacts_select" ON public.family_contacts;
DROP POLICY IF EXISTS "family_contacts_insert" ON public.family_contacts;
DROP POLICY IF EXISTS "family_contacts_update" ON public.family_contacts;
DROP POLICY IF EXISTS "family_contacts_delete" ON public.family_contacts;

-- family_media
DROP POLICY IF EXISTS "Media viewable by family" ON public.family_media;
DROP POLICY IF EXISTS "Media insertable by family" ON public.family_media;
DROP POLICY IF EXISTS "family_media_select" ON public.family_media;
DROP POLICY IF EXISTS "family_media_insert" ON public.family_media;
DROP POLICY IF EXISTS "family_media_update" ON public.family_media;
DROP POLICY IF EXISTS "family_media_delete" ON public.family_media;

-- family_documents
DROP POLICY IF EXISTS "Documents viewable by family" ON public.family_documents;
DROP POLICY IF EXISTS "Documents insertable by family" ON public.family_documents;
DROP POLICY IF EXISTS "Documents updatable by uploader" ON public.family_documents;
DROP POLICY IF EXISTS "family_documents_select" ON public.family_documents;
DROP POLICY IF EXISTS "family_documents_insert" ON public.family_documents;
DROP POLICY IF EXISTS "family_documents_update" ON public.family_documents;
DROP POLICY IF EXISTS "family_documents_delete" ON public.family_documents;

-- safe_zones
DROP POLICY IF EXISTS "Safe zones viewable by family" ON public.safe_zones;
DROP POLICY IF EXISTS "Safe zones insertable by family" ON public.safe_zones;
DROP POLICY IF EXISTS "Safe zones updatable by family" ON public.safe_zones;
DROP POLICY IF EXISTS "Safe zones deletable by family" ON public.safe_zones;
DROP POLICY IF EXISTS "safe_zones_select" ON public.safe_zones;
DROP POLICY IF EXISTS "safe_zones_insert" ON public.safe_zones;
DROP POLICY IF EXISTS "safe_zones_update" ON public.safe_zones;
DROP POLICY IF EXISTS "safe_zones_delete" ON public.safe_zones;

-- child_accounts
DROP POLICY IF EXISTS "Child accounts viewable by family" ON public.child_accounts;
DROP POLICY IF EXISTS "Child accounts insertable by family" ON public.child_accounts;
DROP POLICY IF EXISTS "child_accounts_select" ON public.child_accounts;
DROP POLICY IF EXISTS "child_accounts_insert" ON public.child_accounts;
DROP POLICY IF EXISTS "child_accounts_update" ON public.child_accounts;
DROP POLICY IF EXISTS "child_accounts_delete" ON public.child_accounts;

-- ai_suggestions_cache
DROP POLICY IF EXISTS "AI suggestions viewable by family" ON public.ai_suggestions_cache;
DROP POLICY IF EXISTS "AI suggestions insertable by family" ON public.ai_suggestions_cache;
DROP POLICY IF EXISTS "ai_suggestions_select" ON public.ai_suggestions_cache;
DROP POLICY IF EXISTS "ai_suggestions_insert" ON public.ai_suggestions_cache;
DROP POLICY IF EXISTS "ai_suggestions_update" ON public.ai_suggestions_cache;
DROP POLICY IF EXISTS "ai_suggestions_delete" ON public.ai_suggestions_cache;

-- weather_cache
DROP POLICY IF EXISTS "Weather viewable by family" ON public.weather_cache;
DROP POLICY IF EXISTS "weather_cache_select" ON public.weather_cache;
DROP POLICY IF EXISTS "weather_cache_insert" ON public.weather_cache;

-- crash_events
DROP POLICY IF EXISTS "Crash events viewable by family" ON public.crash_events;
DROP POLICY IF EXISTS "crash_events_select" ON public.crash_events;
DROP POLICY IF EXISTS "crash_events_insert" ON public.crash_events;

-- =============================================================================
-- PHASE 2: CREATE CLEAN POLICIES
-- =============================================================================

-- -----------------------------------------------------------------------------
-- PROFILES
-- -----------------------------------------------------------------------------
CREATE POLICY "profiles_select_all"
  ON public.profiles FOR SELECT TO authenticated
  USING (true);

CREATE POLICY "profiles_update_own"
  ON public.profiles FOR UPDATE TO authenticated
  USING (id = auth.uid())
  WITH CHECK (id = auth.uid());

-- -----------------------------------------------------------------------------
-- FAMILIES
-- -----------------------------------------------------------------------------
CREATE POLICY "families_select"
  ON public.families FOR SELECT TO authenticated
  USING (
    id IN (SELECT family_id FROM public.profiles WHERE id = auth.uid() AND family_id IS NOT NULL)
  );

CREATE POLICY "families_insert"
  ON public.families FOR INSERT TO authenticated
  WITH CHECK (true);

CREATE POLICY "families_update"
  ON public.families FOR UPDATE TO authenticated
  USING (
    id IN (SELECT family_id FROM public.profiles WHERE id = auth.uid() AND family_id IS NOT NULL)
  );

-- -----------------------------------------------------------------------------
-- FAMILY_MEMBERS  (CRITICAL - the root cause of 0/0/0/0 data)
-- -----------------------------------------------------------------------------
CREATE POLICY "family_members_select_self"
  ON public.family_members FOR SELECT TO authenticated
  USING (user_id = auth.uid());

CREATE POLICY "family_members_select_by_family"
  ON public.family_members FOR SELECT TO authenticated
  USING (
    family_id IN (SELECT family_id FROM public.profiles WHERE id = auth.uid() AND family_id IS NOT NULL)
  );

CREATE POLICY "family_members_insert"
  ON public.family_members FOR INSERT TO authenticated
  WITH CHECK (
    family_id IN (SELECT family_id FROM public.profiles WHERE id = auth.uid() AND family_id IS NOT NULL)
    OR user_id = auth.uid()
  );

CREATE POLICY "family_members_update"
  ON public.family_members FOR UPDATE TO authenticated
  USING (
    family_id IN (SELECT family_id FROM public.profiles WHERE id = auth.uid() AND family_id IS NOT NULL)
  );

-- -----------------------------------------------------------------------------
-- EVENTS
-- -----------------------------------------------------------------------------
CREATE POLICY "events_select"
  ON public.events FOR SELECT TO authenticated
  USING (
    family_id IN (SELECT family_id FROM public.profiles WHERE id = auth.uid() AND family_id IS NOT NULL)
  );

CREATE POLICY "events_insert"
  ON public.events FOR INSERT TO authenticated
  WITH CHECK (
    family_id IN (SELECT family_id FROM public.profiles WHERE id = auth.uid() AND family_id IS NOT NULL)
  );

CREATE POLICY "events_update"
  ON public.events FOR UPDATE TO authenticated
  USING (
    family_id IN (SELECT family_id FROM public.profiles WHERE id = auth.uid() AND family_id IS NOT NULL)
  );

CREATE POLICY "events_delete"
  ON public.events FOR DELETE TO authenticated
  USING (
    family_id IN (SELECT family_id FROM public.profiles WHERE id = auth.uid() AND family_id IS NOT NULL)
  );

-- -----------------------------------------------------------------------------
-- TASKS
-- -----------------------------------------------------------------------------
CREATE POLICY "tasks_select"
  ON public.tasks FOR SELECT TO authenticated
  USING (
    family_id IN (SELECT family_id FROM public.profiles WHERE id = auth.uid() AND family_id IS NOT NULL)
  );

CREATE POLICY "tasks_insert"
  ON public.tasks FOR INSERT TO authenticated
  WITH CHECK (
    family_id IN (SELECT family_id FROM public.profiles WHERE id = auth.uid() AND family_id IS NOT NULL)
  );

CREATE POLICY "tasks_update"
  ON public.tasks FOR UPDATE TO authenticated
  USING (
    family_id IN (SELECT family_id FROM public.profiles WHERE id = auth.uid() AND family_id IS NOT NULL)
  );

CREATE POLICY "tasks_delete"
  ON public.tasks FOR DELETE TO authenticated
  USING (
    family_id IN (SELECT family_id FROM public.profiles WHERE id = auth.uid() AND family_id IS NOT NULL)
  );

-- -----------------------------------------------------------------------------
-- MESSAGES
-- -----------------------------------------------------------------------------
CREATE POLICY "messages_select"
  ON public.messages FOR SELECT TO authenticated
  USING (
    family_id IN (SELECT family_id FROM public.profiles WHERE id = auth.uid() AND family_id IS NOT NULL)
  );

CREATE POLICY "messages_insert"
  ON public.messages FOR INSERT TO authenticated
  WITH CHECK (
    family_id IN (SELECT family_id FROM public.profiles WHERE id = auth.uid() AND family_id IS NOT NULL)
  );

CREATE POLICY "messages_update"
  ON public.messages FOR UPDATE TO authenticated
  USING (user_id = auth.uid());

CREATE POLICY "messages_delete"
  ON public.messages FOR DELETE TO authenticated
  USING (user_id = auth.uid());

-- -----------------------------------------------------------------------------
-- FAMILY_MOODS
-- -----------------------------------------------------------------------------
CREATE POLICY "family_moods_select"
  ON public.family_moods FOR SELECT TO authenticated
  USING (
    family_id IN (SELECT family_id FROM public.profiles WHERE id = auth.uid() AND family_id IS NOT NULL)
  );

CREATE POLICY "family_moods_insert"
  ON public.family_moods FOR INSERT TO authenticated
  WITH CHECK (
    family_id IN (SELECT family_id FROM public.profiles WHERE id = auth.uid() AND family_id IS NOT NULL)
  );

CREATE POLICY "family_moods_update"
  ON public.family_moods FOR UPDATE TO authenticated
  USING (user_id = auth.uid());

CREATE POLICY "family_moods_delete"
  ON public.family_moods FOR DELETE TO authenticated
  USING (user_id = auth.uid());

-- -----------------------------------------------------------------------------
-- SHOPPING_ITEMS
-- -----------------------------------------------------------------------------
CREATE POLICY "shopping_items_select"
  ON public.shopping_items FOR SELECT TO authenticated
  USING (
    family_id IN (SELECT family_id FROM public.profiles WHERE id = auth.uid() AND family_id IS NOT NULL)
  );

CREATE POLICY "shopping_items_insert"
  ON public.shopping_items FOR INSERT TO authenticated
  WITH CHECK (
    family_id IN (SELECT family_id FROM public.profiles WHERE id = auth.uid() AND family_id IS NOT NULL)
  );

CREATE POLICY "shopping_items_update"
  ON public.shopping_items FOR UPDATE TO authenticated
  USING (
    family_id IN (SELECT family_id FROM public.profiles WHERE id = auth.uid() AND family_id IS NOT NULL)
  );

CREATE POLICY "shopping_items_delete"
  ON public.shopping_items FOR DELETE TO authenticated
  USING (
    family_id IN (SELECT family_id FROM public.profiles WHERE id = auth.uid() AND family_id IS NOT NULL)
  );

-- -----------------------------------------------------------------------------
-- FAMILY_CONTACTS
-- -----------------------------------------------------------------------------
CREATE POLICY "family_contacts_select"
  ON public.family_contacts FOR SELECT TO authenticated
  USING (
    family_id IN (SELECT family_id FROM public.profiles WHERE id = auth.uid() AND family_id IS NOT NULL)
  );

CREATE POLICY "family_contacts_insert"
  ON public.family_contacts FOR INSERT TO authenticated
  WITH CHECK (
    family_id IN (SELECT family_id FROM public.profiles WHERE id = auth.uid() AND family_id IS NOT NULL)
  );

CREATE POLICY "family_contacts_update"
  ON public.family_contacts FOR UPDATE TO authenticated
  USING (
    family_id IN (SELECT family_id FROM public.profiles WHERE id = auth.uid() AND family_id IS NOT NULL)
  );

CREATE POLICY "family_contacts_delete"
  ON public.family_contacts FOR DELETE TO authenticated
  USING (
    family_id IN (SELECT family_id FROM public.profiles WHERE id = auth.uid() AND family_id IS NOT NULL)
  );

-- -----------------------------------------------------------------------------
-- FAMILY_MEDIA
-- -----------------------------------------------------------------------------
CREATE POLICY "family_media_select"
  ON public.family_media FOR SELECT TO authenticated
  USING (
    family_id IN (SELECT family_id FROM public.profiles WHERE id = auth.uid() AND family_id IS NOT NULL)
  );

CREATE POLICY "family_media_insert"
  ON public.family_media FOR INSERT TO authenticated
  WITH CHECK (
    family_id IN (SELECT family_id FROM public.profiles WHERE id = auth.uid() AND family_id IS NOT NULL)
  );

-- -----------------------------------------------------------------------------
-- FAMILY_DOCUMENTS
-- -----------------------------------------------------------------------------
CREATE POLICY "family_documents_select"
  ON public.family_documents FOR SELECT TO authenticated
  USING (
    family_id IN (SELECT family_id FROM public.profiles WHERE id = auth.uid() AND family_id IS NOT NULL)
  );

CREATE POLICY "family_documents_insert"
  ON public.family_documents FOR INSERT TO authenticated
  WITH CHECK (
    family_id IN (SELECT family_id FROM public.profiles WHERE id = auth.uid() AND family_id IS NOT NULL)
  );

CREATE POLICY "family_documents_update"
  ON public.family_documents FOR UPDATE TO authenticated
  USING (
    family_id IN (SELECT family_id FROM public.profiles WHERE id = auth.uid() AND family_id IS NOT NULL)
  );

CREATE POLICY "family_documents_delete"
  ON public.family_documents FOR DELETE TO authenticated
  USING (
    family_id IN (SELECT family_id FROM public.profiles WHERE id = auth.uid() AND family_id IS NOT NULL)
  );

-- -----------------------------------------------------------------------------
-- SAFE_ZONES
-- -----------------------------------------------------------------------------
CREATE POLICY "safe_zones_select"
  ON public.safe_zones FOR SELECT TO authenticated
  USING (
    family_id IN (SELECT family_id FROM public.profiles WHERE id = auth.uid() AND family_id IS NOT NULL)
  );

CREATE POLICY "safe_zones_insert"
  ON public.safe_zones FOR INSERT TO authenticated
  WITH CHECK (
    family_id IN (SELECT family_id FROM public.profiles WHERE id = auth.uid() AND family_id IS NOT NULL)
  );

CREATE POLICY "safe_zones_update"
  ON public.safe_zones FOR UPDATE TO authenticated
  USING (
    family_id IN (SELECT family_id FROM public.profiles WHERE id = auth.uid() AND family_id IS NOT NULL)
  );

CREATE POLICY "safe_zones_delete"
  ON public.safe_zones FOR DELETE TO authenticated
  USING (
    family_id IN (SELECT family_id FROM public.profiles WHERE id = auth.uid() AND family_id IS NOT NULL)
  );

-- -----------------------------------------------------------------------------
-- CHILD_ACCOUNTS
-- -----------------------------------------------------------------------------
CREATE POLICY "child_accounts_select"
  ON public.child_accounts FOR SELECT TO authenticated
  USING (
    family_id IN (SELECT family_id FROM public.profiles WHERE id = auth.uid() AND family_id IS NOT NULL)
  );

CREATE POLICY "child_accounts_insert"
  ON public.child_accounts FOR INSERT TO authenticated
  WITH CHECK (
    family_id IN (SELECT family_id FROM public.profiles WHERE id = auth.uid() AND family_id IS NOT NULL)
  );

CREATE POLICY "child_accounts_update"
  ON public.child_accounts FOR UPDATE TO authenticated
  USING (
    family_id IN (SELECT family_id FROM public.profiles WHERE id = auth.uid() AND family_id IS NOT NULL)
  );

CREATE POLICY "child_accounts_delete"
  ON public.child_accounts FOR DELETE TO authenticated
  USING (
    family_id IN (SELECT family_id FROM public.profiles WHERE id = auth.uid() AND family_id IS NOT NULL)
  );

-- -----------------------------------------------------------------------------
-- AI_SUGGESTIONS_CACHE
-- -----------------------------------------------------------------------------
CREATE POLICY "ai_suggestions_select"
  ON public.ai_suggestions_cache FOR SELECT TO authenticated
  USING (
    family_id IN (SELECT family_id FROM public.profiles WHERE id = auth.uid() AND family_id IS NOT NULL)
  );

CREATE POLICY "ai_suggestions_insert"
  ON public.ai_suggestions_cache FOR INSERT TO authenticated
  WITH CHECK (
    family_id IN (SELECT family_id FROM public.profiles WHERE id = auth.uid() AND family_id IS NOT NULL)
  );

-- -----------------------------------------------------------------------------
-- WEATHER_CACHE
-- -----------------------------------------------------------------------------
CREATE POLICY "weather_cache_select"
  ON public.weather_cache FOR SELECT TO authenticated
  USING (
    family_id IN (SELECT family_id FROM public.profiles WHERE id = auth.uid() AND family_id IS NOT NULL)
  );

CREATE POLICY "weather_cache_insert"
  ON public.weather_cache FOR INSERT TO authenticated
  WITH CHECK (
    family_id IN (SELECT family_id FROM public.profiles WHERE id = auth.uid() AND family_id IS NOT NULL)
  );

-- -----------------------------------------------------------------------------
-- CRASH_EVENTS
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.crash_events (
  id uuid DEFAULT uuid_generate_v4() PRIMARY KEY,
  family_id uuid REFERENCES public.families(id) ON DELETE CASCADE,
  user_id uuid REFERENCES public.profiles(id) ON DELETE SET NULL,
  error_message text,
  stack_trace text,
  app_version text,
  device_info text,
  created_at timestamptz DEFAULT now()
);

CREATE POLICY "crash_events_select"
  ON public.crash_events FOR SELECT TO authenticated
  USING (
    family_id IN (SELECT family_id FROM public.profiles WHERE id = auth.uid() AND family_id IS NOT NULL)
  );

CREATE POLICY "crash_events_insert"
  ON public.crash_events FOR INSERT TO authenticated
  WITH CHECK (
    family_id IN (SELECT family_id FROM public.profiles WHERE id = auth.uid() AND family_id IS NOT NULL)
  );

-- =============================================================================
-- PHASE 3: ENABLE RLS ON TABLES (if not already enabled)
-- =============================================================================
ALTER TABLE IF EXISTS public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.families ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.family_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.events ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.tasks ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.family_moods ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.shopping_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.family_contacts ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.family_media ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.family_documents ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.safe_zones ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.child_accounts ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.ai_suggestions_cache ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.weather_cache ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.crash_events ENABLE ROW LEVEL SECURITY;

-- =============================================================================
-- PHASE 4: FORCE POLICY RELOAD (Supabase cache clear)
-- =============================================================================
NOTIFY pgrst, 'reload schema';

-- ============================================
-- RLS POLICY FIX TAMAMLANDI
-- Tum tablolar icin policyler yeniden olusturuldu.
-- Lutfen uygulamayi tamamen kapatip yeniden acin.
-- ============================================


-- ============================================================================
-- 046_final_rls_and_users.sql
-- NET COZUM: RLS fix + profiles insert policy + kullanici ekleme
-- Calistirma: Supabase Dashboard > SQL Editor > New Query > Run
-- ============================================================================

-- =============================================================================
-- PHASE 1: FIX BROKEN POLICIES (045 bozdu, 044 duzeltiyoruz)
-- =============================================================================

-- 1a. profiles INSERT policy EKSIKTI — signUp'ta profiles.upsert basarisiz oluyordu
DROP POLICY IF EXISTS "profiles_insert_own" ON public.profiles;
CREATE POLICY "profiles_insert_own"
  ON public.profiles FOR INSERT TO authenticated
  WITH CHECK (id = auth.uid());

-- 1b. family_members_select_by_family 045'te recursive yapilmisti, duzelt
DROP POLICY IF EXISTS "family_members_select_by_family" ON public.family_members;
CREATE POLICY "family_members_select_by_family"
  ON public.family_members FOR SELECT TO authenticated
  USING (
    family_id IN (SELECT family_id FROM public.profiles WHERE id = auth.uid() AND family_id IS NOT NULL)
  );

-- 1c. family_members viewable by self (kayit sirasinda family_id null iken gerekli)
DROP POLICY IF EXISTS "family_members_viewable_by_self" ON public.family_members;
CREATE POLICY "family_members_viewable_by_self"
  ON public.family_members FOR SELECT TO authenticated
  USING (user_id = auth.uid());

-- 1d. families SELECT policy (aileye katilanlar gorebilsin)
DROP POLICY IF EXISTS "families_select_by_member" ON public.families;
CREATE POLICY "families_select_by_member"
  ON public.families FOR SELECT TO authenticated
  USING (
    id IN (SELECT family_id FROM public.profiles WHERE id = auth.uid() AND family_id IS NOT NULL)
    OR id IN (SELECT family_id FROM public.family_members WHERE user_id = auth.uid())
  );

-- =============================================================================
-- PHASE 2: CHILD ACCOUNTS age kolonu (eksikse ekle)
-- =============================================================================
ALTER TABLE public.child_accounts ADD COLUMN IF NOT EXISTS age int;

-- =============================================================================
-- PHASE 3: KULLANICI EKLEME (SQL Editor'da RLS bypass edilir)
-- =============================================================================

-- 3a. Ebeveyn kullanicisini auth.users'tan bul
DO $$
DECLARE
  v_parent_id uuid;
  v_family_id uuid := '3816dedb-c232-493a-b8f5-eccf326f0d3c';
  v_existing_family_id uuid;
BEGIN
  -- Ebeveyn kullanici ID'sini auth.users'tan al
  SELECT id INTO v_parent_id FROM auth.users WHERE email = 'hilalsahbaz2018@gmail.com' LIMIT 1;
  
  IF v_parent_id IS NULL THEN
    RAISE NOTICE 'Ebeveyn kullanici auth.users tablosunda bulunamadi. Once uygulamadan kayit olunmalidir.';
  ELSE
    -- profiles tablosunda var mi kontrol et, yoksa ekle
    IF NOT EXISTS (SELECT 1 FROM public.profiles WHERE id = v_parent_id) THEN
      INSERT INTO public.profiles (id, display_name, email, family_id, created_at, updated_at)
      VALUES (v_parent_id, 'Hilal', 'hilalsahbaz2018@gmail.com', v_family_id, now(), now());
      RAISE NOTICE 'Ebeveyn profili olusturuldu.';
    ELSE
      -- family_id guncelle (eger null veya farkliysa)
      UPDATE public.profiles SET family_id = v_family_id, updated_at = now() WHERE id = v_parent_id AND (family_id IS NULL OR family_id != v_family_id);
      RAISE NOTICE 'Ebeveyn profili guncellendi.';
    END IF;
    
    -- family_members tablosunda var mi kontrol et, yoksa ekle
    IF NOT EXISTS (SELECT 1 FROM public.family_members WHERE user_id = v_parent_id AND family_id = v_family_id) THEN
      INSERT INTO public.family_members (family_id, user_id, role, display_name, joined_at)
      VALUES (v_family_id, v_parent_id, 'parent', 'Hilal', now());
      RAISE NOTICE 'Ebeveyn aileye eklendi (rol: parent).';
    ELSE
      RAISE NOTICE 'Ebeveyn zaten ailede.';
    END IF;
  END IF;
END $$;

-- 3b. Cocuk ekleme (child_accounts)
DO $$
DECLARE
  v_family_id uuid := '3816dedb-c232-493a-b8f5-eccf326f0d3c';
  v_creator_id uuid;
  v_child_id uuid;
BEGIN
  -- Aileyi olusturan kullaniciyi bul (created_by)
  SELECT created_by INTO v_creator_id FROM public.families WHERE id = v_family_id LIMIT 1;
  IF v_creator_id IS NULL THEN
    -- Fallback: ilk admin/parent'i bul
    SELECT user_id INTO v_creator_id FROM public.family_members WHERE family_id = v_family_id AND role IN ('admin','parent') LIMIT 1;
  END IF;
  
  -- Mevcut Mirac kaydi var mi kontrol et
  SELECT id INTO v_child_id FROM public.child_accounts WHERE family_id = v_family_id AND name = 'Mirac' LIMIT 1;
  
  IF v_child_id IS NULL THEN
    INSERT INTO public.child_accounts (
      family_id, name, age, pin_hash, role, color, 
      created_by, is_active, daily_screen_time_minutes, 
      can_approve_tasks, can_send_messages, can_view_budget
    ) VALUES (
      v_family_id, 'Mirac', 6, '2704', 'child', '#3B82F6',
      v_creator_id, true, 120,
      false, true, false
    );
    RAISE NOTICE 'Cocuk (Mirac) eklendi.';
  ELSE
    UPDATE public.child_accounts SET 
      age = 6, pin_hash = '2704', role = 'child', 
      is_active = true, updated_at = now()
    WHERE id = v_child_id;
    RAISE NOTICE 'Cocuk (Mirac) guncellendi.';
  END IF;
END $$;

-- =============================================================================
-- PHASE 4: FORCE POLICY RELOAD
-- =============================================================================
NOTIFY pgrst, 'reload schema';

-- ============================================
-- TAMAMLANDI
-- 1. RLS politikalari duzeltildi
-- 2. Ebeveyn (hilalsahbaz2018@gmail.com) aileye eklendi
-- 3. Cocuk (Mirac, 6 yas) eklendi/guncellendi
-- Uygulamayi kapatip acin.
-- ============================================
