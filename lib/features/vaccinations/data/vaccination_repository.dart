import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import '../../../services/auth_service.dart';
import '../../../services/hive_service.dart';
import '../../../services/content/content_localizer.dart';

/// Aşı kaynağı (resmî kurum + URL).
class VaccineSource {
  final String authority;
  final String url;
  const VaccineSource(this.authority, this.url);
}

/// Tek aşı kaydı (aktif dile indirgenmiş).
class VaccineItem {
  final String id;
  final String ageBand;
  final String name;
  final String timing;
  final String note;
  const VaccineItem({
    required this.id,
    required this.ageBand,
    required this.name,
    required this.timing,
    required this.note,
  });
}

/// Aşı kategorisi (çocuk/yetişkin/hamilelik/seyahat).
class VaccineCategory {
  final String key;
  final String label;
  final String desc;
  final List<VaccineItem> vaccines;
  final List<VaccineSource> sources;
  const VaccineCategory({
    required this.key,
    required this.label,
    required this.desc,
    required this.vaccines,
    required this.sources,
  });
}

/// Ülkeye göre aşı referans takvimini `assets/data/health/vaccinations_<ülke>.json`'dan
/// yükler ve aktif dile (i18n) indirger. "Yapıldı" durumu kullanıcı-izole Hive'da
/// (kişi tipi + aşı id) tutulur — resmî kayıt değil, kişisel takip amaçlıdır.
class VaccinationRepository {
  VaccinationRepository._();
  static final instance = VaccinationRepository._();

  final Map<String, List<VaccineCategory>> _cache = {};
  static const _supported = {'BE'};

  Future<List<VaccineCategory>> forCountry(String country, String lang) async {
    final code = _supported.contains(country) ? country : 'BE';
    final key = '$code|$lang';
    final cached = _cache[key];
    if (cached != null) return cached;

    List<VaccineCategory> out = const [];
    try {
      final txt = await rootBundle
          .loadString('assets/data/health/vaccinations_${code.toLowerCase()}.json');
      final raw = jsonDecode(txt) as Map<String, dynamic>;
      final sourcesRaw = (raw['sources'] as Map?) ?? const {};
      final cats = (raw['categories'] as List?) ?? const [];
      out = cats.map<VaccineCategory>((c) {
        final loc = normalizeContent(c, lang);
        final m = (loc is Map) ? loc.cast<String, dynamic>() : <String, dynamic>{};
        final catKey = (m['key'] ?? '').toString();
        final vaccines = ((m['vaccines'] as List?) ?? const [])
            .map<VaccineItem>((v) {
          final vm = (v is Map) ? v.cast<String, dynamic>() : <String, dynamic>{};
          return VaccineItem(
            id: (vm['id'] ?? '').toString(),
            ageBand: (vm['ageBand'] ?? '').toString(),
            name: (vm['name'] ?? '').toString(),
            timing: (vm['timing'] ?? '').toString(),
            note: (vm['note'] ?? '').toString(),
          );
        }).toList();
        return VaccineCategory(
          key: catKey,
          label: (m['label'] ?? catKey).toString(),
          desc: (m['desc'] ?? '').toString(),
          vaccines: vaccines,
          sources: _parseSources(sourcesRaw[catKey]),
        );
      }).toList();
    } catch (_) {
      out = const [];
    }
    _cache[key] = out;
    return out;
  }

  static List<VaccineSource> _parseSources(dynamic raw) {
    if (raw is List) {
      return raw
          .whereType<Map<String, dynamic>>()
          .map((s) => VaccineSource(
              (s['authority'] ?? '').toString(), (s['url'] ?? '').toString()))
          .toList();
    }
    return const [];
  }

  // ── Kişi-izole "yapıldı" takibi ──
  String get _doneKey {
    final uid = AuthService.currentUserId ?? 'anon';
    return 'vacc_done_$uid';
  }

  Set<String> doneIds() {
    final raw = HiveService.getSetting(_doneKey);
    if (raw == null || raw.isEmpty) return {};
    try {
      return (jsonDecode(raw) as List).map((e) => e.toString()).toSet();
    } catch (_) {
      return {};
    }
  }

  /// Anahtar: `<memberType>:<categoryKey>:<vaccineId>` (kişi başına ayrı takip).
  String markKey(String memberType, String categoryKey, String vaccineId) =>
      '$memberType:$categoryKey:$vaccineId';

  bool isDone(String key) => doneIds().contains(key);

  Future<void> toggleDone(String key) async {
    final ids = doneIds();
    if (!ids.add(key)) ids.remove(key);
    await HiveService.setSetting(_doneKey, jsonEncode(ids.toList()));
  }
}
