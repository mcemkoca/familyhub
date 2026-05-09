-- ============================================================================
-- 053_fcm_push_trigger.sql
-- Database webhook triggers for FCM push notifications via Edge Function
-- ============================================================================

-- Enable pg_net for async HTTP requests from triggers
CREATE EXTENSION IF NOT EXISTS pg_net;

-- Helper function: call fcm-push Edge Function
CREATE OR REPLACE FUNCTION public.notify_family_members()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_project_ref TEXT;
  v_function_url TEXT;
  v_service_role TEXT;
BEGIN
  -- Get project ref from environment (set in Supabase Dashboard)
  v_project_ref := current_setting('app.settings.supabase_project_ref', true);
  IF v_project_ref IS NULL OR v_project_ref = '' THEN
    v_project_ref := split_part(current_setting('supabase.functions_url', true), '.', 1);
  END IF;

  v_function_url := 'https://' || v_project_ref || '.supabase.co/functions/v1/fcm-push';
  v_service_role := current_setting('supabase.service_role_key', true);

  -- Async HTTP POST to Edge Function
  PERFORM net.http_post(
    url := v_function_url,
    headers := jsonb_build_object(
      'Content-Type', 'application/json',
      'Authorization', 'Bearer ' || COALESCE(v_service_role, '')
    ),
    body := jsonb_build_object(
      'type', TG_OP,
      'table', TG_TABLE_NAME,
      'record', row_to_json(NEW)
    )
  );

  RETURN NEW;
END;
$$;

-- Trigger: New messages -> push notification
DROP TRIGGER IF EXISTS messages_push_notify ON public.messages;
CREATE TRIGGER messages_push_notify
  AFTER INSERT ON public.messages
  FOR EACH ROW
  EXECUTE FUNCTION public.notify_family_members();

-- Trigger: New SOS alerts -> push notification
DROP TRIGGER IF EXISTS sos_alerts_push_notify ON public.sos_alerts;
CREATE TRIGGER sos_alerts_push_notify
  AFTER INSERT ON public.sos_alerts
  FOR EACH ROW
  EXECUTE FUNCTION public.notify_family_members();

-- Trigger: New tasks (when assigned) -> push notification
DROP TRIGGER IF EXISTS tasks_push_notify ON public.tasks;
CREATE TRIGGER tasks_push_notify
  AFTER INSERT ON public.tasks
  FOR EACH ROW
  EXECUTE FUNCTION public.notify_family_members();

-- ============================================================================
-- NOTE: To make this work, you must set the following secrets in Supabase:
--   1. FIREBASE_SERVICE_ACCOUNT_JSON  (Firebase service account JSON)
--   2. SUPABASE_SERVICE_ROLE_KEY      (already available)
--
-- Set via: supabase secrets set FIREBASE_SERVICE_ACCOUNT_JSON '...json...'
-- ============================================================================
