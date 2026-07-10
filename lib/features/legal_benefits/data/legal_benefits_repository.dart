import 'dart:convert';
import '../../../services/auth_service.dart';
import '../../../services/hive_service.dart';
import '../domain/legal_benefit.dart';

/// Yasal hak/avantaj verisi — resmî kaynaklı statik seed + kullanıcı-izole
/// "kaydedilenler". İnternet gerektirmez; içerik doğrulanmış resmî kaynaklara
/// (federal/bölgesel kurumlar) bağlıdır. Kaydedilenler userId ile izole edilir.
class LegalBenefitsRepository {
  LegalBenefitsRepository._();
  static final instance = LegalBenefitsRepository._();

  /// Kaydedilenler Hive anahtarı — kullanıcı bazlı izolasyon (hesap değişiminde
  /// başka kullanıcının kayıtları görünmez).
  String get _savedKey {
    final uid = AuthService.currentUserId ?? 'anon';
    return 'legal_saved_$uid';
  }

  Set<String> savedIds() {
    final raw = HiveService.getSetting(_savedKey);
    if (raw == null || raw.isEmpty) return {};
    try {
      return (jsonDecode(raw) as List).map((e) => e.toString()).toSet();
    } catch (_) {
      return {};
    }
  }

  Future<void> toggleSaved(String id) async {
    final ids = savedIds();
    if (!ids.add(id)) ids.remove(id);
    await HiveService.setSetting(_savedKey, jsonEncode(ids.toList()));
  }

  bool isSaved(String id) => savedIds().contains(id);

  /// Ülkeye göre resmî kaynaklı yasal hak/avantaj listesi.
  /// Belçika için federal + bölgesel (Flaman/Valon/Brüksel) katmanları ayrı.
  List<LegalBenefit> forCountry(String country) {
    final list = _seed[country] ?? _seed['BE']!;
    // Süresi geçmiş içerik listelenir ama isExpired ile işaretlenir (UI ayırır).
    return list;
  }

  static DateTime _v(int y, int m, int d) => DateTime(y, m, d);

