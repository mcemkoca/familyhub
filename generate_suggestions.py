import json
import os

# Base suggestion template
SUGGESTION_TEMPLATE = {
    "module": "",
    "version": "1.0.0",
    "language": "tr",
    "region": "TR",
    "suggestions": []
}

# Helper to build a suggestion
def build_suggestion(sid, title, description, category, difficulty="Kolay", duration=15, participants=4, tags=None, tips=None, action_type="show_detail"):
    return {
        "id": sid,
        "title": title,
        "description": description,
        "category": category,
        "difficulty": difficulty,
        "duration_minutes": duration,
        "participants": participants,
        "tags": tags or [category],
        "tips": tips or ["Ailece yapılan her şey daha keyifli!"],
        "action_type": action_type
    }

# ──────────────────────────────────────────────────────────────────────────────
# 1. AİLE İLETİŞİMİ (100)
# ──────────────────────────────────────────────────────────────────────────────
def build_family_communication():
    base = [
        ("Günün Özeti Sohbeti", "Akşam yemeğinde herkes gününün en güzel anını anlatsın.", 20, ["iletişim", "günlük rutin"], ["Aktif dinlemeye özen gösterin.", "Yargılamadan dinlemek bağları güçlendirir."]),
        ("Teşekkür Rutini", "Her akşam bir ailenize teşekkür edin.", 5, ["iletişim", "minnettarlık"], ["Küçük teşekkürler büyük fark yaratır."]),
        ("Haftalık Aile Toplantısı", "Haftanın planını, sorunları ve kutlamaları konuşun.", 30, ["iletişim", "planlama"], ["Herkesin söz hakkı olsun.", "Not alın, kararları takip edin."]),
        ("Duygu Kartları Oyunu", "Kart çekip o duyguyu ifade edin, neden hissettiğinizi anlatın.", 15, ["iletişim", "duygusal zeka"], ["Çocuklar için özellikle faydalıdır."]),
        ("Rahatsız Eden Konuları Konuş", "Birikmeyen, açıkça konuşulan sorunlar daha kolay çözülür.", 25, ["iletişim", "çatışma çözümü"], [""""Ben"" dili kullanın: ""Ben şunu hissediyorum..."""]),
        ("Aile Gazetesi", "Herkes bir haber yazsın, haftalık gazete oluşturun.", 45, ["iletişim", "yaratıcılık"], ["Çocukların yazma becerisini geliştirir."]),
        ("Birlikte Müzik Dinleme", "Herkes sevdiği bir şarkıyı seçip neden sevdiğini anlatsın.", 20, ["iletişim", "müzik"], ["Farklı zevkleri saygıyla dinleyin."]),
        ("Anlat-Bakalım Oyunu", "Bir olayı farklı bakış açılarından anlatın.", 15, ["iletişim", "empati"], ["Empati kurma yeteneğini geliştirir."]),
        ("Aile Sözleşmesi", "Ev kurallarını birlikte belirleyip imzalayın.", 30, ["iletişim", "kurallar"], ["Çocuklar da kural önermeli."]),
        ("Gülümseme Günü", "Bugün herkes birbirine en az 3 kez gülümsesin.", 0, ["iletişim", "pozitiflik"], ["Beden dili iletişimin %55'ini oluşturur."]),
        ("Sessiz Kahvaltı", "Bazen sessizce bir arada olmak da iletişimdir.", 20, ["iletişim", "huzur"], ["Sessizlik de bağ kurar."]),
        ("Rüya Paylaşımı", "Sabah kalkınca rüyalarınızı anlatın.", 10, ["iletişim", "yaratıcılık"], ["Rüyalar yaratıcılığı tetikler."]),
        ("Aile Münazarası", "Bir konu seçin, tartışın, jüri oylasın.", 40, ["iletişim", "eleştirel düşünme"], ["Fikirlere saygı, kişilere değil."]),
        ("Hatırlatma Notları", "Buzdolabına sevgi dolu notlar yapıştırın.", 5, ["iletişim", "sevgi"], ["Küçük jestler büyük etki yaratır."]),
        ("Birlikte Yemek Yapmak", "Yemek hazırlarken sohbet edin, iş bölümü yapın.", 60, ["iletişim", "yemek"], ["Ortak aktiviteler bağı güçlendirir."]),
        ("Kutlama Gelenekleri", "Başarıları küçük de olsa kutlayın.", 15, ["iletişim", "kutlama"], ["Takdir edilmek motivasyonu artırır."]),
        ("Aile Fotoğraf Anıları", "Eski fotoğraflara bakıp anıları paylaşın.", 30, ["iletişim", "anılar"], ["Geçmişi paylaşmak kimliği güçlendirir."]),
        ("Teknolojisiz Yemek", "Yemek sırasında telefon yasak.", 30, ["iletişim", "dijital denge"], ["Göz teması kurmak önemlidir."]),
        ("Özür Dileme Pratiği", "Hata yapan samimi özür dilesin.", 5, ["iletişim", "samimiyet"], ["Özür dilemek güçlülük göstergesidir."]),
        ("Gelecek Hayalleri", "Herkes 5 yıl sonra kendini nerede görüyor anlatsın.", 25, ["iletişim", "hedefler"], ["Hayalleri paylaşmak onları gerçekleştirmeye yaklaştırır."]),
    ]
    # Generate 100 by rotating tips and adding variations
    suggestions = []
    prefixes = ["", "Bugün ", "Bu Hafta ", "Ailece ", "Herkesle "]
    for i in range(100):
        b = base[i % len(base)]
        title = (prefixes[i % len(prefixes)] + b[0]).strip()
        desc = b[1]
        tips = b[4]
        # Vary duration slightly
        dur = b[2] + (i % 3) * 5
        tags = b[3]
        suggestions.append(build_suggestion(f"fc{i+1:03d}", title, desc, "communication", duration=dur, tags=tags, tips=tips))
    return suggestions

