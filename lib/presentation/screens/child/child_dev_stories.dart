import 'package:flutter/material.dart';
import '../../../services/ai/ai_content_service.dart';
import '../../../features/content/domain/localized_content.dart' show contentFallbackChain;

/// Görselli çocuk hikayeleri havuzu + günlük 4 hikaye rotasyonu.
/// Hikayeler klasik/halk masalları ve öğretici kısa hikayelerdir (aile dostu).
/// ÇOK DİLLİ: başlık ve ahlak dersi 4 dilde (tr/en/fr/nl); gövde (pages) şu an
/// TR + fallback — EN/FR/NL gövde çevirisi takip işidir (LocalizedContent modeli).

class KidStory {
  final String id;
  final Map<String, String> titleL10n;
  final Map<String, String> moralL10n;
  final Map<String, List<String>> pagesL10n;
  final String emoji;
  final List<Color> gradient;
  final String? readMoreUrl;
  final int minAge; // yaş (yıl)

  const KidStory({
    required this.id,
    required this.titleL10n,
    required this.moralL10n,
    required this.pagesL10n,
    required this.emoji,
    required this.gradient,
    this.readMoreUrl,
    this.minAge = 3,
  });

  /// AI/tek dilli hikaye için kısayol (aktif dile göre tek dil kaydı).
  factory KidStory.single({
    required String id,
    required String title,
    required String moral,
    required List<String> pages,
    required String emoji,
    required List<Color> gradient,
    String locale = 'tr',
    String? readMoreUrl,
    int minAge = 3,
  }) =>
      KidStory(
        id: id,
        titleL10n: {locale: title},
        moralL10n: {locale: moral},
        pagesL10n: {locale: pages},
        emoji: emoji,
        gradient: gradient,
        readMoreUrl: readMoreUrl,
        minAge: minAge,
      );

  String _pick(Map<String, dynamic> m, String locale) {
    for (final l in contentFallbackChain(locale)) {
      if (m.containsKey(l)) return l;
    }
    return m.keys.first;
  }

  String titleOf(String locale) => titleL10n[_pick(titleL10n, locale)] ?? '';
  String moralOf(String locale) => moralL10n[_pick(moralL10n, locale)] ?? '';
  List<String> pagesOf(String locale) =>
      pagesL10n[_pick(pagesL10n, locale)] ?? const [];
}

