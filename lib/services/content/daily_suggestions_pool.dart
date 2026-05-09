import 'dart:math';
import 'package:intl/intl.dart';
import '../../domain/models/ai_suggestion.dart';

/// 400+ günlük öneri havuzu.
/// Her gün deterministik rastgele seçim ile farklı öneriler gösterilir.
/// Son 30 gün gösterilen öneriler tekrar etmez.
class DailySuggestionsPool {
  static final _random = Random();

  static final List<AISuggestion> _pool = _buildPool();

  static List<AISuggestion> get all => List.unmodifiable(_pool);

  static List<AISuggestion> pickDaily({
    required DateTime date,
    required List<String> excludedIds,
    int count = 4,
  }) {
    final choreSuggestion = ChoreRotationService.getTodayChore(date);

    final available = _pool
        .where((s) => !excludedIds.contains(s.id))
        .where((s) => s.type != 'chore')
        .toList();

    final seed = date.year * 10000 + date.month * 100 + date.day;
    final dailyRandom = Random(seed);
    available.shuffle(dailyRandom);

    final picked = available.take(count - 1).toList();

    return [choreSuggestion, ...picked];
  }

  static List<AISuggestion> pickMore({
    required DateTime date,
    required List<String> alreadyShownIds,
    int count = 5,
  }) {
    final available = _pool
        .where((s) => !alreadyShownIds.contains(s.id))
        .toList();

    final seed = date.year * 10000 + date.month * 100 + date.day + 9999;
    final random = Random(seed);
    available.shuffle(random);

    return available.take(count).toList();
  }

  static List<AISuggestion> _buildPool() {
    return [
      ..._buildRecipes(),
      ..._buildSocial(),
      ..._buildHealth(),
      ..._buildEducation(),
      ..._buildFinance(),
      ..._buildSafety(),
      ..._buildChores(),
    ];
  }

