import { serve } from 'https://deno.land/std@0.224.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.45.0';

const webhookSecret = Deno.env.get('REVENUECAT_WEBHOOK_SECRET') ?? '';
const supabase = createClient(
  Deno.env.get('SUPABASE_URL') ?? '',
  Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '',
);

serve(async (request) => {
  if (request.method !== 'POST') {
    return new Response('Method not allowed', { status: 405 });
  }
  if (!webhookSecret || request.headers.get('authorization') !== `Bearer ${webhookSecret}`) {
    return new Response('Unauthorized', { status: 401 });
  }

  try {
    const payload = await request.json();
    const event = payload.event;
    const userId = event?.app_user_id;
    const type = event?.type as string | undefined;
    if (!userId || !type) {
      return new Response('Invalid event', { status: 400 });
    }

    const handled = new Set([
      'INITIAL_PURCHASE',
      'RENEWAL',
      'UNCANCELLATION',
      'CANCELLATION',
      'EXPIRATION',
      'PRODUCT_CHANGE',
      'SUBSCRIPTION_PAUSED',
    ]);
    if (!handled.has(type)) return Response.json({ received: true });

    const expirationMs = Number(event.expiration_at_ms ?? 0);
    const expiresAt = expirationMs > 0
      ? new Date(expirationMs).toISOString()
      : null;
    const isActive = !['EXPIRATION', 'SUBSCRIPTION_PAUSED'].includes(type) &&
      (expirationMs === 0 || expirationMs > Date.now());
    const productId = String(event.product_id ?? '').toLowerCase();
    const tier = productId.includes('family') ? 'family' : 'premium';

    const { error } = await supabase.from('profiles').update({
      is_premium: isActive,
      subscription_tier: isActive ? tier : 'free',
      subscription_expires_at: expiresAt,
      subscription_provider: 'revenuecat',
      updated_at: new Date().toISOString(),
    }).eq('id', userId);

    if (error) {
      console.error('Profile subscription update failed', error);
      return new Response('Database update failed', { status: 500 });
    }
    return Response.json({ received: true });
  } catch (error) {
    console.error('RevenueCat webhook error', error);
    return new Response('Invalid request', { status: 400 });
  }
});
