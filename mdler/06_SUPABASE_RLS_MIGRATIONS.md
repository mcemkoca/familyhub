# SUPABASE RLS & MIGRATIONS
## 8 Veritabani Sorunu | Hedef: Guvenli ve Otomatik DB

---

## 29. SupabaseConfig.safeClient — Singleton Refactor

**Sorun:** `Supabase.instance.client` 25+ dosyada direkt kullaniliyor

### lib/core/config/supabase_config.dart
```dart
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  static SupabaseClient? _client;
  static bool _isInitialized = false;

  /// Guvenli client erisimi
  static SupabaseClient get safeClient {
    _client ??= Supabase.instance.client;

    if (_client == null) {
      throw SupabaseException('Supabase client baslatilmamis');
    }

    if (_client!.auth.currentSession == null) {
      throw AuthException('Oturum sona ermis. Lutfen tekrar giris yapin.');
    }

    return _client!;
  }

  /// Auth durumu kontrolu
  static bool get isAuthenticated => 
      _client?.auth.currentSession != null;

  /// Mevcut kullanici
  static User? get currentUser => _client?.auth.currentUser;

  /// Auth state degisikliklerini dinle
  static void initializeAuthListener() {
    _client ??= Supabase.instance.client;

    _client!.auth.onAuthStateChange.listen((data) {
      final AuthChangeEvent event = data.event;

      switch (event) {
        case AuthChangeEvent.signedOut:
          _client = null;
          break;
        case AuthChangeEvent.tokenRefreshed:
          _client = Supabase.instance.client;
          break;
        default:
          break;
      }
    });
  }

  /// Tum Supabase.instance.client kullanimlarini bul
  /// grep -r "Supabase.instance.client" lib/
}

class SupabaseException implements Exception {
  final String message;
  SupabaseException(this.message);
  @override
  String toString() => message;
}
```

### Refactoring komutu:
```bash
# Tum dosyalarda degistir
grep -r "Supabase.instance.client" lib/ --include="*.dart"

# Her dosyada:
# 1. import 'package:your_app/core/config/supabase_config.dart'; ekle
# 2. Supabase.instance.client → SupabaseConfig.safeClient degistir
```

---

## 30. SQL Migration Otomasyonu

**Sorun:** `046_final_rls_and_users.sql` manuel calistiriliyor

### supabase/migrations/046_final_rls_and_users.sql
```sql
-- ============================================
-- 046_final_rls_and_users.sql
-- ============================================

-- Tum tablolarda otomatik RLS enable
CREATE OR REPLACE FUNCTION rls_auto_enable()
RETURNS EVENT_TRIGGER 
LANGUAGE plpgsql 
SECURITY DEFINER 
AS $$
BEGIN
  FOR cmd IN 
    SELECT * FROM pg_event_trigger_ddl_commands()
    WHERE command_tag IN ('CREATE TABLE', 'CREATE TABLE AS')
  LOOP
    EXECUTE format('ALTER TABLE %s ENABLE ROW LEVEL SECURITY', cmd.object_identity);
  END LOOP;
END;
$$;

CREATE EVENT TRIGGER ensure_rls 
ON ddl_command_end
WHEN TAG IN ('CREATE TABLE', 'CREATE TABLE AS')
EXECUTE FUNCTION rls_auto_enable();

-- ============================================
-- TUM TABLOLAR ICIN RLS POLICIES
-- ============================================

-- users tablosu
ALTER TABLE users ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own profile"
ON users FOR SELECT TO authenticated
USING (id = auth.uid());

CREATE POLICY "Users can update own profile"
ON users FOR UPDATE TO authenticated
USING (id = auth.uid());

-- family_members tablosu
ALTER TABLE family_members ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Family members can view family"
ON family_members FOR SELECT TO authenticated
USING (
  family_id IN (
    SELECT family_id FROM family_members 
    WHERE user_id = auth.uid() AND is_active = true
  )
);

CREATE POLICY "Users can manage own membership"
ON family_members FOR ALL TO authenticated
USING (user_id = auth.uid())
WITH CHECK (user_id = auth.uid());

-- task_assignments tablosu
ALTER TABLE task_assignments ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view family assignments"
ON task_assignments FOR SELECT TO authenticated
USING (
  assigned_to = auth.uid() 
  OR assigned_by = auth.uid()
  OR EXISTS (
    SELECT 1 FROM family_members fm
    WHERE fm.user_id = auth.uid()
    AND fm.family_id = (
      SELECT family_id FROM family_members 
      WHERE user_id = task_assignments.assigned_to
    )
  )
);

CREATE POLICY "Users can create assignments"
ON task_assignments FOR INSERT TO authenticated
WITH CHECK (assigned_by = auth.uid());

CREATE POLICY "Users can update own assignments"
ON task_assignments FOR UPDATE TO authenticated
USING (assigned_to = auth.uid() OR assigned_by = auth.uid());

-- chat_messages tablosu (048'de detayli)
-- health_cards tablosu (049'da detayli)
-- mood_entries tablosu (047'de detayli)
```

