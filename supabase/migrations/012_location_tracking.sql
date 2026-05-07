-- Migration: 012_location_tracking.sql
-- Battery-aware location tracking system tables

-- ─────────────────────────────────────────────
-- LOCATION TRACKING SETTINGS
-- ─────────────────────────────────────────────
create table if not exists location_tracking_settings (
    id uuid primary key default gen_random_uuid(),
    member_id uuid references family_members(id) on delete cascade unique,
    family_id uuid references families(id) on delete cascade,

    enabled boolean not null default true,
    priority text not null default 'balanced',

    battery_thresholds jsonb not null default '{
        "critical": 10,
        "low": 20,
        "medium": 50,
        "high": 80,
        "full": 100
    }',

    motion_profiles jsonb not null default '{
        "stationary": {"updateInterval": 300, "accuracy": "low", "providers": ["wifi", "cellular"], "useGeofence": true, "geofenceRadius": 100},
        "walking": {"updateInterval": 60, "accuracy": "medium", "providers": ["wifi", "cellular", "gps"]},
        "running": {"updateInterval": 30, "accuracy": "medium", "providers": ["gps", "cellular"]},
        "cycling": {"updateInterval": 15, "accuracy": "high", "providers": ["gps"]},
        "driving": {"updateInterval": 10, "accuracy": "high", "providers": ["gps"]},
        "highSpeed": {"updateInterval": 5, "accuracy": "best", "providers": ["gps"]},
        "emergency": {"updateInterval": 3, "accuracy": "best", "providers": ["gps", "wifi", "cellular"], "maxAccuracyMode": true}
    }',

    transition_rules jsonb default '[]',

    power_optimization jsonb not null default '{
        "adaptiveBrightness": true,
        "backgroundRefresh": true,
        "networkBatching": true,
        "locationCache": true,
        "motionCoProcessor": true
    }',

    time_rules jsonb default '[]',
    location_rules jsonb default '[]',

    notify_profile_changes boolean not null default false,
    updated_at timestamptz not null default now()
);

-- ─────────────────────────────────────────────
-- LOCATION HISTORY (BATCHED)
-- ─────────────────────────────────────────────
create table if not exists location_history (
    id uuid primary key default gen_random_uuid(),
    batch_id text not null,
    member_id uuid references family_members(id) on delete cascade,
    family_id uuid references families(id) on delete cascade,

    recorded_at timestamptz not null,
    uploaded_at timestamptz not null default now(),
    batch_size int not null default 0,
    battery_at_start int,
    power_profile text not null default 'balanced',

    locations jsonb not null default '[]',
    segment jsonb,

    created_at timestamptz not null default now()
);

create index if not exists idx_location_history_member on location_history(member_id);
create index if not exists idx_location_history_family on location_history(family_id);
create index if not exists idx_location_history_recorded on location_history(recorded_at desc);
create index if not exists idx_location_history_batch on location_history(batch_id);

-- ─────────────────────────────────────────────
-- BATTERY LOGS
-- ─────────────────────────────────────────────
create table if not exists battery_logs (
    id uuid primary key default gen_random_uuid(),
    member_id uuid references family_members(id) on delete cascade,

    timestamp timestamptz not null default now(),
    battery_level int not null,
    temperature decimal(4,1),
    voltage decimal(5,3),
    health text,
    is_charging boolean not null default false,
    charge_type text,

    tracking_profile text not null default 'balanced',
    update_interval int not null default 60,
    accuracy text not null default 'medium',
    provider text not null default 'gps',
    locations_recorded int not null default 0,
    estimated_drain decimal(5,2),

    created_at timestamptz not null default now()
);

create index if not exists idx_battery_logs_member on battery_logs(member_id);
create index if not exists idx_battery_logs_timestamp on battery_logs(timestamp desc);

