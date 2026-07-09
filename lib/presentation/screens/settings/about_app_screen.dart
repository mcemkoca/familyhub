import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../config/routes.dart';

class AboutAppScreen extends StatelessWidget {
  const AboutAppScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor:
          const Color(0xFF0A0A0F),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 220,
            pinned: true,
            backgroundColor:
                const Color(0xFF0A0A0F),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => context.pop(),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF8B5CF6), Color(0xFF3B82F6)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: SafeArea(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 84,
                        height: 84,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                              color: Colors.white.withAlpha(60), width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withAlpha(40),
                              blurRadius: 16,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Image.asset('assets/images/logo_full.png',
                            fit: BoxFit.cover),
                      ),
                      const SizedBox(height: 12),
                      const Text('FamilyHub',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.w800)),
                      const SizedBox(height: 4),
                      const Text('Ailenizin kalbi burada atıyor',
                          style:
                              TextStyle(color: Colors.white70, fontSize: 14)),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(30),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text('v2.0.0 · Flutter',
                            style: TextStyle(
                                color: Colors.white70, fontSize: 12)),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SectionTitle('Özellikler', isDark),
                  const SizedBox(height: 10),
                  _FeatureGrid(isDark: isDark),
                  const SizedBox(height: 20),
                  _SectionTitle('Teknoloji', isDark),
                  const SizedBox(height: 10),
                  _TechStack(isDark: isDark),
                  const SizedBox(height: 20),
                  _SectionTitle('İstatistikler', isDark),
                  const SizedBox(height: 10),
                  _StatsRow(isDark: isDark),
                  const SizedBox(height: 20),
                  _SectionTitle('Hızlı Erişim', isDark),
                  const SizedBox(height: 10),
                  _QuickLinks(isDark: isDark),
                  const SizedBox(height: 24),
                  const Center(
                    child: Text(
                      '© 2025 FamilyHub • Tüm hakları saklıdır',
                      style: TextStyle(
                          fontSize: 12, color: Color(0xFF6B7280)),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final bool isDark;
  const _SectionTitle(this.title, this.isDark);

  @override
  Widget build(BuildContext context) => Text(title,
      style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w800,
          color:
              Color(0xFFE5E7EB)));
}

class _FeatureGrid extends StatelessWidget {
  final bool isDark;
  const _FeatureGrid({required this.isDark});

