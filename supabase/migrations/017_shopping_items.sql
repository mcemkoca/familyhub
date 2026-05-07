-- Shopping Items Table: Family-shared shopping list
CREATE TABLE IF NOT EXISTS shopping_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    family_id UUID NOT NULL REFERENCES families(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    category TEXT DEFAULT 'other' CHECK (category IN ('grocery', 'pharmacy', 'stationery', 'household', 'other')),
    quantity INTEGER DEFAULT 1,
    is_completed BOOLEAN DEFAULT false,
    completed_by TEXT,
    requested_by TEXT,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

-- RLS Policies
ALTER TABLE IF EXISTS shopping_items ENABLE ROW LEVEL SECURITY;

-- Anon (child accounts) can view and manage shopping items for their family
DROP POLICY IF EXISTS "Child can view family shopping" ON shopping_items;
CREATE POLICY "Child can view family shopping" ON shopping_items
    FOR SELECT TO anon
    USING (family_id IN (
        SELECT family_id FROM child_accounts WHERE id = nullif(current_setting('app.current_child_id', true), '')::uuid
    ));

DROP POLICY IF EXISTS "Child can update shopping items" ON shopping_items;
CREATE POLICY "Child can update shopping items" ON shopping_items
    FOR UPDATE TO anon
    USING (family_id IN (
        SELECT family_id FROM child_accounts WHERE id = nullif(current_setting('app.current_child_id', true), '')::uuid
    ))
    WITH CHECK (family_id IN (
        SELECT family_id FROM child_accounts WHERE id = nullif(current_setting('app.current_child_id', true), '')::uuid
    ));

DROP POLICY IF EXISTS "Child can insert shopping items" ON shopping_items;
CREATE POLICY "Child can insert shopping items" ON shopping_items
    FOR INSERT TO anon
    WITH CHECK (family_id IN (
        SELECT family_id FROM child_accounts WHERE id = nullif(current_setting('app.current_child_id', true), '')::uuid
    ));

-- Authenticated parents can manage shopping items for their family
DROP POLICY IF EXISTS "Parent can manage family shopping" ON shopping_items;
CREATE POLICY "Parent can manage family shopping" ON shopping_items
    FOR ALL TO authenticated
    USING (family_id IN (
        SELECT family_id FROM profiles WHERE id = auth.uid()
    ))
    WITH CHECK (family_id IN (
        SELECT family_id FROM profiles WHERE id = auth.uid()
    ));

-- Indexes
CREATE INDEX IF NOT EXISTS idx_shopping_items_family ON shopping_items(family_id, is_completed, created_at DESC);

-- Realtime
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_publication_tables
    WHERE pubname = 'supabase_realtime'
      AND schemaname = 'public'
      AND tablename = 'shopping_items'
  ) THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE shopping_items;
  END IF;
END $$;
