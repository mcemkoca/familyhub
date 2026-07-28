-- ============================================================
-- Migration 055: subscriptions table + document_reminders
-- ============================================================

-- ── Subscriptions ────────────────────────────────────────────
-- Tracks Stripe subscription state per family.

CREATE TABLE IF NOT EXISTS public.subscriptions (
  id               UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  family_id        UUID NOT NULL REFERENCES public.families(id) ON DELETE CASCADE,
  user_id          UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  stripe_customer_id    TEXT,
  stripe_subscription_id TEXT,
  stripe_price_id  TEXT,
  plan             TEXT NOT NULL DEFAULT 'free'
                     CHECK (plan IN ('free','premium_monthly','premium_yearly','family_pack')),
  status           TEXT NOT NULL DEFAULT 'inactive'
                     CHECK (status IN ('active','inactive','past_due','cancelled','trialing')),
  current_period_start TIMESTAMPTZ,
  current_period_end   TIMESTAMPTZ,
  cancel_at_period_end BOOLEAN DEFAULT FALSE,
  created_at       TIMESTAMPTZ DEFAULT NOW(),
  updated_at       TIMESTAMPTZ DEFAULT NOW()
);

-- 003_analytics_and_billing.sql daha once subscriptions'i family_id olmadan
-- olusturmus olabilir. Eksik kolonlari garanti et:
ALTER TABLE public.subscriptions ADD COLUMN IF NOT EXISTS family_id             UUID REFERENCES public.families(id) ON DELETE CASCADE;
ALTER TABLE public.subscriptions ADD COLUMN IF NOT EXISTS user_id               UUID REFERENCES public.profiles(id) ON DELETE CASCADE;
ALTER TABLE public.subscriptions ADD COLUMN IF NOT EXISTS stripe_customer_id     TEXT;
ALTER TABLE public.subscriptions ADD COLUMN IF NOT EXISTS stripe_subscription_id TEXT;
ALTER TABLE public.subscriptions ADD COLUMN IF NOT EXISTS stripe_price_id        TEXT;
ALTER TABLE public.subscriptions ADD COLUMN IF NOT EXISTS plan                   TEXT DEFAULT 'free';
ALTER TABLE public.subscriptions ADD COLUMN IF NOT EXISTS current_period_start   TIMESTAMPTZ;
ALTER TABLE public.subscriptions ADD COLUMN IF NOT EXISTS current_period_end     TIMESTAMPTZ;
ALTER TABLE public.subscriptions ADD COLUMN IF NOT EXISTS cancel_at_period_end   BOOLEAN DEFAULT FALSE;
ALTER TABLE public.subscriptions ADD COLUMN IF NOT EXISTS updated_at             TIMESTAMPTZ DEFAULT NOW();

ALTER TABLE public.subscriptions ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Subscriptions select" ON public.subscriptions;
DROP POLICY IF EXISTS "Subscriptions insert" ON public.subscriptions;
DROP POLICY IF EXISTS "Subscriptions update" ON public.subscriptions;

-- Only the family owner and admins can view subscriptions
CREATE POLICY "Subscriptions select"
  ON public.subscriptions FOR SELECT
  USING (family_id IN (
    SELECT family_id FROM public.family_members WHERE user_id = auth.uid()
  ));

-- Insert only for the authenticated user
CREATE POLICY "Subscriptions insert"
  ON public.subscriptions FOR INSERT
  WITH CHECK (user_id = auth.uid());

-- Update only for the row owner (or via service_role from webhooks)
CREATE POLICY "Subscriptions update"
  ON public.subscriptions FOR UPDATE
  USING (user_id = auth.uid());

CREATE UNIQUE INDEX IF NOT EXISTS idx_subscriptions_family
  ON public.subscriptions(family_id);

CREATE INDEX IF NOT EXISTS idx_subscriptions_stripe
  ON public.subscriptions(stripe_subscription_id)
  WHERE stripe_subscription_id IS NOT NULL;

-- ── Document Reminders ───────────────────────────────────────
-- Sends push notifications before a family document expires.

CREATE TABLE IF NOT EXISTS public.document_reminders (
  id          UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  document_id UUID NOT NULL REFERENCES public.family_documents(id) ON DELETE CASCADE,
  family_id   UUID NOT NULL REFERENCES public.families(id) ON DELETE CASCADE,
  remind_at   TIMESTAMPTZ NOT NULL,
  days_before INT NOT NULL DEFAULT 30,
  sent        BOOLEAN DEFAULT FALSE,
  sent_at     TIMESTAMPTZ,
  created_at  TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.document_reminders ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Document reminders select"
  ON public.document_reminders FOR SELECT
  USING (family_id IN (
    SELECT family_id FROM public.family_members WHERE user_id = auth.uid()
  ));

CREATE POLICY "Document reminders insert"
  ON public.document_reminders FOR INSERT
  WITH CHECK (family_id IN (
    SELECT family_id FROM public.family_members WHERE user_id = auth.uid()
  ));

CREATE INDEX IF NOT EXISTS idx_document_reminders_due
  ON public.document_reminders(remind_at)
  WHERE sent = FALSE;

-- Auto-create 30-day reminder when expiry_date is set on a document
CREATE OR REPLACE FUNCTION public.create_document_reminder()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
  IF NEW.expiry_date IS NOT NULL AND
     (OLD.expiry_date IS NULL OR OLD.expiry_date <> NEW.expiry_date) THEN
    INSERT INTO public.document_reminders (document_id, family_id, remind_at, days_before)
    VALUES (NEW.id, NEW.family_id, NEW.expiry_date - INTERVAL '30 days', 30)
    ON CONFLICT DO NOTHING;
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_document_reminder ON public.family_documents;
CREATE TRIGGER trg_document_reminder
  AFTER INSERT OR UPDATE OF expiry_date ON public.family_documents
  FOR EACH ROW EXECUTE FUNCTION public.create_document_reminder();
