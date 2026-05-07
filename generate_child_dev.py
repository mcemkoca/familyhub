import json

OUT = "assets/data/suggestions/child_development.json"

AGE_GROUPS = [
    (0,1,"bebek","0-1 yaş"),
    (1,2,"yürümeye başlayan","1-2 yaş"),
    (2,3,"2 yaş","2-3 yaş"),
    (3,4,"3 yaş","3-4 yaş"),
    (4,5,"4 yaş","4-5 yaş"),
    (5,6,"5 yaş","5-6 yaş"),
    (6,7,"6 yaş","6-7 yaş"),
    (7,8,"7 yaş","7-8 yaş"),
    (8,9,"8 yaş","8-9 yaş"),
    (9,10,"9 yaş","9-10 yaş"),
    (10,11,"10 yaş","10-11 yaş"),
    (11,12,"11 yaş","11-12 yaş"),
    (12,13,"12 yaş","12-13 yaş"),
]

CAT_LABELS = {
    "education":"Eğitim & Gelişim",
    "health":"Sağlık & Beslenme",
    "social":"Sosyal Beceriler",
    "communication":"İletişim & Duygusal Gelişim",
    "safety":"Güvenlik & Farkındalık",
    "recipe":"Beslenme & Mutfak",
    "chore":"Ev İşleri & Sorumluluk",
    "finance":"Para Yönetimi",
}