# ──────────────────────────────────────────────────────────────────────────────
# 2. SAĞLIKLI YAŞAM (100)
# ──────────────────────────────────────────────────────────────────────────────
def build_healthy_living():
    base = [
        ("Sabah Esneme Rutini", "Yataktan kalkınca 5 dk esneme hareketleri.", 5, ["sağlık", "spor"], ["Sırt ve boyun ağrılarını önler."]),
        ("Günlük Su Takibi", "Herkes 8 bardak su içsin, takip edin.", 0, ["sağlık", "su"], ["Su şişenizi yanınızda taşıyın."]),
        ("Akşam Yürüyüşü", "Yemekten sonra 20 dk hafif yürüyüş.", 20, ["sağlık", "yürüyüş"], ["Sindirimi hızlandırır."]),
        ("Sebze Günü", "Bugün her öğünde farklı renkte sebze olsun.", 0, ["sağlık", "beslenme"], ["Renkli tabak = vitaminli tabak."]),
        ("Dijital Detoks", "2 saat telefonsuz aile zamanı.", 120, ["sağlık", "zihinsel"], ["Göz yorgunluğunu azaltır."]),
        ("Meditasyon Zamanı", "5 dk nefes egzersizi, sessizlik.", 5, ["sağlık", "zihinsel"], ["Stres hormonunu düşürür."]),
        ("Evde Dans Partisi", "Enerjik müziklerle 20 dk dans.", 20, ["sağlık", "egzersiz"], ["Kalori yakmak hiç bu kadar eğlenceli olmamıştı."]),
        ("Uyku Rutini", "Herkes aynı saatte yatağa, kitap okuyun.", 30, ["sağlık", "uyku"], ["Düzenli uyku bağışıklığı güçlendirir."]),
        ("Vitamin Deposu Smoothie", "Ispanak, muz, elma, yoğurt karışımı.", 10, ["sağlık", "beslenme"], ["Çocuklar renkli smoothie'leri sever."]),
        ("Ekran Molası", "Her saat başı 10 dk göz egzersizi.", 10, ["sağlık", "göz"], ["20-20-20 kuralı: Her 20 dk'da 20 saniye 20 metre öteye bakın."]),
        ("Aile Yoga Seansı", "YouTube videosuyla birlikte yoga.", 20, ["sağlık", "yoga"], ["Esneklik ve dengeyi artırır."]),
        ("Evde Step Sayma", "Telefonu cebde bırakın, 5000 adım hedef.", 45, ["sağlık", "yürüyüş"], ["Merdiven çıkmak ekstra kalori yaktırır."]),
        ("Sağlıklı Atıştırmalık", "Cips yerine kuruyemiş, meyve.", 5, ["sağlık", "beslenme"], ["Kuru yemişleri porsiyonlayın."]),
        ("Aile Bisiklet Turu", "Haftada bir kez, 5 km bisiklet.", 30, ["sağlık", "bisiklet"], ["Kask takmayı unutmayın."]),
        ("Duruş Düzeltme Egzersizi", "Sırt, boyun, omuz egzersizleri.", 10, ["sağlık", "postür"], ["Masa başı çalışanlar için özellikle önemli."]),
        ("Güneş Işığı Alma", "Balkonda 15 dk güneş, D vitamini.", 15, ["sağlık", "vitamin"], ["Güneş kremi unutmayın."]),
        ("Aile Koşusu", "Parkta hafif tempolu koşu.", 20, ["sağlık", "koşu"], ["Isınma hareketlerini atlamayın."]),
        ("Şeker Detoksu", "Bugün hiç şekerli gıda yemeyin.", 0, ["sağlık", "beslenme"], ["Meyve ile tatlı krizini bastırabilirsiniz."]),
        ("Aile Masaj Günü", "Omuz, sırt masajı, gevşeme.", 20, ["sağlık", "gevşeme"], ["Masaj yağı kullanın."]),
        ("Bağışıklık Çayı", "Zencefil, zerdeçal, bal, limon çayı.", 10, ["sağlık", "bağışıklık"], ["Günde 2 fincan ideal."]),
    ]
    suggestions = []
    prefixes = ["", "Bugün ", "Bu Hafta ", "Ailece ", "Herkesle ", "Sabah ", "Akşam "]
    for i in range(100):
        b = base[i % len(base)]
        title = (prefixes[i % len(prefixes)] + b[0]).strip()
        dur = b[2] + (i % 4) * 5
        suggestions.append(build_suggestion(f"hl{i+1:03d}", title, b[1], "health", duration=dur, tags=b[3], tips=b[4]))
    return suggestions

