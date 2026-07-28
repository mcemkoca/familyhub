-- ============================================================
-- Migration 054: family_documents — category + expiry_date
-- ============================================================
-- Adds Belgium-specific document category and expiry tracking.

ALTER TABLE public.family_documents
  ADD COLUMN IF NOT EXISTS category TEXT DEFAULT 'other'
    CHECK (category IN ('identity','health','insurance','school','residence','vehicle','tax','mutualite','other')),
  ADD COLUMN IF NOT EXISTS expiry_date TIMESTAMPTZ;

-- Index for quick expiry queries (reminders, "expiring soon" badges)
CREATE INDEX IF NOT EXISTS idx_family_documents_expiry
  ON public.family_documents(family_id, expiry_date)
  WHERE expiry_date IS NOT NULL;
