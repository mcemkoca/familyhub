import 'package:flutter/material.dart';
import '../../../services/ai/ai_content_service.dart';

/// Görselli çocuk hikayeleri havuzu + günlük 4 hikaye rotasyonu.
/// Hikayeler klasik/halk masalları ve öğretici kısa hikayelerdir (aile dostu).
/// Görsel: her hikayenin sahne emojisi + degrade (güvenilir, ağ bağımsız);
/// isteyene "internetten devamını oku" bağlantısı sunulur.

class KidStory {
  final String id;
  final String title;
  final String emoji;
  final List<Color> gradient;
  final String moral;
  final List<String> pages;
  final String? readMoreUrl;
  final int minAge; // yaş (yıl)
  const KidStory({
    required this.id,
    required this.title,
    required this.emoji,
    required this.gradient,
    required this.moral,
    required this.pages,
    this.readMoreUrl,
    this.minAge = 3,
  });
}

const List<KidStory> kidStories = [
  KidStory(
    id: 'aslan_fare',
    title: 'Aslan ile Fare',
    emoji: '🦁',
    gradient: [Color(0xFFF59E0B), Color(0xFFD97706)],
    moral: 'Küçük bir dost bile büyük yardım edebilir.',
    pages: [
      'Bir ormanda kocaman bir aslan uyuyordu. Küçük bir fare koşarken '
          'yanlışlıkla aslanın üzerine çıktı ve onu uyandırdı.',
      'Aslan fareyi patisiyle yakaladı. Fare: "Lütfen beni bırak, bir gün '
          'sana ben de yardım ederim!" dedi. Aslan güldü ama onu bıraktı.',
      'Günler sonra aslan avcıların ağına yakalandı. Kükredi ama '
          'kurtulamadı. Fare sesi duydu ve koşarak geldi.',
      'Fare keskin dişleriyle ipleri kemirdi ve aslanı kurtardı. '
          'Aslan, küçük dostuna teşekkür etti.',
    ],
    readMoreUrl:
        'https://www.google.com/search?q=aslan+ile+fare+masalı+çocuk',
  ),
  KidStory(
    id: 'tavsan_kaplumbaga',
    title: 'Tavşan ile Kaplumbağa',
    emoji: '🐢',
    gradient: [Color(0xFF10B981), Color(0xFF059669)],
    moral: 'Yavaş ama kararlı olan kazanır.',
    pages: [
      'Hızlı bir tavşan, yavaş kaplumbağayla dalga geçerdi. '
          'Kaplumbağa bir gün ona yarış teklif etti.',
      'Yarış başladı. Tavşan çok hızlıydı, öne geçti. "Kaplumbağa çok '
          'geride, biraz uyusam da olur" dedi ve bir ağacın altında uyudu.',
      'Kaplumbağa ise hiç durmadan, yavaş yavaş yürüdü. '
          'Tavşanın yanından sessizce geçti.',
      'Tavşan uyanınca kaplumbağanın bitişe vardığını gördü. '
          'Kaplumbağa kararlılığıyla yarışı kazanmıştı.',
    ],
  ),
  KidStory(
    id: 'karinca_agustos',
    title: 'Karınca ile Ağustos Böceği',
    emoji: '🐜',
    gradient: [Color(0xFF8B5CF6), Color(0xFF7C3AED)],
    moral: 'Zamanında çalışmak, sonra rahat etmeyi sağlar.',
    pages: [
      'Yazın karınca kışlık yiyecek taşırken, ağustos böceği '
          'gün boyu şarkı söyleyip eğleniyordu.',
      '"Gel biraz dinlen!" dedi ağustos böceği. Karınca: '
          '"Kış gelince yiyecek lazım olacak" diye çalışmaya devam etti.',
      'Kış geldi, hava soğudu. Ağustos böceği aç kaldı. '
          'Karıncanın kapısını çaldı.',
      'Karınca ona yardım etti ama ağustos böceği artık '
          'zamanında hazırlık yapmayı öğrenmişti.',
    ],
  ),
  KidStory(
    id: 'kirmizi_baslikli',
    title: 'Kırmızı Başlıklı Kız',
    emoji: '🧺',
    gradient: [Color(0xFFEF4444), Color(0xFFDC2626)],
    moral: 'Yabancılara dikkatli olmalı ve büyükleri dinlemeliyiz.',
    pages: [
      'Kırmızı başlıklı kız, hasta olan büyükannesine yiyecek '
          'götürmek için ormandan geçiyordu.',
      'Yolda bir kurtla karşılaştı. Kurt ona büyükannesinin evini '
          'sordu. Kız bilmeden anlattı.',
      'Kurt önce eve gitti. Ama ormancı gürültüyü duydu ve '
          'yardıma koştu.',
      'Ormancı büyükanneyi ve kızı kurtardı. Kız artık '
          'yabancılarla konuşurken daha dikkatli olacaktı.',
    ],
  ),
  KidStory(
    id: 'uc_kucuk_domuz',
    title: 'Üç Küçük Domuz',
    emoji: '🐷',
    gradient: [Color(0xFFEC4899), Color(0xFFDB2777)],
    moral: 'Sağlam ve özenli iş, bizi korur.',
    pages: [
      'Üç küçük domuz kendilerine ev yapmaya karar verdi. '
          'Biri samandan, biri çalıdan, biri tuğladan.',
      'Kurt geldi. Saman evi ve çalı evi kolayca üfleyip yıktı. '
          'Domuzlar tuğla eve kaçtı.',
      'Kurt tuğla evi ne kadar üflese de yıkamadı. '
          'Ev çok sağlamdı.',
      'Üç domuz güvenle tuğla evde kaldı. Özenle yapılan iş '
          'onları korumuştu.',
    ],
  ),
  KidStory(
    id: 'altin_yumurta',
    title: 'Altın Yumurtlayan Tavuk',
    emoji: '🐔',
    gradient: [Color(0xFFF59E0B), Color(0xFFEAB308)],
    moral: 'Açgözlülük elimizdekini de kaybettirir.',
    pages: [
      'Bir çiftçinin tavuğu her gün bir altın yumurta yumurtluyordu. '
          'Çiftçi çok mutluydu.',
      'Ama çiftçi sabırsızlandı. "Karnında bir sürü altın olmalı" '
          'diye düşündü.',
      'Açgözlülükle tavuğu kesti ama içinde hiç altın yoktu.',
      'Artık her gün gelen altın yumurta da yoktu. Çiftçi '
          'sahip olduğunun kıymetini geç anladı.',
    ],
  ),
  KidStory(
    id: 'balik_dilek',
    title: 'Konuşan Balık',
    emoji: '🐟',
    gradient: [Color(0xFF3B82F6), Color(0xFF2563EB)],
    moral: 'İyilik yapmak, iyilikle geri döner.',
    pages: [
      'Küçük bir çocuk gölde yakaladığı balığı, gözlerindeki '
          'üzüntüyü görünce suya geri bıraktı.',
      'Balık: "Teşekkürler! İyiliğini unutmayacağım" dedi ve '
          'suya daldı.',
      'Bir gün çocuğun oyuncağı göle düştü. Balık onu bulup '
          'kıyıya getirdi.',
      'Çocuk çok sevindi. İyiliğin karşılıksız kalmadığını gördü.',
    ],
  ),
  KidStory(
    id: 'yildiz_toplayan',
    title: 'Yıldız Toplayan Çocuk',
    emoji: '⭐',
    gradient: [Color(0xFF6366F1), Color(0xFF4F46E5)],
    moral: 'Küçük iyilikler dünyayı aydınlatır.',
    pages: [
      'Bir çocuk her gece gökyüzündeki bir yıldıza bir iyilik '
          'diler, sonra birine yardım ederdi.',
      'Bir gün arkadaşına oyuncağını paylaştı, yaşlı komşusuna '
          'çantasını taşıdı.',
      'Yaptığı her iyilikte içi ışıl ışıl oldu, tıpkı yıldızlar gibi.',
      'Zamanla mahallesindeki herkes birbirine yardım etmeye '
          'başladı. Küçük iyilikler çoğalmıştı.',
    ],
  ),
  KidStory(
    id: 'renkli_gokkusagi',
    title: 'Renkleri Küsen Gökkuşağı',
    emoji: '🌈',
    gradient: [Color(0xFF14B8A6), Color(0xFF06B6D4)],
    moral: 'Farklılıklar bir araya gelince güzellik olur.',
    pages: [
      'Gökkuşağının renkleri "En güzel benim!" diye tartışıyordu. '
          'Kırmızı, mavi, sarı… hepsi küsmüştü.',
      'Renkler ayrılınca gökyüzü rengini kaybetti, her yer '
          'gri oldu.',
      'Yağmur geldi ve renklere "Birlikte olursanız gökkuşağı '
          'olursunuz" dedi.',
      'Renkler el ele tutuştu ve gökyüzünde kocaman, güzel bir '
          'gökkuşağı belirdi. Herkes onları sevdi.',
    ],
  ),
  KidStory(
    id: 'kucuk_tohum',
    title: 'Küçük Tohumun Yolculuğu',
    emoji: '🌱',
    gradient: [Color(0xFF22C55E), Color(0xFF16A34A)],
    moral: 'Sabırla büyüyen şeyler en güçlü olur.',
    pages: [
      'Toprağın altında küçük bir tohum vardı. "Ne zaman ağaç '
          'olacağım?" diye merak ediyordu.',
      'Güneş ısıttı, yağmur suladı. Tohum yavaş yavaş filizlendi, '
          'toprağın üstüne çıktı.',
      'Rüzgâr onu sarssa da tohum kökleriyle sıkıca tutundu, '
          'her gün biraz daha büyüdü.',
      'Yıllar sonra kocaman bir ağaç oldu; kuşlara yuva, '
          'insanlara gölge verdi.',
    ],
  ),
  KidStory(
    id: 'ayicik_uyku',
    title: 'Uyumak İstemeyen Ayıcık',
    emoji: '🐻',
    gradient: [Color(0xFFA855F7), Color(0xFF9333EA)],
    moral: 'Dinlenmek, ertesi gün güçlü olmamızı sağlar.',
    pages: [
      'Küçük ayıcık kış uykusuna yatmak istemiyordu. '
          '"Daha oynamak istiyorum!" diyordu.',
      'Annesi ona sıcak bir yatak hazırladı ve bir masal anlattı.',
      'Ayıcık esnedi, gözleri ağırlaştı. Rüyasında bahar '
          'çiçekleriyle oynadı.',
      'Baharda uyandığında kocaman ve güçlüydü. İyi bir uykunun '
          'ne kadar iyi geldiğini anladı.',
    ],
  ),
  KidStory(
    id: 'paylasan_elma',
    title: 'Paylaşan Elma Ağacı',
    emoji: '🍎',
    gradient: [Color(0xFFEF4444), Color(0xFFF97316)],
    moral: 'Paylaşmak mutluluğu çoğaltır.',
    pages: [
      'Bahçede kırmızı elmalarla dolu bir ağaç vardı. '
          'Çocuklar gelip elmaları toplardı.',
      'Bir çocuk topladığı elmaları arkadaşlarıyla paylaştı. '
          'Herkes bir elma yedi.',
      'Ağaç bunu görünce mutlu oldu ve ertesi yıl daha çok '
          'elma verdi.',
      'Paylaştıkça çoğaldı; bahçe kahkahalarla doldu.',
    ],
  ),
];