# ──────────────────────────────────────────────────────────────────────────────
# 3. ÇOCUK GELİŞİMİ (100)
# ──────────────────────────────────────────────────────────────────────────────
def build_child_development():
    base = [
        ("Birlikte Puzzle Yap", "500 parça puzzle, ailece çözün.", 120, ["çocuk", "zeka"], ["Sabit bir masada çalışın."]),
        ("Bilgi Yarışması", "Tarih, coğrafya, bilim soruları.", 30, ["çocuk", "bilgi"], ["Yaş gruplarına göre soru hazırlayın."]),
        ("Yeni Kelime Öğren", "Herkes 3 İngilizce kelime öğrensin.", 15, ["çocuk", "dil"], ["Gün içinde o kelimeleri kullanın."]),
        ("Birlikte Deney Yap", "Basit kimya/fizik deneyleri.", 45, ["çocuk", "fen"], ["Güvenlik önlemlerini atlamayın."]),
        ("Harita Çalışması", "Dünya haritasında ülkeler bulun.", 20, ["çocuk", "coğrafya"], ["Bayrakları da öğrenin."]),
        ("Aile Gazetesi", "Herkes bir haber yazsın, gazete yapın.", 60, ["çocuk", "yazma"], ["Resimli haberler daha eğlenceli."]),
        ("Müzik Enstrümanı Dene", "Ukulele, kaval veya ritim.", 30, ["çocuk", "müzik"], ["Sabırlı olun, herkes farklı hızda öğrenir."]),
        ("Hayvan Belgeseli", "Eğitici belgesel izleyin, tartışın.", 45, ["çocuk", "doğa"], ["Sonra kendi gözlemlerini anlatmalarını isteyin."]),
        ("Ders Tekrarı", "Çocukların konusunu birlikte tekrar edin.", 30, ["çocuk", "ders"], ["Öğretmek en iyi öğrenme yöntemidir."]),
        ("Zeka Oyunları", "Satranç, mangala, reversi.", 40, ["çocuk", "strateji"], ["Kaybetmeyi de öğretin."]),
        ("Hafıza Oyunu", "Eşya dizin, 1 dk sonra hatırlatın.", 15, ["çocuk", "hafıza"], ["Zorluk seviyesini artırın."]),
        ("Dünya Mutfakları", "Her hafta farklı ülke yemeği.", 60, ["çocuk", "kültür"], ["O ülkenin bayrağını da çizin."]),
        ("Aile Defteri", "Bugün neler yaptık, hissettik? Yazın.", 15, ["çocuk", "yazma"], ["Çocuklar resim de yapabilir."]),
        ("Birlikte Programlama", "Scratch veya kodlama uygulaması.", 45, ["çocuk", "kodlama"], ["Basit animasyonlarla başlayın."]),
        ("Geometri Origami", "Kağıt katlama, şekiller öğrenin.", 30, ["çocuk", "matematik"], ["Renkli kağıtlar kullanın."]),
        ("Tarih Konulu Oyun", "Osmanlı, Cumhuriyet bilgi yarışması.", 30, ["çocuk", "tarih"], ["Kostümler giyin, daha eğlenceli olur."]),
        ("Fen Bilgisi Projesi", "Volkan deneyi, bitki büyütme.", 60, ["çocuk", "proje"], ["Günlük gözlem kaydı tutun."]),
        ("Astronomi Gecesi", "Ay, gezegenleri tanıyın, uygulama kullanın.", 45, ["çocuk", "uzay"], ["Teleskop varsa kullanın."]),
        ("Dil Öğrenme Uygulaması", "Duolingo, herkes 1 ünite tamamlasın.", 20, ["çocuk", "dil"], ["Birlikte yarışın."]),
        ("Matematik Oyunu", "Mental aritmetik, zamanlı yarışma.", 15, ["çocuk", "matematik"], ["Günlük hayattan örnekler kullanın."]),
    ]
    suggestions = []
    prefixes = ["", "Bugün ", "Bu Hafta Sonu ", "Ailece ", "Çocuklarla ", "Akşam "]
    for i in range(100):
        b = base[i % len(base)]
        title = (prefixes[i % len(prefixes)] + b[0]).strip()
        dur = b[2] + (i % 5) * 5
        suggestions.append(build_suggestion(f"cd{i+1:03d}", title, b[1], "education", duration=dur, tags=b[3], tips=b[4]))
    return suggestions

# ──────────────────────────────────────────────────────────────────────────────
# 4. EV DÜZENİ (100)
# ──────────────────────────────────────────────────────────────────────────────
def build_home_organization():
    base = [
        ("Dolap Düzenleme", "Giyilmeyenleri ayırın, bağış yapın.", 45, ["ev", "düzen"], ["Mevsimlere göre ayırın."]),
        ("Buzdolabı Temizliği", "Bozulmuşları atın, raf düzeni yapın.", 30, ["ev", "mutfak"], ["Son kullanma tarihlerini kontrol edin."]),
        ("Kitaplık Düzenleme", "Kitapları kategoriye göre sıralayın.", 30, ["ev", "kitap"], ["Okunmayanları bağışlayın."]),
        ("Balkon Düzenleme", "Saksıları yeniden dizayn edin, süpürün.", 40, ["ev", "balkon"], ["Vertikal bahçe düşünün."]),
        ("Fotoğraf Arşivleme", "Telefondaki fotoğrafları kategorilere ayırın.", 60, ["ev", "dijital"], ["Yedekleme yapmayı unutmayın."]),
        ("Ayakkabı Dolabı", "Eskileri temizleyin veya atın.", 20, ["ev", "dolap"], ["Koku giderici koyun."]),
        ("Çocuk Odası Revizyon", "Oyuncakları sınıflandırın.", 45, ["ev", "çocuk odası"], ["Kırık oyuncakları ayırın."]),
        ("Mutfak Çekmecesi", "Kaşık, çatal, spatula düzenini yenileyin.", 20, ["ev", "mutfak"], ["Çekmece içi düzenleyiciler kullanın."]),
        ("Banyo Rafı Düzenleme", "Şampuan, sabun düzenini kontrol edin.", 15, ["ev", "banyo"], ["Son kullanma tarihlerini atın."]),
        ("Yatak Odası Havalandırma", "Yorganları asın, pencere açın.", 15, ["ev", "yatak odası"], ["Güneşli havada yapın."]),
        ("Garaj / Kiler Kontrolü", "Mevsimlik eşyaları yerleştirin.", 60, ["ev", "depo"], ["Nem önleyici koyun."]),
        ("E-posta ve Fatura Düzeni", "Ödenmemiş faturaları kontrol edin.", 20, ["ev", "evrak"], ["Dijital arşiv oluşturun."]),
        ("Aile Takvimi Güncelleme", "Yaklaşan özel günleri takvime ekleyin.", 15, ["ev", "planlama"], ["Tüm aileye paylaşın."]),
        ("Evcil Hayvan Bakımı", "Kafes, diş, tırnak kontrolü.", 20, ["ev", "hayvan"], ["Veteriner takvimini kontrol edin."]),
        ("Araba İçi Düzenleme", "Eşyaları çıkarın, vakumlayın.", 30, ["ev", "araba"], ["Kokulu süs koyun."]),
        ("Perde ve Yorgan Yıkama", "Büyük çamaşır günü, makineye atın.", 45, ["ev", "çamaşır"], ["Etiket talimatlarını okuyun."]),
        ("Halı ve Kilim Temizliği", "Çırpma, süpürme, leke çıkarma.", 60, ["ev", "temizlik"], ["Güneşte bekletin."]),
        ("Mutfak Dolabı İçi", "Yağlı fırın, dolap içi silme.", 40, ["ev", "mutfak"], ["Doğal temizleyiciler kullanın."]),
        ("Beyaz Eşya Temizliği", "Buzdolabı, çamaşır makinesi, bulaşık makinesi.", 45, ["ev", "bakım"], ["Kireç çözücü kullanın."]),
        ("Pencere Temizliği", "Cam silme, pervaz tozu alma.", 60, ["ev", "temizlik"], ["Gazete kağıdı ile parlaklık artar."]),
    ]
    suggestions = []
    prefixes = ["", "Bugün ", "Bu Hafta ", "Ailece ", "Hafta Sonu "]
    for i in range(100):
        b = base[i % len(base)]
        title = (prefixes[i % len(prefixes)] + b[0]).strip()
        dur = b[2] + (i % 4) * 5
        suggestions.append(build_suggestion(f"ho{i+1:03d}", title, b[1], "chore", duration=dur, tags=b[3], tips=b[4]))
    return suggestions

