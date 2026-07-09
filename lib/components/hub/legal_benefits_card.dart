import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../presentation/providers/app_providers.dart';
import '../../services/ai/ai_content_service.dart';
import '../../services/hive_service.dart';

/// Yaşanılan ülkeye göre aileyi ilgilendiren güncel yasal düzenlemeler ve
/// aileye katkı sağlayacak yasal avantajlar/haklar (Belçika, Hollanda, Türkiye).
/// İçerik FamilyHub AI'dan gelir (haftalık önbellekli + "Yenile" ile anlık),
/// ülke ayarına göre otomatik değişir.
class LegalBenefitsCard extends ConsumerStatefulWidget {
  const LegalBenefitsCard({super.key});

  @override
  ConsumerState<LegalBenefitsCard> createState() => _LegalBenefitsCardState();
}

class _LegalBenefitsCardState extends ConsumerState<LegalBenefitsCard> {
  late bool _expanded =
      HiveService.getBoolSetting('legal_benefits_expanded', defaultValue: true);
  int _refreshTick = 0;

  static const _countryNames = {
    'BE': 'Belçika',
    'NL': 'Hollanda',
    'TR': 'Türkiye',
    'DE': 'Almanya',
    'FR': 'Fransa',
  };

  void _toggle() {
    setState(() => _expanded = !_expanded);
    HiveService.setBoolSetting('legal_benefits_expanded', _expanded);
  }

  @override
  Widget build(BuildContext context) {
    final country = ref.watch(countryProvider);
    final countryName = _countryNames[country] ?? 'Belçika';

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 4),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF102A1E), Color(0xFF0E2233)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0x2A10B981)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              onTap: _toggle,
              borderRadius: BorderRadius.circular(12),
              child: Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                          colors: [Color(0xFF10B981), Color(0xFF059669)]),
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: const Icon(Icons.gavel_rounded,
                        color: Colors.white, size: 18),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Yasal Haklar & Avantajlar',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w800)),
                        Text('$countryName · aileni ilgilendiren güncel bilgiler',
                            style: const TextStyle(
                                color: Color(0xFF9CA3AF), fontSize: 12)),
                      ],
                    ),
                  ),
                  if (_expanded)
                    IconButton(
                      onPressed: () => setState(() => _refreshTick++),
                      icon: const Icon(Icons.refresh_rounded,
                          color: Color(0xFF10B981), size: 20),
                      tooltip: 'Yenile',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  const SizedBox(width: 6),
                  AnimatedRotation(
                    turns: _expanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: const Icon(Icons.keyboard_arrow_down_rounded,
                        color: Color(0xFF9CA3AF), size: 24),
                  ),
                ],
              ),
            ),
            if (_expanded) ...[
              const SizedBox(height: 12),
              FutureBuilder<List<Map<String, dynamic>>>(
                future: AiContentService.weeklyList(
                  topic: 'legal_benefits_${country}_$_refreshTick',
                  forceRefresh: _refreshTick > 0,
                  prompt: '''
$countryName'da yaşayan bir aile için GÜNCEL ve pratik yasal bilgileri üret.
İki tür içerik ver: (1) aileyi ilgilendiren yasal düzenleme/yükümlülükler,
(2) aileye maddi/hukuki katkı sağlayacak yasal HAK, destek ve avantajlar
(çocuk yardımı, vergi indirimi, doğum/ebeveyn izni, eğitim/sağlık destekleri vb.).
Yalnızca $countryName için geçerli, gerçek ve güncel bilgiler ver.
4-5 madde. Her madde kısa ve uygulanabilir olsun.
Sadece JSON döndür: {"items":[{"title":"Kısa başlık","description":"1-2 cümle açıklama","type":"hak|düzenleme"}]}
Türkçe yaz.''',
                  listKey: 'items',
                  maxTokens: 900,
                  fallback: [
                    {
                      'title': 'İnternet bağlantısı gerekli',
                      'description':
                          'Ülkeye özel güncel yasal bilgiler için internete '
                              'bağlanın ve "Yenile"ye dokunun.',
                      'type': 'düzenleme',
                    },
                  ],
                ),
                builder: (context, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Row(children: [
                        const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Color(0xFF10B981))),
                        const SizedBox(width: 10),
                        Text('$countryName için güncel bilgiler alınıyor…',
                            style: const TextStyle(
                                color: Color(0xFF9CA3AF), fontSize: 13)),
                      ]),
                    );
                  }
                  final items = snap.data ?? const [];
                  if (items.isEmpty) {
                    return const Text('Şu an bilgi alınamadı.',
                        style:
                            TextStyle(color: Color(0xFF9CA3AF), fontSize: 13));
                  }
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (final it in items) _item(it),
                    ],
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _item(Map<String, dynamic> it) {
    final title = (it['title'] ?? '').toString();
    final desc = (it['description'] ?? '').toString();
    final isRight = (it['type'] ?? '').toString().toLowerCase().contains('hak');
    final color = isRight ? const Color(0xFF34D399) : const Color(0xFF60A5FA);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(isRight ? Icons.verified_rounded : Icons.info_outline_rounded,
              size: 16, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (title.isNotEmpty)
                  Text(title,
                      style: TextStyle(
                          color: color,
                          fontSize: 13,
                          fontWeight: FontWeight.w700)),
                if (desc.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(desc,
                        style: const TextStyle(
                            color: Color(0xFFD1D5DB),
                            fontSize: 12.5,
                            height: 1.4)),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