  static const _features = [
    (Icons.chat_bubble_outline, '💬', 'Aile Sohbeti', Color(0xFF8B5CF6),
        'Gerçek zamanlı mesajlaşma, emoji, fotoğraf paylaşımı'),
    (Icons.photo_library_outlined, '📸', 'Galeri', Color(0xFFEC4899),
        'Aile anlarını paylaşın, albüm oluşturun'),
    (Icons.shopping_cart_outlined, '🛒', 'Alışveriş', Color(0xFF10B981),
        'AI önerileri, kategori, miktar takibi'),
    (Icons.restaurant, '🍳', 'Mutfak', Color(0xFFF97316),
        '21K+ tarif, haftalık plan, alışveriş entegrasyonu'),
    (Icons.school_outlined, '🎓', 'Eğitim', Color(0xFF6366F1),
        '300 aktivite, 20 kategori, ebeveyn rehberi'),
    (Icons.location_on_outlined, '📍', 'GPS Takibi', Color(0xFF06B6D4),
        'Aile haritası, güvenli bölge, batarya takibi'),
    (Icons.account_balance_wallet_outlined, '💰', 'Bütçe', Color(0xFF3B82F6),
        'Harcama takibi, AI analiz, kategori bütçeleri'),
    (Icons.child_care, '👧', 'Çocuk Gelişimi', Color(0xFFF59E0B),
        'Görev, ödev, program, güvenlik, AI önerileri'),
    (Icons.auto_awesome, '🤖', 'Tokensiz AI', Color(0xFF8B5CF6),
        'API gerektirmeyen yerel AI içerik motoru'),
    (Icons.shield_outlined, '🛡️', 'Güvenlik & SOS', Color(0xFFEF4444),
        'Kaza algılama, acil SOS, sağlık kartı'),
    (Icons.calendar_today_outlined, '📅', 'Takvim', Color(0xFF3B82F6),
        'Aile etkinlikleri, akıllı hatırlatıcılar'),
    (Icons.repeat, '🔄', 'Rutinler', Color(0xFF10B981),
        'Günlük/haftalık rutinler, iş bölümü'),
  ];

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: 2.0,
      children: _features.map((f) {
        final (icon, _, title, color, desc) = f;
        return Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFF13131A),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withAlpha(40)),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withAlpha(20),
                  blurRadius: 6,
                  offset: const Offset(0, 2))
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                    color: color.withAlpha(25),
                    borderRadius: BorderRadius.circular(10)),
                child: Icon(icon, color: color, size: 18),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFFE5E7EB))),
                    Text(desc,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 9, color: Color(0xFF6B7280), height: 1.3)),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _TechStack extends StatelessWidget {
  final bool isDark;
  const _TechStack({required this.isDark});

  static const _stack = [
    ('Flutter', '🐦', 'Dart ile cross-platform geliştirme'),
    ('Supabase', '⚡', 'Gerçek zamanlı veritabanı ve auth'),
    ('Firebase', '🔥', 'Bildirimler, Crashlytics, Analytics'),
    ('Riverpod', '🎯', 'Reaktif durum yönetimi'),
    ('GoRouter', '🧭', 'Tip-güvenli navigasyon'),
    ('Hive', '🗄️', 'Çevrimdışı önbellekleme'),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: _stack.map((s) {
        final (name, emoji, desc) = s;
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFF13131A),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withAlpha(20),
                  blurRadius: 4)
            ],
          ),
          child: Row(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 20)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name,
                        style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFFE5E7EB))),
                    Text(desc,
                        style: const TextStyle(
                            fontSize: 11, color: Color(0xFF6B7280))),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _StatsRow extends StatelessWidget {
  final bool isDark;
  const _StatsRow({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _StatCard('21K+', 'Tarif', const Color(0xFFF97316), isDark),
        const SizedBox(width: 8),
        _StatCard('300', 'Aktivite', const Color(0xFF8B5CF6), isDark),
        const SizedBox(width: 8),
        _StatCard('400+', 'AI Öneri', const Color(0xFF10B981), isDark),
        const SizedBox(width: 8),
        _StatCard('12', 'Özellik', const Color(0xFF3B82F6), isDark),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String value, label;
  final Color color;
  final bool isDark;
  const _StatCard(this.value, this.label, this.color, this.isDark);

  @override
  Widget build(BuildContext context) => Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            gradient: LinearGradient(
                colors: [color.withAlpha(30), color.withAlpha(10)]),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withAlpha(50)),
          ),
          child: Column(
            children: [
              Text(value,
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: color)),
              Text(label,
                  style: const TextStyle(
                      fontSize: 10, color: Color(0xFF6B7280))),
            ],
          ),
        ),
      );
}

class _QuickLinks extends StatelessWidget {
  final bool isDark;
  const _QuickLinks({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final links = [
      (Icons.restaurant, 'Mutfak', AppRoutes.kitchen,
          const Color(0xFFF97316)),
      (Icons.school_outlined, 'Eğitim', AppRoutes.education,
          const Color(0xFF8B5CF6)),
      (Icons.location_on, 'Aile Haritası', AppRoutes.familyMap,
          const Color(0xFF06B6D4)),
      (Icons.shopping_cart, 'Alışveriş', AppRoutes.shopping,
          const Color(0xFF10B981)),
    ];
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: links.map((l) {
        final (icon, label, route, color) = l;
        return GestureDetector(
          onTap: () => context.push(route),
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: color.withAlpha(20),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: color.withAlpha(60)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 14, color: color),
                const SizedBox(width: 6),
                Text(label,
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: color)),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
