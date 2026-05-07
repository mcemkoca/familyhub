import json
import os
import random

OUTPUT_DIR = "assets/data/content"
os.makedirs(OUTPUT_DIR, exist_ok=True)

# ============== RECIPES ==============
def generate_recipes():
    recipes = []
    categories = {
        "kahvalti": 22, "ogle_yemegi": 22, "aksam_yemegi": 22, "atistirmalik": 22,
        "tatli": 22, "icecek": 22, "vejetaryen": 22, "cocuk_dostu": 22,
        "hizli_yemek": 21, "geleneksel": 21, "dunya_mutfagi": 21, "diyet": 21,
        "ramazan": 21, "piknik": 21
    }
    
    recipe_templates = [
        ("Menemen", "kahvalti", 15, 20, 4, ["Yumurta", "Domates", "Biber", "Soğan", "Zeytinyağı", "Tuz", "Karabiber"], ["Soğanı yemeklik doğrayıp zeytinyağında kavurun.", "Doğranmış biberi ekleyip 2 dk daha kavurun.", "Domatesleri rendeleyip tencereye ekleyin.", "5 dk pişirdikten sonra yumurtaları kırın.", "Yumurtalar pişene kadar karıştırın ve servis yapın."], 320, "18g", "22g", "20g"),
        ("Mercimek Çorbası", "ogle_yemegi", 10, 30, 6, ["Kırmızı mercimek", "Soğan", "Havuç", "Patates", "Tereyağı", "Un", "Kimyon", "Nane", "Tuz"], ["Mercimeği yıkayıp süzün.", "Soğan, havuç ve patatesi küp küp doğrayın.", "Tencereye sebzeleri ve mercimeği ekleyip su ilave edin.", "Sebzeler yumuşayana kadar 25 dk pişirin.", "Blenderdan geçirin, tereyağında nane ve kırmızı biber yakıp üzerine gezdirin."], 180, "12g", "28g", "4g"),
        ("Izgara Tavuk", "aksam_yemegi", 15, 25, 4, ["Tavuk göğsü", "Zeytinyağı", "Limon suyu", "Sarımsak", "Kekik", "Tuz", "Karabiber"], ["Tavuk göğüslerini yıkayıp kurulayın.", "Zeytinyağı, limon suyu, sarımsak ve baharatları karıştırın.", "Tavukları marine edip en az 30 dk dinlendirin.", "Izgara tavada veya fırında 20-25 dk pişirin.", "Dinlendirip dilimleyerek servis yapın."], 280, "35g", "2g", "14g"),
        ("Kısır", "atistirmalik", 15, 0, 4, ["İnce bulgur", "Domates salçası", "Biber salçası", "Nar ekşisi", "Taze soğan", "Maydanoz", "Dereotu", "Salatalık", "Domates", "Limon suyu"], ["Bulguru sıcak suyla ıslatıp 15 dk dinlendirin.", "Tüm sebzeleri ince ince doğrayın.", "Şişen bulgura salça, baharat ve nar ekşisini ekleyin.", "Doğranmış sebzeleri ilave edip karıştırın.", "Limon suyu ve zeytinyağı gezdirip servis yapın."], 220, "6g", "38g", "8g"),
        ("Sütlaç", "tatli", 10, 45, 6, ["Pirinç", "Süt", "Şeker", "Nişasta", "Vanilin", "Tarçın"], ["Pirinci yıkayıp suda haşlayın.", "Haşlanmış pirince sütü ekleyip kaynatın.", "Nişasta ve şekeri az süt ile açıp tencereye ekleyin.", "Koyulaşana kadar karıştırarak pişirin.", "Kaselere paylaştırıp soğutun, üzerine tarçın serpin."], 200, "5g", "32g", "6g"),
        ("Ayran", "icecek", 5, 0, 2, ["Yoğurt", "Su", "Tuz"], ["Yoğurdu bir kaseye alın.", "Üzerine su ve tuzu ekleyin.", "Çırpıcı ile köpürene kadar çırpın.", "Buz ekleyerek servis yapın."], 80, "4g", "8g", "3g"),
        ("Sebzeli Nohut Yemeği", "vejetaryen", 15, 35, 4, ["Nohut", "Soğan", "Biber", "Domates", "Havuç", "Zeytinyağı", "Kimyon", "Kekik", "Tuz"], ["Nohutu bir gece önceden ıslatın ve haşlayın.", "Soğan ve biberi doğrayıp zeytinyağında kavurun.", "Doğranmış domates ve havucu ekleyin.", "Haşlanmış nohutu ve baharatları ilave edin.", "30 dk kısık ateşte pişirin."], 280, "14g", "42g", "8g"),
        ("Köfte ve Patates", "cocuk_dostu", 20, 30, 4, ["Kıyma", "Soğan", "Galeta unu", "Yumurta", "Patates", "Sıvı yağ", "Tuz", "Karabiber", "Kimyon"], ["Kıymaya rendelenmiş soğan, yumurta ve galeta ununu ekleyin.", "Baharatları katıp yoğurun ve köfte şekli verin.", "Patatesleri dilimleyip yağlanmış tepsiye dizin.", "Köfteleri patateslerin aralarına yerleştirin.", "180 derece fırında 30 dk pişirin."], 450, "28g", "35g", "22g"),
        ("Tost Makinesinde Tavuk Dürüm", "hizli_yemek", 5, 5, 1, ["Lavaş", "Tavuk göğsü", "Marul", "Domates", "Mayonez", "Ketçap"], ["Tavuk göğsünü jülyen doğrayıp az yağda kavurun.", "Lavaşı ısıtın.", "Lavaşın üzerine marul, domates ve tavuk parçalarını koyun.", "Mayonez ve ketçap ekleyip sarın.", "Tost makinesinde 2-3 dk ısıtıp servis yapın."], 380, "25g", "40g", "12g"),
        ("Kuru Fasulye", "geleneksel", 20, 45, 6, ["Kuru fasulye", "Soğan", "Biber salçası", "Domates salçası", "Sıvı yağ", "Tuz", "Karabiber"], ["Fasulyeyi bir gece önceden ıslatın.", "Tencerede haşlayıp suyunu süzün.", "Soğanı yemeklik doğrayıp yağda kavurun.", "Salçaları ekleyip kokusu çıkana kadar kavurun.", "Haşlanmış fasulyeyi ve suyunu ekleyip 30 dk pişirin."], 320, "18g", "48g", "6g"),
    ]
    
    extra_titles = [
        ("Karnıyarık", "aksam_yemegi", 25, 40, 4), ("Mantı", "geleneksel", 45, 30, 6),
        ("Pilav", "ogle_yemegi", 5, 20, 4), ("Ezogelin Çorbası", "ramazan", 10, 25, 6),
        ("Taze Fasulye Yemeği", "vejetaryen", 15, 30, 4), ("Kumpir", "atistirmalik", 10, 45, 2),
        ("Börek", "kahvalti", 20, 35, 6), ("Mücver", "atistirmalik", 15, 20, 4),
        ("Karnabahar Kızartması", "vejetaryen", 15, 25, 4), ("Lahana Sarması", "geleneksel", 40, 50, 8),
        ("Türlü", "diyet", 20, 35, 4), ("Kabak Mücveri", "diyet", 15, 20, 4),
        ("Yumurtalı Ekmek", "kahvalti", 5, 10, 2), ("Pankek", "cocuk_dostu", 10, 15, 4),
        ("Waffle", "tatli", 15, 10, 2), ("Fırında Makarna", "cocuk_dostu", 15, 25, 4),
        ("Balık Izgara", "diyet", 15, 15, 2), ("Sebze Çorbası", "diyet", 10, 25, 4),
        ("Gözleme", "hizli_yemek", 15, 15, 2), ("Pizza", "cocuk_dostu", 20, 20, 4),
        ("Kadayıf", "tatli", 20, 30, 6), ("Baklava", "tatli", 60, 40, 12),
        ("Revani", "tatli", 15, 30, 8), ("Helva", "tatli", 10, 20, 8),
        ("Dondurma", "tatli", 10, 0, 4), ("Aşure", "tatli", 30, 45, 10),
        ("Güllaç", "ramazan", 20, 0, 6), ("Höşmerim", "tatli", 15, 15, 4),
        ("Lokma", "tatli", 20, 20, 8), ("Şekerpare", "tatli", 20, 25, 8),
    ]
    
    all_templates = recipe_templates + [
        (title, cat, pt, ct, sv, ["Malzeme 1", "Malzeme 2", "Malzeme 3", "Malzeme 4", "Malzeme 5"],
         ["Adım 1: Malzemeleri hazırlayın.", "Adım 2: Pişirme işlemine başlayın.", "Adım 3: Baharatları ekleyin.",
          "Adım 4: Kısık ateşte pişirin.", "Adım 5: Sıcak servis yapın."], 350, "20g", "40g", "15g")
        for title, cat, pt, ct, sv in extra_titles
    ]
    
    idx = 0
    for cat, count in categories.items():
        for i in range(count):
            template = all_templates[idx % len(all_templates)]
            r = {
                "id": f"recipe_{idx+1:03d}",
                "title": template[0],
                "category": cat,
                "difficulty": random.choice(["kolay", "orta", "zor"]),
                "prep_time": template[2],
                "cook_time": template[3],
                "servings": template[4],
                "ingredients": [{"name": ing, "amount": str(random.randint(1, 300)), "unit": random.choice(["gr", "adet", "yemek kaşığı", "su bardağı"]), "optional": random.random() > 0.8} for ing in template[5]],
                "instructions": template[6],
                "nutrition": {"calories": template[7], "protein": template[8], "carbs": template[9], "fat": template[10]},
                "tips": ["Taze malzemeler kullanın.", "Çocuklar için az baharatlı yapabilirsiniz.", "Yanında salata ile servis edin."],
                "tags": [cat, random.choice(["hizli", "saglikli", "ekonomik", "cocuk_dostu"])],
                "image_prompt": f"Traditional Turkish {template[0]} beautifully plated, food photography, warm lighting",
                "rating": round(random.uniform(4.0, 5.0), 1),
                "review_count": random.randint(50, 500)
            }
            recipes.append(r)
            idx += 1
    return recipes

