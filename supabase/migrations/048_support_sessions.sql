-- Live Support Sessions Schema
CREATE TABLE IF NOT EXISTS support_sessions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    agent_id UUID,
    status VARCHAR(20) DEFAULT 'waiting' CHECK (status IN ('waiting', 'active', 'closed')),
    location TEXT,
    messages JSONB DEFAULT '[]',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Enable RLS
ALTER TABLE support_sessions ENABLE ROW LEVEL SECURITY;

-- RLS Policies
CREATE POLICY "Users view own support sessions"
ON support_sessions FOR SELECT TO authenticated
USING (auth.uid() = user_id);

CREATE POLICY "Users insert own support sessions"
ON support_sessions FOR INSERT TO authenticated
WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users update own support sessions"
ON support_sessions FOR UPDATE TO authenticated
USING (auth.uid() = user_id);

-- Index
CREATE INDEX idx_support_sessions_user_id ON support_sessions(user_id);
CREATE INDEX idx_support_sessions_status ON support_sessions(status);
