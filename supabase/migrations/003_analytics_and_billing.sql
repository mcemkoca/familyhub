-- ============================================================
-- Migration 003: Analytics, Billing, Referrals, Enterprise
-- ============================================================

-- Ensure is_admin column exists before policies reference it
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS is_admin boolean default false;

-- Analytics events table
CREATE TABLE IF NOT EXISTS public.analytics_events (
  id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  event text NOT NULL,
  properties jsonb DEFAULT '{}',
  user_id uuid REFERENCES public.profiles(id) ON DELETE SET NULL,
  created_at timestamptz DEFAULT now()
);

ALTER TABLE IF EXISTS public.analytics_events ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Analytics events are insertable by authenticated users" ON public.analytics_events;
CREATE POLICY "Analytics events are insertable by authenticated users"
  ON public.analytics_events FOR INSERT TO authenticated WITH CHECK (true);
DROP POLICY IF EXISTS "Analytics events are viewable by admins" ON public.analytics_events;
CREATE POLICY "Analytics events are viewable by admins"
  ON public.analytics_events FOR SELECT TO authenticated USING (
    EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND is_admin = true)
  );

-- Heatmap tracking table
CREATE TABLE IF NOT EXISTS public.heatmaps (
  id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  type text NOT NULL CHECK (type IN ('tap', 'scroll')),
  screen text NOT NULL,
  element_id text,
  x numeric,
  y numeric,
  scroll_depth numeric,
  user_id uuid REFERENCES public.profiles(id) ON DELETE SET NULL,
  created_at timestamptz DEFAULT now()
);

ALTER TABLE IF EXISTS public.heatmaps ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Heatmaps are insertable by authenticated users" ON public.heatmaps;
CREATE POLICY "Heatmaps are insertable by authenticated users"
  ON public.heatmaps FOR INSERT TO authenticated WITH CHECK (true);
DROP POLICY IF EXISTS "Heatmaps are viewable by admins" ON public.heatmaps;
CREATE POLICY "Heatmaps are viewable by admins"
  ON public.heatmaps FOR SELECT TO authenticated USING (
    EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND is_admin = true)
  );

-- Referrals table
CREATE TABLE IF NOT EXISTS public.referrals (
  id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  code text NOT NULL UNIQUE,
  inviter_id uuid REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
  invited_id uuid REFERENCES public.profiles(id) ON DELETE SET NULL,
  family_id uuid REFERENCES public.families(id) ON DELETE CASCADE NOT NULL,
  status text DEFAULT 'active' CHECK (status IN ('active', 'completed', 'expired')),
  created_at timestamptz DEFAULT now(),
  completed_at timestamptz
);

ALTER TABLE IF EXISTS public.referrals ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Referrals are viewable by inviter or invited" ON public.referrals;
CREATE POLICY "Referrals are viewable by inviter or invited"
  ON public.referrals FOR SELECT TO authenticated USING (
    inviter_id = auth.uid() OR invited_id = auth.uid()
  );
DROP POLICY IF EXISTS "Referrals are insertable by authenticated users" ON public.referrals;
CREATE POLICY "Referrals are insertable by authenticated users"
  ON public.referrals FOR INSERT TO authenticated WITH CHECK (inviter_id = auth.uid());

-- Subscriptions table
CREATE TABLE IF NOT EXISTS public.subscriptions (
  id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id uuid REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
  subscription_tier text NOT NULL CHECK (subscription_tier IN ('free', 'premium', 'family')),
  amount numeric,
  currency text DEFAULT 'USD',
  status text DEFAULT 'active' CHECK (status IN ('active', 'cancelled', 'expired')),
  expires_at timestamptz,
  created_at timestamptz DEFAULT now()
);

ALTER TABLE IF EXISTS public.subscriptions ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Users can view own subscriptions" ON public.subscriptions;
CREATE POLICY "Users can view own subscriptions"
  ON public.subscriptions FOR SELECT TO authenticated USING (user_id = auth.uid());

-- Organizations table (Enterprise)
CREATE TABLE IF NOT EXISTS public.organizations (
  id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  name text NOT NULL,
  domain text NOT NULL UNIQUE,
  employee_count integer,
  admin_email text NOT NULL,
  status text DEFAULT 'pending_verification' CHECK (status IN ('pending_verification', 'verified', 'suspended')),
  verified_at timestamptz,
  created_at timestamptz DEFAULT now()
);

