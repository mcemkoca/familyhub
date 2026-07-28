// Hard-coded kullanıcı metni tarayıcı — i18n kapsam denetimi.
//
// Amaç: Kullanıcıya görünen ama AppLocalizations'tan GEÇMEYEN string
// literallerini bulur. Dil değiştirildiğinde değişmeyen metinlerin kaynağı
// bunlardır. Çıktı: dosya · satır · metin · önerilen namespace.
//
// Kullanım:
//   dart run tool/hardcoded_string_scan.dart            # özet + ilk 40 offender
//   dart run tool/hardcoded_string_scan.dart --full     # tüm bulgular
//   dart run tool/hardcoded_string_scan.dart --ci N      # >N bulgu → exit 1
//
// Heuristik olduğundan false-positive olabilir; amaç önceliklendirmedir.
import 'dart:io';

const _scanDirs = ['lib/presentation', 'lib/features', 'lib/components'];

// Kullanıcıya görünen metin taşıyan widget parametreleri/çağrıları.
final _userFacing = RegExp(
  r'''(?:Text|SelectableText|Tooltip|hintText|labelText|helperText|'''
  r'''errorText|title|subtitle|label|semanticLabel|message|content)'''
  r'''\s*[:(]\s*(?:const\s+)?(['"])(.*?)\1''',
  dotAll: false,
);

// En az bir harf içeren ve çeviri gerektiren metin (yalnız sembol/rakam değil).
final _hasLetters = RegExp(r'[A-Za-zĞÜŞİÖÇğüşıöç]{2,}');
// Türkçe'ye özgü işaret — güçlü "çevrilmemiş" sinyali.
final _turkish = RegExp(r'[ğüşıöçİĞÜŞÖÇ]');

// Metin gibi görünmeyen teknik değerler (route, asset, key, id).
final _technical = RegExp(
  r'''^(?:/|assets/|http|[a-z0-9_]+\.(?:png|jpg|svg|webp|json)$|'''
  r'''[a-z][a-zA-Z0-9_]*$|#[0-9A-Fa-f]{3,8}$)''',
);

String _namespaceFor(String path) {
  final p = path.replaceAll(r'\', '/');
  for (final m in {
    'shopping': 'shopping',
    'kitchen': 'kitchen',
    'child': 'child',
    'health': 'health',
    'development': 'development',
    'budget': 'budget',
    'settings': 'settings',
    'auth': 'auth',
    'hub': 'home',
    'onboarding': 'onboarding',
    'familyhub_ai': 'familyHubAI',
    'family_intelligence': 'familyIntelligence',
    'legal': 'legalBenefits',
    'notification': 'notifications',
  }.entries) {
    if (p.contains('/${m.key}') || p.contains('${m.key}_')) return m.value;
  }
  return 'common';
}

class _Finding {
  final String file;
  final int line;
  final String text;
  final String namespace;
  _Finding(this.file, this.line, this.text, this.namespace);
}

void main(List<String> args) {
  final full = args.contains('--full');
  final ciIdx = args.indexOf('--ci');
  final ciThreshold =
      ciIdx >= 0 && ciIdx + 1 < args.length ? int.tryParse(args[ciIdx + 1]) : null;

  final findings = <_Finding>[];
  for (final d in _scanDirs) {
    final dir = Directory(d);
    if (!dir.existsSync()) continue;
    for (final f in dir.listSync(recursive: true).whereType<File>()) {
      if (!f.path.endsWith('.dart')) continue;
      final lines = f.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        final line = lines[i];
        if (line.trimLeft().startsWith('//')) continue;
        if (line.contains('AppLocalizations')) continue;
        if (line.contains('debugPrint') || line.contains('print(')) continue;
        for (final m in _userFacing.allMatches(line)) {
          final text = m.group(2)!.trim();
          if (text.isEmpty) continue;
          if (!_hasLetters.hasMatch(text)) continue;
          if (_technical.hasMatch(text)) continue;
          if (text.startsWith(r'$') || text.startsWith('{')) continue;
          findings.add(_Finding(f.path, i + 1, text, _namespaceFor(f.path)));
        }
      }
    }
  }

  // Kesin çevrilmemiş (Türkçe işaret içeren) → yüksek öncelik.
  final turkish = findings.where((f) => _turkish.hasMatch(f.text)).toList();

  final byFile = <String, int>{};
  for (final f in findings) {
    byFile[f.file] = (byFile[f.file] ?? 0) + 1;
  }
  final ranked = byFile.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));

  stdout.writeln('== Hard-coded kullanıcı metni taraması ==');
  stdout.writeln('Toplam bulgu: ${findings.length}');
  stdout.writeln('Kesin çevrilmemiş (Türkçe işaretli): ${turkish.length}');
  stdout.writeln('Etkilenen dosya: ${byFile.length}\n');

  stdout.writeln('-- En çok hard-coded metin içeren dosyalar --');
  for (final e in ranked.take(full ? ranked.length : 40)) {
    stdout.writeln('  ${e.value.toString().padLeft(3)}  '
        '${e.key.replaceAll(r'\', '/')}  [${_namespaceFor(e.key)}]');
  }

  if (full) {
    stdout.writeln('\n-- Tüm bulgular (dosya:satır — metin) --');
    for (final f in findings) {
      stdout.writeln('${f.file.replaceAll(r'\', '/')}:${f.line}  '
          '[${f.namespace}]  "${f.text}"');
    }
  }

  if (ciThreshold != null && findings.length > ciThreshold) {
    stderr.writeln('\nCI: ${findings.length} hard-coded metin > eşik '
        '$ciThreshold — başarısız.');
    exit(1);
  }
  stdout.writeln('\nTARAMA TAMAM.');
}
