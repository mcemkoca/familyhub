import 'package:flutter/material.dart';

/// Gelişim bölümü için 6 gelişim alanı ve 0-10 yaş kilometre taşları içeriği.

class DevArea {
  final String key;
  final String label;
  final IconData icon;
  final List<Color> gradient;
  const DevArea(this.key, this.label, this.icon, this.gradient);
}

const devAreas = <DevArea>[
  DevArea('dil', 'Dil', Icons.chat_bubble_rounded,
      [Color(0xFF22C55E), Color(0xFF16A34A)]),
  DevArea('motor', 'Motor', Icons.directions_run_rounded,
      [Color(0xFFF59E0B), Color(0xFFD97706)]),
  DevArea('sosyal', 'Sosyal', Icons.groups_rounded,
      [Color(0xFF14B8A6), Color(0xFF0D9488)]),
  DevArea('bilissel', 'Bilişsel', Icons.psychology_rounded,
      [Color(0xFF8B5CF6), Color(0xFF7C3AED)]),
  DevArea('ozbakim', 'Öz Bakım', Icons.favorite_rounded,
      [Color(0xFFEF4444), Color(0xFFDC2626)]),
  DevArea('duyusal', 'Duyusal', Icons.visibility_rounded,
      [Color(0xFF3B82F6), Color(0xFF2563EB)]),
];

DevArea areaByKey(String key) =>
    devAreas.firstWhere((a) => a.key == key, orElse: () => devAreas.first);

