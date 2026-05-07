-- Health Cards Schema
CREATE TABLE IF NOT EXISTS health_cards (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    family_id UUID REFERENCES families(id) ON DELETE CASCADE,
    blood_type TEXT,
    allergies TEXT[] DEFAULT '{}',
    medications JSONB DEFAULT '[]',
    chronic_conditions TEXT[] DEFAULT '{}',
    emergency_contact_name TEXT,
    emergency_contact_phone TEXT,
    emergency_contact_relation TEXT,
    doctor_name TEXT,
    doctor_phone TEXT,
    doctor_hospital TEXT,
    organ_donor BOOLEAN DEFAULT false,
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Enable RLS
ALTER TABLE health_cards ENABLE ROW LEVEL SECURITY;

-- RLS Policies
CREATE POLICY "Users can view family health cards"
ON health_cards FOR SELECT TO authenticated
USING (
    family_id IN (
        SELECT family_id FROM family_members WHERE user_id = auth.uid()
    )
);

CREATE POLICY "Users can insert own health card"
ON health_cards FOR INSERT TO authenticated
WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own health card"
ON health_cards FOR UPDATE TO authenticated
USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own health card"
ON health_cards FOR DELETE TO authenticated
USING (auth.uid() = user_id);

-- Indexes
CREATE INDEX idx_health_cards_family_id ON health_cards(family_id);
CREATE INDEX idx_health_cards_user_id ON health_cards(user_id);

-- Updated at trigger
CREATE OR REPLACE FUNCTION update_health_cards_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS health_cards_updated_at ON health_cards;
CREATE TRIGGER health_cards_updated_at
    BEFORE UPDATE ON health_cards
    FOR EACH ROW
    EXECUTE FUNCTION update_health_cards_updated_at();