# ──────────────────────────────────────────────────────────────────────────────
# 5. BÜTÇE YÖNETİMİ (100)
# ──────────────────────────────────────────────────────────────────────────────
def build_budget_management():
    base = [
        ("Market Alışveriş Listesi", "İhtiyaç listesi yapın, gereksiz almayın.", 15, ["bütçe", "market"], ["Açken markete gitmeyin."]),
        ("Enerji Tasarrufu Günü", "Gereksiz ışıkları kapatın, fişleri çekin.", 0, ["bütçe", "fatura"], ["LED ampuller tasarruf sağlar."]),
        ("Ev Yapımı Hediye", "Doğum günü için evde hediye yapın.", 60, ["bütçe", "hediye"], ["Kişiselleştirilmiş hediyeler daha değerlidir."]),
        ("Bütçe Kontrolü", "Bu haftanın harcamalarını gözden geçirin.", 20, ["bütçe", "kontrol"], ["Küçük harcamaları toplayın, şaşıracaksınız."]),
        ("Kumbara Sayımı", "Biriken paraları sayın, hedef belirleyin.", 15, ["bütçe", "birikim"], ["Çocuklara kumbara alışkanlığı kazandırın."]),
        ("Abonelik İnceleme", "Kullanılmayan abonelikleri iptal edin.", 20, ["bütçe", "abonelik"], ["Aylık toplamı hesaplayın."]),
        ("Kupon ve İndirim Takibi", "Haftalık market broşürlerini inceleyin.", 15, ["bütçe", "indirim"], ["Aynı ürünü farklı marketlerde karşılaştırın."]),
        ("Evde Tamir Günü", "Küçük tamirleri kendiniz yapın.", 60, ["bütçe", "tamir"], ["YouTube'dan öğrenin."]),
        ("Aile Harcama Limiti", "Bugün için harcama limiti belirleyin.", 10, ["bütçe", "limit"], ["Nakit kullanmak kontrolü artırır."]),
        ("Birikim Hedefi Belirle", "Ailece tatil, oyun hedefi seçin.", 20, ["bütçe", "hedef"], ["Görsel bir hedef panosu yapın."]),
        ("Yemek Sepeti Analizi", "Son 1 ay yemek siparişi maliyetini hesaplayın.", 15, ["bütçe", "yemek"], ["Ev yemeği çok daha ucuz."]),
        ("Geri Dönüşüm Getirisi", "Kağıt, plastik, cam geri dönüşüm kazancı.", 20, ["bütçe", "geri dönüşüm"], ["Çocuklara çevre bilinci kazandırın."]),
        ("Aile İkinci El Günü", "Kullanılmayan eşyaları satın/takas edin.", 60, ["bütçe", "satış"], ["Fotoğraf çekip online ilan verin."]),
        ("Fatura Karşılaştırma", "Son 3 ay elektrik, su, doğalgaz karşılaştırma.", 20, ["bütçe", "fatura"], ["Tüketim alışkanlıklarınızı analiz edin."]),
        ("Ev Yapımı Temizlik", "Market ürünü yerine sirke, karbonat kullanın.", 30, ["bütçe", "temizlik"], ["Doğal ve ucuz."]),
        ("Aile Borsa Oyunu", "Sanal para ile borsa oynayın, öğrenin.", 30, ["bütçe", "yatırım"], ["Risk almadan öğrenin."]),
        ("Doğum Günü Bütçesi", "Ailece doğum günü bütçesi planlayın.", 20, ["bütçe", "kutlama"], ["Evde parti daha ekonomik."]),
        ("Yakıt Tasarrufu", "Toplu taşıma, yürüyüş, bisiklet günü.", 0, ["bütçe", "ulaşım"], ["Aynı zamanda sağlıklı."]),
        ("Aile Kira Getirisi", "Boş oda, garaj, depo değerlendirin.", 30, ["bütçe", "gelir"], ["Güvenlik kontrolü yapın."]),
        ("Elektrikli Alet Kontrolü", "Eski ampulleri LED ile değiştirin.", 30, ["bütçe", "elektrik"], ["Uzun vadede çok tasarruf."]),
    ]
    suggestions = []
    prefixes = ["", "Bugün ", "Bu Ay ", "Ailece ", "Hafta Sonu "]
    for i in range(100):
        b = base[i % len(base)]
        title = (prefixes[i % len(prefixes)] + b[0]).strip()
        dur = b[2] + (i % 3) * 5
        suggestions.append(build_suggestion(f"bm{i+1:03d}", title, b[1], "finance", duration=dur, tags=b[3], tips=b[4]))
    return suggestions