-- ─────────────────────────────────────────────
-- TRACKING ANALYTICS (DAILY AGGREGATE)
-- ─────────────────────────────────────────────
create table if not exists tracking_analytics (
    id uuid primary key default gen_random_uuid(),
    member_id uuid references family_members(id) on delete cascade,
    date date not null,

    total_locations int not null default 0,
    total_distance decimal(10,2) not null default 0,
    active_time_minutes int not null default 0,
    stationary_time_minutes int not null default 0,
    battery_used decimal(5,2) not null default 0,

    profile_usage jsonb not null default '{}',
    locations_per_battery_percent decimal(5,2),
    accuracy_achieved decimal(5,2),
    optimal_profile_percentage decimal(5,2),

    ai_recommendations jsonb default '[]',

    created_at timestamptz not null default now(),

    unique(member_id, date)
);

create index if not exists idx_tracking_analytics_member on tracking_analytics(member_id);
create index if not exists idx_tracking_analytics_date on tracking_analytics(date desc);

-- ─────────────────────────────────────────────
-- RLS POLICIES
-- ─────────────────────────────────────────────

alter table if exists location_tracking_settings enable row level security;

drop policy if exists location_tracking_settings_select_own on location_tracking_settings;
create policy location_tracking_settings_select_own
    on location_tracking_settings for select
    using (member_id in (select id from family_members where auth.uid() = user_id));

drop policy if exists location_tracking_settings_insert_own on location_tracking_settings;
create policy location_tracking_settings_insert_own
    on location_tracking_settings for insert
    with check (member_id in (select id from family_members where auth.uid() = user_id));

drop policy if exists location_tracking_settings_update_own on location_tracking_settings;
create policy location_tracking_settings_update_own
    on location_tracking_settings for update
    using (member_id in (select id from family_members where auth.uid() = user_id));

alter table if exists location_history enable row level security;

drop policy if exists location_history_select_family on location_history;
create policy location_history_select_family
    on location_history for select
    using (family_id in (select family_id from family_members where auth.uid() = user_id));

drop policy if exists location_history_insert_own on location_history;
create policy location_history_insert_own
    on location_history for insert
    with check (member_id in (select id from family_members where auth.uid() = user_id));

alter table if exists battery_logs enable row level security;

drop policy if exists battery_logs_select_own on battery_logs;
create policy battery_logs_select_own
    on battery_logs for select
    using (member_id in (select id from family_members where auth.uid() = user_id));

drop policy if exists battery_logs_insert_own on battery_logs;
create policy battery_logs_insert_own
    on battery_logs for insert
    with check (member_id in (select id from family_members where auth.uid() = user_id));

alter table if exists tracking_analytics enable row level security;

drop policy if exists tracking_analytics_select_family on tracking_analytics;
create policy tracking_analytics_select_family
    on tracking_analytics for select
    using (member_id in (select id from family_members where auth.uid() = user_id));

drop policy if exists tracking_analytics_insert_own on tracking_analytics;
create policy tracking_analytics_insert_own
    on tracking_analytics for insert
    with check (member_id in (select id from family_members where auth.uid() = user_id));

-- ─────────────────────────────────────────────
-- FUNCTIONS
-- ─────────────────────────────────────────────

-- Auto-update timestamp
create or replace function update_location_tracking_timestamp()
returns trigger as $$
begin
    new.updated_at = now();
    return new;
end;
$$ language plpgsql;

drop trigger if exists tr_location_tracking_updated on location_tracking_settings;
create trigger tr_location_tracking_updated
    before update on location_tracking_settings
    for each row
    execute function update_location_tracking_timestamp();

-- Get daily tracking summary for a member
CREATE OR REPLACE FUNCTION get_member_tracking_summary(p_member_id uuid, p_days int default 7)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    result jsonb;
BEGIN
    SELECT jsonb_build_object(
        'totalLocations', coalesce(sum(total_locations), 0),
        'totalDistance', coalesce(sum(total_distance), 0)::numeric(10,2),
        'avgBatteryUsed', coalesce(avg(battery_used), 0)::numeric(5,2),
        'avgAccuracy', coalesce(avg(accuracy_achieved), 0)::numeric(5,2),
        'optimalProfileRate', coalesce(avg(optimal_profile_percentage), 0)::numeric(5,2)
    )
    INTO result
    FROM tracking_analytics
    WHERE member_id = p_member_id
      AND date >= current_date - (p_days || ' days')::interval;

    RETURN result;
END;
$$;
