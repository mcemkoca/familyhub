-- 069_legal_source_registry.sql
-- ============================================================================
-- Yasal Haklar günlük güncelleme altyapısı (FH-05).
-- Statik JSON tek başına yeterli değildi; bu tablolar gerçek pipeline'ı besler:
--   Cron → legal-source-check Edge Function → fetch → hash compare →
--   change detection → review queue → (insan onayı) → publish.
-- KRİTİK GÜVENLİK: kritik hukuki içerik İNSAN ONAYI olmadan auto-publish EDİLMEZ.
-- Idempotent.
-- ============================================================================

-- ── Kaynak kaydı: izlenecek resmî URL'ler ──────────────────────────────────
create table if not exists public.legal_sources (
  id uuid primary key default gen_random_uuid(),
  country_code text not null default 'BE',
  region_code text,                       -- BE-VLG / BE-WAL / BE-BRU / null=federal
  authority text not null,                -- "Groeipakket (Vlaanderen)" vb.
  category text not null,                 -- childBenefits / parentalLeave ...
  url text not null,
  trust_level int not null default 1,     -- 1 = resmî
  last_checked_at timestamptz,
  last_content_hash text,                 -- değişiklik tespiti için
  last_status int,                        -- son HTTP durum kodu
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  unique (url)
);

-- ── Değişiklik/inceleme kuyruğu: auto-publish YOK ──────────────────────────
create table if not exists public.legal_review_queue (
  id uuid primary key default gen_random_uuid(),
  source_id uuid not null references public.legal_sources(id) on delete cascade,
  detected_at timestamptz not null default now(),
  old_hash text,
  new_hash text,
  http_status int,
  -- pending → insan inceler → approved/rejected. published yalnızca onaydan sonra.
  review_status text not null default 'pending'
    check (review_status in ('pending','approved','rejected','error')),
  reviewer_id uuid references public.profiles(id),
  reviewed_at timestamptz,
  notes text
);
create index if not exists idx_legal_review_status
  on public.legal_review_queue(review_status, detected_at desc);

-- ── RLS: okuma tüm authenticated; yazma yalnızca service-role (Edge Function) ─
alter table public.legal_sources enable row level security;
alter table public.legal_review_queue enable row level security;

drop policy if exists "legal_sources_read" on public.legal_sources;
create policy "legal_sources_read" on public.legal_sources
  for select to authenticated using (true);

drop policy if exists "legal_review_read" on public.legal_review_queue;
create policy "legal_review_read" on public.legal_review_queue
  for select to authenticated using (true);
-- INSERT/UPDATE için policy YOK → yalnızca service-role (RLS bypass) yazar.
-- Böylece normal kullanıcı yasal içeriği değiştiremez.

-- ── Başlangıç kaynakları (be.json ile hizalı) ──────────────────────────────
insert into public.legal_sources (country_code, region_code, authority, category, url, trust_level)
values
  ('BE','BE-VLG','Groeipakket (Vlaanderen)','childBenefits','https://www.groeipakket.be/',1),
  ('BE','BE-VLG','Kind en Gezin / Opgroeien','childHealth','https://www.kindengezin.be/',1),
  ('BE',null,'RVA/ONEM','parentalLeave','https://www.rva.be/',1),
  ('BE',null,'FOD Sociale Zekerheid','socialSecurity','https://socialsecurity.belgium.be/',1),
  ('BE','BE-WAL','FWB / AVIQ','childBenefits','https://www.aviq.be/',1),
  ('BE','BE-BRU','Iriscare','childBenefits','https://www.iriscare.brussels/',1)
on conflict (url) do nothing;

-- ── pg_cron ile günlük tetikleme (Edge Function'ı çağırır) ─────────────────
-- NOT: pg_cron + pg_net extension'ları ve Edge Function deploy'u gerekir.
-- Deploy sonrası SQL Editor'da bir kez çalıştırılır (service-role gerektirir):
--
--   select cron.schedule(
--     'legal-source-check-daily',
--     '0 4 * * *',                        -- her gün 04:00 UTC
--     $$ select net.http_post(
--          url := 'https://<PROJECT>.functions.supabase.co/legal-source-check',
--          headers := jsonb_build_object('Authorization','Bearer <SERVICE_ROLE_KEY>')
--        ); $$
--   );