/// devGroup → beceri kilometre taşları [(alan anahtarı, beceri metni)].
/// 0-10 yaş aralığını kapsar; her yaş için 6 alana yayılmış beceriler.
const Map<String, List<(String, String)>> assessmentByGroup = {
  '0-3 ay': [
    ('motor', 'Baş kontrolünü kısa süre yapar'),
    ('motor', 'Yüzüstüyken başını kaldırır'),
    ('sosyal', 'Sosyal gülümseme gösterir'),
    ('sosyal', 'Yüzlere bakar ve takip eder'),
    ('dil', 'Farklı seslerle ağlar'),
    ('dil', 'Agucuk sesleri çıkarır'),
    ('duyusal', 'Sesin geldiği yöne döner'),
    ('duyusal', 'Yakın nesneleri gözüyle takip eder'),
  ],
  '3-6 ay': [
    ('motor', 'Desteksiz oturmaya başlar'),
    ('motor', 'Nesneleri eline alıp kavrar'),
    ('motor', 'Sırtüstünden yana döner'),
    ('sosyal', 'Tanıdık yüzlere sevinir'),
    ('dil', 'Yüksek sesle güler'),
    ('dil', 'Cıvıldama (heceleme) başlar'),
    ('bilissel', 'Nesneleri ağzına götürür, keşfeder'),
    ('duyusal', 'Renkli nesnelere ilgi gösterir'),
  ],
  '6-9 ay': [
    ('motor', 'Desteksiz oturur'),
    ('motor', 'Emeklemeye başlar'),
    ('motor', 'Nesneyi bir elden diğerine geçirir'),
    ('sosyal', 'Yabancı kaygısı gösterir'),
    ('dil', '"ba-ba", "ma-ma" hecelerini tekrarlar'),
    ('bilissel', 'Saklanan nesneyi arar (nesne kalıcılığı)'),
    ('ozbakim', 'Bisküviyi kendisi tutup yer'),
    ('duyusal', 'Küçük nesneleri parmakla toplar'),
  ],
  '9-12 ay': [
    ('motor', 'Destekle ayağa kalkar'),
    ('motor', 'Mobilyalara tutunarak yürür'),
    ('dil', 'İlk anlamlı kelimeyi söyler'),
    ('dil', 'Basit komutları anlar ("hayır")'),
    ('sosyal', 'El sallar, "cee-ee" oynar'),
    ('bilissel', 'İşaret ederek istek belirtir'),
    ('ozbakim', 'Bardaktan yardımla içer'),
    ('duyusal', 'Kutuya nesne koyup çıkarır'),
  ],
  '12-18 ay': [
    ('motor', 'Bağımsız yürür'),
    ('motor', 'Kalem/boya ile karalar'),
    ('dil', '5-10 kelime kullanır'),
    ('dil', 'Vücut bölümlerini gösterir'),
    ('sosyal', 'Taklit oyunları oynar'),
    ('bilissel', 'Basit iki parçalı yapboz yapar'),
    ('ozbakim', 'Kaşıkla yemeye çalışır'),
    ('duyusal', 'Kuleyi 2-3 blokla üst üste dizer'),
  ],
  '18-24 ay': [
    ('motor', 'Koşar, geri geri yürür'),
    ('motor', 'Topa tekme atar'),
    ('dil', '2 kelimelik cümleler kurar ("su ver")'),
    ('dil', '50+ kelime bilir'),
    ('sosyal', 'Diğer çocukların yanında oynar (paralel)'),
    ('bilissel', 'Resimli kitapta nesneleri işaret eder'),
    ('ozbakim', 'Basit giysi çıkarabilir'),
    ('duyusal', 'Şekilleri doğru deliğe yerleştirir'),
  ],
  '2-3 yaş': [
    ('dil', '200-300 kelime, 3 kelimelik cümleler'),
    ('dil', 'Adını söyler'),
    ('motor', 'Üç tekerlekli bisiklet/araç sürer'),
    ('motor', 'Merdiveni ayak değiştirerek çıkar'),
    ('sosyal', 'Sıra beklemeye başlar'),
    ('bilissel', 'Renkleri eşleştirir'),
    ('bilissel', '1-3 arası sayar'),
    ('ozbakim', 'Tuvalet eğitimine başlar'),
    ('duyusal', 'Daire ve çizgi çizer'),
  ],
  '3-4 yaş': [
    ('dil', 'Kısa hikâye/olay anlatır'),
    ('dil', '"Neden, nasıl" soruları sorar'),
    ('motor', 'Makasla kâğıt keser'),
    ('motor', 'Tek ayak üzerinde kısa durur'),
    ('sosyal', 'Grup oyunlarına katılır'),
    ('sosyal', 'Duygularını sözle ifade eder'),
    ('bilissel', 'Renk ve şekilleri sınıflar'),
    ('ozbakim', 'Yardımsız el yıkar'),
    ('duyusal', 'Basit insan figürü çizer'),
  ],
  '4-5 yaş': [
    ('dil', '4-5 kelimelik cümle kurar'),
    ('dil', 'Basit hikâye anlatabilir'),
    ('dil', 'Adını ve yaşını söyler'),
    ('motor', 'Makasla çizgi takip ederek keser'),
    ('motor', 'Zıplar, tek ayakla sekiyor'),
    ('motor', 'Kalemi doğru tutar'),
    ('sosyal', 'Oyuncaklarını paylaşabilir'),
    ('sosyal', 'Sıra kurallarına uyar'),
    ('sosyal', 'Arkadaş edinir'),
    ('bilissel', '10\'a kadar sayar'),
    ('bilissel', 'Bazı harfleri/rakamları tanır'),
    ('bilissel', 'Basit yapboz (12+ parça) yapar'),
    ('ozbakim', 'Yardımsız giyinir'),
    ('ozbakim', 'Tuvalet ihtiyacını kendisi görür'),
    ('duyusal', 'Çember, kare kopyalar'),
    ('duyusal', 'Çizgi içini boyar'),
  ],
  '5-6 yaş': [
    ('dil', 'Akıcı ve dilbilgisine uygun konuşur'),
    ('dil', 'Karşıt kavramları bilir (büyük-küçük)'),
    ('motor', 'İp atlar, top yakalar'),
    ('motor', 'Adını yazmaya çalışır'),
    ('sosyal', 'Kurallı oyunları oynar'),
    ('sosyal', 'Empati gösterir'),
    ('bilissel', '20\'ye kadar sayar'),
    ('bilissel', 'Harfleri tanır, okuma hazırlığı'),
    ('ozbakim', 'Dişini fırçalar'),
    ('duyusal', 'Üçgen ve karmaşık şekiller çizer'),
  ],
  '6-8 yaş': [
    ('dil', 'Akıcı okur, okuduğunu anlatır'),
    ('dil', 'Duygu ve düşüncelerini açıklar'),
    ('motor', 'Bisiklete biner, ip atlar'),
    ('motor', 'Düzgün el yazısı yazar'),
    ('sosyal', 'Yakın arkadaşlık ilişkileri kurar'),
    ('sosyal', 'Grup çalışmasına uyum sağlar'),
    ('bilissel', 'Toplama-çıkarma yapar'),
    ('bilissel', 'Zamanı (saat) okur'),
    ('ozbakim', 'Günlük rutinini kendi yönetir'),
  ],
  '8-10 yaş': [
    ('dil', 'Yazılı metin oluşturur (kompozisyon)'),
    ('motor', 'Spor ve koordinasyon becerileri gelişir'),
    ('sosyal', 'Grup kimliği ve iş birliği güçlenir'),
    ('sosyal', 'Anlaşmazlıkları sözle çözer'),
    ('bilissel', 'Çarpma-bölme ve problem çözer'),
    ('bilissel', 'Soyut düşünmeye başlar'),
    ('ozbakim', 'Sorumluluklarını takip eder (ödev, eşya)'),
  ],
  '10-12 yaş': [
    ('dil', 'Karmaşık metinleri anlar ve tartışır'),
    ('motor', 'Karmaşık motor becerilerini ustalaşır'),
    ('sosyal', 'Akran etkisi ve kimlik gelişir'),
    ('bilissel', 'Mantıksal ve eleştirel düşünür'),
    ('ozbakim', 'Bağımsız planlama yapar'),
  ],
};

