-- ============================================
-- HUB ENHANCEMENTS (AI Suggestions + Realtime + Widget Types)
-- ============================================

-- ============================================
-- AI SUGGESTIONS CACHE
-- ============================================
create table if not exists public.ai_suggestions_cache (
  id uuid default gen_random_uuid() primary key,
  family_id uuid references public.families(id) on delete cascade,
  suggestions jsonb not null,
  context_hash text,
  generated_at timestamptz default now(),
  expires_at timestamptz default (now() + interval '30 minutes')
);

-- ============================================
-- RLS FOR AI SUGGESTIONS
-- ============================================

alter table if exists public.ai_suggestions_cache enable row level security;

drop policy if exists "AI suggestions family view" on public.ai_suggestions_cache;
create policy "AI suggestions family view"
  on public.ai_suggestions_cache for select
  using (family_id in (
    select family_id from public.family_members where user_id = auth.uid()
  ));

-- ============================================
-- HUB WIDGETS: Expand widget_type constraint
-- Drop old check constraint and recreate with expanded list
-- ============================================

alter table public.hub_widgets drop constraint if exists hub_widgets_widget_type_check;

alter table public.hub_widgets add constraint hub_widgets_widget_type_check
  check (widget_type in (
    'today_summary', 'upcoming_events', 'my_tasks',
    'family_mood', 'weather', 'quick_actions',
    'ai_suggestions', 'smart_home', 'health_summary'
  ));

-- ============================================
-- REALTIME: Enable for events and tasks
-- ============================================

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

-- ============================================
-- INDEXES
-- ============================================

create index if not exists idx_ai_suggestions_family on public.ai_suggestions_cache(family_id, expires_at desc);
create index if not exists idx_hub_widgets_user on public.hub_widgets(user_id, family_id);