# ──────────────────────────────────────────────────────────────────────────────
# 6. GÜVENLİK ÖNLEMLERİ (100)
# ──────────────────────────────────────────────────────────────────────────────
def build_safety_measures():
    base = [
        ("Acil Çıkış Planı", "Yangın tatbikatı, toplanma noktası.", 15, ["güvenlik", "yangın"], ["Yılda en az 2 kez tekrarlayın."]),
        ("İlk Yardım Çantası", "Eksik malzemeleri not alın, tamamlayın.", 10, ["güvenlik", "ilk yardım"], ["Son kullanma tarihlerini kontrol edin."]),
        ("Ev Güvenlik Taraması", "Priz kapakları, dolap kilidi kontrolü.", 20, ["güvenlik", "ev"], ["Çocukların ulaşabileceği her yeri kontrol edin."]),
        ("Acil İletişim Listesi", "Önemli numaraları yazın, buzdolabına yapıştırın.", 10, ["güvenlik", "iletişim"], ["112, itfaiye, polis, komşu ekleyin."]),
        ("Bilgisayar Güvenliği", "Şifreleri güncelleyin, çocuklara anlatın.", 20, ["güvenlik", "dijital"], ["İki faktörlü doğrulama açın."]),
        ("Deprem Çantası Kontrolü", "Su, konserve, battaniye, el feneri kontrolü.", 15, ["güvenlik", "deprem"], ["Her üye için ayrı çanta hazırlayın."]),
        ("Gaz Kaçağı Testi", "Kokulu sabun suyu ile bağlantı kontrolü.", 15, ["güvenlik", "gaz"], ["Gaz dedektörü bulundurun."]),
        ("Çocuk İnternet Güvenliği", "Ebeveyn kontrolü, güvenli arama ayarları.", 20, ["güvenlik", "internet"], ["Ortak kullanım alanlarında internet erişimi."]),
        ("Yangın Söndürücü Kontrolü", "Basınç göstergesi, son kullanma tarihi.", 10, ["güvenlik", "yangın"], ["Kullanımını öğrenin."]),
        ("Aile GPS Paylaşımı", "Telefonda konum paylaşımı açık mı kontrol edin.", 10, ["güvenlik", "konum"], ["FamilyHub uygulamasını kullanın."]),
        ("Kimlik Fotokopisi", "Herkesin kimlik fotokopisi ayrı yerde dursun.", 15, ["güvenlik", "evrak"], ["Dijital kopya da bulunsun."]),
        ("Ev Alarm Sistemi Testi", "Sensör, kamera, alarm testi.", 15, ["güvenlik", "alarm"], ["Pilleri kontrol edin."]),
        ("Aile Şifre Protokolü", "Kapı şifresi, telefon şifresi değiştirme.", 15, ["güvenlik", "şifre"], ["Düzenli olarak değiştirin."]),
        ("Bisiklet Kask Kontrolü", "Çocukların kaskı, dizliği, dirsekliği kontrolü.", 10, ["güvenlik", "spor"], ["Kaskın iç etiketini kontrol edin."]),
        ("Ev İlaç Dolabı Kontrolü", "Son kullanma tarihleri, bozulanlar.", 15, ["güvenlik", "sağlık"], ["Çocukların ulaşamayacağı yerde saklayın."]),
        ("Aile Güvenlik Şifresi", "SOS kod kelimesi belirleyin.", 10, ["güvenlik", "acil"], ["Tüm aile bilsin."]),
        ("Duman Dedektörü Testi", "Pil kontrolü, test butonuna basın.", 10, ["güvenlik", "yangın"], ["Her katta bulundurun."]),
        ("Çocuk Kaçırma Eğitimi", "Yabancıyla konuşmama, güvenli yetişkin.", 20, ["güvenlik", "çocuk"], ["Rol yaparak öğretin."]),
        ("Ev Anahtar Yedekleme", "Yedek anahtar komşuda veya kasada.", 10, ["güvenlik", "anahtar"], ["Birkaç yerde yedek bulundurun."]),
        ("Aile Afet Planı", "Deprem, yangın, sel için aile planı.", 30, ["güvenlik", "afet"], ["Toplanma noktası belirleyin."]),
    ]
    suggestions = []
    prefixes = ["", "Bugün ", "Bu Ay ", "Ailece ", "Hafta Sonu "]
    for i in range(100):
        b = base[i % len(base)]
        title = (prefixes[i % len(prefixes)] + b[0]).strip()
        dur = b[2] + (i % 3) * 5
        suggestions.append(build_suggestion(f"sm{i+1:03d}", title, b[1], "safety", duration=dur, tags=b[3], tips=b[4]))
    return suggestions

