-- ============================================
-- 066 — Sağlık Kayıtları (Health Records)
-- Aile üyesi bazlı sağlık kaydı: muayene, aşı, reçete, test, tanı vb.
-- Aile-izole RLS; soft-delete; audit alanları.
-- ============================================

CREATE TABLE IF NOT EXISTS public.health_records (
  id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  family_id uuid REFERENCES public.families(id) ON DELETE CASCADE NOT NULL,
  -- Kaydın ait olduğu kişi: yetişkin için profiles.id, çocuk için child hesap id.
  member_id text NOT NULL,
  member_type text NOT NULL DEFAULT 'adult'
    CHECK (member_type IN ('adult', 'child', 'other')),
  record_type text NOT NULL DEFAULT 'note'
    CHECK (record_type IN (
      'exam','hospital','emergency','vaccine','lab','prescription',
      'medication','allergy','diagnosis','surgery','dental','vision',
      'growth','bloodpressure','symptom','note','document','other')),
  title text NOT NULL,
  description text,
  doctor text,
  institution text,
  address text,
  record_date date NOT NULL DEFAULT CURRENT_DATE,
  privacy_level text NOT NULL DEFAULT 'family'
    CHECK (privacy_level IN ('private','family','caregivers')),
  attachment_url text,
  tags text[] DEFAULT '{}',
  created_by uuid REFERENCES public.profiles(id),
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now(),
  updated_by uuid REFERENCES public.profiles(id),
  deleted_at timestamptz
);

CREATE INDEX IF NOT EXISTS idx_health_records_family
  ON public.health_records(family_id, record_date DESC);
CREATE INDEX IF NOT EXISTS idx_health_records_member
  ON public.health_records(family_id, member_id);

ALTER TABLE public.health_records ENABLE ROW LEVEL SECURITY;

-- Aile-izole: yalnızca kullanıcının ailesindeki kayıtlar (soft-delete hariç
-- filtre uygulama katmanında). Backend erişim kontrolü ZORUNLU (spec §21).
DROP POLICY IF EXISTS "health_records_select" ON public.health_records;
CREATE POLICY "health_records_select"
  ON public.health_records FOR SELECT TO authenticated
  USING (
    family_id IN (
      SELECT family_id FROM public.profiles
      WHERE id = auth.uid() AND family_id IS NOT NULL
    )
  );

DROP POLICY IF EXISTS "health_records_insert" ON public.health_records;
CREATE POLICY "health_records_insert"
  ON public.health_records FOR INSERT TO authenticated
  WITH CHECK (
    family_id IN (
      SELECT family_id FROM public.profiles
      WHERE id = auth.uid() AND family_id IS NOT NULL
    )
  );

DROP POLICY IF EXISTS "health_records_update" ON public.health_records;
CREATE POLICY "health_records_update"
  ON public.health_records FOR UPDATE TO authenticated
  USING (
    family_id IN (
      SELECT family_id FROM public.profiles
      WHERE id = auth.uid() AND family_id IS NOT NULL
    )
  );

DROP POLICY IF EXISTS "health_records_delete" ON public.health_records;
CREATE POLICY "health_records_delete"
  ON public.health_records FOR DELETE TO authenticated
  USING (
    family_id IN (
      SELECT family_id FROM public.profiles
      WHERE id = auth.uid() AND family_id IS NOT NULL
    )
  );