  // ── YEMEK / MUTFAK (50) ──
  static List<AISuggestion> _buildRecipes() {
    final items = [
      _s('y01', 'recipe', 'Anne Köftesi (Fırında)', 'Közlenmiş biberli, mercimekli. Hem sağlıklı hem doyurucu.', 'Kolay', 45, 4, 420),
      _s('y02', 'recipe', 'Karnıyarık', 'Patlıcanları önceden tuzlayın, acısı çıksın.', 'Orta', 60, 4, 380),
      _s('y03', 'recipe', 'Ev Lahmacunu', 'İnce hamur, bol malzeme, fırında çıtır.', 'Orta', 90, 6, 320),
      _s('y04', 'recipe', 'Mercimek Çorbası + Tost', 'Klasik ama vazgeçilmez. Kızarmış ekmekle.', 'Kolay', 30, 4, 280),
      _s('y05', 'recipe', 'Fırında Makarna', 'Beşamel soslu, bol kaşarlı. Çocuklar bayılır.', 'Kolay', 40, 4, 520),
      _s('y06', 'recipe', 'Zeytinyağlı Sarma', 'Asma yaprağında, pirinçli, bol naneli.', 'Zor', 90, 6, 220),
      _s('y07', 'recipe', 'Ev Pidesi', 'Kıymalı, peynirli, kuşbaşılı. Her seferinde farklı.', 'Orta', 75, 4, 450),
      _s('y08', 'recipe', 'Tavuk Şiş + Pilav', 'Düdüklüde pirinç, ızgarada tavuk.', 'Kolay', 35, 4, 480),
      _s('y09', 'recipe', 'Kumpir Akşamı', 'Fırında patates, herkes kendi malzemesini koysun.', 'Kolay', 50, 4, 400),
      _s('y10', 'recipe', 'Ev Mantısı', 'Kayseri usulü, yoğurtlu, tereyağlı sos.', 'Zor', 120, 6, 380),
      _s('y11', 'recipe', 'Izgara Çipura + Roka', 'Balık ve roka salatası. Hafif ve sağlıklı.', 'Kolay', 25, 4, 290),
      _s('y12', 'recipe', 'Türlü Yemeği', 'Biber, patlıcan, kabak, patates; zeytinyağlı.', 'Kolay', 40, 4, 200),
      _s('y13', 'recipe', 'Ev Pizzası', 'Hamur mayalansın, herkes kendi pizzasına malzeme seçsin.', 'Orta', 90, 4, 500),
      _s('y14', 'recipe', 'Yaprak Sarması', 'Zeytinyağlı, nar ekşili, bol dolma fıstığı.', 'Orta', 80, 6, 250),
      _s('y15', 'recipe', 'Kurufasulye + Pilav', 'Geleneksel ama her zaman güzel. Turşu yanında.', 'Kolay', 45, 4, 450),
      _s('y16', 'recipe', 'Çöp Şiş (Ev Usulü)', 'Marine tavuk, sebzelerle şiş, fırında.', 'Orta', 50, 4, 380),
      _s('y17', 'recipe', 'Kabak Mücver', 'Rendelenmiş kabak, maydanoz, dereotu.', 'Kolay', 25, 4, 180),
      _s('y18', 'recipe', 'Nohutlu Bulgur Pilavı', 'Baharatlı nohut, bulgur, soğan kavurması.', 'Kolay', 35, 4, 350),
      _s('y19', 'recipe', 'Ispanaklı Börek', 'El açması veya hazır yufka, bol ıspanak.', 'Orta', 60, 6, 320),
      _s('y20', 'recipe', 'Ev Yapımı Dondurma', 'Muz dondurulup blenderdan geçirilir.', 'Kolay', 15, 4, 150),
      _s('y21', 'recipe', 'Adana Kebap (Evde)', 'Kıyma, yağ, baharat. Ev ızgarasında.', 'Orta', 40, 4, 550),
      _s('y22', 'recipe', 'Zeytinyağlı Barbunya', 'Taze barbunya, havuç, patates, zeytinyağı.', 'Kolay', 45, 4, 240),
      _s('y23', 'recipe', 'İskender (Ev Usulü)', 'Döner eti, yoğurt, tereyağlı domates sos.', 'Orta', 50, 4, 600),
      _s('y24', 'recipe', 'Menemen', 'Yumurta, domates, biber, soğan. Kahvaltı klasik.', 'Kolay', 20, 4, 220),
      _s('y25', 'recipe', 'Sulu Köfte', 'Pirinçli köfte, domatesli sos, limon.', 'Kolay', 40, 4, 350),
      _s('y26', 'recipe', 'Fırında Sebzeli Tavuk', 'Patates, havuç, biber, tavuk but. Tek tepsi.', 'Kolay', 60, 4, 420),
      _s('y27', 'recipe', 'Patates Püresi + Sote', 'Kremsi püre, mantarlı tavuk sote.', 'Kolay', 35, 4, 450),
      _s('y28', 'recipe', 'Ev Yapımı Ekmek', 'Mayalı hamur, fırında çıtır. Tarçınlı da yapın.', 'Orta', 120, 6, 180),
      _s('y29', 'recipe', 'Paella (Ev Usulü)', 'Deniz mahsullü veya tavuklu safranlı pirinç.', 'Orta', 55, 6, 480),
      _s('y30', 'recipe', 'Etli Nohut', 'Düdüklüde pişmiş nohut, et, baharat.', 'Orta', 50, 6, 520),
      _s('y31', 'recipe', 'Krep + Nutella', 'İnce krep, muz dilimleri, çikolata. Çocuklara sürpriz.', 'Kolay', 20, 4, 380),
      _s('y32', 'recipe', 'Fırında Biber Dolması', 'Zeytinyağlı, pirinçli, nar ekşili.', 'Orta', 70, 6, 260),
      _s('y33', 'recipe', 'Hünkar Beğendi', 'Közlenmiş patlıcan püresi, et sote.', 'Orta', 60, 4, 480),
      _s('y34', 'recipe', 'Ev Yapımı Sushi', 'Pirinç, nori, salatalık, avokado, somon.', 'Zor', 90, 4, 320),
      _s('y35', 'recipe', 'Çılbır', 'Poşe yumurta, sarımsaklı yoğurt, tereyağlı pul biber.', 'Kolay', 15, 2, 250),
      _s('y36', 'recipe', 'Tas Kebabı', 'Dana eti, sebzeler, fırın poşetinde.', 'Orta', 70, 6, 450),
      _s('y37', 'recipe', 'Sıcak Çikolata ve Kurabiye', 'Ev yapımı kurabiye, bol kakaolu sıcak çikolata.', 'Kolay', 30, 4, 400),
      _s('y38', 'recipe', 'Ev Yapımı Börek (Su Böreği)', 'Yufkalar ıslatılır, peynirli, fırında.', 'Orta', 75, 6, 350),
      _s('y39', 'recipe', 'Sebzeli Omlet', 'Ispanak, mantar, biber, bol peynir.', 'Kolay', 15, 2, 280),
      _s('y40', 'recipe', 'Fırında Körili Tavuk', 'Kremalı körili sos, mantar, tavuk göğsü.', 'Kolay', 45, 4, 420),
      _s('y41', 'recipe', 'Ev Yapımı Taco', 'Mısır tortillası, kıyma, salsa, guacamole.', 'Orta', 40, 4, 380),
      _s('y42', 'recipe', 'Ayvalık Tostu', 'Bol malzemeli, kare tost. Atom gibi.', 'Kolay', 15, 2, 450),
      _s('y43', 'recipe', 'Ev Yapımı Ramen', 'Tavuk suyu, noodle, yumurta, yeşil soğan.', 'Orta', 60, 4, 350),
      _s('y44', 'recipe', 'Zeytinyağlı Enginar', 'Taze enginar, havuç, bezelye, dereotu.', 'Orta', 50, 4, 220),
      _s('y45', 'recipe', 'Etli Ekmek (Konya)', 'İnce hamur, kıyma, biber, domates.', 'Orta', 55, 4, 420),
      _s('y46', 'recipe', 'Ev Yapımı Pankek', 'Yumuşak pankek, akçaağaç şurubu, meyve.', 'Kolay', 25, 4, 320),
      _s('y47', 'recipe', 'Karnabahar Graten', 'Karnabahar, beşamel sos, kaşar, fırında.', 'Kolay', 40, 4, 300),
      _s('y48', 'recipe', 'Fırında Tavuk But', 'Patates, soğan, sarımsak, baharatlı tavuk but.', 'Kolay', 70, 6, 480),
      _s('y49', 'recipe', 'Ev Yapımı Lokma', 'Mayalı hamur, sıcak yağda, şerbetli.', 'Orta', 45, 8, 280),
      _s('y50', 'recipe', 'Sebzeli Noodle', 'Udon noodle, sebze, soya sosu, zencefil.', 'Kolay', 20, 4, 310),
    ];
    return items;
  }
  // ── AKTİVİTE / SOSYAL (50) ──
  static List<AISuggestion> _buildSocial() {
    return [
      _s('a01', 'social', 'Aile Oyun Gecesi', 'Tabu, kutu oyunları, kart. Kazanan sonrakini seçsin.', 'Kolay', 90, 4, null),
      _s('a02', 'social', 'Piknik Planlayın', 'En yakın parka battaniye, sandviç ve meyve.', 'Kolay', 180, 4, null),
      _s('a03', 'social', 'Film Maratonu', 'Herkes bir film seçsin, popcorn hazırlayın.', 'Kolay', 150, 4, null),
      _s('a04', 'social', 'Gezinti Yürüyüşü', 'Mahallede veya ormanda 30 dk yürüyüş.', 'Kolay', 30, 4, null),
      _s('a05', 'social', 'Mangal Keyfi', 'Balkonda veya bahçede pratik mangal.', 'Orta', 120, 6, null),
      _s('a06', 'social', 'Bisiklet Turu', 'Güvenli rotada ailece bisiklet.', 'Kolay', 60, 4, null),
      _s('a07', 'social', 'Müze Ziyareti', 'Çocuklar için etkileşimli müzeler.', 'Kolay', 120, 4, null),
      _s('a08', 'social', 'Aile Fotoğraf Çekimi', 'Komik pozlar verin, galeriye ekleyin.', 'Kolay', 30, 4, null),
      _s('a09', 'social', 'Balkonda Kamp', 'Çadır kurun, el feneri hikayeleri.', 'Kolay', 60, 4, null),
      _s('a10', 'social', 'Kitap Okuma Saati', 'Herkes kendi kitabını okur, özet anlatır.', 'Kolay', 45, 4, null),
      _s('a11', 'social', 'Origami Etkinliği', 'Kağıttan hayvan, gemi, uçak yapımı.', 'Kolay', 40, 4, null),
      _s('a12', 'social', 'Aile Müzik Gecesi', 'Herkes sevdiği şarkıyı söyler.', 'Kolay', 60, 4, null),
      _s('a13', 'social', 'Hayvanat Bahçesi', 'Çocuklarla hayvanları besleyin.', 'Kolay', 180, 4, null),
      _s('a14', 'social', 'Doğa Yürüyüşü', 'Hafta sonu trekking parkuru.', 'Orta', 180, 4, null),
      _s('a15', 'social', 'Aile Yarışması', 'Mini olimpiyat: ip atlama, balon patlatma.', 'Kolay', 60, 4, null),
      _s('a16', 'social', 'Yıldız İzleme', 'Battaniye serin, yıldızları sayın.', 'Kolay', 45, 4, null),
      _s('a17', 'social', 'Boyama Etkinliği', 'Mandal, kum boyama, tuval.', 'Kolay', 60, 4, null),
      _s('a18', 'social', 'Podcast Dinleme', 'Eğitici podcast, tartışın.', 'Kolay', 30, 4, null),
      _s('a19', 'social', 'Yerel Pazara Gitmek', 'Semt pazarında taze sebze meyve.', 'Kolay', 90, 4, null),
      _s('a20', 'social', 'Aile Vlog Çekimi', 'Gününüzü çekin, montaj yapın.', 'Kolay', 60, 4, null),
      _s('a21', 'social', 'Karaoke Gecesi', 'YouTube karaoke, yarışma yapın.', 'Kolay', 90, 4, null),
      _s('a22', 'social', 'Bahçe Pikniği', 'Ev bahçesinde, su fightı ve oyun.', 'Kolay', 120, 4, null),
      _s('a23', 'social', 'Satranç Turnuvası', 'Aile içi turnuva, kupa hediyesi.', 'Kolay', 60, 2, null),
      _s('a24', 'social', 'Gökyüzü Balonları', 'Balkonda uçuran, dilek tutun.', 'Kolay', 30, 4, null),
      _s('a25', 'social', 'Aile Bahçe İşleri', 'Birlikte fidan dikin, sulayın.', 'Orta', 90, 4, null),
      _s('a26', 'social', 'Kamp Ziyareti', 'Şehir dışı kamp, ateş başı hikaye.', 'Orta', 480, 6, null),
      _s('a27', 'social', 'Botanik Park', 'Bitki türlerini tanıyın, fotoğraf çekin.', 'Kolay', 120, 4, null),
      _s('a28', 'social', 'Paten / Kaykay', 'Güvenli alanda ailece kayın.', 'Kolay', 60, 4, null),
      _s('a29', 'social', 'Aile Yoga Parkı', 'Parkta birlikte yoga veya pilates.', 'Kolay', 45, 4, null),
      _s('a30', 'social', 'Fotoğraf Yarışması', 'Herkes en iyi kareyi çeksin, oylayın.', 'Kolay', 60, 4, null),
      _s('a31', 'social', 'Gönüllü Çalışma', 'Hayvan barınağı, yaşlı ziyareti.', 'Kolay', 180, 4, null),
      _s('a32', 'social', 'Aile Dans Dersi', 'YouTube videoyla salsa, hip-hop deneyin.', 'Kolay', 45, 4, null),
      _s('a33', 'social', 'Günbatımı İzleme', 'En yüksek noktaya çıkın, günbatımı.', 'Kolay', 60, 4, null),
      _s('a34', 'social', 'Kahvaltı Dışarıda', 'Ailece brunch, farklı bir mekan.', 'Kolay', 90, 4, null),
      _s('a35', 'social', 'Scavenger Hunt', 'Evde veya parkta ipuçlu hazine avı.', 'Kolay', 60, 4, null),
      _s('a36', 'social', 'Aile Resim Sergisi', 'Çocukların resimlerini duvara asın.', 'Kolay', 30, 4, null),
      _s('a37', 'social', 'Gece Yürüyüşü', 'Fenerli, güvenli parkta akşam yürüyüşü.', 'Kolay', 30, 4, null),
      _s('a38', 'social', 'Aile Bingo Gecesi', 'Kendiniz kart yapın, ödüller koyun.', 'Kolay', 60, 4, null),
      _s('a39', 'social', 'Hayvanat Bahçesi (Farklı Şehir)', 'Yakın şehirdeki farklı hayvanat bahçesi.', 'Orta', 360, 6, null),
      _s('a40', 'social', 'Aile Kitap Kulübü', 'Her hafta bir kitap, tartışma yapın.', 'Kolay', 60, 4, null),
      _s('a41', 'social', 'Deniz Kenarı Gezisi', 'Sahil yürüyüşü, kumdan kale, deniz.', 'Kolay', 240, 6, null),
      _s('a42', 'social', 'Aile Mutfak Günü', 'Birlikte yemek yapın, sunum yapın.', 'Orta', 120, 6, null),
      _s('a43', 'social', 'Sokak Hayvanlarını Besle', 'Kedi, köpek mamaları, su kabı koyun.', 'Kolay', 30, 4, null),
      _s('a44', 'social', 'Aile Tiyatro Günü', 'Evde kukla tiyatrosu, senaryo yazın.', 'Kolay', 90, 4, null),
      _s('a45', 'social', 'Gözlem Evi Ziyareti', 'Yıldız gözlemi, teleskop bakışı.', 'Kolay', 120, 4, null),
      _s('a46', 'social', 'Aile Boyama Duvarı', 'Bir duvarı tebeşir boyasıyla boyayın.', 'Orta', 120, 4, null),
      _s('a47', 'social', 'Piknik ve Uçurtma', 'Parkta piknik, uçurtma uçurun.', 'Kolay', 180, 4, null),
      _s('a48', 'social', 'Aile Zeka Oyunları', 'Escape room evde, ipuçlu oyun.', 'Orta', 90, 4, null),
      _s('a49', 'social', 'Botanik Bahçe Pikniği', 'Farklı bitkiler, kokulu çiçekler, piknik.', 'Kolay', 180, 4, null),
      _s('a50', 'social', 'Aile Fotoğraf Albümü', 'Eski fotoğrafları seçin, albüm yapın.', 'Kolay', 90, 4, null),
    ];
  }