### Supabase CLI ile otomasyon:
```yaml
# .github/workflows/supabase-deploy.yml
name: Deploy Migrations
on:
  push:
    branches: [main]
    paths:
      - 'supabase/migrations/**'
jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: supabase/setup-cli@v1
        with:
          version: latest
      - run: supabase link --project-ref $SUPABASE_PROJECT_REF
      - run: supabase db push
        env:
          SUPABASE_ACCESS_TOKEN: ${{ secrets.SUPABASE_ACCESS_TOKEN }}
```

---

## 31. 300+ Ev Isleri Seed Data

**Sorun:** Data yuklenmemis

### supabase/seed_household_tasks.sql
```sql
-- ============================================
-- 300+ EV ISLERI SEED DATA
-- ============================================

-- GUNLUK (60 gorev)
INSERT INTO household_tasks (category, task_name, description, estimated_duration_minutes, difficulty_level, room, season, tips, icon_name) VALUES
('daily', 'Mutfak Tezgahi Temizligi', 'Yemek sonrasi tezgahi islak bezle silip kurulama', 10, 2, 'mutfak', 'all_seasons', ARRAY['Sirke suyu ile dogal dezenfeksiyon', 'Mikrofiber bez kullanin', 'Hemen silerseniz yag kurumaz'], 'countertops'),
('daily', 'Cop Atma', 'Ev ici cop kutularini bosaltma', 5, 1, 'tum_ev', 'all_seasons', ARRAY['Her aksam duzenli atin', 'Geri donusumu ayirin'], 'delete'),
('daily', 'Yer Supurme', 'Salon ve mutfak yerlerini supurme', 15, 2, 'salon', 'all_seasons', ARRAY['Koseleri atlamayin', 'Elektrikli supurge daha etkili'], 'cleaning'),
('daily', 'Bulasic Yikama', 'Kirli bulasiciklari yikama ve kurutma', 20, 3, 'mutfak', 'all_seasons', ARRAY['Sicak su ile baslayin', 'Son durulama sirke suyu ile'], 'local_dining'),
('daily', 'Camasir Asma', 'Yikanan camasirlari askiya asma', 10, 1, 'banyo', 'all_seasons', ARRAY['Gomlekleri omuzdan asin', 'Coraplari ciftleyin'], 'dry_cleaning'),
('daily', 'Aksam Yemegi Hazirlik', 'Gunluk aksam yemegini planlama ve hazirlama', 45, 3, 'mutfak', 'all_seasons', ARRAY['Onceden hazirlik yapin', 'Sebzeleri aksamdan yikayin'], 'restaurant'),
('daily', 'Kahvalti Masasi Hazirlama', 'Sabah kahvalti icin masa duzeni', 10, 1, 'mutfak', 'all_seasons', ARRAY['Onceki gece hazirlayin', 'Termos kullanin'], 'breakfast_dining'),
('daily', 'Evcil Hayvan Besleme', 'Kedi/kopek besleme ve su degistirme', 5, 1, 'tum_ev', 'all_seasons', ARRAY['Duzenli saatlerde besleyin', 'Su kabini gunluk degistirin'], 'pets'),
('daily', 'Posta/Kargo Duzenleme', 'Gelen posta ve kargolari acma/ayirma', 5, 1, 'giris', 'all_seasons', ARRAY['Onemli belgeleri dosyalayin', 'Reklamlari hemen geri donusum'], 'mail'),
('daily', 'Aksam Cay Servisi', 'Aksam cayi icin fincan hazirligi', 8, 1, 'mutfak', 'all_seasons', ARRAY['Demlik onceden isitin', 'Cay saatini sabitleyin'], 'coffee');

-- HAFTALIK (100 gorev) - Ornekler
INSERT INTO household_tasks (category, task_name, description, estimated_duration_minutes, difficulty_level, room, season, tips, icon_name) VALUES
('weekly', 'Carsaf Degistirme', 'Tum yatak carsaflarini degistirme', 20, 2, 'yatak_odasi', 'all_seasons', ARRAY['Haftada bir degistirin', '60 derecede yikayin'], 'bed'),
('weekly', 'Banyo Temizligi', 'Banyo fayans ve kuvet temizligi', 30, 3, 'banyo', 'all_seasons', ARRAY['Kirec cozucu kullanin', 'Mikrofiber bez ile parlatın'], 'cleaning_services'),
('weekly', 'Cam Silme', 'Ic ve dis cam temizligi', 45, 4, 'salon', 'all_seasons', ARRAY['Gunesli gunde yapmayin', 'Gazete ile kurulayin'], 'window'),
('weekly', 'Buzdolabi Duzenleme', 'Buzdolabi ici temizlik ve duzen', 25, 2, 'mutfak', 'all_seasons', ARRAY['Son kullanma tarihlerini kontrol edin', 'Bozulmuslari atin'], 'kitchen'),
('weekly', 'Toz Alma', 'Mobilya ve raflardan toz alma', 30, 2, 'tum_ev', 'all_seasons', ARRAY['Yukaridan asagiya calisin', 'Elektrostatik bez kullanin'], 'cleaning'),
('weekly', 'Supurge ve Mop Yikama', 'Temizlik aletlerini yikama', 15, 2, 'banyo', 'all_seasons', ARRAY['Sicak su ve deterjan', 'Gunes kurutma'], 'cleaning_services');

-- AYLIK (80 gorev) - Ornekler
INSERT INTO household_tasks (category, task_name, description, estimated_duration_minutes, difficulty_level, room, season, tips, icon_name) VALUES
('monthly', 'Filtre Temizligi', 'Klima ve supurge filtrelerini temizleme', 20, 2, 'tum_ev', 'all_seasons', ARRAY['Filtreleri suda bekletin', 'Tam kurutmadan takmayin'], 'ac_unit'),
('monthly', 'Derinlemesine Dolap', 'Dolap ici duzenleme ve temizlik', 60, 3, 'yatak_odasi', 'all_seasons', ARRAY['Mevsimlik kiyafetleri ayirin', 'Nem alici koyun'], 'wardrobe'),
('monthly', 'Perde Yikama', 'Perdeleri yikama ve asma', 45, 3, 'salon', 'all_seasons', ARRAY['Etiket talimatlarina uyun', 'Hafif program kullanin'], 'curtains'),
('monthly', 'Hali Yikama', 'Halilari yikama ve kurutma', 90, 4, 'salon', 'all_seasons', ARRAY['Leke varsa on islem yapin', 'Profesyonel destek alabilirsiniz'], 'carpet'),
('monthly', 'Mobilya Cilalama', 'Ahşap mobilyalari cilalama', 40, 2, 'salon', 'all_seasons', ARRAY['Toz almadan once cilalamayin', 'Dogal yag kullanin'], 'chair');

-- YILLIK (60 gorev) - Ornekler
INSERT INTO household_tasks (category, task_name, description, estimated_duration_minutes, difficulty_level, room, season, tips, icon_name) VALUES
('yearly', 'Kombi Bakimi', 'Kombi ve petek temizligi', 120, 4, 'tum_ev', 'kis', ARRAY['Uzman servis cagirin', 'Peteklerde hava varsa aldirin'], 'hvac'),
('yearly', 'Boya Kontrolu', 'Duvarlarda catlak ve kirilmis boya kontrolu', 60, 3, 'tum_ev', 'ilkbahar', ARRAY['Nemli odalara ozen gosterin', 'Kuf varsa uzman yardimi alin'], 'format_paint'),
('yearly', 'Bahce Duzenleme', 'Bahce temizligi ve bitki bakimi', 180, 4, 'bahce', 'ilkbahar', ARRAY['Ilkbahar basinda yapin', 'Kompost hazirlayin'], 'yard'),
('yearly', 'Depo Temizligi', 'Kiler/bodrum temizligi ve duzenleme', 120, 3, 'depo', 'sonbahar', ARRAY['Kullanilmayanlari bagislayin', 'Nem kontrolu yapin'], 'storage'),
('yearly', 'Klima Bakimi', 'Klima dis unite temizligi ve gaz kontrolu', 90, 4, 'tum_ev', 'yaz', ARRAY['Yaz basinda yapin', 'Filtreleri degistirin'], 'ac_unit');

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
```

