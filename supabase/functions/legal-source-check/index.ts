import { serve } from 'https://deno.land/std@0.177.0/http/server.ts'
import { createClient } from 'jsr:@supabase/supabase-js@2'

/**
 * Edge Function: legal-source-check
 *
 * FamilyHub Yasal Haklar — günlük kaynak izleme (FH-05).
 *
 * Her aktif legal_sources kaydını fetch eder, içeriğin SHA-256 hash'ini
 * hesaplar ve önceki hash ile karşılaştırır. DEĞİŞİKLİK varsa
 * legal_review_queue'ya `pending` bir kayıt düşer.
 *
 * KRİTİK: Bu fonksiyon içeriği ASLA otomatik yayınlamaz. Yalnızca değişiklik
 * TESPİT eder ve insan incelemesine gönderir (spec: kritik hukuki içerik
 * insan onayı olmadan auto-publish edilmez). Böylece yanlış/uydurma yasal
 * bilgi kullanıcıya "güncel" gibi gösterilmez.
 *
 * Tetikleme: pg_cron → net.http_post (günlük). Service-role ile çağrılır.
 */

async function sha256(text: string): Promise<string> {
  const data = new TextEncoder().encode(text)
  const digest = await crypto.subtle.digest('SHA-256', data)
  return Array.from(new Uint8Array(digest))
    .map((b) => b.toString(16).padStart(2, '0'))
    .join('')
}

serve(async (_req) => {
  const supabaseUrl = Deno.env.get('SUPABASE_URL')
  const serviceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')
  if (!supabaseUrl || !serviceKey) {
    return new Response(
      JSON.stringify({ error: 'SUPABASE_URL / SERVICE_ROLE_KEY missing' }),
      { status: 500, headers: { 'Content-Type': 'application/json' } },
    )
  }

  const supabase = createClient(supabaseUrl, serviceKey)

  const { data: sources, error } = await supabase
    .from('legal_sources')
    .select('*')
    .eq('is_active', true)

  if (error) {
    return new Response(JSON.stringify({ error: error.message }), {
      status: 500,
      headers: { 'Content-Type': 'application/json' },
    })
  }

  let checked = 0
  let changed = 0
  let failed = 0

  for (const src of sources ?? []) {
    checked++
    try {
      const res = await fetch(src.url, {
        headers: { 'User-Agent': 'FamilyHub-LegalBot/1.0 (+family app)' },
        redirect: 'follow',
        signal: AbortSignal.timeout(15000),
      })
      const body = await res.text()
      const hash = await sha256(body)

      const nowIso = new Date().toISOString()

      if (src.last_content_hash && src.last_content_hash !== hash) {
        // Değişiklik → inceleme kuyruğuna (auto-publish YOK).
        changed++
        await supabase.from('legal_review_queue').insert({
          source_id: src.id,
          old_hash: src.last_content_hash,
          new_hash: hash,
          http_status: res.status,
          review_status: res.ok ? 'pending' : 'error',
        })
      }

      await supabase
        .from('legal_sources')
        .update({
          last_checked_at: nowIso,
          last_content_hash: hash,
          last_status: res.status,
        })
        .eq('id', src.id)
    } catch (e) {
      failed++
      await supabase.from('legal_review_queue').insert({
        source_id: src.id,
        review_status: 'error',
        notes: `fetch failed: ${e instanceof Error ? e.message : String(e)}`,
      })
    }
  }

  return new Response(
    JSON.stringify({ ok: true, checked, changed, failed }),
    { headers: { 'Content-Type': 'application/json' } },
  )
})
