-- Görev oyunlaştırması (XP, rozet, lider tablosu)

-- XP ve rozet bilgileri profiles tablosuna eklendi
ALTER TABLE profiles
ADD COLUMN IF NOT EXISTS xp INTEGER DEFAULT 0,
ADD COLUMN IF NOT EXISTS badges JSONB DEFAULT '[]';

-- Rozet tanımları
CREATE TABLE IF NOT EXISTS badges (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  description TEXT NOT NULL,
  icon TEXT NOT NULL,
  threshold_xp INTEGER NOT NULL,
  color TEXT DEFAULT '#3B82F6',
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Varsayılan rozetler
INSERT INTO badges (id, name, description, icon, threshold_xp, color) VALUES
  ('first_task', 'İlk Adım', 'İlk görevi tamamla', 'emoji_events', 0, '#10B981'),
  ('task_master_10', 'Görev Ustası', '10 görev tamamla', 'emoji_events', 100, '#3B82F6'),
  ('task_master_50', 'Görev Kahramanı', '50 görev tamamla', 'emoji_events', 500, '#8B5CF6'),
  ('streak_7', '7 Gün Seri', '7 gün üst üste görev tamamla', 'local_fire_department', 200, '#F59E0B'),
  ('streak_30', 'Aylık Şampiyon', '30 gün üst üste görev tamamla', 'local_fire_department', 1000, '#EF4444'),
  ('helper', 'Yardımsever', '5 arkadaşını davet et', 'group', 150, '#EC4899')
ON CONFLICT (id) DO NOTHING;

-- XP ekleme fonksiyonu
CREATE OR REPLACE FUNCTION add_user_xp(p_user_id UUID, p_amount INTEGER)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  UPDATE profiles
  SET xp = COALESCE(xp, 0) + p_amount
  WHERE id = p_user_id;
END;
$$;
