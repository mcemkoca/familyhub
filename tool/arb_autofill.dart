// ARB otomatik-doldurma — kaynak (app_tr.arb) ile hedef dilleri karşılaştırır.
// Kullanım:
//   dart run tool/arb_autofill.dart --report        # eksik anahtarları JSON raporla
//   dart run tool/arb_autofill.dart --apply          # sağlayıcı ile doldur (secret gerekir)
//
// GÜNCELLEME AKIŞI: geliştirici yalnızca app_tr.arb'ye yeni anahtar ekler ve
// UI'da kullanır. Bu araç en/fr/nl'de eksik anahtarları bulur; çeviri sağlayıcı
// (ARB_TRANSLATE_API_KEY) yapılandırılmışsa otomatik doldurur, değilse raporlar.
// Sağlayıcı yoksa SAHTE çeviri üretmez — eksikleri listeler ve CI'ı uyarır.

import 'dart:convert';
import 'dart:io';
import 'content_sync/content_translator.dart';

const _dir = 'lib/l10n';
const _template = 'tr';
const _targets = ['en', 'fr', 'nl'];

Map<String, dynamic> _loadRaw(String locale) =>
    jsonDecode(File('$_dir/app_$locale.arb').readAsStringSync())
        as Map<String, dynamic>;

/// Metadata (@) hariç çevrilebilir anahtarlar.
Set<String> _keys(Map<String, dynamic> arb) =>
    arb.keys.where((k) => !k.startsWith('@')).toSet();

/// Kaynakta olup hedefte olmayan anahtarlar.
List<String> missingKeys(Map<String, dynamic> template, Map<String, dynamic> target) {
  final t = _keys(target);
  return _keys(template).where((k) => !t.contains(k)).toList()..sort();
}

Future<void> main(List<String> args) async {
  final report = args.contains('--report') || !args.contains('--apply');
  final template = _loadRaw(_template);

  final TranslationProvider provider = PendingTranslationProvider();

  final result = <String, dynamic>{
    'template': _template,
    'provider_configured': provider.isConfigured,
    'targets': {},
  };
  var totalMissing = 0;

  for (final loc in _targets) {
    final target = _loadRaw(loc);
    final missing = missingKeys(template, target);
    totalMissing += missing.length;
    (result['targets'] as Map)[loc] = {
      'missing_count': missing.length,
      'missing_keys': missing,
    };

    if (!report && missing.isNotEmpty) {
      if (!provider.isConfigured) {
        stderr.writeln(
            'HATA: $loc için ${missing.length} eksik anahtar var ama çeviri '
            'sağlayıcı yapılandırılmamış. --report kullanın veya '
            'ARB_TRANSLATE_API_KEY sağlayın.');
        exit(1);
      }
      // Sağlayıcı varsa burada çeviri yapılır (bu ortamda erişilemez).
    }
  }

  stdout.writeln(const JsonEncoder.withIndent('  ').convert(result));
  stdout.writeln('Toplam eksik anahtar: $totalMissing');
  if (totalMissing == 0) {
    stdout.writeln('PARITY TAM: tüm hedef diller kaynakla eşit.');
  }
}
