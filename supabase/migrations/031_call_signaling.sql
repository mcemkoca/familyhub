-- WebRTC signaling tablosu (ücretsiz peer-to-peer sesli arama için)
CREATE TABLE IF NOT EXISTS call_signaling (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  session_id uuid REFERENCES call_sessions(id) ON DELETE CASCADE NOT NULL,
  sender_id uuid NOT NULL,
  type text NOT NULL CHECK (type IN ('offer', 'answer', 'ice_candidate')),
  payload jsonb NOT NULL,
  created_at timestamptz DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_call_signaling_session ON call_signaling(session_id);

-- RLS: kullanıcı sadece kendi ailesinin signaling mesajlarını görebilir
ALTER TABLE call_signaling ENABLE ROW LEVEL SECURITY;

CREATE POLICY "family_call_signaling_access" ON call_signaling
FOR ALL USING (
  session_id IN (
    SELECT id FROM call_sessions WHERE family_id IN (
      SELECT family_id FROM family_members WHERE user_id = auth.uid()
    )
  )
);