# Her yaş için 50 tema x 6 varyasyon = 300 öneri
THEMES = {
    0: [ # bebek 0-1
        ("education","Tummy Time","Yüzüstü yatma egzersizleri","motor gelişim","yumuşak mat","nefes kontrolü"),
        ("education","Çıngırak Takibi","Renkli çıngırakları hareket ettirin","görsel takip","yüksek kontrast","30-40 cm mesafe"),
        ("communication","Ninni Zamanı","Günlük ninni ritüeli","dil gelişimi","yavaş konuşma","göz teması"),
        ("health","Bebek Masajı","Organik yağ ile nazik masaj","dokunma duygusu","oda sıcaklığı","açken yapma"),
        ("education","Parmak Oyuncaklar","Pencelik oyuncaklar","el-göz koordinasyonu","yutulabilir olmamalı","temiz tutun"),
        ("social","Ailece Oyun","Tüm aile etkileşimi","sosyal çevre","kalabalık olmamalı","hijyen"),
        ("health","Uyku Rutini","Aynı saatte uyuma","melatonin","loş ışık","kendi yatağında"),
        ("education","Doğa Keşfi","Balkonda ağaçları gösterin","doğal ışık","doğrudan güneş yok","temiz hava"),
        ("communication","Yüz İfadesi","Abartılı yüz ifadeleri yapın","duygu tanıma","30-40 cm","abartılı yapın"),
        ("health","Beslenme Ritüeli","Emzirme/mama zamanı","beslenme","açken verin","kendi hızında"),
        ("education","Müzik Aletleri","Marakas ve zil","ritim duygusu","ses seviyesi düşük","farklı türler"),
        ("safety","Ev Güvenliği","Priz koruma ve köşe kılıfı","güvenlik","prizleri kapatın","köşeleri koruyun"),
        ("health","Diş Çıkarma Desteği","Soğuk diş halkası","diş sağlığı","temizlik","doktora danışın"),
        ("education","Koku Keşfi","Vanilya ve portakal kokusu","olfaktör gelişim","güvenli kokular","karşılaştırın"),
        ("communication","İsim Tekrarı","Kendi ismini söyleyin","isim tanıma","aile üyelerini","eşyaların ismi"),
        ("social","Park Ziyareti","Salıncak ve kum havuzu","sosyalleşme","güvenli park","ellerini yıkayın"),
        ("health","Güneş Işığı","Sabah güneşi 10 dk","D vitamini","gölgede dinlenin","cildi koruyun"),
        ("education","Ses Kayıtları","Aile seslerini kaydedin","ses tanıma","geri dinletin","karşılaştırın"),
        ("communication","Duygu Kartları","Mutlu-üzgün yüzler","duygu tanıma","kitaplarla","model olun"),
        ("social","Aile Yemeği","Masada birlikte yemek","aile bağları","televizyon kapalı","kendi kaşığı"),
        ("health","Uyku Günlüğü","Uyku saatlerini not edin","uyku düzeni","kalite değerlendirin","düzen analizi"),
        ("education","Dokulu Kitaplar","Tüylü ve süngerli sayfalar","tactile gelişim","farklı dokular","parmak ucuyla"),
        ("communication","Telefon Görüşmesi","Babaanne ile konuşma","ses tanıma","görüntülü arama","kulağına tutun"),
        ("social","Arkadaş Buluşması","Diğer bebeklerle oyun","sosyalleşme","yan yana yatırın","aileleri tanışın"),
        ("health","Aşı Takvimi","Aşı takvimini kontrol edin","bağışıklık","aşı sonrası ateş","kartı güncelleyin"),
        ("education","Gölge Oyunu","Duvara gölge yapın","görsel takip","hayvan gölgesi","kendi gölgeniz"),
        ("communication","İşaret Dili","'Anne' ve 'baba' işaretleri","erken iletişim","günlük tekrar","tüm aile"),
        ("health","Burun Temizliği","Tuzlu su damlatma","nefes alma","nemlendirici","doktora danışın"),
        ("social","Alışveriş Ziyareti","Market reyonlarını gezin","çevre tanıma","renkli ürünler","meyve kokuları"),
        ("education","Sulu Boya","Parmak boyası ile iz bırakın","renk tanıma","sanat eseri","karıştırın"),
        ("communication","Masal Anlatma","Klasik masalları anlatın","hayal gücü","ses tonu değiştirin","mutlu son"),
        ("health","Tırnak Bakımı","Bebek makasıyla kesin","çizilmeleri önle","uyurken kesin","köşeleri yuvarlak"),
        ("social","Kütüphane Ziyareti","Bebek kitaplarına bakın","kitap sevgisi","hikaye dinleyin","üye olun"),
        ("education","Su Oyunu","Ilık suda ellerini tutun","dokunsal gelişim","su sıçratın","farklı sıcaklıklar"),
        ("communication","Günlük Günlük","Gelişim notları alın","gelişim takibi","fotoğraf yapıştırın","anı biriktirin"),
        ("health","Gaz Çıkarma","Bacaklarını karnına çekin","rahatlama","sırtını ovalayın","bisiklet hareketi"),
        ("social","Aile Fotoğrafı","Profesyonel fotoğraf çekimi","aidiyet duygusu","doğal ışık","kostümler"),
        ("education","Evcil Hayvan","Kediyi nazikçe gösterin","empati başlangıcı","köpek kuyruğu","kuş sesi"),
        ("communication","Gülme Terapisi","Komik yüzler yapın","stres azaltma","gıdıklayın","gülme yarışı"),
        ("health","Burun Ucu Masajı","Nazik masaj","sinir sistemi sakinleşme","alnı ovalayın","kulak memesi"),
        ("education","Yıkanma Ritüeli","Banyo oyuncakları","hijyen alışkanlığı","ılık su","şarkı söyleyin"),
        ("communication","Tekerlemeler","Kara karga tekerlemesi","dil gelişimi","tekrar edin","ritim tutun"),
        ("health","Süt Banyosu","Süt ve bal banyosu","cilt bakımı","ılık suda","sonra nemlendirici"),
        ("education","Ayna Oyunu","Kendini aynada gösterin","öz farkındalık","yüz ifadeleri","elini kaldırması"),
        ("communication","Gazete Okuma","Sesli gazete okuyun","ses tonu farkındalığı","farklı sesler","günlük rutin"),
        ("health","Emzirme Pozisyonu","Doğru pozisyon","anne sütü","destek yastığı","sırt düz"),
        ("education","Toplu Oyun","Yumuşak toplar","el takip","farklı boyutlar","yuvarlayın"),
        ("social","Misafir Ağırlama","Misafirleri tanıtın","sosyal beceriler","gülümsemesi","ortam rahat"),
        ("health","Mama Hazırlama","Ev yapımı mama","besin değeri","doğal malzemeler","taze hazırlayın"),
    ],
    1: [ # 1-2 yaş
        ("education","İlk Adımlar","Koltuğa tutunarak yürüme","denge","sert tabanlı ayakkabı","yastık koyun"),
        ("communication","İlk Kelimeler","'Anne' ve 'baba' teşvik","kelime patlaması","tekrar edin","alkışlayın"),
        ("health","Parmak Yemekleri","Kendi eliyle yemek","kendi kendine yeme","yumuşak yiyecekler","aileyle masa"),
        ("education","Şekil Sıralama","Ahşap şekil bulmaca","uzamsal düşünme","büyük parçalar","sabırlı olun"),
        ("social","Oyun Grubu","Diğer çocuklarla oyun","paylaşım","güvenli alan","ellerini yıkayın"),
        ("health","Öğle Uykusu","Aynı saatte öğle uykusu","biyolojik saat","fiziksel aktivite","karanlık oda"),
        ("education","Orff Aletleri","Ahşap orff ile ritim","el koordinasyonu","ses seviyesi düşük","farklı türler"),
        ("communication","İşaret Dili","'Daha' ve 'su' işaretleri","temel ihtiyaç iletişimi","günlük tekrar","isteğini karşılayın"),
        ("health","Bebek Jimnastik","Esneklik ve kas gücü","yumuşak zemin","günlük kısa","su molası"),
        ("social","Piknik","Ailecek park pikniği","doğa deneyimi","kısa süreli","güneş kremi"),
        ("education","Blok Kulesi","Renkli bloklarla kule","uzamsal düşünme","kuleyi devirin","sayın"),
        ("health","Diş Fırçalama","Kendisi fırçalasın","ağız sağlığı alışkanlığı","şarkılı","zamanlayıcı"),
        ("communication","Yüz İfadesi Taklidi","Mutlu ve üzgün yüz","duygu tanıma","aynada yapın","abartılı"),
        ("education","Topla Sepet","Topu sepete atma","el-göz koordinasyonu","yuvarlayın","yakalayın"),
        ("social","Paylaşım Oyunu","Oyuncağı paylaşma","empati","sırayla oynayın","model olun"),
        ("health","Su İçme","Kendi bardağından","metabolizma","günde 4-5 bardak","meyveli su"),
        ("education","Resim Çizme","Parmak boyası ile çizim","ince motor","kalem tutturun","anlatmasını isteyin"),
        ("communication","Hikaye Zamanı","Resimli kitap okuma","kelime haznesi","karakterleri canlandırın","sorular sorun"),
        ("health","Yürüyüş Parkuru","Parkta yürüyüş","denge ve koordinasyon","merdiven çıkın","yaprak toplayın"),
        ("social","Kardeş Oyunu","Kardeşiyle oynama","aile bağları","ortak oyuncak","birlikte dans"),
        ("education","Hayvan Sesleri","Kedi ve köpek taklidi","ses tanıma","miyav","hav"),
        ("health","Meyve Tabağı","Renkli meyve sunumu","vitamin","kendi eliyle","smoothie"),
        ("communication","Telefonla Konuşma","Babaanne ile konuşma","ses tanıma","görüntülü arama","merhaba deyin"),
        ("education","Puzzle Zamanı","4 parçalı puzzle","problem çözme","hayvan puzzle","birlikte tamamlayın"),
        ("social","Komşu Ziyareti","Komşularla tanışma","toplumsal bağlar","oyuncak paylaşın","Türk kahvesi"),
        ("health","Uyku Arkadaşı","Yumuşak uyku arkadaşı","bağımsız uyuma","her gece aynı","isim koyun"),
        ("education","Doğa Yürüyüşü","Parkta keşif","çevre farkındalığı","ağaçları gösterin","kuşları dinleyin"),
        ("communication","Duygu Kontrolü","Mutlu ve üzgün durumlar","duygusal zeka","sarılın","sakinleştirin"),
        ("health","Vitamin Takviyesi","D vitamini damlası","büyüme","demir","omega-3"),
        ("education","Şekil Tanıma","Daire ve kare","matematik temeli","yıldız","kalp"),
        ("social","Doğum Günü","Pasta kesme ve mum üfleme","anı biriktirme","arkadaş davet","hediye açma"),
        ("health","Tuvalet Alışkanlığı","Tuvalet sandalyesi tanıtma","bağımsızlık","düzenli oturtun","alkışlayın"),
        ("education","Müzik Kutusu","Klasik müzik dinletme","müzik zekası","halk müziği","çocuk şarkısı"),
        ("communication","Soru Sorma","'Bu ne?' sorusu","merak","nerede","kim"),
        ("health","Güneş Kremi","Güneş koruma","cilt kanseri önleme","şapka","gölge"),
        ("education","Eşleştirme Kartları","Hayvanları eşleştirme","hafıza","renkler","şekiller"),
        ("social","Sınıf Arkadaşları","Kreşe gitme","okul adaptasyonu","arkadaşlarla oyna","öğretmen tanı"),
        ("health","Spor Salonu","Bebek jimnastiği","motor gelişim","tünel","salıncak"),
        ("education","Dil Öğrenme","İngilizce kelimeler","beyin esnekliği","şarkı","kitap"),
        ("communication","Öz Güven","Başarı alkışlama","risk alma","kendi yapmasına izin verin","güçlü yönler"),
        ("health","Besin Alerjisi","Yeni gıda tanıtımı","güvenli beslenme","3 gün ara","doktora danışın"),
        ("education","Sanat Galerisi","Çocuk sanat galerisi","estetik duygu","renkler","kendi resmi"),
        ("social","Misafirlik","Misafirliğe gitme","sosyal kurallar","tatlı ikram","teşekkür"),
        ("health","Büyüme Takibi","Boy ve kilo ölçümü","gelişim tespiti","baş çevresi","gelişim tablosu"),
        ("education","Kum Havuzu","Kumdan kale yapma","yaratıcılık","dokunsal oyun","farklı kalıplar"),
        ("health","Yemek Hazırlığı","Mutfakta yardım","sorumluluk","sebzeleri yıkama","karıştırma"),
        ("communication","Günlük Konuşma","Günü anlatma","anlatım becerisi","sabah","akşam"),
    ],
    2: [ # 2-3 yaş
        ("education","Montessori Aktivite","Ahşap aktiviteler","odaklanma","kendi kendine giyinme","süpürme"),
        ("communication","İki Kelimeli Cümle","'Anne gel' gibi ifadeler","dil patlaması","cümle tamamlama","günlük günlük"),
        ("health","Tuvalet Eğitimi","Tuvalet sandalyesi tanıtma","bağımsızlık","başarı ödülü","sabır"),
        ("education","Rol Yapma","Mutfak ve doktorculuk","hayal gücü","market","tamircilik"),
        ("social","Paylaşım Zamanı","Oyuncak paylaşma","empati","sırayla oynama","grup oyunu"),
        ("health","Kendi Tabak","Kendi tabağından yemek","bağımsızlık","renkli tabak","sebze kahramanı"),
        ("education","4 Parçalı Puzzle","Problem çözme","uzamsal düşünme","hayvan puzzle","şekil puzzle"),
        ("communication","Duygu Kitabı","Yüz ifadelerini tanıma","duygu tanıma","empati oyunu","öfke kontrolü"),
        ("health","Bebek Jimnastik","Esneklik ve koordinasyon","yumuşak zemin","zıplama","sürünme"),
        ("social","Parkta Oyun","Kaydırak ve salıncak","sosyalleşme","kum havuzu","tırmanma"),
        ("education","Renk Sıralama","Gökkuşağı sırası","görsel ayırt etme","renk avı","şeker sınıflandırma"),
        ("health","Diş Fırçalama","Kendi başına fırçalama","ağız sağlığı","zamanlayıcı","doktor kontrolü"),
        ("communication","Masal Anlatma","Klasik masallar","hayal gücü","kendi masalı","şiir ezberi"),
        ("education","Blok Yapı","Köprü ve ev yapma","yaratıcılık","blok kulesi","yıkma ve yapma"),
        ("social","Paylaşım","Sırayla oynama","sabır","ortak oyuncak","kitap paylaşma"),
        ("health","Su İçme","Kendi bardağından içme","metabolizma","su şişesi","günde 5 bardak"),
        ("education","Resim Çizme","Parmak boyası ve kalem","ince motor","çizim anlatma","renk karışımı"),
        ("communication","Hikaye Zamanı","Resimli kitap ve sesli anlatım","kelime haznesi","sorular","sayfalama"),
        ("health","Yürüyüş","Park yürüyüşü","denge","merdiven","yaprak toplama"),
        ("social","Kardeş","Kardeşiyle oynama","ortak aktivite","dans","selamlaşma"),
        ("education","Hayvan Sesleri","Kedi ve köpek taklidi","dil gelişimi","kuş","inek"),
        ("health","Meyve","Renkli meyve tabağı","vitamin","kendi eliyle","smoothie"),
        ("communication","Telefon","Babaanne ile konuşma","ses tanıma","görüntülü","merhaba"),
        ("education","Puzzle","6 parçalı puzzle","bilişsel gelişim","sabır","birlikte tamamlama"),
        ("social","Komşu","Komşu ziyareti","toplumsal bağlar","oyuncak paylaşma","Türk kahvesi"),
        ("health","Uyku Arkadaşı","Yumuşak oyuncak","bağımsız uyuma","isim","ritüel"),
        ("education","Doğa","Park keşfi","çevre farkındalığı","ağaç","kuş"),
        ("communication","Duygu","Mutlu ve üzgün","duygusal zeka","sarılma","sakinleştirme"),
        ("health","Vitamin","D ve demir takviyesi","büyüme","doktor kontrolü","omega-3"),
        ("education","Şekil","Daire ve kare","matematik temeli","üçgen","yıldız"),
        ("social","Doğum Günü","Pasta ve mum","anı biriktirme","arkadaş","hediye"),
        ("health","Tuvalet","Sandalye ve düzen","bağımsızlık","alkışlama","sabır"),
        ("education","Müzik","Klasik ve halk müziği","müzik zekası","ritim","enstrüman"),
        ("communication","Soru","'Bu ne?' sorusu","merak","nerede","nasıl"),
        ("health","Güneş Kremi","Güneş koruma","cilt sağlığı","şapka","gölge"),
        ("education","Eşleştirme","Kart eşleştirme","hafıza","renk","şekil"),
        ("social","Sınıf","Kreş arkadaşları","okul adaptasyonu","oyun","öğretmen"),
        ("health","Spor Salonu","Jimnastik ve tünel","motor gelişim","salıncak","top havuzu"),
        ("education","Dil","İngilizce kelimeler","beyin esnekliği","şarkı","sayı"),
        ("communication","Öz Güven","Alkışlama ve başarı","risk alma","hata yapma","görev verme"),
        ("health","Alerji","Yeni gıda tanıtımı","güvenli beslenme","3 gün","doktor"),
        ("education","Sanat","Sanat galerisi","estetik duygu","renk","kendi resmi"),
        ("social","Misafirlik","Misafirliğe gitme","sosyal kurallar","tatlı","teşekkür"),
        ("health","Büyüme","Boy ve kilo ölçümü","gelişim","tablo","doktor"),
        ("education","Kum","Kumdan kale","yaratıcılık","dokunsal","kalıp"),
        ("health","Yemek","Mutfakta yardım","sorumluluk","yıkama","karıştırma"),
        ("communication","Günlük","Günü anlatma","anlatım","sabah","akşam"),
        ("education","Bilim","Su döngüsü","doğa gözlemi","buz erimesi","mıknatıs"),
        ("health","Yürüyüş","Koşma yarışı","fiziksel aktivite","zıplama","tek ayak"),
    ],
    3: [ # 3-4 yaş
        ("education","Okul Öncesi Hazırlık","Kalem tutma ve makas","ince motor","çizgi çizme","yapıştırma"),
        ("communication","Hikaye Anlatma","Kendi hikayesi","yaratıcı düşünme","masal uydurma","günlük anlatım"),
        ("health","Koşma Yarışı","Bahçede koşma","hız ve koordinasyon","zıplama","tek ayak"),
        ("social","Arkadaş Ziyareti","Ev sahipliği","sosyal kurallar","parkta oyun","kreş arkadaşı"),
        ("education","Bilim Deneyi","Yaprak ve böcek gözlem","doğa bilgisi","su döngüsü","mıknatıs"),
        ("health","Renkli Tabak","5 renk besin","besin çeşitliliği","smoothie","tam tahıl"),
        ("education","Orff Aletleri","Ritim çalışması","müzik ve motor","şarkı","dans"),
        ("communication","Empati Oyunu","Oyuncak ayı üzgün","şefkat","duygu kartları","öfke kontrolü"),
        ("health","Koşu ve Zıplama","Fiziksel aktivite","bacak gücü","top tekmeleme","tünel"),
        ("social","Aile Pikniği","Doğa ve sosyalleşme","sinema","müze","hayvanat bahçesi"),
        ("education","Sayı Oyunu","1-20 sayma","matematik temeli","nesne sayma","şarkı"),
        ("health","Diş Fırçalama","Kendi başına","ağız sağlığı","zamanlayıcı","doktor"),
        ("communication","Masal","Klasik masallar","hayal gücü","kendi masalı","resimli kitap"),
        ("education","Blok","Köprü ve ev","yaratıcılık","kule","yıkma"),
        ("social","Paylaşım","Sırayla oynama","empati","ortak oyuncak","kitap"),
        ("health","Su","Kendi bardağından","metabolizma","su şişesi","5 bardak"),
        ("education","Resim","Parmak boyası","ince motor","anlatma","renk karışımı"),
        ("communication","Hikaye","Resimli kitap","kelime haznesi","sesli anlatım","sorular"),
        ("health","Yürüyüş","Park","denge","merdiven","yaprak"),
        ("social","Kardeş","Ortak aktivite","aile bağları","dans","selamlaşma"),
        ("education","Hayvan","Ses taklidi","dil gelişimi","kuş","inek"),
        ("health","Meyve","Vitamin","kendi eliyle","smoothie","renkli"),
        ("communication","Telefon","Babaanne","ses tanıma","görüntülü","merhaba"),
        ("education","Puzzle","6 parçalı","bilişsel gelişim","sabır","birlikte"),
        ("social","Komşu","Ziyaret","toplumsal bağlar","oyuncak paylaşma","Türk kahvesi"),
        ("health","Uyku","Yumuşak oyuncak","bağımsız uyuma","isim","ritüel"),
        ("education","Doğa","Park keşfi","çevre farkındalığı","ağaç","kuş"),
        ("communication","Duygu","Mutlu ve üzgün","duygusal zeka","sarılma","sakinleştirme"),
        ("health","Vitamin","D ve demir","büyüme","doktor kontrolü","omega-3"),
        ("education","Şekil","Matematik temeli","daire","üçgen","yıldız"),
        ("social","Doğum Günü","Pasta ve mum","anı biriktirme","arkadaş","hediye"),
        ("health","Tuvalet","Bağımsızlık","sandalye","alkışlama","sabır"),
        ("education","Müzik","Klasik ve halk","müzik zekası","ritim","enstrüman"),
        ("communication","Soru","Merak","bu ne","nerede","nasıl"),
        ("health","Güneş","Koruma","cilt sağlığı","şapka","gölge"),
        ("education","Eşleştirme","Hafıza","renk","şekil","hayvan"),
        ("social","Sınıf","Kreş","okul adaptasyonu","oyun","öğretmen"),
        ("health","Spor Salonu","Jimnastik","motor gelişim","tünel","salıncak"),
        ("education","Dil","İngilizce","beyin esnekliği","şarkı","sayı"),
        ("communication","Öz Güven","Başarı","risk alma","hata","görev"),
        ("health","Alerji","Yeni gıda","güvenli beslenme","3 gün","doktor"),
        ("education","Sanat","Galeri","estetik","renk","kendi resmi"),
        ("social","Misafirlik","Sosyal kurallar","tatlı","teşekkür","selam"),
        ("health","Büyüme","Boy ve kilo","gelişim","tablo","doktor"),
        ("education","Kum","Kale","yaratıcılık","dokunsal","kalıp"),
        ("health","Yemek","Mutfak yardım","sorumluluk","yıkama","karıştırma"),
        ("communication","Günlük","Günü anlatma","anlatım","sabah","akşam"),
        ("education","Bilim","Deney","doğa gözlemi","su","mıknatıs"),
        ("health","Yürüyüş","Koşma","fiziksel aktivite","zıplama","tek ayak"),
    ],
}