# ============== TRAVEL ==============
def generate_travel():
    destinations = [
        ("Kapadokya", "Nevşehir", "turkiye", 38.6431, 34.8289, "orta", "2-3 gün", 3, 99),
        ("Pamukkale", "Denizli", "turkiye", 37.9165, 29.1165, "ekonomik", "1-2 gün", 3, 99),
        ("Efes Antik Kenti", "İzmir", "turkiye", 37.9490, 27.3640, "ekonomik", "1 gün", 5, 99),
        ("Ayvalık", "Balıkesir", "turkiye", 39.3163, 26.6914, "orta", "2-3 gün", 0, 99),
        ("Bodrum", "Muğla", "turkiye", 37.0344, 27.4305, "luks", "3-5 gün", 0, 99),
        ("Antalya", "Antalya", "turkiye", 36.8969, 30.7133, "orta", "3-5 gün", 0, 99),
        ("Karadeniz Yaylaları", "Rize", "turkiye", 41.0205, 40.5236, "ekonomik", "2-3 gün", 3, 99),
        ("Safranbolu", "Karabük", "turkiye", 41.2498, 32.6832, "ekonomik", "1-2 gün", 3, 99),
        ("Göbeklitepe", "Şanlıurfa", "turkiye", 37.2231, 38.9223, "ekonomik", "1 gün", 5, 99),
        ("Van Gölü", "Van", "turkiye", 38.5012, 43.3727, "ekonomik", "2-3 gün", 3, 99),
        ("Paris", "Paris", "avrupa", 48.8566, 2.3522, "luks", "4-5 gün", 3, 99),
        ("Roma", "Roma", "avrupa", 41.9028, 12.4964, "orta", "3-4 gün", 3, 99),
        ("Barselona", "Barselona", "avrupa", 41.3851, 2.1734, "orta", "3-4 gün", 2, 99),
        ("Amsterdam", "Amsterdam", "avrupa", 52.3676, 4.9041, "orta", "2-3 gün", 3, 99),
        ("Tokyo", "Tokyo", "asya", 35.6762, 139.6503, "luks", "5-7 gün", 3, 99),
        ("Bali", "Bali", "asya", -8.3405, 115.0920, "orta", "5-7 gün", 0, 99),
        ("New York", "New York", "amerika", 40.7128, -74.0060, "luks", "5-7 gün", 3, 99),
        ("Bora Bora", "Polinezya", "okyanusya", -16.5004, -151.7415, "luks", "5-7 gün", 5, 99),
        ("Kızılcahamam", "Ankara", "turkiye", 40.4560, 32.6449, "ekonomik", "1-2 gün", 2, 99),
        ("Marmaris", "Muğla", "turkiye", 36.8565, 28.2602, "orta", "3-5 gün", 0, 99),
    ]
    
    travel = []
    categories = ["turkiye", "avrupa", "asya", "amerika", "afrika", "okyanusya", "plaj", "dag", "sehir", "koy",
                  "tarihi", "macera", "kultur", "cocuk_dostu", "bebek_dostu", "ekonomik", "luks", "kamp",
                  "kisa_hafta_sonu", "uzun_tatil"]
    
    idx = 0
    for cat in categories:
        count = 15
        for i in range(count):
            dest = destinations[idx % len(destinations)]
            t = {
                "id": f"travel_{idx+1:03d}",
                "title": f"{dest[0]}: {random.choice(['Keşif Turu', 'Aile Tatili', 'Macera Rotası', 'Kültür Gezisi', 'Doğa Kaçamağı'])}",
                "destination": dest[0],
                "country": "Türkiye" if dest[2] == "turkiye" else dest[2].capitalize(),
                "city": dest[1],
                "category": cat,
                "coordinates": {"lat": dest[3], "lng": dest[4]},
                "best_season": random.sample(["ilkbahar", "yaz", "sonbahar", "kis"], k=random.randint(1, 3)),
                "duration": dest[6],
                "budget": dest[5],
                "age_suitable": {"min": dest[7], "max": dest[8]},
                "activities": [
                    {"name": "Gezi", "description": "Yerel rehber eşliğinde keşif turu", "duration": "2-3 saat", "cost": "10-30€/kişi", "booking_required": random.choice([True, False]), "maps_location": dest[0]},
                    {"name": "Fotoğraf Turu", "description": "En iyi manzara noktaları", "duration": "1-2 saat", "cost": "0€", "booking_required": False, "maps_location": dest[0]}
                ],
                "tips": ["Erken rezervasyon yapın.", "Rahat ayakkabı giyin.", "Çocuklar için atıştırmalık yanınızda bulundurun."],
                "safety_info": "Genel olarak güvenli bölge.",
                "rating": round(random.uniform(4.0, 5.0), 1),
                "review_count": random.randint(100, 5000)
            }
            travel.append(t)
            idx += 1
    return travel

