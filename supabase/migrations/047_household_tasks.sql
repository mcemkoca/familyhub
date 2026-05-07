-- Household Tasks Schema
CREATE TABLE IF NOT EXISTS household_tasks (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    category VARCHAR(50) NOT NULL CHECK (category IN ('daily', 'weekly', 'monthly', 'yearly')),
    task_name VARCHAR(200) NOT NULL,
    description TEXT,
    estimated_duration_minutes INT,
    difficulty_level INT CHECK (difficulty_level BETWEEN 1 AND 5),
    room VARCHAR(50) CHECK (room IN ('mutfak', 'salon', 'banyo', 'yatak_odasi', 'balkon', 'koridor', 'genel')),
    season VARCHAR(20) DEFAULT 'tum_sezon' CHECK (season IN ('tum_sezon', 'ilkbahar', 'yaz', 'sonbahar', 'kis')),
    tips TEXT[] DEFAULT '{}',
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS task_schedules (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    task_id UUID REFERENCES household_tasks(id) ON DELETE CASCADE,
    family_id UUID REFERENCES families(id) ON DELETE CASCADE,
    frequency VARCHAR(20) CHECK (frequency IN ('daily', 'weekly', 'bi_weekly', 'monthly', 'quarterly', 'yearly')),
    day_of_week INT CHECK (day_of_week BETWEEN 0 AND 6),
    week_of_month INT CHECK (week_of_month BETWEEN 1 AND 4),
    month_of_year INT CHECK (month_of_year BETWEEN 1 AND 12),
    priority INT DEFAULT 3,
    assigned_to UUID REFERENCES auth.users(id),
    is_completed BOOLEAN DEFAULT false,
    completed_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Enable RLS
ALTER TABLE household_tasks ENABLE ROW LEVEL SECURITY;
ALTER TABLE task_schedules ENABLE ROW LEVEL SECURITY;

-- RLS Policies for household_tasks (read-only system table, all authenticated users can read)
CREATE POLICY "Authenticated users can read household_tasks"
ON household_tasks FOR SELECT TO authenticated USING (true);

-- RLS Policies for task_schedules (users can only see their family's tasks)
CREATE POLICY "Users can view family task schedules"
ON task_schedules FOR SELECT TO authenticated
USING (
    family_id IN (
        SELECT family_id FROM family_members WHERE user_id = auth.uid()
    )
);

CREATE POLICY "Users can insert family task schedules"
ON task_schedules FOR INSERT TO authenticated
WITH CHECK (
    family_id IN (
        SELECT family_id FROM family_members WHERE user_id = auth.uid()
    )
);

CREATE POLICY "Users can update family task schedules"
ON task_schedules FOR UPDATE TO authenticated
USING (
    family_id IN (
        SELECT family_id FROM family_members WHERE user_id = auth.uid()
    )
);

CREATE POLICY "Users can delete family task schedules"
ON task_schedules FOR DELETE TO authenticated
USING (
    family_id IN (
        SELECT family_id FROM family_members WHERE user_id = auth.uid()
    )
);

-- Indexes
CREATE INDEX idx_task_schedules_family_id ON task_schedules(family_id);
CREATE INDEX idx_task_schedules_assigned_to ON task_schedules(assigned_to);
CREATE INDEX idx_household_tasks_category ON household_tasks(category);