  // ── SAĞLIK / SPOR (30) ──
  static List<AISuggestion> _buildHealth() {
    return [
      _s('s01', 'health', 'Sabah Egzersizi', '15 dk esneme veya yoga. Herkes katılsın.', 'Kolay', 15, 4, 80),
      _s('s02', 'health', 'Günlük Su Hedefi', 'Herkes 8 bardak su içsin, takip edin.', 'Kolay', 0, 4, 0),
      _s('s03', 'health', 'Meyve Tabağı', 'Renkli meyveler, yoğurt ve bal.', 'Kolay', 10, 4, 120),
      _s('s04', 'health', 'Akşam Yürüyüşü', 'Yemekten sonra 20 dk hafif tempo.', 'Kolay', 20, 4, 100),
      _s('s05', 'health', 'Dijital Detoks', '2 saat telefonsuz aile zamanı.', 'Kolay', 120, 4, null),
      _s('s06', 'health', 'Meditasyon Zamanı', '5 dk nefes egzersizi, sessizlik.', 'Kolay', 5, 4, null),
      _s('s07', 'health', 'Evde Dans Partisi', 'Enerjik müziklerle 20 dk dans.', 'Kolay', 20, 4, 150),
      _s('s08', 'health', 'Sebze Günü', 'Bugün her öğünde farklı sebze olsun.', 'Kolay', 0, 4, null),
      _s('s09', 'health', 'Uyku Rutini', 'Herkes aynı saatte yatağa, kitap okuyun.', 'Kolay', 30, 4, null),
      _s('s10', 'health', 'Balkonda Bitki Bakımı', 'Sulama, budama, yeni tohum.', 'Kolay', 20, 4, null),
      _s('s11', 'health', 'Aile Spor Günü', 'Evde pilates, şınav, mekik yarışması.', 'Orta', 30, 4, 200),
      _s('s12', 'health', 'Diş Bakım Kontrolü', 'Çocuklara doğru fırçalama tekniği.', 'Kolay', 10, 4, null),
      _s('s13', 'health', 'Vitamin Deposu Smoothie', 'Ispanak, muz, elma, yoğurt karışımı.', 'Kolay', 10, 4, 140),
      _s('s14', 'health', 'Ekran Molası', 'Her saat başı 10 dk göz egzersizi.', 'Kolay', 10, 4, null),
      _s('s15', 'health', 'Aile Yoga Seansı', 'YouTube videosuyla birlikte yoga.', 'Kolay', 20, 4, 100),
      _s('s16', 'health', 'Evde Step Sayma', 'Telefonu cebde bırakın, 5000 adım hedef.', 'Kolay', 45, 4, 200),
      _s('s17', 'health', 'Sağlıklı Atıştırmalık', 'Cips yerine kuruyemiş, meyve.', 'Kolay', 5, 4, 150),
      _s('s18', 'health', 'Aile Bisiklet Turu', 'Haftada bir kez, 5 km bisiklet.', 'Kolay', 30, 4, 180),
      _s('s19', 'health', 'Duruş Düzeltme Egzersizi', 'Sırt, boyun, omuz egzersizleri.', 'Kolay', 10, 4, 50),
      _s('s20', 'health', 'Güneş Işığı Alma', 'Balkonda 15 dk güneş, D vitamini.', 'Kolay', 15, 4, null),
      _s('s21', 'health', 'Aile Koşusu', 'Parkta hafif tempolu koşu.', 'Orta', 20, 4, 180),
      _s('s22', 'health', 'Şeker Detoksu', 'Bugün hiç şekerli gıda yemeyin.', 'Kolay', 0, 4, null),
      _s('s23', 'health', 'Aile Masaj Günü', 'Omuz, sırt masajı, gevşeme.', 'Kolay', 20, 2, null),
      _s('s24', 'health', 'Su Sporları (Yaz)', 'Yüzme, kano, su topu.', 'Kolay', 60, 4, 250),
      _s('s25', 'health', 'Aile Hamak Keyfi', 'Ağaçlar arası hamak, kitap, dinlenme.', 'Kolay', 30, 4, null),
      _s('s26', 'health', 'Sağlıklı Kahvaltı', 'Yumurta, avokado, tam tahıllı ekmek.', 'Kolay', 15, 4, 300),
      _s('s27', 'health', 'Aile Jimnastiği', '10 dk koşu yerinde, zıplama, şınav.', 'Kolay', 10, 4, 100),
      _s('s28', 'health', 'Bağışıklık Çayı', 'Zencefil, zerdeçal, bal, limon çayı.', 'Kolay', 10, 4, 30),
      _s('s29', 'health', 'Aile Paten / Kaykay', 'Denge egzersizi, eğlenceli spor.', 'Kolay', 30, 4, 120),
      _s('s30', 'health', 'Nefes ve Gevşeme', '10 dk derin nefes, kas gevşetme.', 'Kolay', 10, 4, null),
    ];
  }
  // ── EĞİTİM / GELİŞİM (100) ──
  static List<AISuggestion> _buildEducation() {
    return [
      _s('e01', 'education', 'Birlikte Puzzle Yap', '500 parça puzzle, ailece çözün.', 'Orta', 120, 4, null),
      _s('e02', 'education', 'Bilgi Yarışması', 'Tarih, coğrafya, bilim soruları.', 'Kolay', 30, 4, null),
      _s('e03', 'education', 'Yeni Kelime Öğren', 'Herkes 3 İngilizce kelime öğrensin.', 'Kolay', 15, 4, null),
      _s('e04', 'education', 'Birlikte Deney Yap', 'Basit kimya/fizik deneyleri.', 'Orta', 45, 4, null),
      _s('e05', 'education', 'Harita Çalışması', 'Dünya haritasında ülkeler bulun.', 'Kolay', 20, 4, null),
      _s('e06', 'education', 'Aile Gazetesi', 'Herkes bir haber yazsın, gazete yapın.', 'Orta', 60, 4, null),
      _s('e07', 'education', 'Müzik Enstrümanı Dene', 'Ukulele, kaval veya ritim.', 'Kolay', 30, 4, null),
      _s('e08', 'education', 'Hayvan Belgeseli', 'Eğitici belgesel izleyin, tartışın.', 'Kolay', 45, 4, null),
      _s('e09', 'education', 'Ders Tekrarı', 'Çocukların konusunu birlikte tekrar edin.', 'Kolay', 30, 4, null),
      _s('e10', 'education', 'Zeka Oyunları', 'Satranç, mangala, reversi.', 'Kolay', 40, 2, null),
      _s('e11', 'education', 'Hafıza Oyunu', 'Eşya dizin, 1 dk sonra hatırlatın.', 'Kolay', 15, 4, null),
      _s('e12', 'education', 'Dünya Mutfakları', 'Her hafta farklı ülke yemeği.', 'Kolay', 30, 4, null),
      _s('e13', 'education', 'Aile Defteri', 'Bugün neler yaptık, hissettik? Yazın.', 'Kolay', 15, 4, null),
      _s('e14', 'education', 'Birlikte Programlama', 'Scratch veya kodlama uygulaması.', 'Kolay', 45, 2, null),
      _s('e15', 'education', 'Geometri Origami', 'Kağıt katlama, şekiller öğrenin.', 'Kolay', 30, 4, null),
      _s('e16', 'education', 'Tarih Konulu Oyun', 'Osmanlı, Cumhuriyet bilgi yarışması.', 'Kolay', 30, 4, null),
      _s('e17', 'education', 'Fen Bilgisi Projesi', 'Volkan deneyi, bitki büyütme.', 'Orta', 60, 4, null),
      _s('e18', 'education', 'Astronomi Gecesi', 'Ay, gezegenleri tanıyın, uygulama kullanın.', 'Kolay', 45, 4, null),
      _s('e19', 'education', 'Dil Öğrenme Uygulaması', 'Duolingo, herkes 1 ünite tamamlasın.', 'Kolay', 20, 4, null),
      _s('e20', 'education', 'Matematik Oyunu', 'Mental aritmetik, zamanlı yarışma.', 'Kolay', 15, 4, null),
      _s('e21', 'education', 'Aile Kütüphanesi', 'Kitapları kategoriye göre sıralayın.', 'Kolay', 30, 4, null),
      _s('e22', 'education', 'Bilim Müzesi Ziyareti', 'Teknik müze veya planetarium.', 'Kolay', 180, 4, null),
      _s('e23', 'education', 'Yazı Yazma Egzersizi', 'Günlük tutun, hikaye yazın.', 'Kolay', 20, 4, null),
      _s('e24', 'education', 'Coğrafya Bulmaca', 'Başkentler, dağlar, nehirler bulmacası.', 'Kolay', 20, 4, null),
      _s('e25', 'education', 'Robotik Kodlama', 'Lego Mindstorms veya benzeri.', 'Orta', 90, 2, null),
      _s('e26', 'education', 'Aile Tarihi Araştırması', 'Büyükannelerin hikayelerini kaydedin.', 'Kolay', 60, 4, null),
      _s('e27', 'education', 'Maket Yapımı', 'Ev, köprü, uçak maketi yapın.', 'Orta', 120, 4, null),
      _s('e28', 'education', 'Kimya Seti Deneyleri', 'Güvenli ev deneyleri, asit-baz.', 'Orta', 45, 4, null),
      _s('e29', 'education', 'Sanat Tarihi Sunumu', 'Bir ressamı araştırın, sunum yapın.', 'Orta', 60, 4, null),
      _s('e30', 'education', 'Fizik Oyunları', 'Misket, ip, yerçekimi deneyleri.', 'Kolay', 30, 4, null),
      _s('e31', 'education', 'Biyoloji Gözlemi', 'Böcek, bitki, kuş gözlemi yapın.', 'Kolay', 45, 4, null),
      _s('e32', 'education', 'Aile Kelime Oyunu', 'Kelime türetme, kelime zinciri.', 'Kolay', 20, 4, null),
      _s('e33', 'education', 'Edebiyat Sohbeti', 'Bir şiir veya hikaye okuyun, tartışın.', 'Kolay', 30, 4, null),
      _s('e34', 'education', 'Müzik Tarihi Dinleme', 'Klasik müzik, bestecileri tanıyın.', 'Kolay', 30, 4, null),
      _s('e35', 'education', 'Aile Münazara', 'Bir konu seçin, tartışın, jüri oylasın.', 'Kolay', 45, 4, null),
      _s('e36', 'education', 'Dinozor Günü', 'Dinozor türleri, fosiller, belgesel.', 'Kolay', 60, 4, null),
      _s('e37', 'education', 'Gökyüzü Haritası', 'Takımyıldızları çizin, harita yapın.', 'Kolay', 40, 4, null),
      _s('e38', 'education', 'Aile Gazeteciliği', 'Haftalık haber bülteni yazın.', 'Kolay', 60, 4, null),
      _s('e39', 'education', 'Mekanik Oyuncak', 'Saat, oyuncak söküp takın.', 'Orta', 60, 2, null),
      _s('e40', 'education', 'Ekosistem Projesi', 'Teraryum yapın, bitki-hayvan döngüsü.', 'Orta', 90, 4, null),
      _s('e41', 'education', 'Tarihi Yer Ziyareti', 'Yakındaki tarihi yapıyı ziyaret edin.', 'Kolay', 180, 4, null),
      _s('e42', 'education', 'Aile Matematik Günü', 'Market hesabı, oran-orantı oyunu.', 'Kolay', 30, 4, null),
      _s('e43', 'education', 'Dünya Dinleri Tanıma', 'Saygı çerçevesinde bilgi edinin.', 'Kolay', 30, 4, null),
      _s('e44', 'education', 'Aile Fotoğraf Tarihi', 'Eski fotoğrafları tarihsel bağlamda anlatın.', 'Kolay', 45, 4, null),
      _s('e45', 'education', 'Seramik / Kil Çalışması', 'Evde tuz hamuru veya kil modelleme.', 'Kolay', 60, 4, null),
      _s('e46', 'education', 'İklim Değişikliği Paneli', 'Çocuklara bilinçlendirme, proje.', 'Kolay', 45, 4, null),
      _s('e47', 'education', 'Aile İngilizce Günü', '1 saat sadece İngilizce konuşun.', 'Kolay', 60, 4, null),
      _s('e48', 'education', 'Mıknatıs Deneyleri', 'Mıknatıslarla basit fizik deneyleri.', 'Kolay', 30, 4, null),
      _s('e49', 'education', 'Aile Tiyatro Yazımı', 'Birlikte senaryo yazın, oynayın.', 'Orta', 90, 4, null),
      _s('e50', 'education', 'Geometri Şekilleri Avı', 'Evde geometrik şekiller bulun, sayın.', 'Kolay', 20, 4, null),
      _s('e51', 'education', 'Birlikte Sudoku Çöz', 'Zorluk seviyesi artan sudoku.', 'Kolay', 20, 2, null),
      _s('e52', 'education', 'Aile Bilim Fuarı', 'Herkes bir proje hazırlasın, sergi açın.', 'Orta', 120, 4, null),
      _s('e53', 'education', 'Tarihsel Kostüm Günü', 'Dönem kıyafetleri giyin, fotoğraf çekin.', 'Kolay', 60, 4, null),
      _s('e54', 'education', 'Aile Yabancı Dil Pratiği', 'Otel, restoran rol yapma.', 'Kolay', 30, 4, null),
      _s('e55', 'education', 'Hayvan Adaptasyonu', 'Neden deve hörgüçlü, penguen uçamaz?', 'Kolay', 30, 4, null),
      _s('e56', 'education', 'Aile Gözlem Günlüğü', 'Hava, bitki, kuş gözlemi kaydetme.', 'Kolay', 15, 4, null),
      _s('e57', 'education', 'Dünya Bayrakları', 'Bayrakları tanıyın, hafıza oyunu.', 'Kolay', 20, 4, null),
      _s('e58', 'education', 'Aile Mimarlık Günü', 'Karton veya Lego ile bina tasarımı.', 'Kolay', 60, 4, null),
      _s('e59', 'education', 'Felsefe Sohbeti', 'Basit felsefi sorular, çocuklara uygun.', 'Kolay', 30, 4, null),
      _s('e60', 'education', 'Aile Matematik Olimpiyatı', 'Zor problemler, takım yarışması.', 'Orta', 45, 4, null),
      _s('e61', 'education', 'DNA ve Genetik', 'Basit genetik kavramlar, aile benzerlikleri.', 'Kolay', 30, 4, null),
      _s('e62', 'education', 'Aile Çevre Projesi', 'Geri dönüşüm, kompost, tasarruf.', 'Kolay', 60, 4, null),
      _s('e63', 'education', 'Osmanlıca Harfler', 'Eski harfleri tanıyın, isim yazın.', 'Kolay', 30, 4, null),
      _s('e64', 'education', 'Aile İcat Günü', 'Bir sorun bulun, çözüm tasarlayın.', 'Kolay', 60, 4, null),
      _s('e65', 'education', 'Dünya Okyanusları', 'Okyanus canlıları, kirlilik, belgesel.', 'Kolay', 45, 4, null),
      _s('e66', 'education', 'Aile Hikaye Zinciri', 'Herkes bir cümle, ortaya çıkan hikaye.', 'Kolay', 20, 4, null),
      _s('e67', 'education', 'Yeraltı Dünyası', 'Mağaralar, madenler, jeoloji.', 'Kolay', 30, 4, null),
      _s('e68', 'education', 'Aile Güvenlik Eğitimi', 'Yangın, deprem, ilk yardım bilgisi.', 'Kolay', 45, 4, null),
      _s('e69', 'education', 'Dünya Müzikleri Dinle', 'Farklı ülke müzikleri, ritim deneyin.', 'Kolay', 30, 4, null),
      _s('e70', 'education', 'Aile Röportaj', 'Büyüklerle röportaj yapın, kaydedin.', 'Kolay', 45, 4, null),
      _s('e71', 'education', 'Elektrik Devreleri', 'Pil, tel, ampul ile basit devre.', 'Kolay', 30, 4, null),
      _s('e72', 'education', 'Aile Dünya Saati', 'Farklı ülkelerin saatlerini hesaplayın.', 'Kolay', 15, 4, null),
      _s('e73', 'education', 'İnsan Vücudu Haritası', 'Organları öğrenin, maket çizin.', 'Kolay', 45, 4, null),
      _s('e74', 'education', 'Aile Basit Makineler', 'Kaldıraç, makara, eğik düzlem deneyi.', 'Kolay', 30, 4, null),
      _s('e75', 'education', 'Dünya Mitolojisi', 'Yunan, Türk, İskandinav mitleri.', 'Kolay', 30, 4, null),
      _s('e76', 'education', 'Aile Hava Durumu İstasyonu', 'Termometre, yağmur ölçer yapımı.', 'Kolay', 45, 4, null),
      _s('e77', 'education', 'Parçacık Fiziği (Basit)', 'Atom, proton, elektron modelleri.', 'Kolay', 30, 4, null),
      _s('e78', 'education', 'Aile Tarih Çizelgesi', 'Aile olaylarını tarihsel çizelgeye ekleyin.', 'Kolay', 30, 4, null),
      _s('e79', 'education', 'Dünya Enerji Kaynakları', 'Güneş, rüzgar, hidroelektrik.', 'Kolay', 30, 4, null),
      _s('e80', 'education', 'Aile Kriptografi', 'Basit şifreleme, Morse alfabesi.', 'Kolay', 30, 4, null),
      _s('e81', 'education', 'Uzay Keşfi', 'NASA, astronotlar, uzay istasyonu.', 'Kolay', 45, 4, null),
      _s('e82', 'education', 'Aile Tarih Müzesi', 'Evde minyatür müze kurun, objeler sergileyin.', 'Orta', 90, 4, null),
      _s('e83', 'education', 'Dinozor İsimleri', 'İsim anlamları, dönemleri, boyutları.', 'Kolay', 20, 4, null),
      _s('e84', 'education', 'Aile Zeka Küpü', 'Rubik küpü çözmeyi öğrenin, yarışın.', 'Orta', 30, 4, null),
      _s('e85', 'education', 'Yerel Tarih Araştırması', 'Mahallenizin, ilçenizin tarihi.', 'Kolay', 45, 4, null),
      _s('e86', 'education', 'Aile İstatistik Günü', 'Evdeki eşyaları sayın, grafik yapın.', 'Kolay', 30, 4, null),
      _s('e87', 'education', 'Bitki Fotosentezi', 'Yaprak deneyi, güneş ve su etkisi.', 'Kolay', 30, 4, null),
      _s('e88', 'education', 'Aile Arkeolojisi', 'Eski eşyaları araştırın, tarihini bulun.', 'Kolay', 45, 4, null),
      _s('e89', 'education', 'Dünya Saat Dilimleri', 'Harita üzerinde saat dilimleri.', 'Kolay', 20, 4, null),
      _s('e90', 'education', 'Aile Bilgi Kartları', 'Kartlara bilgi yazın, hafıza oyunu.', 'Kolay', 30, 4, null),
      _s('e91', 'education', 'İnsan Hakları Günü', 'Çocuk hakları, eşitlik konuşun.', 'Kolay', 30, 4, null),
      _s('e92', 'education', 'Aile Cografya Quiz', 'Başkentler, bayraklar, ünlü yerler.', 'Kolay', 20, 4, null),
      _s('e93', 'education', 'Ses Dalgaları Deneyi', 'Su, tel, kavanozla ses deneyleri.', 'Kolay', 30, 4, null),
      _s('e94', 'education', 'Aile Tarihsel Yürüyüş', 'Yakındaki tarihi yerleri keşfedin.', 'Kolay', 120, 4, null),
      _s('e95', 'education', 'Dünya Dilleri Tanıma', 'Selamlaşma, teşekkür, farklı diller.', 'Kolay', 20, 4, null),
      _s('e96', 'education', 'Aile Bilim Blogu', 'Birlikte blog yazın, paylaşın.', 'Orta', 60, 4, null),
      _s('e97', 'education', 'Yerçekimi ve Ağırlık', 'Terazi, yay deneyleri, ağırlık ölçüm.', 'Kolay', 30, 4, null),
      _s('e98', 'education', 'Aile Tarih Canlandırma', 'Tarihi olayları canlandırın, oynayın.', 'Orta', 60, 4, null),
      _s('e99', 'education', 'Dünya Mirasları', 'UNESCO miras listesi, Türkiye\'den örnekler.', 'Kolay', 30, 4, null),
      _s('e100', 'education', 'Aile Keşif Defteri', 'Yeni öğrenilen her şeyi kaydedin.', 'Kolay', 15, 4, null),
    ];
  }
  // ── BÜTÇE / FİNANS (50) ──
  static List<AISuggestion> _buildFinance() {
    return [
      _s('f01', 'finance', 'Market Alışveriş Listesi', 'İhtiyaç listesi yapın, gereksiz almayın.', 'Kolay', 15, 4, null),
      _s('f02', 'finance', 'Enerji Tasarrufu Günü', 'Gereksiz ışıkları kapatın, fişleri çekin.', 'Kolay', 0, 4, null),
      _s('f03', 'finance', 'Ev Yapımı Hediye', 'Doğum günü için evde hediye yapın.', 'Kolay', 60, 2, null),
      _s('f04', 'finance', 'Bütçe Kontrolü', 'Bu haftanın harcamalarını gözden geçirin.', 'Kolay', 20, 2, null),
      _s('f05', 'finance', 'Kumbara Sayımı', 'Biriken paraları sayın, hedef belirleyin.', 'Kolay', 15, 4, null),
      _s('f06', 'finance', 'Abonelik İnceleme', 'Kullanılmayan abonelikleri iptal edin.', 'Kolay', 20, 2, null),
      _s('f07', 'finance', 'Kupon ve İndirim Takibi', 'Haftalık market broşürlerini inceleyin.', 'Kolay', 15, 2, null),
      _s('f08', 'finance', 'Evde Tamir Günü', 'Küçük tamirleri kendiniz yapın.', 'Orta', 60, 2, null),
      _s('f09', 'finance', 'Aile Harcama Limiti', 'Bugün için harcama limiti belirleyin.', 'Kolay', 10, 2, null),
      _s('f10', 'finance', 'Birikim Hedefi Belirle', 'Ailece tatil, oyun hedefi seçin.', 'Kolay', 20, 4, null),
      _s('f11', 'finance', 'Yemek Sepeti Analizi', 'Son 1 ay yemek siparişi maliyetini hesaplayın.', 'Kolay', 15, 2, null),
      _s('f12', 'finance', 'Geri Dönüşüm Getirisi', 'Kağıt, plastik, cam geri dönüşüm kazancı.', 'Kolay', 20, 4, null),
      _s('f13', 'finance', 'Aile İkinci El Günü', 'Kullanılmayan eşyaları satın/takas edin.', 'Kolay', 60, 4, null),
      _s('f14', 'finance', 'Fatura Karşılaştırma', 'Son 3 ay elektrik, su, doğalgaz karşılaştırma.', 'Kolay', 20, 2, null),
      _s('f15', 'finance', 'Ev Yapımı Temizlik', 'Market ürünü yerine sirke, karbonat kullanın.', 'Kolay', 30, 2, null),
      _s('f16', 'finance', 'Aile Borsa Oyunu', 'Sanal para ile borsa oynayın, öğrenin.', 'Kolay', 30, 4, null),
      _s('f17', 'finance', 'Doğum Günü Bütçesi', 'Ailece doğum günü bütçesi planlayın.', 'Kolay', 20, 4, null),
      _s('f18', 'finance', 'Yakıt Tasarrufu', 'Toplu taşıma, yürüyüş, bisiklet günü.', 'Kolay', 0, 4, null),
      _s('f19', 'finance', 'Aile Kira Getirisi', 'Boş oda, garaj, depo değerlendirin.', 'Kolay', 30, 2, null),
      _s('f20', 'finance', 'Elektrikli Alet Kontrolü', 'Eski ampulleri LED ile değiştirin.', 'Kolay', 30, 2, null),
      _s('f21', 'finance', 'Aile Kredi Kartı Analizi', 'Taksit, faiz, ödeme planı gözden geçirin.', 'Kolay', 20, 2, null),
      _s('f22', 'finance', 'Ev Yapımı Kozmetik', 'Doğal yüz maskesi, saç bakımı.', 'Kolay', 30, 2, null),
      _s('f23', 'finance', 'Aile Sigorta İncelemesi', 'Mevcut sigortaları karşılaştırın.', 'Kolay', 30, 2, null),
      _s('f24', 'finance', 'Su Tasarruf Kontrolü', 'Sızıntı, akıllı başlık, bidon kullanımı.', 'Kolay', 20, 2, null),
      _s('f25', 'finance', 'Aile Yatırım Sohbeti', 'Borsa, altın, döviz, gayrimenkul bilgisi.', 'Kolay', 30, 2, null),
      _s('f26', 'finance', 'Okul Malzemesi Tasarrufu', 'Önceki yılın malzemelerini değerlendirin.', 'Kolay', 30, 2, null),
      _s('f27', 'finance', 'Aile Garaj Satışı', 'Kullanılmayan eşyaları komşulara satın.', 'Kolay', 120, 4, null),
      _s('f28', 'finance', 'İnternet Paketi İnceleme', 'Kullanımına göre uygun paket seçin.', 'Kolay', 20, 2, null),
      _s('f29', 'finance', 'Aile Yemek Bütçesi', 'Haftalık yemek bütçesi planlayın.', 'Kolay', 20, 4, null),
      _s('f30', 'finance', 'Doğal Gübre Yapımı', 'Kompost, bitki gübresi, bahçe tasarrufu.', 'Kolay', 30, 2, null),
      _s('f31', 'finance', 'Aile Vergi Bilgisi', 'Vergi iadeleri, indirimler, muafiyetler.', 'Kolay', 30, 2, null),
      _s('f32', 'finance', 'Kıyafet Takas Günü', 'Aile içi kıyafet takası, dışarıya satış.', 'Kolay', 60, 4, null),
      _s('f33', 'finance', 'Aile Telefon Faturası', 'Kullanılmayan hatları, fazla paketleri iptal edin.', 'Kolay', 20, 2, null),
      _s('f34', 'finance', 'Ev Yapımı Oyuncak', 'Karton, kumaştan oyuncak yapımı.', 'Kolay', 60, 4, null),
      _s('f35', 'finance', 'Aile Enerji Denetimi', 'Termostat, kombi, klima ayarlarını optimize edin.', 'Kolay', 20, 2, null),
      _s('f36', 'finance', 'Kitap Takası', 'Kullanılmayan kitapları takas edin, satın.', 'Kolay', 30, 4, null),
      _s('f37', 'finance', 'Aile Aidat Kontrolü', 'Site aidatı, giderler, karşılaştırma.', 'Kolay', 20, 2, null),
      _s('f38', 'finance', 'Ev Yapımı Sabun', 'Glycerin, esans, kalıp ile sabun yapımı.', 'Kolay', 45, 2, null),
      _s('f39', 'finance', 'Aile Tatil Bütçesi', 'Yıllık tatil hedefi ve birikim planı.', 'Kolay', 30, 4, null),
      _s('f40', 'finance', 'Gıda İsrafı Önleme', 'Buzdolabı düzeni, son kullanma tarihleri.', 'Kolay', 20, 4, null),
      _s('f41', 'finance', 'Aile Arıza Bütçesi', 'Acil durum fonu, beklenmeyen giderler.', 'Kolay', 20, 2, null),
      _s('f42', 'finance', 'Kendi Yıkama', 'Araba yıkama, halı yıkama, kuru temizleme.', 'Kolay', 60, 2, null),
      _s('f43', 'finance', 'Aile Kira Analizi', 'Kira artış oranları, piyasa karşılaştırma.', 'Kolay', 20, 2, null),
      _s('f44', 'finance', 'Ev Yapımı Mum', 'Parafin, fitil, koku ile mum yapımı.', 'Kolay', 45, 2, null),
      _s('f45', 'finance', 'Aile Eğlence Bütçesi', 'Sinema, oyun parkı, etkinlik maliyetleri.', 'Kolay', 20, 4, null),
      _s('f46', 'finance', 'Su Isıtıcı Bakımı', 'Kireç temizliği, verimlilik artışı.', 'Kolay', 30, 2, null),
      _s('f47', 'finance', 'Aile Sağlık Bütçesi', 'Spor, vitamin, kontrol maliyetleri.', 'Kolay', 20, 4, null),
      _s('f48', 'finance', 'Kendi Bakım Ürünleri', 'Doğal deodorant, diş macunu alternatifleri.', 'Kolay', 45, 2, null),
      _s('f49', 'finance', 'Aile Eğitim Fonu', 'Çocukların eğitimi için birikim planı.', 'Kolay', 20, 2, null),
      _s('f50', 'finance', 'Kış Hazırlık Bütçesi', 'Kombi bakımı, pencere contası, izolasyon.', 'Kolay', 30, 2, null),
    ];
  }

