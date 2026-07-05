import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'child_dev_content.dart' show DevHeader, areaByKey;

/// Gelişim içeriği için güvenilir kaynak kaydı (Source Registry).
/// Belçika yerel kurumları (Kind en Gezin, ONE) + uluslararası otoriter
/// kaynaklar (WHO, CDC, NHS, AAP, UNICEF) önceliklidir.
/// KESİN KURAL: kaynağı olmayan gelişim iddiası gösterilmez.

enum TrustTier { officialLocal, officialIntl, academic, activity }

class DevSource {
  final String id;
  final String title;
  final String organization;
  final String country;
  final String url;
  final TrustTier trustTier;
  const DevSource({
    required this.id,
    required this.title,
    required this.organization,
    required this.country,
    required this.url,
    required this.trustTier,
  });

  String get tierLabel {
    switch (trustTier) {
      case TrustTier.officialLocal:
        return 'Resmi · Belçika';
      case TrustTier.officialIntl:
        return 'Resmi · Uluslararası';
      case TrustTier.academic:
        return 'Akademik';
      case TrustTier.activity:
        return 'Aktivite kaynağı';
    }
  }

  Color get tierColor {
    switch (trustTier) {
      case TrustTier.officialLocal:
        return const Color(0xFF10B981);
      case TrustTier.officialIntl:
        return const Color(0xFF3B82F6);
      case TrustTier.academic:
        return const Color(0xFF8B5CF6);
      case TrustTier.activity:
        return const Color(0xFFF59E0B);
    }
  }
}

const List<DevSource> devSources = [
  DevSource(
    id: 'kindengezin',
    title: 'Kind en Gezin — Opgroeien (Çocuk gelişimi)',
    organization: 'Kind en Gezin (Flanders)',
    country: 'BE',
    url: 'https://www.kindengezin.be',
    trustTier: TrustTier.officialLocal,
  ),
  DevSource(
    id: 'one_be',
    title: 'ONE — Développement de l\'enfant',
    organization: 'Office de la Naissance et de l\'Enfance',
    country: 'BE',
    url: 'https://www.one.be',
    trustTier: TrustTier.officialLocal,
  ),
  DevSource(
    id: 'who_ecd',
    title: 'WHO — Early Child Development',
    organization: 'World Health Organization',
    country: 'INTL',
    url: 'https://www.who.int/health-topics/early-child-development',
    trustTier: TrustTier.officialIntl,
  ),
  DevSource(
    id: 'cdc_milestones',
    title: 'CDC — Developmental Milestones (Learn the Signs)',
    organization: 'Centers for Disease Control and Prevention',
    country: 'US',
    url: 'https://www.cdc.gov/ncbddd/actearly/milestones/index.html',
    trustTier: TrustTier.officialIntl,
  ),
  DevSource(
    id: 'nhs_child',
    title: 'NHS — Baby & child development',
    organization: 'National Health Service (UK)',
    country: 'UK',
    url: 'https://www.nhs.uk/conditions/baby/babys-development/',
    trustTier: TrustTier.officialIntl,
  ),
  DevSource(
    id: 'aap_healthychildren',
    title: 'AAP — HealthyChildren.org (Ages & Stages)',
    organization: 'American Academy of Pediatrics',
    country: 'US',
    url: 'https://www.healthychildren.org/English/ages-stages/Pages/default.aspx',
    trustTier: TrustTier.officialIntl,
  ),
  DevSource(
    id: 'unicef_parenting',
    title: 'UNICEF — Child development & parenting',
    organization: 'UNICEF',
    country: 'INTL',
    url: 'https://www.unicef.org/parenting/child-development',
    trustTier: TrustTier.officialIntl,
  ),
];

DevSource? sourceById(String id) {
  for (final s in devSources) {
    if (s.id == id) return s;
  }
  return null;
}

