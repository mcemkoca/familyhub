-- ============================================================
-- FamilyHub Test Verisi (Seed)
-- Aile: Koca Ailesi
-- Baba: Mustafa Cem Koca [mcemkoca0@gmail.com]
-- Anne: Hilal Sahbaz Koca [hilalsahbaz2018@gmail.com]
-- Çocuk: Mirac Koca (6 yaşında)
-- ============================================================
-- BU DOSYAYI SUPABASE DASHBOARD > SQL EDITOR'DA ÇALIŞTIRIN
-- ============================================================

DO $$
DECLARE
  baba_id uuid;
  anne_id uuid;
  existing_anne_id uuid;
  family_id uuid := 'f1111111-1111-1111-1111-111111111111'::uuid;
  mirac_child_id uuid := 'c1111111-1111-1111-1111-111111111111'::uuid;
BEGIN

  -- ==========================================================
  -- 1. Mevcut kullanıcıyı bul (Baba / Mustafa Cem Koca)
  -- ==========================================================
  SELECT id INTO baba_id FROM auth.users ORDER BY created_at DESC LIMIT 1;

  IF baba_id IS NULL THEN
    RAISE EXCEPTION 'Oturum açık kullanıcı bulunamadı. Lütfen önce uygulamadan kaydolun/giriş yapın.';
  END IF;

  -- ==========================================================
  -- 2. Anne kullanıcısı zaten var mı kontrol et
  -- ==========================================================
  SELECT id INTO existing_anne_id FROM auth.users WHERE email = 'hilalsahbaz2018@gmail.com' LIMIT 1;

  IF existing_anne_id IS NOT NULL THEN
    anne_id := existing_anne_id;
    RAISE NOTICE 'Anne kullanıcısı zaten mevcut, ID: %', anne_id;
  ELSE
    anne_id := 'a1111111-1111-1111-1111-111111111111'::uuid;

    INSERT INTO auth.users (
      instance_id, id, aud, role, email, encrypted_password,
      email_confirmed_at, raw_app_meta_data, raw_user_meta_data,
      created_at, updated_at
    ) VALUES (
      '00000000-0000-0000-0000-000000000000'::uuid,
      anne_id,
      'authenticated',
      'authenticated',
      'hilalsahbaz2018@gmail.com',
      crypt('Mirac2704*', gen_salt('bf')),
      now(),
      '{"provider":"email","providers":["email"]}'::jsonb,
      '{"display_name":"Hilal"}'::jsonb,
      now(),
      now()
    );

    INSERT INTO auth.identities (
      id, user_id, identity_data, provider, created_at, updated_at
    ) VALUES (
      anne_id,
      anne_id,
      '{"sub":"' || anne_id || '","email":"hilalsahbaz2018@gmail.com"}'::jsonb,
      'email',
      now(),
      now()
    )
    ON CONFLICT (id, provider) DO NOTHING;
  END IF;

  -- ==========================================================
  -- 3. Aile oluştur (eğer yoksa)
  -- ==========================================================
  INSERT INTO public.families (id, name, created_at, updated_at)
  VALUES (family_id, 'Koca Ailesi', now(), now())
  ON CONFLICT (id) DO NOTHING;

  -- ==========================================================
  -- 4. Baba profilini güncelle
  -- ==========================================================
  INSERT INTO public.profiles (id, display_name, full_name, email, family_id, xp, is_premium, accent_color, created_at, updated_at)
  VALUES (baba_id, 'Mustafa Cem', 'Mustafa Cem Koca', 'mcemkoca0@gmail.com', family_id, 150, false, 'cobalt', now(), now())
  ON CONFLICT (id) DO UPDATE SET
    family_id = EXCLUDED.family_id,
    display_name = EXCLUDED.display_name,
    full_name = EXCLUDED.full_name,
    email = EXCLUDED.email,
    updated_at = now();

  -- ==========================================================
  -- 5. Anne profili
  -- ==========================================================
  INSERT INTO public.profiles (id, display_name, full_name, email, family_id, xp, is_premium, accent_color, created_at, updated_at)
  VALUES (anne_id, 'Hilal', 'Hilal Sahbaz Koca', 'hilalsahbaz2018@gmail.com', family_id, 200, false, 'purple', now(), now())
  ON CONFLICT (id) DO UPDATE SET
    family_id = EXCLUDED.family_id,
    display_name = EXCLUDED.display_name,
    full_name = EXCLUDED.full_name,
    email = EXCLUDED.email,
    updated_at = now();

  -- ==========================================================
  -- 6. family_members kayıtları
  -- ==========================================================
  INSERT INTO public.family_members (user_id, family_id, role, is_active, joined_at)
  VALUES (baba_id, family_id, 'admin', true, now())
  ON CONFLICT DO NOTHING;

  INSERT INTO public.family_members (user_id, family_id, role, is_active, joined_at)
  VALUES (anne_id, family_id, 'parent', true, now())
  ON CONFLICT DO NOTHING;

  -- ==========================================================
  -- 7. Çocuk hesabı: Mirac Koca (6 yaşında)
  -- ==========================================================
  INSERT INTO public.child_accounts (id, family_id, name, pin_code, color, birth_date, is_active, created_at)
  VALUES (mirac_child_id, family_id, 'Mirac', '2704', '#FF6B6B', '2018-01-01', true, now())
  ON CONFLICT (id) DO UPDATE SET family_id = EXCLUDED.family_id;

  -- ==========================================================
  -- 8. GÖREVLER (tasks)
  -- ==========================================================
  INSERT INTO public.tasks (id, family_id, title, description, status, priority, assigned_to, created_by, due_date, created_at)
  VALUES
    (gen_random_uuid(), family_id, 'Odaları süpür', 'Salon ve mutfak süpürülecek', 'pending', 'medium', baba_id, baba_id, now() + interval '2 days', now()),
    (gen_random_uuid(), family_id, 'Bulaşıkları yıka', 'Akşam yemeği bulaşıkları', 'pending', 'high', anne_id, baba_id, now() + interval '1 day', now()),
    (gen_random_uuid(), family_id, 'Mirac''ın ödevlerini kontrol et', 'Matematik ve Türkçe ödevleri', 'pending', 'medium', anne_id, anne_id, now() + interval '3 days', now()),
    (gen_random_uuid(), family_id, 'Çamaşırları katla', 'Kuru çamaşırları katlayıp dolaba kaldır', 'pending', 'low', baba_id, anne_id, now() + interval '5 days', now()),
    (gen_random_uuid(), family_id, 'Market alışverişi', 'Süt, ekmek, yumurta, meyve', 'pending', 'high', anne_id, baba_id, now() + interval '1 day', now()),
    (gen_random_uuid(), family_id, 'Çöpleri çıkar', 'Mutfak ve banyo çöpleri', 'completed', 'low', baba_id, baba_id, now() - interval '1 day', now() - interval '2 days')
  ON CONFLICT DO NOTHING;

  -- ==========================================================
  -- 9. ETKİNLİKLER (events)
  -- ==========================================================
  INSERT INTO public.events (id, family_id, title, description, start_time, end_time, location, category, is_all_day, status, created_by, created_at)
  VALUES
    (gen_random_uuid(), family_id, 'Mirac''ın Doğum Günü Partisi', '6. yaş doğum günü kutlaması 🎂', now() + interval '3 days', now() + interval '3 days 4 hours', 'Ev', 'birthday', false, 'active', anne_id, now()),
    (gen_random_uuid(), family_id, 'Aile Pikniği', 'Hafta sonu parkta piknik', now() + interval '5 days 10 hours', now() + interval '5 days 14 hours', 'Brüksel Parkı', 'outing', false, 'active', baba_id, now()),
    (gen_random_uuid(), family_id, 'Diş Hekimi Randevusu', 'Mirac''ın rutin diş kontrolü', now() + interval '2 days 9 hours', now() + interval '2 days 10 hours', 'Diş Hekimi', 'health', false, 'active', anne_id, now()),
    (gen_random_uuid(), family_id, 'Veli Toplantısı', 'Okul veli toplantısı', now() + interval '1 day 17 hours', now() + interval '1 day 19 hours', 'Mirac''ın Okulu', 'school', false, 'active', anne_id, now()),
    (gen_random_uuid(), family_id, 'Aile Oyun Gecesi', 'Masa oyunları ve pizza gecesi 🎲', now() + interval '1 day 19 hours', now() + interval '1 day 22 hours', 'Ev', 'home', false, 'active', baba_id, now())
  ON CONFLICT DO NOTHING;

  -- ==========================================================
  -- 10. AİLE RUH HALİ (family_moods)
  -- ==========================================================
  INSERT INTO public.family_moods (id, family_id, user_id, mood_emoji, mood_note, energy_level, is_shared, created_at)
  VALUES
    (gen_random_uuid(), family_id, baba_id, '😊', 'Harika bir gün!', 8, true, now() - interval '2 hours'),
    (gen_random_uuid(), family_id, anne_id, '☕', 'Biraz yorgun ama mutluyum', 6, true, now() - interval '4 hours'),
    (gen_random_uuid(), family_id, baba_id, '🚀', 'Yeni projeye başladım', 9, true, now() - interval '1 day'),
    (gen_random_uuid(), family_id, anne_id, '🌸', 'Bahçe işleri güzel gidiyor', 7, true, now() - interval '1 day 5 hours')
  ON CONFLICT DO NOTHING;

  -- ==========================================================
  -- 11. MESAJLAR (messages)
  -- ==========================================================
  INSERT INTO public.messages (id, family_id, user_id, text, type, created_at)
  VALUES
    (gen_random_uuid(), family_id, baba_id, 'Akşam yemeğinde ne yapsak?', 'text', now() - interval '3 hours'),
    (gen_random_uuid(), family_id, anne_id, 'Mercimek çorbası ve salata yapabilirim', 'text', now() - interval '2 hours 45 minutes'),
    (gen_random_uuid(), family_id, baba_id, 'Süper! Mirac da sever.', 'text', now() - interval '2 hours 30 minutes'),
    (gen_random_uuid(), family_id, anne_id, 'Mirac''ın ödevleri bitti mi?', 'text', now() - interval '1 hour'),
    (gen_random_uuid(), family_id, baba_id, 'Matematik bitti, Türkçe kaldı. Ben yardım ediyorum.', 'text', now() - interval '45 minutes')
  ON CONFLICT DO NOTHING;

  -- ==========================================================
  -- 12. ALIŞVERİŞ LİSTESİ (shopping_items)
  -- ==========================================================
  INSERT INTO public.shopping_items (id, family_id, name, quantity, category, is_purchased, created_by, created_at)
  VALUES
    (gen_random_uuid(), family_id, 'Süt', '2 Litre', 'market', false, anne_id, now()),
    (gen_random_uuid(), family_id, 'Ekmek', '1 Adet', 'market', false, anne_id, now()),
    (gen_random_uuid(), family_id, 'Yumurta', '15 Adet', 'market', false, baba_id, now()),
    (gen_random_uuid(), family_id, 'Elma', '1 Kg', 'meyve', false, anne_id, now()),
    (gen_random_uuid(), family_id, 'Tuvalet Kağıdı', '1 Paket', 'temizlik', true, baba_id, now() - interval '1 day'),
    (gen_random_uuid(), family_id, 'Çocuk Diş Macunu', '1 Adet', 'kişisel_bakım', false, anne_id, now())
  ON CONFLICT DO NOTHING;

  -- ==========================================================
  -- 13. AİLE REHBERİ (family_contacts)
  -- ==========================================================
  INSERT INTO public.family_contacts (id, family_id, name, phone, email, type, notes, created_by, created_at)
  VALUES
    (gen_random_uuid(), family_id, 'Büyükanne', '+32 470 12 34 56', null, 'family', 'Pazar günleri aranır', baba_id, now()),
    (gen_random_uuid(), family_id, 'Dr. Ahmet Yılmaz', '+32 2 123 45 67', 'ahmet@klinik.be', 'doctor', 'Aile hekimi', anne_id, now()),
    (gen_random_uuid(), family_id, 'Okul Müdürü', '+32 2 987 65 43', 'mudur@okul.be', 'school', 'Mirac''ın okulu', anne_id, now()),
    (gen_random_uuid(), family_id, 'Komşu Ayşe Teyze', '+32 471 11 22 33', null, 'friend', 'Acil durumda evde olur', baba_id, now()),
    (gen_random_uuid(), family_id, '112 Acil', '112', null, 'emergency', 'Ambulans, itfaiye, polis', anne_id, now())
  ON CONFLICT DO NOTHING;

  -- ==========================================================
  -- 14. AI ÖNERİLER (ai_suggestions_cache)
  -- ==========================================================
  INSERT INTO public.ai_suggestions_cache (family_id, suggestions, provider, created_at)
  VALUES (
    family_id,
    '[
      {"type":"task","title":"Haftalık Buzdolabı Temizliği","description":"Buzdolabındaki eski ürünleri kontrol edin ve temizlik yapın.","priority":"medium"},
      {"type":"meal","title":"Sebzeli Kış Çorbası","description":"Havuç, kereviz ve patatesle besleyici bir çorba.","prep_time":"40 dk"},
      {"type":"activity","title":"Aile Oyun Gecesi","description":"Cuma akşamı masa oyunu ve pizza gecesi planlayın.","suggested_day":"Cuma"},
      {"type":"budget","title":"Enerji Tasarrufu","description":"Akşam 22:00''den sonra elektrikli cihazları prizden çekin.","monthly_savings":"~25€"},
      {"type":"health","title":"Mirac İçin Diş Fırçalama Rutini","description":"Her akşam 21:00''de diş fırçalama hatırlatıcısı ekleyin.","frequency":"Günlük"}
    ]'::jsonb,
    'familyhub_ai',
    now()
  )
  ON CONFLICT DO NOTHING;

  -- ==========================================================
  -- 15. SAFE ZONES (güvenli bölgeler)
  -- ==========================================================
  INSERT INTO public.safe_zones (id, family_id, name, latitude, longitude, radius, type, created_at)
  VALUES
    (gen_random_uuid(), family_id, 'Ev', 50.8503, 4.3517, 100, 'home', now()),
    (gen_random_uuid(), family_id, 'Mirac''ın Okulu', 50.8476, 4.3572, 150, 'school', now()),
    (gen_random_uuid(), family_id, 'Büyükanne', 50.8601, 4.3400, 100, 'family', now())
  ON CONFLICT DO NOTHING;

  -- ==========================================================
  -- 16. FAMILY DOCUMENTS (belgeler)
  -- ==========================================================
  INSERT INTO public.family_documents (id, family_id, title, file_url, file_type, status, uploaded_by, created_at)
  VALUES
    (gen_random_uuid(), family_id, 'Mirac''ın Karne Notları', 'https://example.com/docs/karne.pdf', 'pdf', 'active', anne_id, now()),
    (gen_random_uuid(), family_id, 'Aile Sağlık Karnesi', 'https://example.com/docs/saglik.pdf', 'pdf', 'active', baba_id, now())
  ON CONFLICT DO NOTHING;

  RAISE NOTICE 'Koca Ailesi test verileri başarıyla yüklendi!';
  RAISE NOTICE 'Baba ID: %, Anne ID: %, Aile ID: %', baba_id, anne_id, family_id;

END $$;