  // ── GÜVENLİK (20) ──
  static List<AISuggestion> _buildSafety() {
    return [
      _s('g01', 'safety', 'Acil Çıkış Planı', 'Yangın tatbikatı, toplanma noktası.', 'Kolay', 15, 4, null),
      _s('g02', 'safety', 'İlk Yardım Çantası', 'Eksik malzemeleri not alın, tamamlayın.', 'Kolay', 10, 2, null),
      _s('g03', 'safety', 'Ev Güvenlik Taraması', 'Priz kapakları, dolap kilidi kontrolü.', 'Kolay', 20, 2, null),
      _s('g04', 'safety', 'Acil İletişim Listesi', 'Önemli numaraları yazın, buzdolabına yapıştırın.', 'Kolay', 10, 2, null),
      _s('g05', 'safety', 'Bilgisayar Güvenliği', 'Şifreleri güncelleyin, çocuklara anlatın.', 'Kolay', 20, 2, null),
      _s('g06', 'safety', 'Deprem Çantası Kontrolü', 'Su, konserve, battaniye, el feneri kontrolü.', 'Kolay', 15, 2, null),
      _s('g07', 'safety', 'Gaz Kaçağı Testi', 'Kokulu sabun suyu ile bağlantı kontrolü.', 'Kolay', 15, 2, null),
      _s('g08', 'safety', 'Çocuk İnternet Güvenliği', 'Ebeveyn kontrolü, güvenli arama ayarları.', 'Kolay', 20, 2, null),
      _s('g09', 'safety', 'Yangın Söndürücü Kontrolü', 'Basınç göstergesi, son kullanma tarihi.', 'Kolay', 10, 1, null),
      _s('g10', 'safety', 'Aile GPS Paylaşımı', 'Telefonda konum paylaşımı açık mı kontrol edin.', 'Kolay', 10, 2, null),
      _s('g11', 'safety', 'Kimlik Fotokopisi', 'Herkesin kimlik fotokopisi ayrı yerde dursun.', 'Kolay', 15, 2, null),
      _s('g12', 'safety', 'Ev Alarm Sistemi Testi', 'Sensör, kamera, alarm testi.', 'Kolay', 15, 2, null),
      _s('g13', 'safety', 'Aile Şifre Protokolü', 'Kapı şifresi, telefon şifresi değiştirme.', 'Kolay', 15, 2, null),
      _s('g14', 'safety', 'Bisiklet Kask Kontrolü', 'Çocukların kaskı, dizliği, dirsekliği kontrolü.', 'Kolay', 10, 2, null),
      _s('g15', 'safety', 'Ev İlaç Dolabı Kontrolü', 'Son kullanma tarihleri, bozulanlar.', 'Kolay', 15, 2, null),
      _s('g16', 'safety', 'Aile Güvenlik Şifresi', 'SOS kod kelimesi belirleyin.', 'Kolay', 10, 4, null),
      _s('g17', 'safety', 'Duman Dedektörü Testi', 'Pil kontrolü, test butonuna basın.', 'Kolay', 10, 2, null),
      _s('g18', 'safety', 'Çocuk Kaçırma Eğitimi', 'Yabancıyla konuşmama, güvenli yetişkin.', 'Kolay', 20, 4, null),
      _s('g19', 'safety', 'Ev Anahtar Yedekleme', 'Yedek anahtar komşuda veya kasada.', 'Kolay', 10, 2, null),
      _s('g20', 'safety', 'Aile Afet Planı', 'Deprem, yangın, sel için aile planı.', 'Kolay', 30, 4, null),
    ];
  }

