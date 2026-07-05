import 'package:flutter/material.dart';
import '../../widgets/settings/screen_header.dart';
import 'package:go_router/go_router.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  final _sections = const [
    {
      'title': '1. Toplanan Veriler',
      'content':
          'FamilyHub, ad, e-posta, telefon numarası, profil fotoğrafı, konum verisi ve uygulama kullanım istatistiklerini toplar. Tüm veriler şifrelenerek saklanır.',
    },
    {
      'title': '2. Veri Kullanımı',
      'content':
          'Toplanan veriler yalnızca hizmet sunumu, güvenlik ve kişiselleştirme amacıyla kullanılır. Veriler üçüncü taraflarla paylaşılmaz.',
    },
    {
      'title': '3. Konum Verisi',
      'content':
          'Konum verisi yalnızca aile üyeleri arasında paylaşılır. Kullanıcılar istedikleri zaman konum paylaşımını devre dışı bırakabilir.',
    },
    {
      'title': '4. Çocukların Gizliliği',
      'content':
          '13 yaş altı çocukların verileri ebeveyn kontrolündedir. Çocuk hesaplarında reklam ve harici analitik kullanılmaz.',
    },
    {
      'title': '5. Haklarınız',
      'content':
          'Verilerinize erişme, düzeltme, silme ve taşınabilirlik haklarına sahipsiniz. Talepleriniz için destek ekibimizle iletişime geçebilirsiniz.',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final bg = const Color(0xFF0A0A0F);

    return Scaffold(
      backgroundColor: bg,
      appBar: ScreenHeader(
        title: 'Gizlilik Politikası',
        showBack: true,
        onBack: () => context.pop(),
      ),
      body: ListView.builder(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(20),
        itemCount: _sections.length,
        itemBuilder: (context, index) {
          final s = _sections[index];
          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF13131A),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  s['title']!,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFE5E7EB),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  s['content']!,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.6,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
