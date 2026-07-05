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