# ──────────────────────────────────────────────────────────────────────────────
# 7. EĞİTİM DESTEĞİ (100)
# ──────────────────────────────────────────────────────────────────────────────
def build_education_support():
    base = [
        ("Ödev Kontrol Rutini", "Çocukların ödevlerini birlikte gözden geçirin.", 20, ["eğitim", "ödev"], ["Yardım etmek yerine yönlendirin."]),
        ("Okuma Saati", "Her gün 30 dk kitap okuma.", 30, ["eğitim", "okuma"], ["Sesli okuma da yapın."]),
        ("Bilgi Kartları", "Zor konular için kartlar hazırlayın.", 25, ["eğitim", "teknik"], ["Görsel hafıza güçlüdür."]),
        ("Sınav Takvimi", "Yaklaşan sınavları takvime yazın.", 15, ["eğitim", "planlama"], ["Geriye sayım başlatın."]),
        ("Öğretmen Görüşmesi", "Veli toplantısına hazırlık yapın.", 20, ["eğitim", "iletişim"], ["Sorularınızı önceden yazın."]),
        ("Birlikte Öğrenme", "Çocuğunuzun konusunu siz de öğrenin.", 30, ["eğitim", "destek"], ["YouTube eğitim videoları izleyin."]),
        ("Proje Yardımı", "Okul projesinde rehberlik edin, yapmayın.", 45, ["eğitim", "proje"], ["Fikir verin, uygulamayı onlar yapsın."]),
        ("Kütüphane Ziyareti", "Haftada bir kütüphaneye gidin.", 60, ["eğitim", "kütüphane"], ["Kendi kartlarını olsun."]),
        ("Bilim Fuarı Hazırlığı", "Evde mini deneyler yapın.", 40, ["eğitim", "bilim"], ["Günlük gözlem defteri tutun."]),
        ("Yazma Pratiği", "Günlük tutma alışkanlığı kazandırın.", 15, ["eğitim", "yazma"], ["Resimli günlük de olabilir."]),
        ("Matematik Oyunları", "Market hesabı, oran-orantı oyunu.", 20, ["eğitim", "matematik"], ["Günlük hayattan örnekler."]),
        ("Tarih Canlandırma", "Tarihi olayları evde canlandırın.", 35, ["eğitim", "tarih"], ["Kostümler giyin."]),
        ("Dil Pratiği", "Evde belirli saatlerde İngilizce konuşun.", 30, ["eğitim", "dil"], ["Film izleyip altyazısız tekrar edin."]),
        ("Müze Ziyareti", "Sanat veya tarih müzesine gidin.", 120, ["eğitim", "müze"], ["Önceden müze hakkında araştırma yapın."]),
        ("Müzik Eğitimi", "Bir enstrüman çalmayı deneyin.", 30, ["eğitim", "müzik"], ["Ukulele kolay başlangıçtır."]),
        ("Spor Aktivitesi", "Düzenli spor yapma alışkanlığı.", 45, ["eğitim", "spor"], ["Okul takımlarına katılmayı teşvik edin."]),
        ("Sanat Atölyesi", "Resim, seramik, el işi deneyin.", 40, ["eğitim", "sanat"], ["Malzemeleri birlikte seçin."]),
        ("Doğa Gözlemi", "Parkta bitki ve hayvan gözlemi.", 30, ["eğitim", "doğa"], ["Gözlem defteri tutun."]),
        ("Teknoloji Eğitimi", "Güvenli internet kullanımını öğretin.", 20, ["eğitim", "teknoloji"], ["Aile içi kurallar belirleyin."]),
        ("Hedef Belirleme", "Dönemlik hedefler koyun, takip edin.", 20, ["eğitim", "hedef"], ["Ulaşılabilir ve ölçülebilir hedefler."]),
    ]
    suggestions = []
    prefixes = ["", "Bugün ", "Bu Hafta ", "Ailece ", "Çocuklarla "]
    for i in range(100):
        b = base[i % len(base)]
        title = (prefixes[i % len(prefixes)] + b[0]).strip()
        dur = b[2] + (i % 5) * 5
        suggestions.append(build_suggestion(f"es{i+1:03d}", title, b[1], "education", duration=dur, tags=b[3], tips=b[4]))
    return suggestions

# ──────────────────────────────────────────────────────────────────────────────
# 8. YEMEK & BESLENME (100)
# ──────────────────────────────────────────────────────────────────────────────
def build_meal_nutrition():
    base = [
        ("Anne Köftesi (Fırında)", "Közlenmiş biberli, mercimekli. Hem sağlıklı hem doyurucu.", 45, ["yemek", "ana yemek"], ["Malzemeleri önceden hazırlayın."]),
        ("Karnıyarık", "Patlıcanları önceden tuzlayın, acısı çıksın.", 60, ["yemek", "ana yemek"], ["Zeytinyağlı da yapabilirsiniz."]),
        ("Mercimek Çorbası + Tost", "Klasik ama vazgeçilmez. Kızarmış ekmekle.", 30, ["yemek", "çorba"], ["Limon sıkın, lezzet artsın."]),
        ("Fırında Makarna", "Beşamel soslu, bol kaşarlı. Çocuklar bayılır.", 40, ["yemek", "makarna"], ["Farklı peynirler deneyin."]),
        ("Zeytinyağlı Sarma", "Asma yaprağında, pirinçli, bol naneli.", 90, ["yemek", "zeytinyağlı"], ["Yaprakları önceden haşlayın."]),
        ("Ev Pidesi", "Kıymalı, peynirli, kuşbaşılı. Her seferinde farklı.", 75, ["yemek", "hamur işi"], ["Hamuru mayalanmaya bırakın."]),
        ("Tavuk Şiş + Pilav", "Düdüklüde pirinç, ızgarada tavuk.", 35, ["yemek", "ızgara"], ["Marine en az 2 saat beklesin."]),
        ("Kumpir Akşamı", "Fırında patates, herkes kendi malzemesini koysun.", 50, ["yemek", "atıştırmalık"], ["Mısır, zeytin, turşu, kaşar hazır bulundurun."]),
        ("Ev Mantısı", "Kayseri usulü, yoğurtlu, tereyağlı sos.", 120, ["yemek", "hamur işi"], ["Birlikte yapmak eğlenceli."]),
        ("Izgara Çipura + Roka", "Balık ve roka salatası. Hafif ve sağlıklı.", 25, ["yemek", "deniz ürünleri"], ["Limon ve zeytinyağı ile servis edin."]),
        ("Türlü Yemeği", "Biber, patlıcan, kabak, patates; zeytinyağlı.", 40, ["yemek", "zeytinyağlı"], ["Sebzelerin tazesine dikkat edin."]),
        ("Ev Pizzası", "Hamur mayalansın, herkes kendi pizzasına malzeme seçsin.", 90, ["yemek", "pizza"], ["Yüksek ısıda kısa sürede pişirin."]),
        ("Yaprak Sarması", "Zeytinyağlı, nar ekşili, bol dolma fıstığı.", 80, ["yemek", "zeytinyağlı"], ["Sıkı sarmaya dikkat edin."]),
        ("Kurufasulye + Pilav", "Geleneksel ama her zaman güzel. Turşu yanında.", 45, ["yemek", "ana yemek"], ["Düdüklü tencere kullanın."]),
        ("Çöp Şiş (Ev Usulü)", "Marine tavuk, sebzelerle şiş, fırında.", 50, ["yemek", "ızgara"], ["Sebzeleri ayrı şişe takın."]),
        ("Kabak Mücver", "Rendelenmiş kabak, maydanoz, dereotu.", 25, ["yemek", "atıştırmalık"], ["Fazla yağ çekmemesi için kızgın yağda kızartın."]),
        ("Nohutlu Bulgur Pilavı", "Baharatlı nohut, bulgur, soğan kavurması.", 35, ["yemek", "pilav"], ["Tereyağlı kavrulmuş soğan ile servis."]),
        ("Ispanaklı Börek", "El açması veya hazır yufka, bol ıspanak.", 60, ["yemek", "börek"], ["Ispanağı soteleyip suyunu süzün."]),
        ("Ev Yapımı Dondurma", "Muz dondurulup blenderdan geçirilir.", 15, ["yemek", "tatlı"], ["Kakaolu veya çilekli de yapabilirsiniz."]),
        ("Menemen", "Yumurta, domates, biber, soğan. Kahvaltı klasik.", 20, ["yemek", "kahvaltı"], ["Kekirip kıvamında pişirin."]),
    ]
    suggestions = []
    prefixes = ["", "Bugün ", "Bu Akşam ", "Ailece ", "Hafta Sonu "]
    for i in range(100):
        b = base[i % len(base)]
        title = (prefixes[i % len(prefixes)] + b[0]).strip()
        dur = b[2] + (i % 4) * 5
        suggestions.append(build_suggestion(f"mn{i+1:03d}", title, b[1], "recipe", duration=dur, tags=b[3], tips=b[4]))
    return suggestions