# ============== INDOOR ==============
def generate_indoor():
    activities = [
        ("Evde Volkan Deneyi", "bilim_deneyleri", 4, 12, "20-30 dk", "kirli"),
        ("Origami Kelebek Yapımı", "el_sanatlari", 5, 99, "15-20 dk", "temiz"),
        ("Karton Kukla Tiyatrosu", "oyun", 3, 10, "45-60 dk", "orta"),
        ("Sulu Boya Manzara", "sanat", 5, 99, "30-45 dk", "kirli"),
        ("Evde Pizza Yapımı", "yemek_yapma", 4, 99, "60-90 dk", "kirli"),
        ("Yoga Seansı", "yoga", 5, 99, "20-30 dk", "temiz"),
        ("Kutu Oyunları Gecesi", "oyun", 6, 99, "60-120 dk", "temiz"),
        ("Kitap Okuma Kulübü", "egitici", 7, 99, "30-60 dk", "temiz"),
        ("Müzik Dinleme Partisi", "muzik", 3, 99, "60 dk", "temiz"),
        ("Dans Etkinliği", "dans", 4, 99, "30-45 dk", "temiz"),
        ("Evde Mini Sinema", "film_gunu", 3, 99, "120 dk", "temiz"),
        ("Bahçe Saksı Boyama", "bahce_ici", 5, 99, "30-45 dk", "kirli"),
        ("Kitaplık Düzenleme", "organizasyon", 10, 99, "60 dk", "orta"),
        ("Fotoğraf Albümü Hazırlama", "fotograf", 8, 99, "45-60 dk", "temiz"),
        ("Günlük Yazma", "yazma", 8, 99, "15-30 dk", "temiz"),
        ("İngilizce Kelime Oyunu", "dil_ogrenme", 7, 99, "20-30 dk", "temiz"),
        ("Scratch ile Kodlama", "programlama", 8, 14, "45-60 dk", "temiz"),
        ("Lego İnşaat Yarışması", "oyun", 4, 12, "60-90 dk", "orta"),
        ("Evde Slime Yapımı", "el_sanatlari", 6, 12, "20-30 dk", "kirli"),
        ("Bitki Yetiştirme", "bahce_ici", 5, 99, "30 dk/gün", "temiz"),
    ]
    
    categories = ["el_sanatlari", "bilim_deneyleri", "yemek_yapma", "oyun", "egitici", "sanat", "muzik", "dans",
                  "yoga", "fitness", "film_gunu", "kitap_kulubu", "bahce_ici", "tamirat", "dekorasyon",
                  "organizasyon", "fotograf", "yazma", "dil_ogrenme", "programlama"]
    
    indoor = []
    idx = 0
    for cat in categories:
        count = 15
        for i in range(count):
            act = activities[idx % len(activities)]
            indoor.append({
                "id": f"indoor_{idx+1:03d}",
                "title": act[0],
                "category": cat,
                "difficulty": random.choice(["kolay", "orta", "zor"]),
                "duration": act[4],
                "age_suitable": {"min": act[2], "max": act[3]},
                "materials": [{"name": f"Malzeme {j+1}", "amount": f"{random.randint(1, 5)} adet", "alternative": f"Alternatif {j+1}"} for j in range(5)],
                "instructions": [f"Adım {j+1}: {random.choice(['Hazırlık yapın.', 'Malzemeleri yerleştirin.', 'İşleme başlayın.', 'Kontrol edin.', 'Tamamlayın.'])}" for j in range(5)],
                "safety_notes": ["Çocuklar ebeveyn gözetiminde yapmalı.", "Malzemeleri ağzınıza almayın.", "Sonrası elleri yıkayın."],
                "fun_factor": random.randint(6, 10),
                "mess_level": act[5],
                "rating": round(random.uniform(4.0, 5.0), 1),
                "review_count": random.randint(50, 500)
            })
            idx += 1
    return indoor