/// Güne göre deterministik 4 hikaye döndürür (her gün farklı).
List<KidStory> dailyStories({int count = 4}) {
  final now = DateTime.now();
  final dayIndex = now.difference(DateTime(2020)).inDays;
  final start = (dayIndex * 4) % kidStories.length;
  final result = <KidStory>[];
  for (var i = 0; i < count; i++) {
    result.add(kidStories[(start + i * 3) % kidStories.length]);
  }
  // Tekrarı azalt
  final seen = <String>{};
  final unique = <KidStory>[];
  for (final s in result) {
    if (seen.add(s.id)) unique.add(s);
  }
  var k = 0;
  while (unique.length < count && k < kidStories.length) {
    if (seen.add(kidStories[k].id)) unique.add(kidStories[k]);
    k++;
  }
  return unique.take(count).toList();
}

/// İnternetten (AI) günlük taze 4 hikaye üretir; başarısız/çevrimdışıysa
/// yerel [dailyStories] havuzuna düşer. Günlük önbelleklidir.
Future<List<KidStory>> aiDailyStories({int count = 4}) async {
  const palette = [
    [Color(0xFFF59E0B), Color(0xFFD97706)],
    [Color(0xFF10B981), Color(0xFF059669)],
    [Color(0xFF3B82F6), Color(0xFF2563EB)],
    [Color(0xFF8B5CF6), Color(0xFF6D28D9)],
    [Color(0xFFEC4899), Color(0xFFDB2777)],
  ];
  const emojis = ['🦊', '🐻', '🐰', '🦉', '🐢', '🐸', '🦁', '🐼'];

  final items = await AiContentService.dailyList(
    topic: 'kid_stories',
    prompt:
        'Bugün için 3-7 yaş çocuklara uygun, öğretici, güvenli 4 kısa masal '
        'üret. Her masal 3-4 kısa paragraf olsun. Sadece JSON döndür: '
        '{"items":[{"title":"...","moral":"...","pages":["...","..."]}]}. '
        'Türkçe, sıcak ve sade bir dille.',
    listKey: 'items',
    fallback: const [],
    maxTokens: 1600,
  );

  if (items.isEmpty) return dailyStories(count: count);

  final stories = <KidStory>[];
  for (var i = 0; i < items.length && stories.length < count; i++) {
    final m = items[i];
    final title = m['title']?.toString() ?? '';
    final pagesRaw = m['pages'];
    final pages = pagesRaw is List
        ? pagesRaw.map((e) => e.toString()).where((e) => e.isNotEmpty).toList()
        : <String>[];
    if (title.isEmpty || pages.isEmpty) continue;
    stories.add(KidStory(
      id: 'ai_${DateTime.now().day}_$i',
      title: title,
      emoji: emojis[i % emojis.length],
      gradient: palette[i % palette.length],
      moral: m['moral']?.toString() ?? '',
      pages: pages,
      readMoreUrl:
          'https://www.google.com/search?q=${Uri.encodeComponent('$title çocuk masalı')}',
      minAge: 3,
    ));
  }
  return stories.isEmpty ? dailyStories(count: count) : stories;
}
