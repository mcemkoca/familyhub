-- Seed 300+ Household Tasks (truncated sample; full data loaded from application assets)
INSERT INTO household_tasks (category, task_name, description, estimated_duration_minutes, difficulty_level, room, season, tips) VALUES
('daily', 'Mutfak Tezgahı Temizliği', 'Yemek sonrası tezgahı ıslak bezle silip kuru bezle kurulama', 10, 2, 'mutfak', 'tum_sezon', ARRAY['Sirke suyu ile doğal dezenfeksiyon yapın', 'Mikrofiber bez kullanın', 'Her yemekten hemen sonra silerseniz yağlar kurumaz']),
('daily', 'Çöp Atma', 'Ev genelindeki çöp tenekelerini boşaltma', 5, 1, 'genel', 'tum_sezon', ARRAY['Poşetleri düğümleyerek kokuyu önleyin', 'Geri dönüşümü ayrı toplayın']),
('daily', 'Yer Süpürme', 'Mutfak ve salonun hızlı süpürülmesi', 15, 2, 'salon', 'tum_sezon', ARRAY['Elektrikli süpürge ile daha hızlı temizlik', 'Köşeleri atlamayın']),
('daily', 'Bulaşık Yıkama', 'Bulaşıkları elde veya makinede yıkama', 20, 2, 'mutfak', 'tum_sezon', ARRAY['Sıcak su ile ön durulama yapın', 'Bulaşık makinesini tam dolmadan çalıştırmayın']),
('daily', 'Çamaşır Asma', 'Yıkanan çamaşırları asmak veya kurutucuya yerleştirme', 15, 1, 'balkon', 'tum_sezon', ARRAY['Gölgelikte asın renklerin solmasını önleyin', 'Gömlekleri omuzlarından asın']),
('daily', 'Banyo Lavabosu Temizliği', 'Lavaboyu ve muslukları silme', 10, 2, 'banyo', 'tum_sezon', ARRAY['Kireç çözücü sprey kullanın', 'Mikrofiber bez ile parlatın']),
('daily', 'Yatak Düzeltme', 'Tüm odalardaki yatakları düzeltme', 10, 1, 'yatak_odasi', 'tum_sezon', ARRAY['Her sabah düzenli yapın alışkanlık oluşsun', 'Yastıkları havalandırın']),
('weekly', 'Çarşaf Değiştirme', 'Tüm yatak çarşaflarını değiştirme', 30, 2, 'yatak_odasi', 'tum_sezon', ARRAY['Sıcak suda yıkayın', 'Yastık kılıflarını da haftada bir değiştirin']),
('weekly', 'Banyo Temizliği', 'Küvet, duşakabin, lavabo ve klozeti derinlemesine temizleme', 45, 3, 'banyo', 'tum_sezon', ARRAY['Kireç çözücü ile duşakabini temizleyin', 'Tuvalet fırçasına dezenfektan dökün']),
('weekly', 'Cam Silme', 'İç cephe camları ve aynaları silme', 40, 2, 'salon', 'tum_sezon', ARRAY['Gazete kağıdı ile silerseniz iz kalmaz', 'Bulutlu havada yapın güneş izleri göstermez']),
('monthly', 'Filtre Temizliği', 'Bulaşık makinesi, çamaşır makinesi ve aspiratör filtrelerini temizleme', 30, 3, 'mutfak', 'tum_sezon', ARRAY['Filtreleri ılık suda bekletin', 'Aspiratör filtresini degreaser ile temizleyin']),
('monthly', 'Derinlemesine Dolap İçi', 'Mutfak dolaplarının içini boşaltıp silme', 45, 3, 'mutfak', 'tum_sezon', ARRAY['Bozulmuş ürünleri atın', 'Raf örtüsü kullanın temizliği kolaylaştırır']),
('monthly', 'Perde Yıkama', 'Perdeleri makinede veya elde yıkama', 40, 2, 'salon', 'tum_sezon', ARRAY['Etiketteki yıkama talimatına uyun', 'Narin çevrimde yıkayın']),
('yearly', 'Kombi Bakımı', 'Kombi ve peteklerin profesyonel bakımı', 120, 4, 'genel', 'kis', ARRAY['Yıllık servis anlaşması yaptırın', 'Petek havasını sonbaharda aldırın']),
('yearly', 'Boya Kontrolü ve Tamirat', 'Duvarlardaki çatlak ve lekeleri boyama', 180, 4, 'genel', 'ilkbahar', ARRAY['Kalan boyadan saklayın', 'Küçük alanlarda rulo, köşelerde fırça kullanın']),
('yearly', 'Bahçe/Balkon Düzenleme', 'Saksı toprağı değişimi ve bitki budama', 90, 3, 'balkon', 'ilkbahar', ARRAY['Bitki türüne göre budama zamanını seçin', 'Eskimiş toprağı değiştirin']);

-- ============================================
-- ADIL DAGILIM FONKSIYONU
-- ============================================

CREATE OR REPLACE FUNCTION calculate_fairness_score(
  p_user_id UUID,
  p_week_start DATE
)
RETURNS DECIMAL(5,2)
LANGUAGE plpgsql
AS $$
DECLARE
  v_total_tasks INT;
  v_total_minutes INT;
  v_difficulty_sum INT;
  v_capacity INT;
  v_score DECIMAL(5,2);
BEGIN
  SELECT 
    COUNT(*),
    COALESCE(SUM(estimated_duration_minutes), 0),
    COALESCE(SUM(difficulty_level), 0)
  INTO v_total_tasks, v_total_minutes, v_difficulty_sum
  FROM task_assignments ta
  JOIN household_tasks ht ON ta.task_id = ht.id
  WHERE ta.assigned_to = p_user_id
  AND ta.assigned_date >= p_week_start
  AND ta.assigned_date < p_week_start + INTERVAL '7 days';

  SELECT weekly_capacity_minutes INTO v_capacity
  FROM family_members
  WHERE user_id = p_user_id;

  -- Skor hesaplama: Dusuk yuk = yuksek skor
  v_score := 100 - (v_total_minutes::DECIMAL / NULLIF(v_capacity, 0) * 50)
               - (v_difficulty_sum::DECIMAL / NULLIF(v_total_tasks, 0) * 10);

  RETURN GREATEST(0, LEAST(100, v_score));
END;
$$;

-- Full 300+ task seed is loaded from assets/data/household_tasks.json via application logic