  static final Map<String, List<LegalBenefit>> _seed = {
    'BE': [
      LegalBenefit(
        id: 'be_groeipakket',
        title: 'Groeipakket (Çocuk Yardımı)',
        description:
            'Flaman Bölgesi\'nde her çocuk için aylık büyüme paketi. Tutar çocuk sayısı ve duruma göre değişir. Uygunluk resmî kurum tarafından belirlenir.',
        category: LegalCategory.childBenefits,
        countryCode: 'BE',
        region: LegalRegion.flanders,
        sourceTitle: 'Groeipakket (Vlaanderen)',
        sourceUrl: 'https://www.groeipakket.be/',
        lastVerifiedAt: _v(2026, 1, 1),
      ),
      LegalBenefit(
        id: 'be_caf_wallonie',
        title: 'Allocations familiales (FAMIWAL)',
        description:
            'Valon Bölgesi\'nde çocuk başına aylık aile yardımı. Başvuru ve tutar için resmî kuruma başvurun.',
        category: LegalCategory.childBenefits,
        countryCode: 'BE',
        region: LegalRegion.wallonia,
        sourceTitle: 'FAMIWAL',
        sourceUrl: 'https://www.famiwal.be/',
        lastVerifiedAt: _v(2026, 1, 1),
      ),
      LegalBenefit(
        id: 'be_famiris_brussels',
        title: 'Allocations familiales (FAMIRIS)',
        description:
            'Brüksel-Başkent Bölgesi\'nde çocuk yardımı. Uygun olabilirsiniz; şartları resmî kaynaktan doğrulayın.',
        category: LegalCategory.childBenefits,
        countryCode: 'BE',
        region: LegalRegion.brussels,
        sourceTitle: 'FAMIRIS',
        sourceUrl: 'https://www.famiris.brussels/',
        lastVerifiedAt: _v(2026, 1, 1),
      ),
      LegalBenefit(
        id: 'be_ouderschapsverlof',
        title: 'Ebeveyn İzni (Ouderschapsverlof)',
        description:
            'Federal düzeyde her ebeveyn çocuk başına tam/yarı zamanlı ücretli ebeveyn izni kullanabilir. Detaylar için resmî kaynağa bakın.',
        category: LegalCategory.parentalLeave,
        countryCode: 'BE',
        region: LegalRegion.federal,
        sourceTitle: 'RVA/ONEM',
        sourceUrl: 'https://www.rva.be/',
        lastVerifiedAt: _v(2026, 1, 1),
      ),
      LegalBenefit(
        id: 'be_verhoogde',
        title: 'Verhoogde Tegemoetkoming',
        description:
            'Düşük gelirli aileler için sağlık ve ilaç masraflarında artırılmış geri ödeme. Uygunluk gelire bağlıdır.',
        category: LegalCategory.healthRights,
        countryCode: 'BE',
        region: LegalRegion.federal,
        sourceTitle: 'RIZIV/INAMI',
        sourceUrl: 'https://www.riziv.fgov.be/',
        lastVerifiedAt: _v(2026, 1, 1),
      ),
    ],
    'NL': [
      LegalBenefit(
        id: 'nl_kinderbijslag',
        title: 'Kinderbijslag (SVB)',
        description:
            '18 yaş altı her çocuk için üç ayda bir devlet çocuk yardımı. Başvuru SVB üzerinden yapılır.',
        category: LegalCategory.childBenefits,
        countryCode: 'NL',
        region: LegalRegion.federal,
        sourceTitle: 'SVB',
        sourceUrl: 'https://www.svb.nl/',
        lastVerifiedAt: _v(2026, 1, 1),
      ),
      LegalBenefit(
        id: 'nl_kindgebonden',
        title: 'Kindgebonden Budget',
        description:
            'Gelire bağlı ek çocuk bütçesi. Belastingdienst/Toeslagen üzerinden başvurulur.',
        category: LegalCategory.familySupport,
        countryCode: 'NL',
        region: LegalRegion.federal,
        sourceTitle: 'Belastingdienst Toeslagen',
        sourceUrl: 'https://www.belastingdienst.nl/toeslagen',
        lastVerifiedAt: _v(2026, 1, 1),
      ),
    ],
    'TR': [
      LegalBenefit(
        id: 'tr_analik_izni',
        title: 'Doğum (Analık) İzni',
        description:
            'Çalışan anneye doğumdan önce 8, sonra 8 hafta olmak üzere 16 hafta ücretli izin. Şartlar için resmî kaynağa bakın.',
        category: LegalCategory.parentalLeave,
        countryCode: 'TR',
        region: LegalRegion.federal,
        sourceTitle: 'ÇSGB',
        sourceUrl: 'https://www.csgb.gov.tr/',
        lastVerifiedAt: _v(2026, 1, 1),
      ),
    ],
    'DE': [
      LegalBenefit(
        id: 'de_kindergeld',
        title: 'Kindergeld',
        description:
            'Her çocuk için aylık düzenli çocuk parası. Başvuru Familienkasse üzerinden yapılır.',
        category: LegalCategory.childBenefits,
        countryCode: 'DE',
        region: LegalRegion.federal,
        sourceTitle: 'Familienkasse',
        sourceUrl: 'https://www.arbeitsagentur.de/familie-und-kinder',
        lastVerifiedAt: _v(2026, 1, 1),
      ),
    ],
    'FR': [
      LegalBenefit(
        id: 'fr_caf',
        title: 'Allocations Familiales (CAF)',
        description:
            'İki ve daha fazla çocuklu aileler için aylık aile yardımı. Uygunluk CAF tarafından belirlenir.',
        category: LegalCategory.childBenefits,
        countryCode: 'FR',
        region: LegalRegion.federal,
        sourceTitle: 'CAF',
        sourceUrl: 'https://www.caf.fr/',
        lastVerifiedAt: _v(2026, 1, 1),
      ),
    ],
  };
}