# ============== EDUCATION ==============
def generate_education():
    topics = [
        ("Günlük Matematik Oyunları", "stem", 6, 10),
        ("Renkleri Öğrenme Aktiviteleri", "okul_oncesi", 3, 5),
        ("Okuma Alışkanlığı Geliştirme", "ilkokul", 6, 10),
        ("Bilimsel Deney Setleri", "ortaokul", 10, 14),
        ("Eleştirel Düşünme Atölyesi", "lise", 14, 18),
        ("Robotik Kodlama", "stem", 8, 14),
        ("İngilizce Hikaye Anlatımı", "dil_ogrenimi", 5, 12),
        ("Müzik Aleti Çalma", "muzik_egitimi", 6, 14),
        ("Yüzme Eğitimi", "spor", 5, 12),
        ("Empati ve Duygu Kartları", "sosyal_beceriler", 4, 10),
        ("Duygu Yönetimi Teknikleri", "duygusal_zeka", 5, 12),
        ("Kumbara ve Birikim", "finansal_okuryazarlik", 6, 12),
        ("Geri Dönüşüm Projesi", "cevre_bilinci", 5, 14),
        ("Güvenli İnternet Kullanımı", "dijital_okuryazarlik", 8, 14),
        ("Resim ve Heykel Atölyesi", "sanat_egitimi", 5, 12),
        ("Hafıza Oyunları", "hafiza_gelistirme", 6, 12),
        ("Mindfulness Çocuklar İçin", "odaklanma", 5, 12),
        ("Yaratıcı Yazma", "yaraticilik", 8, 14),
        ("Problem Çözme Stratejileri", "problem_cozme", 8, 14),
        ("Tartışma ve Münazara", "elestirel_dusunme", 12, 18),
    ]
    
    categories = ["okul_oncesi", "ilkokul", "ortaokul", "lise", "stem", "dil_ogrenimi", "muzik_egitimi", "spor",
                  "sosyal_beceriler", "duygusal_zeka", "finansal_okuryazarlik", "cevre_bilinci", "dijital_okuryazarlik",
                  "sanat_egitimi", "hafiza_gelistirme", "odaklanma", "yaraticilik", "problem_cozme", "elestirel_dusunme", "liderlik"]
    
    education = []
    idx = 0
    for cat in categories:
        count = 15
        for i in range(count):
            topic = topics[idx % len(topics)]
            education.append({
                "id": f"edu_{idx+1:03d}",
                "title": topic[0],
                "category": cat,
                "age_group": {"min": topic[2], "max": topic[3]},
                "development_area": [cat, random.choice(["odaklanma", "yaraticilik", "problem_cozme", "sosyal_beceriler"])],
                "learning_objectives": ["Beceri geliştirme", "Özgüven artırma", "Eğlenceli öğrenme"],
                "duration": random.choice(["15 dk/gün", "30 dk/gün", "45 dk/hafta", "1 saat/hafta"]),
                "frequency": random.choice(["günlük", "haftada 3 kez", "haftada 5 kez"]),
                "materials": [{"name": f"Malzeme {j+1}", "purpose": "Eğitim için", "alternative": f"Alternatif {j+1}"} for j in range(3)],
                "steps": [f"Adım {j+1}: {random.choice(['Konuyu tanıtın.', 'Örnek gösterin.', 'Çocuğa uygulatın.', 'Pekiştirin.', 'Değerlendirin.'])}" for j in range(5)],
                "parent_tips": ["Sabırlı olun.", "Pozitif pekiştirme verin.", "Günlük rutine ekleyin."],
                "rating": round(random.uniform(4.0, 5.0), 1),
                "review_count": random.randint(50, 300)
            })
            idx += 1
    return education