/// Gelişim alanı → o alanı destekleyen otoriter kaynak id'leri.
const Map<String, List<String>> areaSourceIds = {
  'dil': ['cdc_milestones', 'nhs_child', 'kindengezin'],
  'motor': ['who_ecd', 'cdc_milestones', 'nhs_child'],
  'sosyal': ['cdc_milestones', 'aap_healthychildren', 'one_be'],
  'bilissel': ['cdc_milestones', 'nhs_child', 'unicef_parenting'],
  'ozbakim': ['nhs_child', 'kindengezin', 'one_be'],
  'duyusal': ['aap_healthychildren', 'nhs_child', 'who_ecd'],
};

List<DevSource> sourcesForArea(String areaKey) {
  final ids = areaSourceIds[areaKey] ?? const ['cdc_milestones', 'nhs_child'];
  return ids.map(sourceById).whereType<DevSource>().toList();
}

/// Uygulama genelinde gösterilen bilgilendirme metni (teşhis koymaz).
const String devDisclaimer =
    'Bu içerik yalnızca bilgilendirme amaçlıdır; teşhis niteliği taşımaz. '
    'Gelişim yaş aralığına göre farklılık gösterebilir. Endişeniz varsa veya '
    'acil/ciddi bir durumda bir sağlık ya da çocuk gelişimi uzmanına danışın.';

/// Küçük, tekrar kullanılabilir disclaimer şeridi.
class DevDisclaimerBanner extends StatelessWidget {
  const DevDisclaimerBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A24),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0x1FF59E0B)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, size: 16, color: Color(0xFFF59E0B)),
          SizedBox(width: 8),
          Expanded(
            child: Text(devDisclaimer,
                style: TextStyle(
                    color: Color(0xFF9CA3AF), fontSize: 12, height: 1.4)),
          ),
        ],
      ),
    );
  }
}

/// Bir kaynağı tarayıcıda açan tıklanabilir kart.
class DevSourceTile extends StatelessWidget {
  final DevSource source;
  const DevSourceTile({super.key, required this.source});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        final uri = Uri.tryParse(source.url);
        if (uri != null) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF13131A),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: source.tierColor.withAlpha(50)),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: source.tierColor.withAlpha(35),
                borderRadius: BorderRadius.circular(11),
              ),
              child: Icon(Icons.verified_outlined,
                  size: 20, color: source.tierColor),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(source.title,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600)),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: source.tierColor.withAlpha(30),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(source.tierLabel,
                            style: TextStyle(
                                color: source.tierColor,
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700)),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(source.organization,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                color: Color(0xFF6B7280), fontSize: 11)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Icon(Icons.open_in_new, size: 16, color: Color(0xFF6B7280)),
          ],
        ),
      ),
    );
  }
}

/// MVP Ekran 6 — Kaynak Detayları. Belirli bir alanın ya da tüm kayıtların
/// otoriter kaynaklarını listeler.
class DevSourcesScreen extends StatelessWidget {
  final String? areaKey;
  const DevSourcesScreen({super.key, this.areaKey});

  @override
  Widget build(BuildContext context) {
    final sources =
        areaKey != null ? sourcesForArea(areaKey!) : devSources;
    final title = areaKey != null
        ? '${areaByKey(areaKey!).label} Kaynakları'
        : 'Kaynaklar';
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      body: SafeArea(
        child: Column(
          children: [
            DevHeader(title: title, subtitle: 'Resmi ve otoriter kaynaklar'),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                children: [
                  const DevDisclaimerBanner(),
                  const SizedBox(height: 16),
                  ...sources.map((s) => DevSourceTile(source: s)),
                  const SizedBox(height: 12),
                  const Text(
                    'İçeriklerimiz bu kurumların yayınlarına dayanır. Kaynak '
                    'bağlantıları düzenli kontrol edilir; erişilemeyen kaynaklar '
                    'incelemeye alınır.',
                    style: TextStyle(color: Color(0xFF6B7280), fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