# ──────────────────────────────────────────────────────────────────────────────
# 9. SOSYAL AKTİVİTELER (100)
# ──────────────────────────────────────────────────────────────────────────────
def build_social_activities():
    base = [
        ("Aile Oyun Gecesi", "Tabu, kutu oyunları, kart. Kazanan sonrakini seçsin.", 90, ["sosyal", "oyun"], ["Müzik ve atıştırmalık hazır bulundurun."]),
        ("Piknik Planlayın", "En yakın parka battaniye, sandviç ve meyve.", 180, ["sosyal", "piknik"], ["Hava durumunu kontrol edin."]),
        ("Film Maratonu", "Herkes bir film seçsin, popcorn hazırlayın.", 150, ["sosyal", "film"], ["Yaş grubuna uygun filmler seçin."]),
        ("Gezinti Yürüyüşü", "Mahallede veya ormanda 30 dk yürüyüş.", 30, ["sosyal", "doğa"], ["Fotoğraf makinesi götürün."]),
        ("Mangal Keyfi", "Balkonda veya bahçede pratik mangal.", 120, ["sosyal", "mangal"], ["Kömürü önceden hazırlayın."]),
        ("Bisiklet Turu", "Güvenli rotada ailece bisiklet.", 60, ["sosyal", "bisiklet"], ["Kask takmayı unutmayın."]),
        ("Müze Ziyareti", "Çocuklar için etkileşimli müzeler.", 120, ["sosyal", "müze"], ["Önceden internetten araştırma yapın."]),
        ("Aile Fotoğraf Çekimi", "Komik pozlar verin, galeriye ekleyin.", 30, ["sosyal", "fotoğraf"], ["Tripod kullanın."]),
        ("Balkonda Kamp", "Çadır kurun, el feneri hikayeleri.", 60, ["sosyal", "kamp"], ["Yıldız gözlem uygulaması kullanın."]),
        ("Kitap Okuma Saati", "Herkes kendi kitabını okur, özet anlatır.", 45, ["sosyal", "kitap"], ["Sessiz ve rahat bir köşe hazırlayın."]),
        ("Origami Etkinliği", "Kağıttan hayvan, gemi, uçak yapımı.", 40, ["sosyal", "origami"], ["Renkli kağıtlar kullanın."]),
        ("Aile Müzik Gecesi", "Herkes sevdiği şarkıyı söyler.", 60, ["sosyal", "müzik"], ["Karaoke uygulaması kullanın."]),
        ("Hayvanat Bahçesi", "Çocuklarla hayvanları besleyin.", 180, ["sosyal", "hayvanat"], ["Su ve atıştırmalık götürün."]),
        ("Doğa Yürüyüşü", "Hafta sonu trekking parkuru.", 180, ["sosyal", "doğa"], ["Uygun ayakkabı giyin."]),
        ("Aile Yarışması", "Mini olimpiyat: ip atlama, balon patlatma.", 60, ["sosyal", "yarışma"], ["Küçük ödüller hazırlayın."]),
        ("Yıldız İzleme", "Battaniye serin, yıldızları sayın.", 45, ["sosyal", "gökyüzü"], ["Uygulama ile takımyıldızları tanıyın."]),
        ("Boyama Etkinliği", "Mandal, kum boyama, tuval.", 60, ["sosyal", "sanat"], ["Önlük giydirin."]),
        ("Podcast Dinleme", "Eğitici podcast, tartışın.", 30, ["sosyal", "podcast"], ["Herkes farklı bir bölüm seçsin."]),
        ("Yerel Pazara Gitmek", "Semt pazarında taze sebze meyve.", 90, ["sosyal", "pazar"], ["Pazarlık yapmayı öğretin."]),
        ("Aile Vlog Çekimi", "Gününüzü çekin, montaj yapın.", 60, ["sosyal", "vlog"], ["Kısa ve eğlenceli tutun."]),
        ("Kahvaltı Dışarıda", "Ailece brunch, farklı bir mekan.", 90, ["sosyal", "kahvaltı"], ["Rezervasyon yaptırın."]),
        ("Scavenger Hunt", "Evde veya parkta ipuçlu hazine avı.", 60, ["sosyal", "oyun"], ["Ödül hazırlayın."]),
        ("Aile Resim Sergisi", "Çocukların resimlerini duvara asın.", 30, ["sosyal", "sergi"], ["Açılış kokteyli yapın."]),
        ("Gece Yürüyüşü", "Fenerli, güvenli parkta akşam yürüyüşü.", 30, ["sosyal", "yürüyüş"], ["Yansıtıcı aksesuarlar takın."]),
        ("Aile Bingo Gecesi", "Kendiniz kart yapın, ödüller koyun.", 60, ["sosyal", "bingo"], ["Aile içi şakalar içeren kartlar yapın."]),
    ]
    suggestions = []
    prefixes = ["", "Bugün ", "Bu Hafta Sonu ", "Ailece ", "Akşam "]
    for i in range(100):
        b = base[i % len(base)]
        title = (prefixes[i % len(prefixes)] + b[0]).strip()
        dur = b[2] + (i % 5) * 5
        suggestions.append(build_suggestion(f"sa{i+1:03d}", title, b[1], "social", duration=dur, tags=b[3], tips=b[4]))
    return suggestions