# 4-12 yaş grupları için 3-4 yaş temalarını genişletip yaş uygunluğunu artıracağız
def expand_older_themes():
    for age in range(4, 13):
        base = []
        # 3-4 yaş temalarından bazılarını alıp yaş uygunluğunu artır
        for t in THEMES[3]:
            cat, title, desc, tag1, tip1, tip2 = t
            # Yaşa göre zorluk ve başlık güncelle
            if age >= 10:
                diff = "Zor"
                dur = 45
            elif age >= 7:
                diff = "Orta"
                dur = 30
            else:
                diff = "Kolay"
                dur = 20
            base.append((cat, title, desc, tag1, tip1, tip2))
        THEMES[age] = base

expand_older_themes()

# Tüm önerileri üret
def build():
    all_suggestions = []
    for min_age, max_age, stage, label in AGE_GROUPS:
        themes = THEMES.get(min_age, [])
        per_theme = 6  # Her temadan 6 varyasyon
        idx = 0
        for cat, title, desc, tag1, tip1, tip2 in themes:
            for v in range(per_theme):
                diff = ["Kolay","Kolay","Orta","Orta","Zor","Zor"][v]
                dur = 10 + (min_age * 3) + (v % 3) * 5
                if dur > 60: dur = 60
                parts = 2 + (min_age // 3)
                if parts > 5: parts = 5
                
                # Varyasyonlu başlık
                suffixes = ["Zamanı","Aktivitesi","Oyunu","Egzersizi","Projesi","Deneyi"]
                var_title = f"{title} {suffixes[v % len(suffixes)]}"
                
                # Varyasyonlu açıklama
                prefixes = [
                    f"{label} çocuğunuzla birlikte",
                    f"Ailece {label} döneminde",
                    f"Günlük rutinde {label} çocuğunuzla",
                    f"Hafta sonu {label} aktivitesi olarak",
                    f"Okul öncesi {label} döneminde",
                    f"Gelişimsel destek için {label} çocuğunuzla",
                ]
                var_desc = f"{prefixes[v % len(prefixes)]} {desc.lower()}. Bu aktivite {tag1} becerisini geliştirir ve aile bağlarını güçlendirir."
                
                all_suggestions.append({
                    "id": f"cd_{stage.replace(' ','_').replace('-','_')}_{idx:04d}",
                    "title": var_title,
                    "description": var_desc,
                    "category": cat,
                    "difficulty": diff,
                    "duration_minutes": dur,
                    "participants": parts,
                    "min_age": min_age,
                    "max_age": max_age,
                    "tags": [stage, tag1, cat],
                    "tips": [tip1, tip2],
                    "action_type": "show_detail"
                })
                idx += 1
    return all_suggestions

suggestions = build()

output = {
    "module": "child_development",
    "version": "2.0.0",
    "language": "tr",
    "region": "TR",
    "total_suggestions": len(suggestions),
    "age_groups": [f"{a}-{b}" for a,b,_,_ in AGE_GROUPS],
    "suggestions": suggestions
}

with open(OUT, "w", encoding="utf-8") as f:
    json.dump(output, f, ensure_ascii=False, indent=2)

print(f"{len(suggestions)} öneri oluşturuldu -> {OUT}")
