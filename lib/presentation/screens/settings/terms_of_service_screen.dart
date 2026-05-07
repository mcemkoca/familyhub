import 'package:flutter/material.dart';
import '../../../config/constants.dart';
import '../../widgets/settings/screen_header.dart';
import 'package:go_router/go_router.dart';

class TermsOfServiceScreen extends StatelessWidget {
  const TermsOfServiceScreen({super.key});

  final _sections = const [
    {
      'title': '1. Hizmet Kapsamı',
      'content':
          'FamilyHub, aile üyelerinin etkinliklerini, görevlerini, sohbetlerini ve konumlarını yönetmelerini sağlayan bir dijital platformdur. Hizmet, mobil uygulama üzerinden sunulur.',
    },
    {
      'title': '2. Kullanım Koşulları',
      'content':
          'Kullanıcılar, uygulamayı yasalara uygun şekilde kullanmayı kabul eder. Başka kullanıcıların haklarını ihlal eden, zararlı veya yasa dışı içerik paylaşımı yasaktır.',
    },
    {
      'title': '3. Hesap ve Güvenlik',
      'content':
          'Kullanıcılar hesap bilgilerinin gizliliğinden sorumludur. Şüpheli bir aktivite fark ederseniz derhal destek ekibimize bildirin.',
    },
    {
      'title': '4. Veri Saklama',
      'content':
          'Kullanıcı verileri şifrelenmiş olarak saklanır. Yedekleme ve silme işlemleri kullanıcının kontrolündedir. Hizmet sonlandırıldığında veriler 30 gün içinde silinir.',
    },
    {
      'title': '5. Değişiklikler',
      'content':
          'FamilyHub, bu koşulları önceden haber vermeksizin güncelleme hakkını saklı tutar. Önemli değişiklikler uygulama içi bildirimle duyurulur.',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkBackground : AppColors.cloudWhite;

    return Scaffold(
      backgroundColor: bg,
      appBar: ScreenHeader(
        title: 'Kullanım Koşulları',
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
              color: isDark ? AppColors.darkCard : Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  s['title']!,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.darkTextPrimary : AppColors.dark,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  s['content']!,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.6,
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.slate,
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