const List<KidStory> kidStories = [
  KidStory(
    id: 'aslan_fare',
    titleL10n: {
      'tr': 'Aslan ile Fare',
      'en': 'The Lion and the Mouse',
      'fr': 'Le Lion et la Souris',
      'nl': 'De Leeuw en de Muis',
    },
    moralL10n: {
      'tr': 'Küçük bir dost bile büyük yardım edebilir.',
      'en': 'Even a small friend can be a big help.',
      'fr': 'Même un petit ami peut rendre un grand service.',
      'nl': 'Zelfs een kleine vriend kan groot helpen.',
    },
    emoji: '🦁',
    gradient: [Color(0xFFF59E0B), Color(0xFFD97706)],
    pagesL10n: {
      'tr': [
        'Bir ormanda kocaman bir aslan uyuyordu. Küçük bir fare koşarken '
            'yanlışlıkla aslanın üzerine çıktı ve onu uyandırdı.',
        'Aslan fareyi patisiyle yakaladı. Fare: "Lütfen beni bırak, bir gün '
            'sana ben de yardım ederim!" dedi. Aslan güldü ama onu bıraktı.',
        'Günler sonra aslan avcıların ağına yakalandı. Kükredi ama '
            'kurtulamadı. Fare sesi duydu ve koşarak geldi.',
        'Fare keskin dişleriyle ipleri kemirdi ve aslanı kurtardı. '
            'Aslan, küçük dostuna teşekkür etti.',
      ],
    },
    readMoreUrl: 'https://www.google.com/search?q=aslan+ile+fare+masalı+çocuk',
  ),
  KidStory(
    id: 'tavsan_kaplumbaga',
    titleL10n: {
      'tr': 'Tavşan ile Kaplumbağa',
      'en': 'The Tortoise and the Hare',
      'fr': 'Le Lièvre et la Tortue',
      'nl': 'De Haas en de Schildpad',
    },
    moralL10n: {
      'tr': 'Yavaş ama kararlı olan kazanır.',
      'en': 'Slow but steady wins the race.',
      'fr': 'Lent mais constant, on gagne la course.',
      'nl': 'Langzaam maar gestaag wint de race.',
    },
    emoji: '🐢',
    gradient: [Color(0xFF10B981), Color(0xFF059669)],
    pagesL10n: {
      'tr': [
        'Hızlı bir tavşan, yavaş kaplumbağayla dalga geçerdi. '
            'Kaplumbağa bir gün ona yarış teklif etti.',
        'Yarış başladı. Tavşan çok hızlıydı, öne geçti. "Kaplumbağa çok '
            'geride, biraz uyusam da olur" dedi ve bir ağacın altında uyudu.',
        'Kaplumbağa ise hiç durmadan, yavaş yavaş yürüdü. '
            'Tavşanın yanından sessizce geçti.',
        'Tavşan uyanınca kaplumbağanın bitişe vardığını gördü. '
            'Kaplumbağa kararlılığıyla yarışı kazanmıştı.',
      ],
    },
  ),
  KidStory(
    id: 'karinca_agustos',
    titleL10n: {
      'tr': 'Karınca ile Ağustos Böceği',
      'en': 'The Ant and the Grasshopper',
      'fr': 'La Cigale et la Fourmi',
      'nl': 'De Mier en de Krekel',
    },
    moralL10n: {
      'tr': 'Zamanında çalışmak, sonra rahat etmeyi sağlar.',
      'en': 'Working in good time lets you rest later.',
      'fr': 'Travailler à temps, c’est se reposer plus tard.',
      'nl': 'Op tijd werken zorgt voor rust later.',
    },
    emoji: '🐜',
    gradient: [Color(0xFF8B5CF6), Color(0xFF7C3AED)],
    pagesL10n: {
      'tr': [
        'Yazın karınca kışlık yiyecek taşırken, ağustos böceği '
            'gün boyu şarkı söyleyip eğleniyordu.',
        '"Gel biraz dinlen!" dedi ağustos böceği. Karınca: '
            '"Kış gelince yiyecek lazım olacak" diye çalışmaya devam etti.',
        'Kış geldi, hava soğudu. Ağustos böceği aç kaldı. '
            'Karıncanın kapısını çaldı.',
        'Karınca ona yardım etti ama ağustos böceği artık '
            'zamanında hazırlık yapmayı öğrenmişti.',
      ],
    },
  ),
  KidStory(
    id: 'kirmizi_baslikli',
    titleL10n: {
      'tr': 'Kırmızı Başlıklı Kız',
      'en': 'Little Red Riding Hood',
      'fr': 'Le Petit Chaperon rouge',
      'nl': 'Roodkapje',
    },
    moralL10n: {
      'tr': 'Yabancılara dikkatli olmalı ve büyükleri dinlemeliyiz.',
      'en': 'Be careful with strangers and listen to grown-ups.',
      'fr': 'Méfie-toi des inconnus et écoute les adultes.',
      'nl': 'Wees voorzichtig met vreemden en luister naar volwassenen.',
    },
    emoji: '🧺',
    gradient: [Color(0xFFEF4444), Color(0xFFDC2626)],
    pagesL10n: {
      'tr': [
        'Kırmızı başlıklı kız, hasta olan büyükannesine yiyecek '
            'götürmek için ormandan geçiyordu.',
        'Yolda bir kurtla karşılaştı. Kurt ona büyükannesinin evini '
            'sordu. Kız bilmeden anlattı.',
        'Kurt önce eve gitti. Ama ormancı gürültüyü duydu ve '
            'yardıma koştu.',
        'Ormancı büyükanneyi ve kızı kurtardı. Kız artık '
            'yabancılarla konuşurken daha dikkatli olacaktı.',
      ],
    },
  ),
  KidStory(
    id: 'uc_kucuk_domuz',
    titleL10n: {
      'tr': 'Üç Küçük Domuz',
      'en': 'The Three Little Pigs',
      'fr': 'Les Trois Petits Cochons',
      'nl': 'De Drie Biggetjes',
    },
    moralL10n: {
      'tr': 'Sağlam ve özenli iş, bizi korur.',
      'en': 'Solid, careful work protects us.',
      'fr': 'Un travail solide et soigné nous protège.',
      'nl': 'Stevig en zorgvuldig werk beschermt ons.',
    },
    emoji: '🐷',
    gradient: [Color(0xFFEC4899), Color(0xFFDB2777)],
    pagesL10n: {
      'tr': [
        'Üç küçük domuz kendilerine ev yapmaya karar verdi. '
            'Biri samandan, biri çalıdan, biri tuğladan.',
        'Kurt geldi. Saman evi ve çalı evi kolayca üfleyip yıktı. '
            'Domuzlar tuğla eve kaçtı.',
        'Kurt tuğla evi ne kadar üflese de yıkamadı. '
            'Ev çok sağlamdı.',
        'Üç domuz güvenle tuğla evde kaldı. Özenle yapılan iş '
            'onları korumuştu.',
      ],
    },
  ),
  KidStory(
    id: 'altin_yumurta',
    titleL10n: {
      'tr': 'Altın Yumurtlayan Tavuk',
      'en': 'The Hen that Laid Golden Eggs',
      'fr': 'La Poule aux œufs d’or',
      'nl': 'De Kip met de Gouden Eieren',
    },
    moralL10n: {
      'tr': 'Açgözlülük elimizdekini de kaybettirir.',
      'en': 'Greed makes us lose what we already have.',
      'fr': 'L’avidité fait perdre ce que l’on a.',
      'nl': 'Hebzucht doet ons verliezen wat we hebben.',
    },
    emoji: '🐔',
    gradient: [Color(0xFFF59E0B), Color(0xFFEAB308)],
    pagesL10n: {
      'tr': [
        'Bir çiftçinin tavuğu her gün bir altın yumurta yumurtluyordu. '
            'Çiftçi çok mutluydu.',
        'Ama çiftçi sabırsızlandı. "Karnında bir sürü altın olmalı" '
            'diye düşündü.',
        'Açgözlülükle tavuğu kesti ama içinde hiç altın yoktu.',
        'Artık her gün gelen altın yumurta da yoktu. Çiftçi '
            'sahip olduğunun kıymetini geç anladı.',
      ],
    },
  ),
  KidStory(
    id: 'balik_dilek',
    titleL10n: {
      'tr': 'Konuşan Balık',
      'en': 'The Talking Fish',
      'fr': 'Le Poisson qui parle',
      'nl': 'De Pratende Vis',
    },
    moralL10n: {
      'tr': 'İyilik yapmak, iyilikle geri döner.',
      'en': 'Kindness comes back with kindness.',
      'fr': 'La bonté est récompensée par la bonté.',
      'nl': 'Vriendelijkheid komt terug met vriendelijkheid.',
    },
    emoji: '🐟',
    gradient: [Color(0xFF3B82F6), Color(0xFF2563EB)],
    pagesL10n: {
      'tr': [
        'Küçük bir çocuk gölde yakaladığı balığı, gözlerindeki '
            'üzüntüyü görünce suya geri bıraktı.',
        'Balık: "Teşekkürler! İyiliğini unutmayacağım" dedi ve '
            'suya daldı.',
        'Bir gün çocuğun oyuncağı göle düştü. Balık onu bulup '
            'kıyıya getirdi.',
        'Çocuk çok sevindi. İyiliğin karşılıksız kalmadığını gördü.',
      ],
    },
  ),
  KidStory(
    id: 'yildiz_toplayan',
    titleL10n: {
      'tr': 'Yıldız Toplayan Çocuk',
      'en': 'The Star-Collecting Child',
      'fr': 'L’Enfant qui collectionnait les étoiles',
      'nl': 'Het Sterrenverzamelende Kind',
    },
    moralL10n: {
      'tr': 'Küçük iyilikler dünyayı aydınlatır.',
      'en': 'Small kindnesses light up the world.',
      'fr': 'Les petites bontés illuminent le monde.',
      'nl': 'Kleine goede daden verlichten de wereld.',
    },
    emoji: '⭐',
    gradient: [Color(0xFF6366F1), Color(0xFF4F46E5)],
    pagesL10n: {
      'tr': [
        'Bir çocuk her gece gökyüzündeki bir yıldıza bir iyilik '
            'diler, sonra birine yardım ederdi.',
        'Bir gün arkadaşına oyuncağını paylaştı, yaşlı komşusuna '
            'çantasını taşıdı.',
        'Yaptığı her iyilikte içi ışıl ışıl oldu, tıpkı yıldızlar gibi.',
        'Zamanla mahallesindeki herkes birbirine yardım etmeye '
            'başladı. Küçük iyilikler çoğalmıştı.',
      ],
    },
  ),
  KidStory(
    id: 'renkli_gokkusagi',
    titleL10n: {
      'tr': 'Renkleri Küsen Gökkuşağı',
      'en': 'The Rainbow Whose Colours Quarrelled',
      'fr': 'L’Arc-en-ciel aux couleurs fâchées',
      'nl': 'De Regenboog met Ruziënde Kleuren',
    },
    moralL10n: {
      'tr': 'Farklılıklar bir araya gelince güzellik olur.',
      'en': 'Differences together create beauty.',
      'fr': 'Les différences réunies créent la beauté.',
      'nl': 'Verschillen samen maken schoonheid.',
    },
    emoji: '🌈',
    gradient: [Color(0xFF14B8A6), Color(0xFF06B6D4)],
    pagesL10n: {
      'tr': [
        'Gökkuşağının renkleri "En güzel benim!" diye tartışıyordu. '
            'Kırmızı, mavi, sarı… hepsi küsmüştü.',
        'Renkler ayrılınca gökyüzü rengini kaybetti, her yer '
            'gri oldu.',
        'Yağmur geldi ve renklere "Birlikte olursanız gökkuşağı '
            'olursunuz" dedi.',
        'Renkler el ele tutuştu ve gökyüzünde kocaman, güzel bir '
            'gökkuşağı belirdi. Herkes onları sevdi.',
      ],
    },
  ),
  KidStory(
    id: 'kucuk_tohum',
    titleL10n: {
      'tr': 'Küçük Tohumun Yolculuğu',
      'en': 'The Little Seed’s Journey',
      'fr': 'Le Voyage de la Petite Graine',
      'nl': 'De Reis van het Kleine Zaadje',
    },
    moralL10n: {
      'tr': 'Sabırla büyüyen şeyler en güçlü olur.',
      'en': 'What grows with patience becomes the strongest.',
      'fr': 'Ce qui pousse avec patience devient le plus fort.',
      'nl': 'Wat met geduld groeit, wordt het sterkst.',
    },
    emoji: '🌱',
    gradient: [Color(0xFF22C55E), Color(0xFF16A34A)],
    pagesL10n: {
      'tr': [
        'Toprağın altında küçük bir tohum vardı. "Ne zaman ağaç '
            'olacağım?" diye merak ediyordu.',
        'Güneş ısıttı, yağmur suladı. Tohum yavaş yavaş filizlendi, '
            'toprağın üstüne çıktı.',
        'Rüzgâr onu sarssa da tohum kökleriyle sıkıca tutundu, '
            'her gün biraz daha büyüdü.',
        'Yıllar sonra kocaman bir ağaç oldu; kuşlara yuva, '
            'insanlara gölge verdi.',
      ],
    },
  ),
  KidStory(
    id: 'ayicik_uyku',
    titleL10n: {
      'tr': 'Uyumak İstemeyen Ayıcık',
      'en': 'The Bear Cub Who Wouldn’t Sleep',
      'fr': 'L’Ourson qui ne voulait pas dormir',
      'nl': 'Het Berenjong dat Niet Wilde Slapen',
    },
    moralL10n: {
      'tr': 'Dinlenmek, ertesi gün güçlü olmamızı sağlar.',
      'en': 'Resting makes us strong the next day.',
      'fr': 'Se reposer nous rend forts le lendemain.',
      'nl': 'Rusten maakt ons de volgende dag sterk.',
    },
    emoji: '🐻',
    gradient: [Color(0xFFA855F7), Color(0xFF9333EA)],
    pagesL10n: {
      'tr': [
        'Küçük ayıcık kış uykusuna yatmak istemiyordu. '
            '"Daha oynamak istiyorum!" diyordu.',
        'Annesi ona sıcak bir yatak hazırladı ve bir masal anlattı.',
        'Ayıcık esnedi, gözleri ağırlaştı. Rüyasında bahar '
            'çiçekleriyle oynadı.',
        'Baharda uyandığında kocaman ve güçlüydü. İyi bir uykunun '
            'ne kadar iyi geldiğini anladı.',
      ],
    },
  ),
  KidStory(
    id: 'paylasan_elma',
    titleL10n: {
      'tr': 'Paylaşan Elma Ağacı',
      'en': 'The Sharing Apple Tree',
      'fr': 'Le Pommier qui partage',
      'nl': 'De Delende Appelboom',
    },
    moralL10n: {
      'tr': 'Paylaşmak mutluluğu çoğaltır.',
      'en': 'Sharing multiplies happiness.',
      'fr': 'Partager multiplie le bonheur.',
      'nl': 'Delen vermenigvuldigt geluk.',
    },
    emoji: '🍎',
    gradient: [Color(0xFFEF4444), Color(0xFFF97316)],
    pagesL10n: {
      'tr': [
        'Bahçede kırmızı elmalarla dolu bir ağaç vardı. '
            'Çocuklar gelip elmaları toplardı.',
        'Bir çocuk topladığı elmaları arkadaşlarıyla paylaştı. '
            'Herkes bir elma yedi.',
        'Ağaç bunu görünce mutlu oldu ve ertesi yıl daha çok '
            'elma verdi.',
        'Paylaştıkça çoğaldı; bahçe kahkahalarla doldu.',
      ],
    },
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
    stories.add(KidStory.single(
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
