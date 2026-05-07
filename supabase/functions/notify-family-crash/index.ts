// Supabase Edge Function: notify-family-crash
// Sends FCM push notifications to all family members when a crash is detected.
//
// Deploy: supabase functions deploy notify-family-crash
// Set secret: supabase secrets set FIREBASE_SERVICE_ACCOUNT "$(cat service-account.json)"

import { createClient } from 'npm:@supabase/supabase-js@2';
import { initializeApp, cert } from 'npm:firebase-admin@12';
import { getMessaging } from 'npm:firebase-admin@12/messaging';

const supabaseUrl = Deno.env.get('SUPABASE_URL')!;
const supabaseServiceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;

// Initialize Firebase Admin once
let messaging: ReturnType<typeof getMessaging> | null = null;

function getFirebaseMessaging() {
  if (messaging) return messaging;
  const serviceAccountJson = Deno.env.get('FIREBASE_SERVICE_ACCOUNT');
  if (!serviceAccountJson) {
    throw new Error('FIREBASE_SERVICE_ACCOUNT secret is missing');
  }
  const serviceAccount = JSON.parse(serviceAccountJson);
  const app = initializeApp({ credential: cert(serviceAccount) });
  messaging = getMessaging(app);
  return messaging;
}

Deno.serve(async (req) => {
  if (req.method !== 'POST') {
    return new Response('Method not allowed', { status: 405 });
  }

  try {
    const { sender_id, family_id, latitude, longitude, confidence } = await req.json();
    if (!sender_id || !family_id) {
      return new Response('Missing sender_id or family_id', { status: 400 });
    }

    const supabase = createClient(supabaseUrl, supabaseServiceRoleKey);

    // Get all family members with FCM tokens (except sender)
    const { data: members, error: membersError } = await supabase
      .from('profiles')
      .select('id, fcm_token, full_name')
      .eq('family_id', family_id)
      .neq('id', sender_id)
      .not('fcm_token', 'is', null);

    if (membersError) {
      console.error('Error fetching members:', membersError);
      return new Response('Database error', { status: 500 });
    }

    if (!members || members.length === 0) {
      return Response.json({ message: 'No family members with FCM tokens found' });
    }

    const tokens = members.map((m) => m.fcm_token).filter(Boolean) as string[];

    if (tokens.length === 0) {
      return Response.json({ message: 'No valid FCM tokens' });
    }

    // Build notification
    const latStr = typeof latitude === 'number' ? latitude.toFixed(4) : '?';
    const lngStr = typeof longitude === 'number' ? longitude.toFixed(4) : '?';

    const message = {
      notification: {
        title: '🚨 Kaza Algılandı!',
        body: `Aile üyesi kaza yaptı. Konum: ${latStr}, ${lngStr}`,
      },
      data: {
        route: 'safety',
        type: 'crash_alert',
        latitude: String(latitude ?? 0),
        longitude: String(longitude ?? 0),
        confidence: String(confidence ?? 0),
        sender_id: String(sender_id),
      },
      tokens,
    };

    const response = await getFirebaseMessaging().sendEachForMulticast(message);

    // Clean up invalid tokens
    const invalidTokens: string[] = [];
    response.responses.forEach((resp, idx) => {
      if (!resp.success) {
        const errorCode = resp.error?.code;
        if (
          errorCode === 'messaging/invalid-registration-token' ||
          errorCode === 'messaging/registration-token-not-registered'
        ) {
          invalidTokens.push(tokens[idx]);
        }
      }
    });

    if (invalidTokens.length > 0) {
      await supabase
        .from('profiles')
        .update({ fcm_token: null })
        .in('fcm_token', invalidTokens);
    }

    return Response.json({
      success: response.successCount,
      failure: response.failureCount,
      invalidTokensRemoved: invalidTokens.length,
    });
  } catch (err) {
    console.error('Crash notification error:', err);
    return new Response(
      JSON.stringify({ error: err.message }),
      { status: 500, headers: { 'Content-Type': 'application/json' } }
    );
  }
});
