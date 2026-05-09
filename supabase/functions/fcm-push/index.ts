import { serve } from 'https://deno.land/std@0.177.0/http/server.ts'
import { createClient } from 'jsr:@supabase/supabase-js@2'
import { encode as base64Encode, decode as base64Decode } from 'https://deno.land/std@0.177.0/encoding/base64.ts'

/**
 * Supabase Edge Function: Send FCM push notifications to family members.
 * Triggered by database webhooks on messages, sos_alerts, tasks, etc.
 */

interface ServiceAccount {
  type: string
  project_id: string
  private_key_id: string
  private_key: string
  client_email: string
  client_id: string
  auth_uri: string
  token_uri: string
}

serve(async (req) => {
  try {
    const body = await req.json()
    const { record, table, old_record, type } = body

    // Only process INSERTs
    if (type !== 'INSERT') {
      return new Response(JSON.stringify({ skipped: true, reason: 'not insert' }), {
        headers: { 'Content-Type': 'application/json' },
      })
    }

    const serviceAccountJson = Deno.env.get('FIREBASE_SERVICE_ACCOUNT_JSON')
    if (!serviceAccountJson) {
      return new Response(
        JSON.stringify({ error: 'FIREBASE_SERVICE_ACCOUNT_JSON missing' }),
        { status: 500, headers: { 'Content-Type': 'application/json' } }
      )
    }

    const serviceAccount: ServiceAccount = JSON.parse(serviceAccountJson)

    // Get access token for FCM HTTP v1 API
    const accessToken = await getAccessToken(serviceAccount)

    // Supabase admin client
    const supabase = createClient(
      Deno.env.get('SUPABASE_URL')!,
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
    )

    // Determine notification content based on table
    const { title, body, route } = buildNotification(table, record)
    const familyId = record.family_id
    const senderId = record.user_id || record.created_by || record.sender_id

    if (!familyId) {
      return new Response(JSON.stringify({ skipped: true, reason: 'no family_id' }), {
        headers: { 'Content-Type': 'application/json' },
      })
    }

    // Find family members with FCM tokens (exclude sender)
    const { data: members, error } = await supabase
      .from('profiles')
      .select('id, fcm_token')
      .eq('family_id', familyId)
      .not('fcm_token', 'is', null)

    if (error) {
      return new Response(JSON.stringify({ error: error.message }), {
        status: 500,
        headers: { 'Content-Type': 'application/json' },
      })
    }

    const results: any[] = []
    for (const member of members || []) {
      if (member.id === senderId) continue
      if (!member.fcm_token) continue

      const result = await sendFcmPush(
        accessToken,
        serviceAccount.project_id,
        member.fcm_token,
        title,
        body,
        route,
        record
      )
      results.push({ userId: member.id, status: result.status })
    }

    return new Response(JSON.stringify({ sent: results.length, details: results }), {
      headers: { 'Content-Type': 'application/json' },
    })
  } catch (err) {
    return new Response(JSON.stringify({ error: (err as Error).message }), {
      status: 500,
      headers: { 'Content-Type': 'application/json' },
    })
  }
})

function buildNotification(
  table: string,
  record: any
): { title: string; body: string; route: string } {
  switch (table) {
    case 'messages':
      return {
        title: record.sender_name || 'FamilyHub',
        body: record.content || 'Yeni mesaj',
        route: '/chat',
      }
    case 'sos_alerts':
      return {
        title: '🚨 ACİL DURUM',
        body: `${record.sender_name || 'Birisi'} acil durum butonunu kullandı!`,
        route: '/safety',
      }
    case 'tasks':
      return {
        title: 'Yeni Görev',
        body: record.title || 'Size yeni bir görev atandı',
        route: '/tasks',
      }
    default:
      return {
        title: 'FamilyHub',
        body: 'Yeni bir bildiriminiz var',
        route: '/hub',
      }
  }
}

async function getAccessToken(sa: ServiceAccount): Promise<string> {
  const now = Math.floor(Date.now() / 1000)

  const header = base64Encode(
    new TextEncoder().encode(JSON.stringify({ alg: 'RS256', typ: 'JWT' }))
  )
  const claim = base64Encode(
    new TextEncoder().encode(
      JSON.stringify({
        iss: sa.client_email,
        sub: sa.client_email,
        scope: 'https://www.googleapis.com/auth/firebase.messaging',
        aud: 'https://oauth2.googleapis.com/token',
        iat: now,
        exp: now + 3600,
      })
    )
  )

  const signingInput = `${header}.${claim}`
  const signature = await signRsaSha256(signingInput, sa.private_key)
  const jwt = `${signingInput}.${base64Encode(signature)}`

  const response = await fetch('https://oauth2.googleapis.com/token', {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body: `grant_type=urn:ietf:params:oauth:grant-type:jwt-bearer&assertion=${jwt}`,
  })

  const data = await response.json()
  if (!data.access_token) {
    throw new Error(`Failed to get access token: ${JSON.stringify(data)}`)
  }
  return data.access_token
}

async function signRsaSha256(input: string, privateKeyPem: string): Promise<Uint8Array> {
  const pem = privateKeyPem.replace(/\\n/g, '\n')
  const keyData = pemToArrayBuffer(pem)

  const cryptoKey = await crypto.subtle.importKey(
    'pkcs8',
    keyData,
    { name: 'RSASSA-PKCS1-v1_5', hash: 'SHA-256' },
    false,
    ['sign']
  )

  const signature = await crypto.subtle.sign(
    'RSASSA-PKCS1-v1_5',
    cryptoKey,
    new TextEncoder().encode(input)
  )

  return new Uint8Array(signature)
}

function pemToArrayBuffer(pem: string): ArrayBuffer {
  const b64 = pem
    .replace('-----BEGIN PRIVATE KEY-----', '')
    .replace('-----END PRIVATE KEY-----', '')
    .replace(/\s/g, '')
  return base64Decode(b64).buffer
}

async function sendFcmPush(
  accessToken: string,
  projectId: string,
  fcmToken: string,
  title: string,
  body: string,
  route: string,
  record: any
): Promise<Response> {
  return fetch(
    `https://fcm.googleapis.com/v1/projects/${projectId}/messages:send`,
    {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${accessToken}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        message: {
          token: fcmToken,
          notification: { title, body },
          data: {
            route,
            family_id: record.family_id || '',
            table: record.table || '',
          },
        },
      }),
    }
  )
}
