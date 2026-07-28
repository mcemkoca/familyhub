-- Migration: 011_crash_detection.sql
-- Crash Detection System tables

-- ─────────────────────────────────────────────
-- CRASH EVENTS
-- ─────────────────────────────────────────────
create table if not exists crash_events (
    id uuid primary key default gen_random_uuid(),
    family_id uuid references families(id) on delete cascade,
    member_id uuid references public.profiles(id) on delete cascade,
    member_name text,

    -- Detection info
    detection_timestamp timestamptz not null default now(),
    detection_confidence decimal(3,2) not null default 0,
    trigger_type text not null default 'high_impact',

    -- Sensor data (JSONB for flexibility)
    sensor_data jsonb not null default '{}',

    -- Context
    context jsonb not null default '{}',

    -- Response
    response_status text not null default 'detected',
    confirmation_window jsonb,
    sos_triggered jsonb,
    notifications_sent jsonb default '[]',

    -- Outcome
    outcome jsonb,

    -- ML features
    ml_features jsonb,

    -- Meta
    created_at timestamptz not null default now(),
    resolved_at timestamptz,
    reviewed_by uuid references public.profiles(id),
    is_false_positive boolean not null default false,

    -- Indexes
    constraint valid_confidence check (detection_confidence between 0 and 1)
);

-- Indexes for crash_events
create index if not exists idx_crash_events_family on crash_events(family_id);
create index if not exists idx_crash_events_member on crash_events(member_id);
create index if not exists idx_crash_events_created on crash_events(created_at desc);
create index if not exists idx_crash_events_status on crash_events(response_status);
create index if not exists idx_crash_events_false_positive on crash_events(is_false_positive);

-- ─────────────────────────────────────────────
-- CRASH DETECTION SETTINGS
-- ─────────────────────────────────────────────
create table if not exists crash_detection_settings (
    id uuid primary key default gen_random_uuid(),
    member_id uuid references public.profiles(id) on delete cascade unique,

    enabled boolean not null default true,
    sensitivity text not null default 'medium',

    custom_thresholds jsonb not null default '{
        "minImpactG": 4.0,
        "minSpeedChange": 8.0,
        "rolloverThreshold": 5.0,
        "confirmationWindowSeconds": 30
    }',

    sos_config jsonb not null default '{
        "autoCallEmergency": false,
        "autoNotifyFamily": true,
        "autoNotifyContacts": true,
        "shareLocation": true,
        "shareMedicalInfo": true
    }',

    emergency_contacts jsonb default '[]',

    notifications jsonb not null default '{
        "soundAlert": true,
        "soundType": "crash_alarm",
        "vibration": true,
        "vibrationPattern": "sos",
        "screenFlash": true,
        "maxVolume": true,
        "bypassDnd": false
    }',

    test_mode jsonb not null default '{
        "enabled": false
    }',

    updated_at timestamptz not null default now()
);

-- ─────────────────────────────────────────────
-- SENSOR LOGS (short-lived, TTL-like cleanup)
-- ─────────────────────────────────────────────
create table if not exists sensor_logs (
    id uuid primary key default gen_random_uuid(),
    member_id uuid references public.profiles(id) on delete cascade,
    timestamp timestamptz not null default now(),

    accelerometer jsonb,
    gyroscope jsonb,
    gps jsonb,

    -- Auto-cleanup: recommend running a cron job to delete older than 24h
    created_at timestamptz not null default now()
);

create index if not exists idx_sensor_logs_member on sensor_logs(member_id);
create index if not exists idx_sensor_logs_timestamp on sensor_logs(timestamp desc);

-- ─────────────────────────────────────────────
-- RLS POLICIES
-- ─────────────────────────────────────────────

-- Crash events: family members can view their own family's events
alter table if exists crash_events enable row level security;

drop policy if exists crash_events_select_family on crash_events;
create policy crash_events_select_family
    on crash_events
    for select
    using (
        family_id in (
            select family_id from family_members
            where auth.uid() = user_id
        )
    );

drop policy if exists crash_events_insert_own on crash_events;
create policy crash_events_insert_own
    on crash_events
    for insert
    with check (
        member_id in (
            select id from family_members
            where auth.uid() = user_id
        )
    );

drop policy if exists crash_events_update_own on crash_events;
create policy crash_events_update_own
    on crash_events
    for update
    using (
        member_id in (
            select id from family_members
            where auth.uid() = user_id
        )
    );

-- Settings: members can only manage their own settings
alter table if exists crash_detection_settings enable row level security;

drop policy if exists crash_settings_select_own on crash_detection_settings;
create policy crash_settings_select_own
    on crash_detection_settings
    for select
    using (
        member_id in (
            select id from family_members
            where auth.uid() = user_id
        )
    );

drop policy if exists crash_settings_insert_own on crash_detection_settings;
create policy crash_settings_insert_own
    on crash_detection_settings
    for insert
    with check (
        member_id in (
            select id from family_members
            where auth.uid() = user_id
        )
    );

drop policy if exists crash_settings_update_own on crash_detection_settings;
create policy crash_settings_update_own
    on crash_detection_settings
    for update
    using (
        member_id in (
            select id from family_members
            where auth.uid() = user_id
        )
    );

-- Sensor logs: members can only see their own
alter table if exists sensor_logs enable row level security;

drop policy if exists sensor_logs_select_own on sensor_logs;
create policy sensor_logs_select_own
    on sensor_logs
    for select
    using (
        member_id in (
            select id from family_members
            where auth.uid() = user_id
        )
    );

drop policy if exists sensor_logs_insert_own on sensor_logs;
create policy sensor_logs_insert_own
    on sensor_logs
    for insert
    with check (
        member_id in (
            select id from family_members
            where auth.uid() = user_id
        )
    );

-- ─────────────────────────────────────────────
-- FUNCTIONS
-- ─────────────────────────────────────────────

-- Auto-update updated_at
create or replace function update_crash_settings_timestamp()
returns trigger as $$
begin
    new.updated_at = now();
    return new;
end;
$$ language plpgsql;

drop trigger if exists tr_crash_settings_updated on crash_detection_settings;
create trigger tr_crash_settings_updated
    before update on crash_detection_settings
    for each row
    execute function update_crash_settings_timestamp();

-- Get crash summary for a family
CREATE OR REPLACE FUNCTION get_family_crash_summary(p_family_id uuid)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    result jsonb;
BEGIN
    SELECT jsonb_build_object(
        'totalEvents', count(*),
        'falseAlarms', count(*) filter (where is_false_positive = true),
        'realCrashes', count(*) filter (where is_false_positive = false and response_status = 'auto_sos'),
        'last30Days', count(*) filter (where created_at > now() - interval '30 days'),
        'avgConfidence', coalesce(avg(detection_confidence), 0)::numeric(3,2)
    )
    INTO result
    FROM crash_events
    WHERE family_id = p_family_id;

    RETURN result;
END;
$$;
