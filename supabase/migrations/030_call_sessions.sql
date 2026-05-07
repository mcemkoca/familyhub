-- Sesli arama oturumları tablosu
CREATE TABLE IF NOT EXISTS call_sessions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  family_id uuid REFERENCES families(id) ON DELETE CASCADE NOT NULL,
  caller_id uuid REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
  callee_id uuid REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
  agora_channel_name text NOT NULL,
  status text NOT NULL DEFAULT 'ringing' CHECK (status IN ('ringing', 'connected', 'ended', 'rejected', 'missed', 'busy')),
  started_at timestamptz DEFAULT now(),
  ended_at timestamptz,
  duration_seconds int,
  caller_joined_at timestamptz,
  callee_joined_at timestamptz,
  created_at timestamptz DEFAULT now()
);

-- Hızlı sorgular için indeksler
CREATE INDEX IF NOT EXISTS idx_call_sessions_family ON call_sessions(family_id);
CREATE INDEX IF NOT EXISTS idx_call_sessions_callee ON call_sessions(callee_id, status);
CREATE INDEX IF NOT EXISTS idx_call_sessions_caller ON call_sessions(caller_id, status);

-- RLS: kullanıcı sadece kendi ailesinin aramalarını görebilir
ALTER TABLE call_sessions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "family_call_access" ON call_sessions
FOR ALL USING (
  family_id IN (
    SELECT family_id FROM family_members WHERE user_id = auth.uid()
  )
);

-- Uygulama çökmesi veya kapanması durumunda missed olarak işaretlemek için yardımcı fonksiyon
CREATE OR REPLACE FUNCTION mark_stale_calls_as_missed()
RETURNS void AS $$
BEGIN
  UPDATE call_sessions
  SET status = 'missed',
      ended_at = COALESCE(ended_at, now())
  WHERE status = 'ringing'
    AND started_at < now() - interval '60 seconds';
END;
$$ LANGUAGE plpgsql;
