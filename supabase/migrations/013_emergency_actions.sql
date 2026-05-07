-- Migration: 013_emergency_actions.sql
-- Emergency auto-actions system tables

-- ─────────────────────────────────────────────
-- EMERGENCY ACTIONS
-- ─────────────────────────────────────────────
create table if not exists emergency_actions (
    id uuid primary key default gen_random_uuid(),
    family_id uuid references families(id) on delete cascade,
    triggered_by uuid references family_members(id) on delete set null,

    trigger_type text not null default 'manual_sos',
    trigger_timestamp timestamptz not null default now(),
    trigger_latitude decimal(10,8),
    trigger_longitude decimal(11,8),
    trigger_confidence decimal(3,2) default 1.0,

    severity text not null default 'high',
    category text not null default 'other',
    description text,
    is_confirmed boolean not null default false,
    confirmation_method text,

    auto_actions jsonb not null default '{}',
    escalation_chain jsonb not null default '{"steps": []}',

    status_state text not null default 'triggered',
    current_step int not null default 0,
    started_at timestamptz not null default now(),
    last_action_at timestamptz,
    resolved_at timestamptz,
    resolved_by uuid references family_members(id),

    response_log jsonb default '[]',

    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now()
);

create index if not exists idx_emergency_actions_family on emergency_actions(family_id);
create index if not exists idx_emergency_actions_status on emergency_actions(status_state);
create index if not exists idx_emergency_actions_created on emergency_actions(created_at desc);

-- ─────────────────────────────────────────────
-- EMERGENCY TEMPLATES
-- ─────────────────────────────────────────────
create table if not exists emergency_templates (
    id uuid primary key default gen_random_uuid(),
    template_id text unique not null,
    name text not null,
    language text not null default 'tr',

    content jsonb not null default '{}',
    variables jsonb default '[]',

    usage_count int not null default 0,
    average_response_time decimal(6,2),

    created_at timestamptz not null default now()
);

-- Insert default template
insert into emergency_templates (template_id, name, language, content, variables)
values (
    'default',
    'Varsayılan Acil Durum',
    'tr',
    '{
        "sms": "🆘 ACİL: {name} yardım istiyor! Konum: {location} Saat: {time}",
        "push": "Yardım çağrısı! Konum: {location}",
        "pushTitle": "🆘 {name} - ACİL DURUM",
        "voice": "Bu otomatik bir acil durum çağrısıdır. {name} yardım istiyor.",
        "email": "Acil durum yardım çağrısı. {name} konum: {location}"
    }',
    '[
        {"name": "name", "source": "user_profile", "required": true},
        {"name": "location", "source": "location", "required": true},
        {"name": "time", "source": "time", "required": true}
    ]'
)
on conflict (template_id) do nothing;

-- ─────────────────────────────────────────────
-- EMERGENCY CONTACTS
-- ─────────────────────────────────────────────
create table if not exists emergency_contacts (
    id uuid primary key default gen_random_uuid(),
    contact_id text unique not null,
    family_id uuid references families(id) on delete cascade,

    name text not null,
    phone text not null,
    email text,
    relation text,
    priority int not null default 1,

    availability jsonb default '{}',
    capabilities jsonb default '{}',
    roles jsonb default '[]',

    is_active boolean not null default true,
    verified_at timestamptz
);

create index if not exists idx_emergency_contacts_family on emergency_contacts(family_id);

-- ─────────────────────────────────────────────
-- ESCALATION POLICIES
-- ─────────────────────────────────────────────
create table if not exists escalation_policies (
    id uuid primary key default gen_random_uuid(),
    policy_id text unique not null,
    family_id uuid references families(id) on delete cascade,

    name text not null,
    triggers jsonb default '[]',
    steps jsonb not null default '[]',
    conditions jsonb default '{}',

    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now()
);

-- ─────────────────────────────────────────────
-- RLS POLICIES
-- ─────────────────────────────────────────────

alter table if exists emergency_actions enable row level security;

drop policy if exists emergency_actions_select_family on emergency_actions;
create policy emergency_actions_select_family
    on emergency_actions for select
    using (family_id in (select family_id from family_members where auth.uid() = user_id));

drop policy if exists emergency_actions_insert_own on emergency_actions;
create policy emergency_actions_insert_own
    on emergency_actions for insert
    with check (triggered_by in (select id from family_members where auth.uid() = user_id));

drop policy if exists emergency_actions_update_family on emergency_actions;
create policy emergency_actions_update_family
    on emergency_actions for update
    using (family_id in (select family_id from family_members where auth.uid() = user_id));

alter table if exists emergency_templates enable row level security;

drop policy if exists emergency_templates_select_all on emergency_templates;
create policy emergency_templates_select_all
    on emergency_templates for select
    using (true);

alter table if exists emergency_contacts enable row level security;

drop policy if exists emergency_contacts_select_family on emergency_contacts;
create policy emergency_contacts_select_family
    on emergency_contacts for select
    using (family_id in (select family_id from family_members where auth.uid() = user_id));

drop policy if exists emergency_contacts_insert_family on emergency_contacts;
create policy emergency_contacts_insert_family
    on emergency_contacts for insert
    with check (family_id in (select family_id from family_members where auth.uid() = user_id));

drop policy if exists emergency_contacts_update_family on emergency_contacts;
create policy emergency_contacts_update_family
    on emergency_contacts for update
    using (family_id in (select family_id from family_members where auth.uid() = user_id));

alter table if exists escalation_policies enable row level security;

drop policy if exists escalation_policies_select_family on escalation_policies;
create policy escalation_policies_select_family
    on escalation_policies for select
    using (family_id in (select family_id from family_members where auth.uid() = user_id));

drop policy if exists escalation_policies_insert_family on escalation_policies;
create policy escalation_policies_insert_family
    on escalation_policies for insert
    with check (family_id in (select family_id from family_members where auth.uid() = user_id));

-- ─────────────────────────────────────────────
-- FUNCTIONS
-- ─────────────────────────────────────────────

-- Get active emergency count for a family
CREATE OR REPLACE FUNCTION get_family_active_emergencies(p_family_id uuid)
RETURNS int
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    count int;
BEGIN
    SELECT count(*) INTO count
    FROM emergency_actions
    WHERE family_id = p_family_id
      AND status_state in ('triggered', 'active', 'escalating');

    RETURN count;
END;
$$;