  // ── GÖREV / GENEL (100) ──
  static List<AISuggestion> _buildChores() {
    return [
      _s('t01', 'task', 'Dolap Düzenleme', 'Giyilmeyenleri ayırın, bağış yapın.', 'Orta', 45, 2, null),
      _s('t02', 'task', 'Buzdolabı Temizliği', 'Bozulmuşları atın, raf düzeni yapın.', 'Orta', 30, 2, null),
      _s('t03', 'task', 'Kitaplık Düzenleme', 'Kitapları kategoriye göre sıralayın.', 'Kolay', 30, 1, null),
      _s('t04', 'task', 'Balkon Düzenleme', 'Saksıları yeniden dizayn edin, süpürün.', 'Kolay', 40, 2, null),
      _s('t05', 'task', 'Fotoğraf Arşivleme', 'Telefondaki fotoğrafları kategorilere ayırın.', 'Orta', 60, 1, null),
      _s('t06', 'task', 'Ayakkabı Dolabı', 'Eskileri temizleyin veya atın.', 'Kolay', 20, 1, null),
      _s('t07', 'task', 'Çocuk Odası Revizyon', 'Oyuncakları sınıflandırın.', 'Orta', 45, 2, null),
      _s('t08', 'task', 'Mutfak Çekmecesi', 'Kaşık, çatal, spatula düzenini yenileyin.', 'Kolay', 20, 1, null),
      _s('t09', 'task', 'Banyo Rafı Düzenleme', 'Şampuan, sabun düzenini kontrol edin.', 'Kolay', 15, 1, null),
      _s('t10', 'task', 'Yatak Odası Havalandırma', 'Yorganları asın, pencere açın.', 'Kolay', 15, 1, null),
      _s('t11', 'task', 'Garaj / Kiler Kontrolü', 'Mevsimlik eşyaları yerleştirin.', 'Orta', 60, 2, null),
      _s('t12', 'task', 'E-posta ve Fatura Düzeni', 'Ödenmemiş faturaları kontrol edin.', 'Kolay', 20, 1, null),
      _s('t13', 'task', 'Aile Takvimi Güncelleme', 'Yaklaşan özel günleri takvime ekleyin.', 'Kolay', 15, 2, null),
      _s('t14', 'task', 'Evcil Hayvan Bakımı', 'Kafes, diş, tırnak kontrolü.', 'Kolay', 20, 2, null),
      _s('t15', 'task', 'Araba İçi Düzenleme', 'Eşyaları çıkarın, vakumlayın.', 'Kolay', 30, 2, null),
      _s('t16', 'task', 'Perde ve Yorgan Yıkama', 'Büyük çamaşır günü, makineye atın.', 'Orta', 45, 2, null),
      _s('t17', 'task', 'Halı ve Kilim Temizliği', 'Çırpma, süpürme, leke çıkarma.', 'Orta', 60, 2, null),
      _s('t18', 'task', 'Mutfak Dolabı İçi', 'Yağlı fırın, dolap içi silme.', 'Orta', 40, 1, null),
      _s('t19', 'task', 'Beyaz Eşya Temizliği', 'Buzdolabı, çamaşır makinesi, bulaşık makinesi.', 'Orta', 45, 1, null),
      _s('t20', 'task', 'Pencere Temizliği', 'Cam silme, pervaz tozu alma.', 'Orta', 60, 2, null),
      _s('t21', 'task', 'Elektrikli Süpürge Bakımı', 'Filtre, hortum, hazne temizliği.', 'Kolay', 15, 1, null),
      _s('t22', 'task', 'Ütü Masası Düzeni', 'Ütü masası, ütü suyu, kıyafet sırası.', 'Kolay', 15, 1, null),
      _s('t23', 'task', 'Giriş Kapısı Düzeni', 'Posta, ayakkabı, anahtarlık, askı.', 'Kolay', 10, 1, null),
      _s('t24', 'task', 'Tavan Arası Kontrolü', 'Toz, nem, böcek kontrolü.', 'Orta', 30, 1, null),
      _s('t25', 'task', 'Banyo Gider Temizliği', 'Kireç, saç, tıkanıklık giderici.', 'Kolay', 20, 1, null),
      _s('t26', 'task', 'Mutfak Tezgah Cilalama', 'Mermer, granit, ahşap tezgah bakımı.', 'Kolay', 15, 1, null),
      _s('t27', 'task', 'Çamaşır Sepeti Düzeni', 'Renklere göre ayırma, leke ön işlem.', 'Kolay', 10, 1, null),
      _s('t28', 'task', 'Yatak Takımı Değişimi', 'Çarşaf, yastık kılıfı, yorgan kılıfı.', 'Kolay', 20, 2, null),
      _s('t29', 'task', 'Mutfak Havlusu Değişimi', 'Kirli mutfak havluları, yeni takma.', 'Kolay', 5, 1, null),
      _s('t30', 'task', 'Buzdolabı Su Filtresi', 'Su filtresi değişimi, temizlik.', 'Kolay', 10, 1, null),
      _s('t31', 'task', 'Salon Minder Düzeni', 'Minder, kırlent, battaniye katlama.', 'Kolay', 10, 1, null),
      _s('t32', 'task', 'Çocuk Çizim Duvarı', 'Eski çizimleri kaldırın, yenileri asın.', 'Kolay', 15, 1, null),
      _s('t33', 'task', 'Banyo Aynası Temizliği', 'Leke, buğu, çerçeve tozu.', 'Kolay', 10, 1, null),
      _s('t34', 'task', 'Mutfak Baharatlık', 'Son kullanma tarihi, düzen, temizlik.', 'Kolay', 15, 1, null),
      _s('t35', 'task', 'Kiler Raf Düzeni', 'Konserve, makarna, bakliyat sıralama.', 'Kolay', 20, 1, null),
      _s('t36', 'task', 'Çöp Kutusu Dezenfekte', 'Çöp kutusu yıkama, koku giderici.', 'Kolay', 15, 1, null),
      _s('t37', 'task', 'Yatak Altı Temizliği', 'Toz, eşya, toz kağıdı kontrolü.', 'Kolay', 15, 1, null),
      _s('t38', 'task', 'Balkon Camı Silme', 'Dışarıdan ve içeriden cam silme.', 'Orta', 30, 1, null),
      _s('t39', 'task', 'Mutfak Musluk Parlatma', 'Kireç lekesi, pas, parlatıcı.', 'Kolay', 10, 1, null),
      _s('t40', 'task', 'Salon Lambası Tozu', 'Avize, aplik, lambader tozu alma.', 'Kolay', 15, 1, null),
      _s('t41', 'task', 'Çocuk Kitaplığı', 'Hasarlı kitaplar, kırık oyuncaklar.', 'Kolay', 20, 1, null),
      _s('t42', 'task', 'Banyo Havlu Değişimi', 'Kirli havlular, yeni havlu takma.', 'Kolay', 10, 1, null),
      _s('t43', 'task', 'Mutfak Robotu Temizliği', 'Blender, mikser, mutfak robotu parçaları.', 'Kolay', 15, 1, null),
      _s('t44', 'task', 'Giriş Paspası Temizliği', 'Paspas çırpma, yıkama, değiştirme.', 'Kolay', 10, 1, null),
      _s('t45', 'task', 'Yatak Odası Komodin', 'Çekmece düzeni, toz alma, lamba.', 'Kolay', 10, 1, null),
      _s('t46', 'task', 'Buzdolabı Magnet Düzeni', 'Eski magnetleri kaldırın, düzenleyin.', 'Kolay', 10, 1, null),
      _s('t47', 'task', 'Salon Sehpa Düzeni', 'Uzaktan kumanda, dergi, bardak altlığı.', 'Kolay', 10, 1, null),
      _s('t48', 'task', 'Çocuk Oyuncak Kutusu', 'Kırık, eksik, küçük parça kontrolü.', 'Kolay', 15, 1, null),
      _s('t49', 'task', 'Banyo Duşakabin Temizliği', 'Kireç, küf, silikon kontrolü.', 'Orta', 25, 1, null),
      _s('t50', 'task', 'Mutfak Ocak Temizliği', 'Gaz ocağı, elektrikli ocak, davlumbaz.', 'Orta', 20, 1, null),
      _s('t51', 'task', 'Yatak Odası Gardırop', 'Mevsimlik kıyafet değişimi, ayırma.', 'Orta', 45, 1, null),
      _s('t52', 'task', 'Balkon Sulama Sistemi', 'Saksı sulama, damlama sistemi kontrolü.', 'Kolay', 15, 1, null),
      _s('t53', 'task', 'Mutfak Çöp Konteyneri', 'Geri dönüşüm ayrımı, poşet değişimi.', 'Kolay', 10, 1, null),
      _s('t54', 'task', 'Salon TV Arkası', 'Kablo düzeni, toz, dekoratif düzen.', 'Kolay', 15, 1, null),
      _s('t55', 'task', 'Çocuk Çalışma Masası', 'Kalem, defter, kitap düzeni.', 'Kolay', 15, 1, null),
      _s('t56', 'task', 'Banyo Lavabo Altı', 'Temizlik malzemeleri, düzen, son kullanma.', 'Kolay', 10, 1, null),
      _s('t57', 'task', 'Mutfak Fırın Temizliği', 'Yanmış yağ, koku, fırın tepsisi.', 'Orta', 30, 1, null),
      _s('t58', 'task', 'Yatak Odası Perde Yıkama', 'Perdeleri indirin, yıkayın, asın.', 'Orta', 40, 2, null),
      _s('t59', 'task', 'Salon Halı Yıkama', 'Kuru köpük, leke çıkarıcı, vakum.', 'Orta', 45, 2, null),
      _s('t60', 'task', 'Çocuk Spor Malzemeleri', 'Top, raket, paten düzeni ve kontrol.', 'Kolay', 15, 1, null),
      _s('t61', 'task', 'Banyo Klozet Temizliği', 'Derinlemesine temizlik, koku giderici.', 'Kolay', 15, 1, null),
      _s('t62', 'task', 'Mutfak Buzdolabı Dışı', 'Kapak, kulp, mıknatıs, toz alma.', 'Kolay', 10, 1, null),
      _s('t63', 'task', 'Yatak Odası Ayna', 'Toz, leke, çerçeve temizliği.', 'Kolay', 10, 1, null),
      _s('t64', 'task', 'Salon Kitaplık Tozu', 'Kitap sırtı, raf, süs eşyası tozu.', 'Kolay', 15, 1, null),
      _s('t65', 'task', 'Çocuk Kıyafet Ayırma', 'Küçülen, yıpranan, mevsimsel ayırma.', 'Orta', 30, 1, null),
      _s('t66', 'task', 'Banyo Duş Başlığı', 'Kireç temizliği, su basıncı kontrolü.', 'Kolay', 10, 1, null),
      _s('t67', 'task', 'Mutfak Tepsi Düzeni', 'Fırın tepsisi, kek kalıbı, saklama.', 'Kolay', 10, 1, null),
      _s('t68', 'task', 'Yatak Odası Lamba Abajur', 'Toz, leke, ampul değişimi.', 'Kolay', 10, 1, null),
      _s('t69', 'task', 'Salon Koltuk Yıkama', 'Kumaş temizleyici, leke çıkarma.', 'Orta', 40, 2, null),
      _s('t70', 'task', 'Çocuk Sanat Malzemeleri', 'Boyama, hamur, yapıştırıcı düzeni.', 'Kolay', 15, 1, null),
      _s('t71', 'task', 'Banyo Zemin Temizliği', 'Fayans arası, küf, derinlemesine.', 'Orta', 25, 1, null),
      _s('t72', 'task', 'Mutfak Raf Örtüsü', 'Raf örtülerini değiştirin, yıkayın.', 'Kolay', 15, 1, null),
      _s('t73', 'task', 'Yatak Odası Halısı', 'Vakum, leke, ters çevirme.', 'Kolay', 15, 1, null),
      _s('t74', 'task', 'Salon Pencere Önü', 'Perde, saksı, pencere sırası düzeni.', 'Kolay', 10, 1, null),
      _s('t75', 'task', 'Çocuk Takvim ve Plan', 'Okul takvimi, etkinlik, ödev planı.', 'Kolay', 15, 1, null),
      _s('t76', 'task', 'Banyo Fan ve Havalandırma', 'Toz, yağ, koku filtre kontrolü.', 'Kolay', 10, 1, null),
      _s('t77', 'task', 'Mutfak Ekmek Kutusu', 'Kuru ekmek temizliği, kutu yıkama.', 'Kolay', 10, 1, null),
      _s('t78', 'task', 'Yatak Odası Çekmece Düzeni', 'Çorap, iç çamaşırı, atkı düzeni.', 'Kolay', 20, 1, null),
      _s('t79', 'task', 'Salon Dekor Değişimi', 'Mevsimsel dekor, çerçeve, mum.', 'Kolay', 30, 1, null),
      _s('t80', 'task', 'Çocuk Ayakkabı Düzeni', 'Okul, spor, bot ayırma, temizlik.', 'Kolay', 15, 1, null),
      _s('t81', 'task', 'Banyo Sabunluk Temizliği', 'Kireç, sabun kalıntısı, dezenfekte.', 'Kolay', 10, 1, null),
      _s('t82', 'task', 'Mutfak Tencere Düzeni', 'Tencere, tava, kapak sıralama.', 'Kolay', 15, 1, null),
      _s('t83', 'task', 'Yatak Odası Perde Boyama', 'Eski perdeyi boyayın, yenileyin.', 'Orta', 60, 2, null),
      _s('t84', 'task', 'Salon Müzik Sistemi', 'Hoparlör tozu, kablo düzeni, raf.', 'Kolay', 10, 1, null),
      _s('t85', 'task', 'Çocuk Yatak Düzeni', 'Çarşaf, yorgan, yastık düzeni.', 'Kolay', 10, 1, null),
      _s('t86', 'task', 'Banyo Bornoz Askısı', 'Bornoz, havlu askı düzeni, temizlik.', 'Kolay', 10, 1, null),
      _s('t87', 'task', 'Mutfak Kağıt Havluluk', 'Yedek, düzen, doldurma kontrolü.', 'Kolay', 5, 1, null),
      _s('t88', 'task', 'Yatak Odası Duvar Temizliği', 'Lekeler, toz, süs değişimi.', 'Kolay', 20, 1, null),
      _s('t89', 'task', 'Salon Giriş Dekoru', 'Vazo, ayna, çiçek, hoşgeldiniz.', 'Kolay', 15, 1, null),
      _s('t90', 'task', 'Çocuk Ödev Kontrolü', 'Biten ödevler, imza, eksikler.', 'Kolay', 15, 1, null),
      _s('t91', 'task', 'Banyo Musluk Parlatma', 'Krom, paslanmaz çelik parlatıcı.', 'Kolay', 10, 1, null),
      _s('t92', 'task', 'Mutfak Pencere Önü', 'Bitki, güneşlik, toz kontrolü.', 'Kolay', 10, 1, null),
      _s('t93', 'task', 'Yatak Odası Klima Filtresi', 'Filtre temizliği, koku kontrolü.', 'Kolay', 15, 1, null),
      _s('t94', 'task', 'Salon Tablo ve Çerçeve', 'Toz, dengesizlik, yeni resim asma.', 'Kolay', 15, 1, null),
      _s('t95', 'task', 'Çocuk Spor Çantası', 'Forma, şort, ayakkabı düzeni.', 'Kolay', 10, 1, null),
      _s('t96', 'task', 'Banyo Tuvalet Kağıtlığı', 'Yedek, düzen, doldurma.', 'Kolay', 5, 1, null),
      _s('t97', 'task', 'Mutfak Elektrikli Cihazlar', 'Kettle, tost makinesi, mikrodalga dışı.', 'Kolay', 15, 1, null),
      _s('t98', 'task', 'Yatak Odası Gardırop Işığı', 'Ampul değişimi, düzen, toz.', 'Kolay', 10, 1, null),
      _s('t99', 'task', 'Salon Klima ve Kalorifer', 'Petek temizliği, klima filtresi.', 'Orta', 30, 1, null),
      _s('t100', 'task', 'Çocuk Odası Duvar Sticker', 'Eski çıkartmaları kaldırın, yenileyin.', 'Kolay', 20, 1, null),
    ];
  }

