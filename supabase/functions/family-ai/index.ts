import { serve } from 'https://deno.land/std@0.177.0/http/server.ts'
import { createClient } from 'jsr:@supabase/supabase-js@2'

/**
 * Edge Function: family-ai
 *
 * FamilyHub "Aile Zekâsı" güvenli Gemini GEÇİDİ (P0 güvenlik düzeltmesi).
 *
 * SORUN: ai_engine.dart Gemini'yi Flutter client'tan DOĞRUDAN çağırıyordu
 * (`...generateContent?key=$_geminiKey`). Key APK'ye gömülü → çıkarılabilir.
 *
 * ÇÖZÜM: Bu fonksiyon SADIK bir proxy'dir. İstemci Gemini istek gövdesini
 * `{ request: <gemini body> }` olarak yollar; fonksiyon:
 *   1. JWT doğrular (gateway + auth.getUser),
 *   2. family_members ile aile üyeliğini doğrular,
 *   3. GEMINI_API_KEY'i Supabase secret'tan ekleyerek Gemini'yi çağırır,
 *   4. kota (429) durumunda sıradaki modele geçer,
 *   5. HAM Gemini yanıtını ({candidates:...}) aynen döndürür.
 *
 * Böylece ai_engine'in mevcut parse mantığı DEĞİŞMEDEN çalışır ve tüm AI
 * özellikleri (bütçe/tarif/öneri JSON'ları) korunur. Key istemciye HİÇ gitmez.
 */

const MODELS = (Deno.env.get('GEMINI_MODELS') ??
  'gemini-2.5-flash,gemini-2.5-flash-lite,gemini-flash-latest,gemini-2.0-flash')
  .split(',')
  .map((m) => m.trim())
  .filter(Boolean)

function json(obj: unknown, status = 200): Response {
  return new Response(JSON.stringify(obj), {
    status,
    headers: { 'Content-Type': 'application/json' },
  })
}

serve(async (req) => {
  const supabaseUrl = Deno.env.get('SUPABASE_URL')
  const anonKey = Deno.env.get('SUPABASE_ANON_KEY')
  const geminiKey = Deno.env.get('GEMINI_API_KEY')
  if (!supabaseUrl || !anonKey) {
    return json({ error: 'INVALID_REQUEST' }, 500)
  }
  if (!geminiKey) {
    return json({ error: 'MODEL_UNAVAILABLE' }, 503)
  }

  const authHeader = req.headers.get('Authorization') ?? ''
  if (!authHeader.startsWith('Bearer ')) {
    return json({ error: 'AUTH_REQUIRED' }, 401)
  }
  const supabase = createClient(supabaseUrl, anonKey, {
    global: { headers: { Authorization: authHeader } },
  })

  const { data: userData, error: userErr } = await supabase.auth.getUser()
  if (userErr || !userData?.user) {
    return json({ error: 'AUTH_REQUIRED' }, 401)
  }

  // Aile üyeliği doğrula (profiles'ta family_id yok → family_members).
  const { data: membership } = await supabase
    .from('family_members')
    .select('family_id')
    .eq('user_id', userData.user.id)
    .maybeSingle()
  if (!membership?.family_id) {
    return json({ error: 'FAMILY_NOT_FOUND' }, 403)
  }

  let request: unknown
  try {
    const payload = await req.json()
    request = payload?.request
  } catch (_) {
    return json({ error: 'INVALID_REQUEST' }, 400)
  }
  if (!request || typeof request !== 'object') {
    return json({ error: 'INVALID_REQUEST' }, 400)
  }

  // Gemini'yi SUNUCUDA çağır — key istemciye gitmez. 429'da sıradaki model.
  let lastStatus = 0
  let lastBody = ''
  for (const model of MODELS) {
    try {
      // Key `X-goog-api-key` HEADER'ında gönderilir — hem yeni format (AQ.…)
      // hem eski format (AIza…) anahtarları bu header ile çalışır.
      const res = await fetch(
        `https://generativelanguage.googleapis.com/v1beta/models/${model}:generateContent`,
        {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
            'X-goog-api-key': geminiKey,
          },
          body: JSON.stringify(request),
          signal: AbortSignal.timeout(30000),
        },
      )
      lastStatus = res.status
      if (res.status === 429) continue // kota → sıradaki model
      const bodyText = await res.text()
      lastBody = bodyText
      if (!res.ok) break // 429 dışı hata → model değiştirmek fayda etmez
      // HAM Gemini yanıtını aynen dön (ai_engine parse eder).
      return new Response(bodyText, {
        status: 200,
        headers: { 'Content-Type': 'application/json' },
      })
    } catch (_) {
      // ağ/timeout → sıradaki model
    }
  }

  return json(
    { error: 'MODEL_UNAVAILABLE', upstream_status: lastStatus, upstream: lastBody.slice(0, 300) },
    502,
  )
})