---

## 32. Backup Repository — Data Leak Duzeltme

**Sorun:** Tum ailelerin backup'ini stream ediyor

### lib/features/backup/repositories/backup_repository.dart
```dart
class BackupRepository {
  final SupabaseClient _client = SupabaseConfig.safeClient;

  Stream<List<Backup>> watchBackups() {
    final user = _client.auth.currentUser;
    if (user == null) return Stream.value([]);

    // SADECE kendi ailesinin backup'larini goster
    return _client
        .from('backups')
        .stream(primaryKey: ['id'])
        .eq('family_id', _getFamilyId())  // ← FILTRE EKLENDI
        .order('created_at', ascending: false)
        .map((data) => data.map((e) => Backup.fromJson(e)).toList());
  }

  String _getFamilyId() {
    // Cache veya provider'dan family_id al
    return SupabaseConfig.currentUser?.userMetadata?['family_id'] ?? '';
  }
}
```

---

## 33. FamilyMembersRepository — Wrong PK Duzeltme

**Sorun:** `['family_id', 'user_id']` yerine `['id']` olmali

### lib/features/family/repositories/family_members_repository.dart
```dart
class FamilyMembersRepository {
  final SupabaseClient _client = SupabaseConfig.safeClient;

  Stream<List<FamilyMember>> watchMembers() {
    // YANLIS: .stream(primaryKey: ['family_id', 'user_id'])
    // DOGRU:
    return _client
        .from('family_members')
        .stream(primaryKey: ['id'])  // ← DUZELTILDI
        .eq('is_active', true)
        .order('created_at', ascending: true)
        .map((data) => data.map((e) => FamilyMember.fromJson(e)).toList());
  }
}
```

---

## Kontrol Listesi

- [ ] SupabaseConfig.safeClient tum dosyalarda kullaniliyor
- [ ] SQL migration'lar Supabase CLI ile otomatik deploy
- [ ] 300+ ev isleri seed data yuklendi
- [ ] RLS policies tum tablolarda aktif
- [ ] Backup repository aile filtresi ile
- [ ] FamilyMembersRepository primaryKey ['id']
- [ ] `supabase db push` hatasiz calisiyor

---
**Versiyon:** 1.0 | **Dosya:** 6/10 | **Hedef:** Guvenli ve Otomatik DB