  static AISuggestion _s(
    String id,
    String type,
    String title,
    String description,
    String difficulty,
    int duration,
    int servings,
    int? calories,
  ) {
    return AISuggestion(
      id: id,
      type: type,
      title: title,
      description: description,
      action: _actionForType(type),
      difficulty: difficulty,
      durationMinutes: duration,
      servings: servings,
      calories: calories,
      ingredients: [],
      tips: [_randomTip(type)],
      isNew: false,
      shareable: true,
      allowAlternatives: false,
      progress: 0,
      isFavorite: false,
      assignedTo: null,
      estimatedCost: null,
      userComment: null,
      badge: null,
      nutritionInfo: null,
      alternativeOptions: [],
    );
  }

  static String _actionForType(String type) {
    switch (type) {
      case 'recipe': return 'show_detail';
      case 'chore': return 'create_task';
      case 'social': return 'create_event';
      case 'health': return 'show_detail';
      case 'education': return 'show_detail';
      case 'finance': return 'navigate_budget';
      case 'safety': return 'show_detail';
      default: return 'show_detail';
    }
  }

  static String _randomTip(String type) {
    final tips = {
      'recipe': [
        'Malzemeleri önceden hazırlayın, süre yarıya inecek.',
        'Çocukları mutfağa davet edin, hem eğlenir hem öğrenir.',
        'Fazla yemeği dondurucuya koyun, ertesi gün pratik olsun.',
      ],
      'chore': [
        'Müzik açın, temizlik daha keyifli olur.',
        'Küçük ödüller motivasyonu artırır.',
        'Zamanlayıcı kurun, yarışma havası oluşturun.',
      ],
      'social': [
        'Fotoğraf çekmeyi unutmayın, anılar galeride kalsın.',
        'Herkes fikrini söylesin, demokratik planlama yapın.',
        'Hava durumunu kontrol edin, yağmurlu gün alternatifi hazır olsun.',
      ],
      'health': [
        'Su şişenizi yanınızda taşıyın, hatırlatma kurun.',
        'Küçük adımlarla başlayın, sürdürülebilir olsun.',
        'Ailece yapınca motive olmak daha kolay.',
      ],
      'education': [
        'Öğrenmeyi oyunlaştırın, puan tablosu yapın.',
        'Her gün 15 dakika bile düzenli pratik çok şey kazandırır.',
        'Çocuklara öğretirken kendiniz de öğrenirsiniz.',
      ],
      'finance': [
        'Küçük birikimler bile zamanla büyür.',
        'Ailece karar verilen harcamalar daha bilinçli olur.',
        'İhtiyaç vs. istek listesi yapın, farkı görün.',
      ],
      'safety': [
        'Çocuklara şarkıyla hatırlatma yapın.',
        'Yılda en az 2 kez yangın tatbikatı yapın.',
        'Acil durum çantasını kolay ulaşılabilir yerde tutun.',
      ],
    };
    final list = tips[type] ?? ['Ailece yapılan her şey daha keyifli!'];
    return list[_random.nextInt(list.length)];
  }
}