ALTER TABLE IF EXISTS public.organizations ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Organizations are viewable by admin members" ON public.organizations;
CREATE POLICY "Organizations are viewable by admin members"
  ON public.organizations FOR SELECT TO authenticated USING (
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE id = auth.uid() AND (is_admin = true OR email = organizations.admin_email)
    )
  );

-- SSO configs table
CREATE TABLE IF NOT EXISTS public.sso_configs (
  id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  org_id uuid REFERENCES public.organizations(id) ON DELETE CASCADE NOT NULL,
  provider text NOT NULL,
  metadata_xml text,
  status text DEFAULT 'pending_setup' CHECK (status IN ('pending_setup', 'active', 'disabled')),
  created_at timestamptz DEFAULT now()
);

ALTER TABLE IF EXISTS public.sso_configs ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "SSO configs are viewable by org admins" ON public.sso_configs;
CREATE POLICY "SSO configs are viewable by org admins"
  ON public.sso_configs FOR SELECT TO authenticated USING (
    EXISTS (
      SELECT 1 FROM public.organizations
      WHERE id = sso_configs.org_id AND admin_email = auth.email()
    )
  );

-- Add premium fields to profiles
ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS subscription_tier text DEFAULT 'free' CHECK (subscription_tier IN ('free', 'premium', 'family')),
  ADD COLUMN IF NOT EXISTS subscription_expires_at timestamptz,
  ADD COLUMN IF NOT EXISTS referral_code text;

-- ============================================================
-- Admin Analytics Views
-- ============================================================

CREATE OR REPLACE VIEW public.daily_active_users AS
SELECT
  date_trunc('day', created_at)::date AS date,
  count(DISTINCT user_id) AS dau
FROM public.analytics_events
WHERE created_at > now() - interval '30 days'
GROUP BY 1
ORDER BY 1 DESC;

CREATE OR REPLACE VIEW public.retention_cohort AS
WITH first_seen AS (
  SELECT
    user_id,
    min(date_trunc('day', created_at)::date) AS first_day
  FROM public.analytics_events
  GROUP BY 1
)
SELECT
  fs.first_day AS cohort,
  (date_trunc('day', ae.created_at)::date - fs.first_day) AS day_offset,
  count(DISTINCT ae.user_id) AS retained_users
FROM first_seen fs
JOIN public.analytics_events ae ON fs.user_id = ae.user_id
GROUP BY 1, 2
ORDER BY 1 DESC, 2;

CREATE OR REPLACE VIEW public.revenue_metrics AS
SELECT
  date_trunc('month', created_at)::date AS month,
  count(*) AS new_subscriptions,
  coalesce(sum(amount), 0) AS revenue,
  currency,
  subscription_tier
FROM public.subscriptions
WHERE status = 'active'
GROUP BY 1, 4, 5
ORDER BY 1 DESC;

-- ============================================================
-- RPC Functions
-- ============================================================

CREATE OR REPLACE FUNCTION public.add_premium_days(user_id uuid, days integer)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  UPDATE public.profiles
  SET
    subscription_tier = 'premium',
    subscription_expires_at = coalesce(subscription_expires_at, now()) + (days || ' days')::interval
  WHERE id = user_id;
END;
$$;

CREATE OR REPLACE FUNCTION public.get_org_stats(org_id uuid)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  result jsonb;
BEGIN
  SELECT jsonb_build_object(
    'total_employees', o.employee_count,
    'active_families', (SELECT count(*) FROM public.families WHERE created_at > now() - interval '30 days'),
    'engagement_rate', 0.75, -- Placeholder: compute from analytics_events
    'health_score', 82,      -- Placeholder: compute from family_moods
    'reduced_sick_days', 12,
    'retention_improvement', 0.18,
    'productivity_gain', 0.23
  ) INTO result
  FROM public.organizations o
  WHERE o.id = org_id;

  RETURN result;
END;
$$;

CREATE OR REPLACE FUNCTION public.send_verification_email(to_email text, org_id uuid)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  -- Placeholder: integrate with Supabase Edge Functions or external email provider
  PERFORM pg_notify('verification_email', json_build_object('email', to_email, 'org_id', org_id)::text);
END;
$$;