# ──────────────────────────────────────────────────────────────────────────────
# 10. DİJİTAL DENGE (100)
# ──────────────────────────────────────────────────────────────────────────────
def build_digital_balance():
    base = [
        ("Teknolojisiz Akşam", "Bugün akşam 3 saat telefon yasak.", 180, ["dijital", "detoks"], ["Kutu koyun, herkes telefonunu içine atsın."]),
        ("Ekran Süresi Kontrolü", "Herkes günlük ekran süresini kontrol etsin.", 10, ["dijital", "kontrol"], ["Hedef koyun, azaltmaya çalışın."]),
        ("Sosyal Medya Detoksu", "1 gün hiç sosyal medya kullanmayın.", 0, ["dijital", "detoks"], ["Uygulamaları geçici olarak silin."]),
        ("Aile Oyun Gecesi (Analog)", "Kutu oyunları, kart, puzzle.", 90, ["dijital", "oyun"], ["Hiçbir elektronik cihaz olmasın."]),
        ("Kitap Okuma Maratonu", "Herkes 1 saat kitap okusun.", 60, ["dijital", "okuma"], ["Telefonu başka odaya koyun."]),
        ("Doğa Yürüyüşü (Telefonsuz)", "Sadece acil durum için telefon yanınızda.", 45, ["dijital", "doğa"], ["Fotoğraf çekmek yasak, sadece yaşayın."]),
        ("Yemek Masası Kuralı", "Yemek sırasında telefon masadan uzakta.", 30, ["dijital", "yemek"], ["Konuşmaya odaklanın."]),
        ("Uyku Öncesi Telefon Yasağı", "Yatmadan 1 saat önce telefon bırakma.", 60, ["dijital", "uyku"], ["Mavi ışık uyku kalitesini bozar."]),
        ("Hafta Sonu Kampı (Offline)", "Şehir dışında internet olmayan yerde kalın.", 1440, ["dijital", "kamp"], ["GPS harici telefon kullanmayın."]),
        ("El Yazısı Günü", "Bugün her şeyi el yazısıyla yazın.", 0, ["dijital", "yazma"], ["Defter ve kalem kullanın."]),
        ("Fotoğraf Makinesi ile Çekim", "Telefon yerine gerçek fotoğraf makinesi kullanın.", 60, ["dijital", "fotoğraf"], ["Anıları sonradan basın."]),
        ("Müzik Dinleme (Radyo)", "Spotify yerine radyo dinleyin.", 60, ["dijital", "müzik"], ["Sürpriz şarkılar keşfedin."]),
        ("Harita Kullanma", "Navigasyon yerine fiziksel harita kullanın.", 0, ["dijital", "navigasyon"], ["Yön bulma becerisini geliştirir."]),
        ("Telefon Şarj İstasyonu", "Evde tek şarj istasyonu belirleyin.", 0, ["dijital", "düzen"], ["Yatak odasına şarj aleti koymayın."]),
        ("Çocuklar için Ekran Kuralı", "Günde max 1 saat eğitici ekran.", 0, ["dijital", "çocuk"], ["Timer kullanın, sınır net olsun."]),
        ("Aile Sohbet Saati", "Her gün 20 dk sadece konuşma.", 20, ["dijital", "iletişim"], ["Televizyon da kapalı olsun."]),
        ("Gazete Okuma Günü", "Online haber yerine fiziksel gazete.", 30, ["dijital", "haber"], ["Farklı gazetelerden okuyun."]),
        ("Mutfakta Telefon Yasak", "Yemek hazırlarken telefon kullanmayın.", 60, ["dijital", "mutfak"], ["Müzik dinlemek serbest."]),
        ("Banyoda Telefon Yasak", "Banyo telefonsuz olsun.", 0, ["dijital", "banyo"], ["Düşünmek için yalnız kalın."]),
        ("Araba Kullanırken Telefon", "Sürücü kesinlikle telefon kullanmasın.", 0, ["dijital", "güvenlik"], ["Aile güvenliği için kural."]),
        ("Akşam Rutini (Analog)", "Kitap, çay, sohbet.", 60, ["dijital", "rutin"], ["Günü sakin bitirin."]),
    ]
    suggestions = []
    prefixes = ["", "Bugün ", "Bu Hafta ", "Ailece ", "Akşam ", "Hafta Sonu "]
    for i in range(100):
        b = base[i % len(base)]
        title = (prefixes[i % len(prefixes)] + b[0]).strip()
        dur = b[2] + (i % 3) * 5
        suggestions.append(build_suggestion(f"db{i+1:03d}", title, b[1], "digital", duration=dur, tags=b[3], tips=b[4]))
    return suggestions

# ──────────────────────────────────────────────────────────────────────────────
# MAIN
# ──────────────────────────────────────────────────────────────────────────────
def main():
    output_dir = "assets/data/suggestions"
    os.makedirs(output_dir, exist_ok=True)

    modules = [
        ("family_communication", build_family_communication),
        ("healthy_living", build_healthy_living),
        ("child_development", build_child_development),
        ("home_organization", build_home_organization),
        ("budget_management", build_budget_management),
        ("safety_measures", build_safety_measures),
        ("education_support", build_education_support),
        ("meal_nutrition", build_meal_nutrition),
        ("social_activities", build_social_activities),
        ("digital_balance", build_digital_balance),
    ]

    for name, builder in modules:
        data = dict(SUGGESTION_TEMPLATE)
        data["module"] = name
        data["suggestions"] = builder()
        path = os.path.join(output_dir, f"{name}.json")
        with open(path, "w", encoding="utf-8") as f:
            json.dump(data, f, ensure_ascii=False, indent=2)
        print(f"Generated {path} with {len(data['suggestions'])} suggestions")

if __name__ == "__main__":
    main()