// ── Chore Rotation Service ──
class ChoreRotationService {
  static final _chores = [
    _Chore('ch1', 'Mutfak Tezgahı Temizliği', 'Tezgahı silin, lavaboyu temizleyin, çöpü atın.', 15, 'chore'),
    _Chore('ch2', 'Salon Süpürgesi', 'Halı ve yerleri süpürün, minderleri düzeltin.', 20, 'chore'),
    _Chore('ch3', 'Çamaşır Makinesi', 'Kirli çamaşırları toplayın, makineye atın, kurutun.', 30, 'chore'),
    _Chore('ch4', 'Bulaşık Makinesi', 'Kirli bulaşıkları makineye dizin, temizleri yerleştirin.', 15, 'chore'),
    _Chore('ch5', 'Banyo Temizliği', 'Klozeti, lavaboyu, duşu temizleyin, havluları değiştirin.', 25, 'chore'),
    _Chore('ch6', 'Toz Alma Günü', 'Mobilyaların üzerini silin, rafları düzenleyin.', 20, 'chore'),
    _Chore('ch7', 'Cam ve Ayna Silme', 'Bütün camları ve aynaları parlatın.', 20, 'chore'),
    _Chore('ch8', 'Yatak Odası Düzeni', 'Yatakları yayın, kıyafetleri katlayın.', 15, 'chore'),
    _Chore('ch9', 'Çocuk Odası Toplama', 'Oyuncakları kutulara koyun, kitapları sıralayın.', 20, 'chore'),
    _Chore('ch10', 'Balkon ve Giriş', 'Süpürün, ayakkabıları düzeltin, saksıları kontrol edin.', 15, 'chore'),
    _Chore('ch11', 'Buzdolabı Kontrolü', 'Bozulmuş ürünleri atın, rafları silin.', 15, 'chore'),
    _Chore('ch12', 'Çöp Atma Günü', 'Tüm çöpleri toplayın, poşetleri değiştirin.', 10, 'chore'),
    _Chore('ch13', 'Yemek Masası Hazırlığı', 'Masayı kurun, peçete koyun, su bardağı hazırlayın.', 10, 'chore'),
    _Chore('ch14', 'Evcil Hayvan Bakımı', 'Mama ve suyunu kontrol edin, kafesi/tuvaleti temizleyin.', 15, 'chore'),
  ];