# ============== FAMILY ==============
def generate_family():
    activities = [
        ("Pazar Kahvaltısı ve Bisiklet Turu", "hafta_sonu", "3-4 saat", "az", "disarisi"),
        ("Kamp ve Doğa Yürüyüşü", "tatil", "2-3 gün", "orta", "dogada"),
        ("Aile Oyun Gecesi", "aksam_aktivitesi", "2-3 saat", "az", "evde"),
        ("Sabah Yürüyüşü ve Kahve", "sabah_rutini", "1-2 saat", "az", "disarisi"),
        ("Plaj ve Deniz Keyfi", "tatil", "1 gün", "orta", "disarisi"),
        ("Müze Gezisi", "kultur", "3-4 saat", "az", "disarisi"),
        ("Orman Pikniği", "dogada", "4-5 saat", "az", "disarisi"),
        ("Film ve Patlamış Mısır Gecesi", "evde", "2-3 saat", "az", "evde"),
        ("Yemek Yapma Yarışması", "yemek_etkinlikleri", "2-3 saat", "az", "evde"),
        ("Kartondan Şehir Yapımı", "evde", "2-3 saat", "az", "evde"),
        ("Gönüllülük Etkinliği", "gonulluluk", "3-4 saat", "az", "disarisi"),
        ("Bayram Ziyaretleri", "geleneksel", "1 gün", "orta", "disarisi"),
        ("Yeni Spor Denemesi", "spor", "1-2 saat", "az", "disarisi"),
        ("Yıldızları İzleme", "gezi", "2-3 saat", "az", "dogada"),
        ("Çadır Kampı", "kamp", "1-2 gece", "orta", "dogada"),
        ("Piknik ve Oyun Parkı", "piknik", "3-4 saat", "az", "disarisi"),
        ("Aile Müzik Gecesi", "muzik_gunu", "2 saat", "az", "evde"),
        ("Sanat Sergisi Ziyareti", "sanat_gunu", "2-3 saat", "az", "disarisi"),
        ("Yeni Restoran Deneyimi", "yemek_etkinlikleri", "2-3 saat", "orta", "disarisi"),
        ("Maraton ve Yürüyüş", "spor", "3-4 saat", "az", "disarisi"),
    ]
    
    categories = ["hafta_sonu", "tatil", "aksam_aktivitesi", "sabah_rutini", "spor", "kultur", "dogada", "evde",
                  "disarda", "yemek_etkinlikleri", "oyun_gunu", "film_gunu", "gezi", "kamp", "piknik",
                  "muzik_gunu", "sanat_gunu", "gonulluluk", "geleneksel", "yeni_denemeler"]
    
    family = []
    idx = 0
    for cat in categories:
        count = 15
        for i in range(count):
            act = activities[idx % len(activities)]
            family.append({
                "id": f"family_{idx+1:03d}",
                "title": act[0],
                "category": cat,
                "bonding_level": random.randint(7, 10),
                "fun_factor": random.randint(7, 10),
                "cost": act[3],
                "duration": act[2],
                "planning_time": random.randint(5, 30),
                "age_suitable": {"min": 3, "max": 99},
                "participant_count": {"min": 2, "max": 8},
                "location_type": act[4],
                "season": random.sample(["ilkbahar", "yaz", "sonbahar", "kis"], k=random.randint(1, 4)),
                "weather_dependency": random.choice([True, False]),
                "materials_needed": [{"item": f"Malzeme {j+1}", "quantity": f"{random.randint(1, 4)} adet", "estimated_cost": "0-10€"} for j in range(3)],
                "preparation_steps": ["Plan yapın.", "Malzemeleri hazırlayın.", "Güzergahı belirleyin.", "Güneş kremi alın.", "İlk yardım çantası hazırlayın."],
                "activity_flow": ["08:00 - Başlangıç", "10:00 - Ana aktivite", "12:00 - Mola", "14:00 - Devam", "16:00 - Bitiş"],
                "conversation_starters": ["Bugün en güzel anın neydi?", "Bir dahaki sefere ne yapalım?", "Bugün ne öğrendin?"],
                "rating": round(random.uniform(4.0, 5.0), 1),
                "review_count": random.randint(100, 1000)
            })
            idx += 1
    return family

