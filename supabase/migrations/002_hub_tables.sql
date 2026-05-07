-- ============================================
-- HUB TABLES (Extension to 001_complete_schema)
-- ============================================

-- ============================================
-- HUB WIDGET STATE (User widget preferences)
-- ============================================
create table if not exists public.hub_widgets (
  id uuid default gen_random_uuid() primary key,
  user_id uuid references public.profiles(id) on delete cascade,
  family_id uuid references public.families(id) on delete cascade,
  widget_type text not null check (widget_type in (
    'today_summary', 'upcoming_events', 'my_tasks',
    'family_mood', 'weather', 'quick_actions'
  )),
  is_visible boolean default true,
  sort_order int default 0,
  config jsonb default '{}',
  updated_at timestamptz default now(),
  unique(user_id, family_id, widget_type)
);

-- ============================================
-- FAMILY MOOD (Mood sharing)
-- ============================================
create table if not exists public.family_moods (
  id uuid default gen_random_uuid() primary key,
  family_id uuid references public.families(id) on delete cascade,
  user_id uuid references public.profiles(id) on delete cascade,
  mood_emoji text not null,
  mood_note text,
  energy_level int check (energy_level between 1 and 10),
  is_shared boolean default true,
  created_at timestamptz default now()
);

-- ============================================
-- WEATHER CACHE
-- ============================================
create table if not exists public.weather_cache (
  id uuid default gen_random_uuid() primary key,
  family_id uuid references public.families(id) on delete cascade,
  location_lat numeric,
  location_lng numeric,
  location_name text,
  current_temp numeric,
  condition text,
  icon_code text,
  humidity int,
  wind_speed numeric,
  forecast jsonb,
  cached_at timestamptz default now(),
  expires_at timestamptz default (now() + interval '1 hour'),
  unique(family_id, location_lat, location_lng)
);

-- ============================================
-- RLS POLICIES FOR HUB TABLES
-- ============================================

alter table if exists public.hub_widgets enable row level security;
alter table if exists public.family_moods enable row level security;
alter table if exists public.weather_cache enable row level security;

drop policy if exists "Hub widgets own" on public.hub_widgets;
create policy "Hub widgets own"
  on public.hub_widgets for all
  using (user_id = auth.uid());

drop policy if exists "Family moods view" on public.family_moods;
create policy "Family moods view"
  on public.family_moods for select
  using (family_id in (
    select family_id from public.family_members where user_id = auth.uid()
  ));

drop policy if exists "Family moods insert" on public.family_moods;
create policy "Family moods insert"
  on public.family_moods for insert
  with check (user_id = auth.uid());

drop policy if exists "Weather cache family" on public.weather_cache;
create policy "Weather cache family"
  on public.weather_cache for select
  using (family_id in (
    select family_id from public.family_members where user_id = auth.uid()
  ));

-- ============================================
-- REALTIME
-- ============================================

do $$
begin
  if not exists (
    select 1 from pg_publication_tables
    where pubname = 'supabase_realtime' and tablename = 'family_moods'
  ) then
    alter publication supabase_realtime add table public.family_moods;
  end if;
end $$;

-- ============================================
-- INDEXES
-- ============================================

create index if not exists idx_family_moods_family on public.family_moods(family_id, created_at desc);
create index if not exists idx_weather_cache_family on public.weather_cache(family_id);