  static final List<String> _members = ['Anne', 'Baba', 'Çocuk 1', 'Çocuk 2'];

  static AISuggestion getTodayChore(DateTime date) {
    final dayOfYear = date.difference(DateTime(date.year, 1, 1)).inDays;
    final choreIndex = dayOfYear % _chores.length;
    final memberIndex = dayOfYear % _members.length;

    final chore = _chores[choreIndex];
    final member = _members[memberIndex];

    return AISuggestion(
      id: chore.id,
      type: 'chore',
      title: chore.title,
      description: '${chore.description}\n\n🎯 Sorumlu: $member',
      action: 'create_task',
      difficulty: 'Kolay',
      durationMinutes: chore.duration,
      servings: null,
      calories: null,
      ingredients: [],
      tips: [
        'Müzik açın, temizlik daha keyifli olur!',
        'Süreye dikkat edin, zamanlayıcı kurun.',
        'İşlem sonrası küçük bir ödül hak ediyorsunuz.',
      ],
      isNew: true,
      shareable: true,
      allowAlternatives: true,
      progress: 0,
      isFavorite: false,
      assignedTo: member,
      estimatedCost: 'Ücretsiz',
      userComment: null,
      badge: '🧹 Günün Görevi',
      nutritionInfo: null,
      alternativeOptions: [
        const AlternativeOption(
          title: 'Başka Görev Seç',
          description: 'Bugün farklı bir temizlik görevi yapın.',
          reason: 'Değişiklik iyi gelir.',
        ),
        const AlternativeOption(
          title: 'Yardım Et',
          description: 'Aile üyesine yardım edin, birlikte yapın.',
          reason: 'Birlikte daha hızlı.',
        ),
        const AlternativeOption(
          title: 'Ertele',
          description: 'Yarın yapın ama unutmayın!',
          reason: 'Mola da hakkınız.',
        ),
      ],
    );
  }

  static List<Map<String, dynamic>> getWeeklySchedule(DateTime startDate) {
    final result = <Map<String, dynamic>>[];
    for (int i = 0; i < 7; i++) {
      final day = startDate.add(Duration(days: i));
      final dayOfYear = day.difference(DateTime(day.year, 1, 1)).inDays;
      final chore = _chores[dayOfYear % _chores.length];
      final member = _members[dayOfYear % _members.length];
      result.add({
        'day': DateFormat('EEEE', 'tr_TR').format(day),
        'date': DateFormat('dd MMM').format(day),
        'chore': chore.title,
        'member': member,
        'duration': chore.duration,
      });
    }
    return result;
  }
}

class _Chore {
  final String id;
  final String title;
  final String description;
  final int duration;
  final String type;
  _Chore(this.id, this.title, this.description, this.duration, this.type);
}