# ============== HOME ==============
def generate_home():
    projects = [
        ("Akıllı Telefon Şarj İstasyonu Yapımı", "organizasyon", "kolay", "30-45 dk", "10-20€"),
        ("Banyo Dolabı Düzenleme", "organizasyon", "kolay", "1-2 saat", "20-50€"),
        ("Duvar Resmi Boyama", "dekorasyon", "orta", "2-3 saat", "30-60€"),
        ("Musluk Tamiri", "tamirat", "orta", "30-60 dk", "10-30€"),
        ("Mini Sebze Bahçesi", "bahce", "kolay", "2-3 saat", "20-40€"),
        ("Mutfak Rafı Düzenleme", "mutfak", "kolay", "1-2 saat", "30-80€"),
        ("Çocuk Odası Depolama Çözümleri", "cocuk_odasi", "kolay", "2-4 saat", "50-150€"),
        ("Yatak Odası Aydınlatma Değişimi", "yatak_odasi", "kolay", "1 saat", "40-100€"),
        ("Salon Duvar Rafı Montajı", "salon", "orta", "1-2 saat", "40-80€"),
        ("Giriş Alanı Paspas ve Raf", "giris", "kolay", "1-2 saat", "30-70€"),
        ("Giysi Dolabı Organizasyonu", "depolama", "kolay", "2-3 saat", "20-60€"),
        ("Kapı Kilidi Değişimi", "guvenlik", "orta", "30-60 dk", "30-80€"),
        ("Akıllı Ampul Kurulumu", "akilli_ev", "kolay", "15-30 dk", "50-150€"),
        ("Pencere Ses Yalıtımı", "ses_yalitimi", "orta", "2-4 saat", "40-100€"),
        ("LED Şerit Işıklandırma", "isiklandirma", "kolay", "1-2 saat", "20-50€"),
        ("Duvar Boyama", "boyama", "orta", "4-6 saat", "50-150€"),
        ("Kitaplık Montajı", "mobilya", "orta", "2-3 saat", "80-200€"),
        ("Geri Dönüşüm Kutusu Yapımı", "geri_donusum", "kolay", "30-60 dk", "0-10€"),
        ("Balkon Süsleme", "bahce", "kolay", "2-3 saat", "30-80€"),
        ("Mutfak Tezgahı Düzenleme", "mutfak", "kolay", "1-2 saat", "20-50€"),
    ]
    
    categories = ["organizasyon", "temizlik", "dekorasyon", "tamirat", "bahce", "mutfak", "banyo", "cocuk_odasi",
                  "yatak_odasi", "salon", "giris", "depolama", "guvenlik", "enerji_verimliligi", "akilli_ev",
                  "ses_yalitimi", "isiklandirma", "boyama", "mobilya", "geri_donusum"]
    
    home = []
    idx = 0
    for cat in categories:
        count = 15
        for i in range(count):
            proj = projects[idx % len(projects)]
            home.append({
                "id": f"home_{idx+1:03d}",
                "title": proj[0],
                "category": cat,
                "difficulty": proj[2],
                "duration": proj[3],
                "cost": proj[4],
                "impact_level": random.randint(6, 10),
                "tools_needed": [{"tool": f"Alet {j+1}", "alternative": f"Alternatif {j+1}"} for j in range(2)],
                "materials": [{"item": f"Malzeme {j+1}", "quantity": f"{random.randint(1, 5)} adet", "estimated_cost": "5-20€"} for j in range(3)],
                "step_by_step": [f"Adım {j+1}: {random.choice(['Hazırlık yapın.', 'Ölçü alın.', 'Kesim yapın.', 'Monte edin.', 'Test edin.'])}" for j in range(5)],
                "safety_warnings": ["Elektrikli aletleri dikkatli kullanın.", "Çocukları uzak tutun.", "Maske ve gözlük takın."],
                "family_involvement": {"suitable_for_kids": random.choice([True, False]), "kid_tasks": ["Taşıma", "Boyama", "Temizlik"], "adult_supervision_required": True},
                "rating": round(random.uniform(4.0, 5.0), 1),
                "review_count": random.randint(50, 500)
            })
            idx += 1
    return home

