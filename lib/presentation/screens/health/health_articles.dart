import 'package:flutter/material.dart';
import 'health_store.dart';

/// Sağlık Makaleleri — kategorili, görselli sağlık içerikleri.
/// Görsel: ağdan (Unsplash) yüklenir, başarısızsa degrade+emoji fallback.
/// İçerik bilgilendirme amaçlıdır (teşhis koymaz).

class HealthArticle {
  final String id;
  final String category;
  final String categoryLabel;
  final Color categoryColor;
  final String title;
  final String summary;
  final String emoji;
  final String imageUrl;
  final String dateLabel;
  final List<String> body;
  const HealthArticle({
    required this.id,
    required this.category,
    required this.categoryLabel,
    required this.categoryColor,
    required this.title,
    required this.summary,
    required this.emoji,
    required this.imageUrl,
    required this.dateLabel,
    required this.body,
  });
}

const _articles = <HealthArticle>[
  HealthArticle(
    id: 'immunity',
    category: 'aile',
    categoryLabel: 'Bağışıklık',
    categoryColor: Color(0xFF22C55E),
    title: 'Bağışıklık Sistemini Güçlendiren 10 Alışkanlık',
    summary: 'Günlük yaşamda uygulayabileceğiniz basit ama etkili yöntemler.',
    emoji: '🥗',
    imageUrl:
        'https://images.unsplash.com/photo-1490645935967-10de6ba17061?w=500&q=60',
    dateLabel: 'Bugün',
    body: [
      'Bağışıklık sistemi, vücudun hastalıklara karşı ilk savunma hattıdır. '
          'Güçlü bir bağışıklık için günlük alışkanlıklar büyük fark yaratır.',
      '1) Renkli sebze ve meyve tüketin (C ve A vitamini).\n'
          '2) Günde 7-8 saat düzenli uyuyun.\n'
          '3) Düzenli fiziksel aktivite yapın.\n'
          '4) Yeterli su için.\n'
          '5) Stresi yönetin (nefes, mola).',
      '6) İşlenmiş şekeri azaltın.\n7) El hijyenine dikkat edin.\n'
          '8) Güneşten D vitamini alın.\n9) Probiyotik gıdalar tüketin.\n'
          '10) Sigara ve alkolden kaçının.',
      'Not: Bu içerik bilgilendirme amaçlıdır. Sağlık sorunlarında bir '
          'hekime danışın.',
    ],
  ),
  HealthArticle(
    id: 'child_fever',
    category: 'cocuk',
    categoryLabel: 'Çocuk Sağlığı',
    categoryColor: Color(0xFF3B82F6),
    title: 'Çocuklarda Ateş: Ne Zaman Endişelenmeli?',
    summary: 'Ateşin nedenleri, doğru ölçüm yöntemi ve ne zaman doktora.',
    emoji: '🤒',
    imageUrl:
        'https://images.unsplash.com/photo-1584515933487-779824d29309?w=500&q=60',
    dateLabel: 'Dün',
    body: [
      'Ateş, vücudun enfeksiyonla savaştığının bir işaretidir ve çoğu zaman '
          'zararsızdır. Önemli olan çocuğun genel durumunu izlemektir.',
      'Doğru ölçüm: Küçük çocuklarda koltuk altı veya kulaktan güvenilir '
          'termometre ile ölçün. 38°C üzeri ateş olarak kabul edilir.',
      'Doktora başvurun: 3 aydan küçük bebekte herhangi bir ateş, '
          '39°C üzeri düşmeyen ateş, nefes güçlüğü, döküntü, aşırı halsizlik '
          'veya havale durumunda VAKIT KAYBETMEYİN.',
      'Bu içerik bilgilendirme amaçlıdır; teşhis koymaz. Endişe durumunda '
          'çocuk doktoruna danışın.',
    ],
  ),
  HealthArticle(
    id: 'menstrual',
    category: 'kadin',
    categoryLabel: 'Kadın Sağlığı',
    categoryColor: Color(0xFFEC4899),
    title: 'Adet Döngüsü Hakkında Bilmeniz Gerekenler',
    summary: 'Adet döngüsünün aşamaları, belirtiler ve dikkat edilmesi gerekenler.',
    emoji: '🌸',
    imageUrl:
        'https://images.unsplash.com/photo-1516574187841-cb9cc2ca948b?w=500&q=60',
    dateLabel: '3 gün önce',
    body: [
      'Adet döngüsü ortalama 28 gündür ancak 21-35 gün arası normaldir. '
          'Döngü dört evreden oluşur: adet, foliküler, yumurtlama ve luteal.',
      'Yumurtlama genellikle döngünün 14. günü civarında olur ve en '
          'doğurgan dönemdir. Bu dönemi takip etmek planlama için faydalıdır.',
      'Düzensizlik, aşırı ağrı veya çok yoğun kanama varsa bir kadın hastalıkları '
          'uzmanına danışın.',
      'Bu içerik bilgilendirme amaçlıdır ve tıbbi tavsiye yerine geçmez.',
    ],
  ),
  HealthArticle(
    id: 'vitamin_d',
    category: 'aile',
    categoryLabel: 'Beslenme',
    categoryColor: Color(0xFFF59E0B),
    title: 'D Vitamini Eksikliği Belirtileri',
    summary: 'Vücudunuzun D vitamini eksikliği sinyallerini nasıl anlarsınız?',
    emoji: '☀️',
    imageUrl:
        'https://images.unsplash.com/photo-1550572017-edd951b55104?w=500&q=60',
    dateLabel: '3 gün önce',
    body: [
      'D vitamini kemik sağlığı, bağışıklık ve kas fonksiyonu için gereklidir. '
          'Eksikliği yaygındır, özellikle güneşe az maruz kalanlarda.',
      'Belirtiler: sürekli yorgunluk, kemik/kas ağrısı, sık hastalanma, '
          'saç dökülmesi ve moral düşüklüğü olabilir.',
      'Öneriler: güneşten (günde 15-20 dk), yağlı balık, yumurta sarısı ve '
          'takviyelerden alınabilir. Takviyeden önce hekime danışın.',
      'Bu içerik bilgilendirme amaçlıdır. Kan testi ve tedavi için hekiminize '
          'başvurun.',
    ],
  ),
  HealthArticle(
    id: 'sleep',
    category: 'aile',
    categoryLabel: 'Uyku',
    categoryColor: Color(0xFF8B5CF6),
    title: 'Kaliteli Uyku İçin 7 İpucu',
    summary: 'Daha iyi uyumak ve dinç uyanmak için pratik öneriler.',
    emoji: '🌙',
    imageUrl:
        'https://images.unsplash.com/photo-1541781774459-bb2af2f05b55?w=500&q=60',
    dateLabel: '4 gün önce',
    body: [
      'Kaliteli uyku, fiziksel ve zihinsel sağlığın temelidir. Yetişkinler '
          'için günde 7-9 saat önerilir.',
      '1) Her gün aynı saatte yatıp kalkın.\n2) Yatmadan 1 saat önce ekranları '
          'bırakın.\n3) Odayı karanlık ve serin tutun.\n4) Akşam kafeini azaltın.',
      '5) Yatmadan ağır yemekten kaçının.\n6) Gün içinde hareketli olun.\n'
          '7) Rahatlatıcı bir rutin oluşturun (kitap, nefes).',
      'Uyku sorunları sürüyorsa bir uzmana danışın.',
    ],
  ),
  HealthArticle(
    id: 'child_nutrition',
    category: 'cocuk',
    categoryLabel: 'Çocuk Beslenmesi',
    categoryColor: Color(0xFF14B8A6),
    title: 'Çocuklarda Sağlıklı Beslenme Alışkanlıkları',
    summary: 'Seçici yiyen çocuklar için pratik ve dengeli beslenme önerileri.',
    emoji: '🍎',
    imageUrl:
        'https://images.unsplash.com/photo-1512621776951-a57141f2eefd?w=500&q=60',
    dateLabel: '5 gün önce',
    body: [
      'Çocuklukta kazanılan beslenme alışkanlıkları ömür boyu sürer. '
          'Renkli ve çeşitli bir tabak sunmak önemlidir.',
      'Öneriler: öğünleri birlikte yiyin, yeni yiyecekleri baskı yapmadan '
          'tekrar tekrar sunun, şekerli atıştırmalıkları sınırlayın.',
      'Çocuğu yemeğe zorlamak ters etki yapabilir; örnek olun ve sabırlı olun.',
      'Büyüme/beslenme endişesinde çocuk doktoruna danışın.',
    ],
  ),
];

