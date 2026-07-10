// Localization audit — ARB dosyalarını kaynak (app_tr.arb) ile karşılaştırır.
//
// Kontroller:
//  - eksik key (kaynakta var, dilde yok)
//  - fazla key (dilde var, kaynakta yok)
//  - boş değer
//  - placeholder mismatch ({name} kümesi farklı)
//  - kaynakla birebir aynı (çevrilmemiş) değer — yalnızca uyarı
//
// Kullanım:  dart run tool/localization_audit.dart
// Kritik hata (eksik key / placeholder mismatch / boş değer) → exit code 1 (CI).
import 'dart:convert';
import 'dart:io';

const _sourceLocale = 'tr';
const _l10nDir = 'lib/l10n';

final _placeholderRe = RegExp(r'\{(\w+)\}');

Map<String, String> _loadArb(String path) {
  final raw = jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>;
  final out = <String, String>{};
  raw.forEach((k, v) {
    if (k.startsWith('@')) return; // metadata
    if (v is String) out[k] = v;
  });
  return out;
}

Set<String> _placeholders(String value) =>
    _placeholderRe.allMatches(value).map((m) => m.group(1)!).toSet();

void main() {
  final dir = Directory(_l10nDir);
  if (!dir.existsSync()) {
    stderr.writeln('HATA: $_l10nDir bulunamadı.');
    exit(2);
  }

  final source = _loadArb('$_l10nDir/app_$_sourceLocale.arb');
  final locales = dir
      .listSync()
      .whereType<File>()
      .map((f) => f.path.replaceAll('\\', '/'))
      .where((p) => RegExp(r'app_\w+\.arb$').hasMatch(p))
      .toList()
    ..sort();

  var errors = 0;
  var warnings = 0;

  stdout.writeln('== Localization Audit ==');
  stdout.writeln('Kaynak: $_sourceLocale (${source.length} key)');
  stdout.writeln('Diller: ${locales.length}\n');

  for (final path in locales) {
    final code = RegExp(r'app_(\w+)\.arb').firstMatch(path)!.group(1)!;
    if (code == _sourceLocale) continue;
    final target = _loadArb(path);

    final missing = source.keys.where((k) => !target.containsKey(k)).toList();
    final extra = target.keys.where((k) => !source.containsKey(k)).toList();
    final empty =
        target.entries.where((e) => e.value.trim().isEmpty).map((e) => e.key);
    final phMismatch = <String>[];
    final untranslated = <String>[];
    for (final k in source.keys) {
      final tv = target[k];
      if (tv == null) continue;
      if (_placeholders(source[k]!).difference(_placeholders(tv)).isNotEmpty ||
          _placeholders(tv).difference(_placeholders(source[k]!)).isNotEmpty) {
        phMismatch.add(k);
      }
      if (tv == source[k] && _placeholders(tv).isEmpty && tv.length > 3) {
        untranslated.add(k);
      }
    }

    stdout.writeln('--- $code (${target.length} key) ---');
    if (missing.isNotEmpty) {
      errors += missing.length;
      stdout.writeln('  EKSİK (${missing.length}): ${missing.take(10).join(", ")}'
          '${missing.length > 10 ? " …" : ""}');
    }
    if (phMismatch.isNotEmpty) {
      errors += phMismatch.length;
      stdout.writeln('  PLACEHOLDER UYUMSUZ (${phMismatch.length}): '
          '${phMismatch.take(10).join(", ")}');
    }
    final emptyList = empty.toList();
    if (emptyList.isNotEmpty) {
      errors += emptyList.length;
      stdout.writeln('  BOŞ (${emptyList.length}): ${emptyList.take(10).join(", ")}');
    }
    if (extra.isNotEmpty) {
      warnings += extra.length;
      stdout.writeln('  FAZLA (${extra.length}): ${extra.take(10).join(", ")}');
    }
    if (untranslated.isNotEmpty) {
      warnings += untranslated.length;
      stdout.writeln('  ÇEVRİLMEMİŞ? (${untranslated.length}): '
          '${untranslated.take(10).join(", ")}');
    }
    if (missing.isEmpty &&
        phMismatch.isEmpty &&
        emptyList.isEmpty &&
        extra.isEmpty &&
        untranslated.isEmpty) {
      stdout.writeln('  ✓ temiz');
    }
    stdout.writeln('');
  }

  stdout.writeln('== Sonuç: $errors kritik hata, $warnings uyarı ==');
  if (errors > 0) {
    stderr.writeln('AUDIT BAŞARISIZ — kritik hatalar var.');
    exit(1);
  }
  stdout.writeln('AUDIT BAŞARILI.');
}