# ============== MAIN ==============
def main():
    print("🤖 Content generation started...")
    
    print("📦 Generating recipes (300 items)...")
    recipes = generate_recipes()
    with open(f"{OUTPUT_DIR}/recipes.json", "w", encoding="utf-8") as f:
        json.dump(recipes, f, ensure_ascii=False, indent=2)
    print(f"  ✅ {len(recipes)} recipes generated")
    
    print("📦 Generating travel (300 items)...")
    travel = generate_travel()
    with open(f"{OUTPUT_DIR}/travel.json", "w", encoding="utf-8") as f:
        json.dump(travel, f, ensure_ascii=False, indent=2)
    print(f"  ✅ {len(travel)} travel items generated")
    
    print("📦 Generating indoor (300 items)...")
    indoor = generate_indoor()
    with open(f"{OUTPUT_DIR}/indoor.json", "w", encoding="utf-8") as f:
        json.dump(indoor, f, ensure_ascii=False, indent=2)
    print(f"  ✅ {len(indoor)} indoor items generated")
    
    print("📦 Generating education (300 items)...")
    education = generate_education()
    with open(f"{OUTPUT_DIR}/education.json", "w", encoding="utf-8") as f:
        json.dump(education, f, ensure_ascii=False, indent=2)
    print(f"  ✅ {len(education)} education items generated")
    
    print("📦 Generating family (300 items)...")
    family = generate_family()
    with open(f"{OUTPUT_DIR}/family.json", "w", encoding="utf-8") as f:
        json.dump(family, f, ensure_ascii=False, indent=2)
    print(f"  ✅ {len(family)} family items generated")
    
    print("📦 Generating home (300 items)...")
    home = generate_home()
    with open(f"{OUTPUT_DIR}/home.json", "w", encoding="utf-8") as f:
        json.dump(home, f, ensure_ascii=False, indent=2)
    print(f"  ✅ {len(home)} home items generated")
    
    total = len(recipes) + len(travel) + len(indoor) + len(education) + len(family) + len(home)
    print(f"\n🎉 DONE! Total items generated: {total}")
    print(f"📁 Output directory: {OUTPUT_DIR}")

if __name__ == "__main__":
    main()