const _categories = [
  ('senin', 'Senin için', Icons.star),
  ('populer', 'Popüler', Icons.local_fire_department),
  ('cocuk', 'Çocuk', Icons.child_care),
  ('kadin', 'Kadın', Icons.female),
  ('aile', 'Aile', Icons.groups),
];

class HealthArticlesScreen extends StatefulWidget {
  const HealthArticlesScreen({super.key});

  @override
  State<HealthArticlesScreen> createState() => _HealthArticlesScreenState();
}

class _HealthArticlesScreenState extends State<HealthArticlesScreen> {
  String _cat = 'senin';

  List<HealthArticle> get _filtered {
    if (_cat == 'senin' || _cat == 'populer') return _articles;
    return _articles.where((a) => a.category == _cat).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      body: SafeArea(
        child: Column(
          children: [
            const HealthHeader(
              title: 'Sağlık Makaleleri',
              subtitle: 'Sağlıklı bir yaşam için doğru bilgi, her gün seninle.',
              icon: Icons.monitor_heart_rounded,
              showBack: true,
            ),
            SizedBox(
              height: 44,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: _categories.map((c) {
                  final sel = _cat == c.$1;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () => setState(() => _cat = c.$1),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: sel
                              ? const Color(0xFF6366F1)
                              : const Color(0xFF13131A),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: sel
                                  ? const Color(0xFF6366F1)
                                  : const Color(0x14FFFFFF)),
                        ),
                        child: Row(
                          children: [
                            Icon(c.$3,
                                size: 15,
                                color: sel
                                    ? Colors.white
                                    : const Color(0xFF9CA3AF)),
                            const SizedBox(width: 6),
                            Text(c.$2,
                                style: TextStyle(
                                    color: sel
                                        ? Colors.white
                                        : const Color(0xFF9CA3AF),
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700)),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                children: [
                  ..._filtered.map((a) => _card(a)),
                  const SizedBox(height: 6),
                  _seeAll(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _card(HealthArticle a) {
    return GestureDetector(
      onTap: () => Navigator.push(context,
          MaterialPageRoute(builder: (_) => _ArticleDetail(article: a))),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: const Color(0xFF13131A),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0x14FFFFFF)),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.horizontal(
                  left: Radius.circular(20)),
              child: _thumb(a),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: a.categoryColor.withAlpha(30),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(a.categoryLabel,
                          style: TextStyle(
                              color: a.categoryColor,
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700)),
                    ),
                    const SizedBox(height: 6),
                    Text(a.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            height: 1.25)),
                    const SizedBox(height: 4),
                    Text(a.summary,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: Color(0xFF9CA3AF),
                            fontSize: 12,
                            height: 1.3)),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.schedule,
                            size: 12, color: Color(0xFF6B7280)),
                        const SizedBox(width: 4),
                        Text(a.dateLabel,
                            style: const TextStyle(
                                color: Color(0xFF6B7280), fontSize: 11)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.only(right: 12),
              child: Icon(Icons.arrow_forward, color: Color(0xFF6B7280)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _thumb(HealthArticle a) {
    return SizedBox(
      width: 110,
      height: 116,
      child: Image.network(
        a.imageUrl,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => _fallback(a),
        loadingBuilder: (_, child, prog) =>
            prog == null ? child : _fallback(a),
      ),
    );
  }

  Widget _fallback(HealthArticle a) => Container(
        width: 110,
        height: 116,
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [
            a.categoryColor,
            a.categoryColor.withAlpha(150),
          ]),
        ),
        child: Center(child: Text(a.emoji, style: const TextStyle(fontSize: 40))),
      );

  Widget _seeAll() {
    return GestureDetector(
      onTap: () => setState(() => _cat = 'senin'),
      child: Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF13131A),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0x226366F1)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFF6366F1).withAlpha(30),
              borderRadius: BorderRadius.circular(13),
            ),
            child: const Icon(Icons.menu_book, color: Color(0xFF8B5CF6)),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Tüm Makaleleri Gör',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w800)),
                Text('Sağlıkla ilgili tüm içeriklere göz atın.',
                    style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 12)),
              ],
            ),
          ),
          const Icon(Icons.arrow_forward, color: Color(0xFF6B7280)),
        ],
      ),
    ),
    );
  }
}

class _ArticleDetail extends StatelessWidget {
  final HealthArticle article;
  const _ArticleDetail({required this.article});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      body: SafeArea(
        child: Column(
          children: [
            HealthHeader(
                title: article.categoryLabel,
                subtitle: 'Sağlık Makalesi',
                showBack: true),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: SizedBox(
                      height: 190,
                      width: double.infinity,
                      child: Image.network(
                        article.imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => Container(
                          height: 190,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(colors: [
                              article.categoryColor,
                              article.categoryColor.withAlpha(150)
                            ]),
                          ),
                          child: Center(
                              child: Text(article.emoji,
                                  style: const TextStyle(fontSize: 64))),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(article.title,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          height: 1.3)),
                  const SizedBox(height: 14),
                  ...article.body.map((p) => Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: Text(p,
                            style: const TextStyle(
                                color: Color(0xFFD1D5DB),
                                fontSize: 15,
                                height: 1.6)),
                      )),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
