-- Mood Entries Schema
CREATE TABLE IF NOT EXISTS mood_entries (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    family_id UUID REFERENCES families(id) ON DELETE CASCADE,
    mood VARCHAR(50) NOT NULL CHECK (mood IN ('happy', 'sad', 'energetic', 'tired', 'stressed', 'calm', 'excited', 'angry')),
    note TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Enable RLS
ALTER TABLE mood_entries ENABLE ROW LEVEL SECURITY;

-- RLS Policies
CREATE POLICY "Users can view family mood entries"
ON mood_entries FOR SELECT TO authenticated
USING (
    family_id IN (
        SELECT family_id FROM family_members WHERE user_id = auth.uid()
    )
);

CREATE POLICY "Users can insert own mood entries"
ON mood_entries FOR INSERT TO authenticated
WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own mood entries"
ON mood_entries FOR UPDATE TO authenticated
USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own mood entries"
ON mood_entries FOR DELETE TO authenticated
USING (auth.uid() = user_id);

-- Index
CREATE INDEX idx_mood_entries_family_id ON mood_entries(family_id);
CREATE INDEX idx_mood_entries_user_id ON mood_entries(user_id);
CREATE INDEX idx_mood_entries_created_at ON mood_entries(created_at DESC);