/// Bir yaş grubu için değerlendirme kalemlerini döndürür (yoksa en yakını).
List<(String, String)> assessmentFor(String devGroup) {
  return assessmentByGroup[devGroup] ?? assessmentByGroup['4-5 yaş']!;
}

/// Bir gelişim alanının detaylı içeriği (açıklama, etkinlik, ipucu, kaynak).
class AreaContent {
  final String description;
  final List<String> activities;
  final List<String> tips;
  final List<(String, String)> links; // (etiket, url)
  const AreaContent({
    required this.description,
    required this.activities,
    required this.tips,
    required this.links,
  });
}

/// Her gelişim alanı için konuya özgü (tekrarsız) detaylı içerik.
/// Etkinlikler yaşa göre `areaActivitiesFor` ile ince ayarlanır.
const Map<String, AreaContent> areaContentByKey = {
  'dil': AreaContent(
    description:
        'Dil gelişimi; sözcük dağarcığı, konuşma, dinleme ve anlama becerilerini '
        'kapsar. Çocuğunuzla bol bol konuşmak, kitap okumak ve şarkı söylemek '
        'bu alanı en çok besleyen etkinliklerdir.',
    activities: [
      'Her gün 10-15 dk resimli kitap okuyun; resimleri birlikte anlatın.',
      'Gün içinde yaptıklarınızı sesli anlatın ("Şimdi elmayı yıkıyoruz").',
      'Tekerleme ve parmak oyunları söyleyin (Portakalı soydum…).',
      'Nesneleri gösterip adlarını ve seslerini söyletin.',
      '"Neden / nasıl" sorularıyla cümle kurmaya teşvik edin.',
    ],
    tips: [
      'Çocuğun cümlesini düzeltmek yerine doğrusunu tekrar ederek modelleyin.',
      'Konuşurken göz teması kurun ve yanıt için zaman tanıyın.',
      'Ekran süresini sınırlayın; karşılıklı konuşma en iyi öğreticidir.',
    ],
    links: [
      ('YouTube: Çocuk dil gelişimi etkinlikleri',
          'https://www.youtube.com/results?search_query=çocuk+dil+gelişimi+etkinlikleri'),
      ('TEDMEM: Erken dil gelişimi',
          'https://www.google.com/search?q=erken+çocuklukta+dil+gelişimi+etkinlikleri'),
    ],
  ),
  'motor': AreaContent(
    description:
        'Motor gelişim; kaba motor (koşma, zıplama, denge) ve ince motor '
        '(kalem tutma, makas, düğme) becerilerini içerir. Hareket ve el '
        'çalışmaları bu alanı güçlendirir.',
    activities: [
      'Parkta koşma, tırmanma, tek ayak üzerinde durma oyunları.',
      'Top yakalama ve atma ile el-göz koordinasyonu.',
      'Hamur/oyun hamuru yoğurma, boncuk dizme (ince motor).',
      'Makasla kâğıt kesme ve çizgi üzerinde ilerleme.',
      'Düğme ilikleme, fermuar çekme gibi öz-bakım pratiği.',
    ],
    tips: [
      'İnce motor için kalın kalemler ve büyük boncuklarla başlayın.',
      'Günlük en az 1 saat aktif fiziksel oyun hedefleyin.',
      'Başarısızlıkta cesaretlendirin; tekrar önemlidir.',
    ],
    links: [
      ('YouTube: İnce motor etkinlikleri',
          'https://www.youtube.com/results?search_query=ince+motor+beceri+etkinlikleri+çocuk'),
      ('Kaba motor oyun fikirleri',
          'https://www.google.com/search?q=çocuklar+için+kaba+motor+oyunları'),
    ],
  ),
  'sosyal': AreaContent(
    description:
        'Sosyal-duygusal gelişim; duyguları tanıma, paylaşma, sıra bekleme, '
        'empati ve arkadaşlık kurma becerilerini kapsar. Oyun ve model olma '
        'en etkili yöntemdir.',
    activities: [
      'Duygu kartlarıyla "şimdi ne hissediyorsun?" oyunu.',
      'Sıra bekleme gerektiren sıra oyunları (kutu oyunları).',
      'Rol yapma: doktor, market, ev oyunları ile empati.',
      'Birlikte paylaşma ve yardımlaşma görevleri verin.',
      'Gün sonunda "bugün seni ne mutlu etti?" sohbeti.',
    ],
    tips: [
      'Duyguları adlandırın ("Kızgın görünüyorsun, ne oldu?").',
      'İstenen davranışı övün; olumlu pekiştirme kullanın.',
      'Anlaşmazlıkta çözüm üretmesine rehberlik edin, çözmeyin.',
    ],
    links: [
      ('YouTube: Duygu eğitimi etkinlikleri',
          'https://www.youtube.com/results?search_query=çocukta+duygu+eğitimi+etkinlikleri'),
      ('Sosyal beceri oyunları',
          'https://www.google.com/search?q=okul+öncesi+sosyal+beceri+oyunları'),
    ],
  ),
  'bilissel': AreaContent(
    description:
        'Bilişsel gelişim; dikkat, hafıza, problem çözme, sayı-şekil-renk '
        'kavramları ve mantık yürütmeyi içerir. Merakı besleyen sorular ve '
        'bulmacalar bu alanı geliştirir.',
    activities: [
      'Yapboz ve eşleştirme oyunları (renk, şekil, sayı).',
      'Basit sıralama: küçükten büyüğe dizme.',
      'Hafıza kartı (memory) oyunu.',
      'Günlük sayma: basamak, elma, oyuncak sayma.',
      '"Ne olurdu eğer…" ile mantık ve tahmin soruları.',
    ],
    tips: [
      'Sorunu hemen çözmeyin; ipucu vererek düşünmesini bekleyin.',
      'Zorluk seviyesini kademeli artırın.',
      'Somut nesnelerle başlayıp soyuta geçin.',
    ],
    links: [
      ('YouTube: Bilişsel gelişim etkinlikleri',
          'https://www.youtube.com/results?search_query=bilişsel+gelişim+etkinlikleri+çocuk'),
      ('Zeka ve dikkat oyunları',
          'https://www.google.com/search?q=çocuklar+için+dikkat+ve+hafıza+oyunları'),
    ],
  ),
  'ozbakim': AreaContent(
    description:
        'Öz bakım; yeme, giyinme, tuvalet, diş fırçalama ve temizlik gibi '
        'günlük yaşam becerilerinin bağımsız yapılmasını kapsar. Rutin ve '
        'sabır ile gelişir.',
    activities: [
      'Kendi başına giyinme/soyunma pratiği (bol zaman tanıyın).',
      'Diş fırçalama rutini; birlikte fırçalayın.',
      'Sofra kurmaya ve toplamaya katılım.',
      'El yıkama adımlarını şarkıyla öğretin.',
      'Oyuncaklarını toplama sorumluluğu.',
    ],
    tips: [
      'Görsel rutin çizelgesi (kalk-giyin-kahvaltı) kullanın.',
      'Küçük görevlerle başlayıp bağımsızlığı artırın.',
      'Acele ettirmeyin; deneme-yanılmaya izin verin.',
    ],
    links: [
      ('YouTube: Öz bakım becerileri',
          'https://www.youtube.com/results?search_query=çocukta+öz+bakım+becerileri'),
      ('Rutin çizelgesi fikirleri',
          'https://www.google.com/search?q=çocuk+günlük+rutin+çizelgesi'),
    ],
  ),
  'duyusal': AreaContent(
    description:
        'Duyusal gelişim; görme, işitme, dokunma, tatma ve koklama yoluyla '
        'çevreyi algılama ve el-göz koordinasyonunu kapsar. Duyusal oyunlar '
        'beyin gelişimini destekler.',
    activities: [
      'Farklı dokular kutusu (pamuk, kum, süngerle keşif).',
      'Renk ve şekil boyama, çizgi içini boyama.',
      'Su ve kum oyunları ile dökme-boşaltma.',
      'Sesli oyuncaklarla ses ayırt etme.',
      'Koku/tat tahmin oyunları (güvenli gıdalarla).',
    ],
    tips: [
      'Duyusal oyunlarda gözetim altında güvenliği önceleyin.',
      'Aşırı uyarandan kaçının; sakin ortam sağlayın.',
      'Çocuğun tepkilerini gözlemleyip tercihleri not edin.',
    ],
    links: [
      ('YouTube: Duyusal oyun etkinlikleri',
          'https://www.youtube.com/results?search_query=duyusal+oyun+etkinlikleri+çocuk'),
      ('Duyu bütünleme etkinlikleri',
          'https://www.google.com/search?q=duyusal+bütünleme+etkinlikleri+ev'),
    ],
  ),
};

AreaContent areaContentFor(String key) =>
    areaContentByKey[key] ?? areaContentByKey['dil']!;

/// Bir alan için yaş grubuna uygun "bu yaşta ne beklenir" beceri listesi.
List<String> areaExpectations(String areaKey, String devGroup) {
  return assessmentFor(devGroup)
      .where((it) => it.$1 == areaKey)
      .map((it) => it.$2)
      .toList();
}

/// Gelişim ekranları için ortak başlık (geri + başlık + alt başlık + sağ ikon).
class DevHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget? trailing;
  final VoidCallback? onTrailing;
  const DevHeader({
    super.key,
    required this.title,
    required this.subtitle,
    this.trailing,
    this.onTrailing,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A24),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w800)),
                Text(subtitle,
                    style: const TextStyle(
                        color: Color(0xFF9CA3AF), fontSize: 13.5)),
              ],
            ),
          ),
          if (trailing != null)
            GestureDetector(
              onTap: onTrailing,
              child: Container(
                width: 42,
                height: 42,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A24),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: trailing,
              ),
            ),
        ],
      ),
    );
  }
}
