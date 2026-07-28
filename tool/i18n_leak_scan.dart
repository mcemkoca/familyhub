// i18n Türkçe-sızıntı tarayıcı.
//
// Türkçe DIŞINDAKİ dil dosyalarında (nl/fr/en) yanlışlıkla kalmış Türkçe
// metinleri tespit eder — "nl → tr fallback" yasağının makine denetimi.
//
// Sinyaller:
//   1) Türkçe'ye özgü karakterler: ğ, ı, İ, ş  (nl/fr/en'de bulunmaz)
//   2) Türkçe belirteç kelimeler: ve, veya, için, ile, bir, ...
//
// Yanlış-pozitifler için allowlist: tool/i18n_leak_allowlist.txt
//   Her satır: <locale>:<key>   (örn. nl:appTitle)  — # ile yorum.
//   Marka/özel ad/teknik değerler buraya gerekçeyle eklenir.
//
// Kullanım:  dart run tool/i18n_leak_scan.dart
// Sızıntı bulunursa exit code 1 (CI).
import 'dart:convert';
import 'dart:io';

const _l10nDir = 'lib/l10n';
const _allowlistPath = 'tool/i18n_leak_allowlist.txt';
const _targetLocales = ['nl', 'fr', 'en'];

// Türkçe'ye özgü harfler (Flemenkçe/Fransızca/İngilizce'de görülmez).
final _turkishChars = RegExp('[ğışĞİ]');

// Türkçe belirteç kelimeler (kelime sınırıyla, küçük harfe indirgenmiş metinde).
const _turkishWords = {
  've', 'veya', 'için', 'icin', 'ile', 'bir', 'bu', 'şu', 'çok', 'daha',
  'giriş', 'giris', 'şifre', 'sifre', 'aile', 'çocuk', 'cocuk', 'ayarlar',
  'kaydet', 'sil', 'iptal', 'tamam', 'devam', 'geri', 'ileri', 'başarılı',
  'basarili', 'hata', 'yükleniyor', 'yukleniyor', 'sağlık', 'saglik',
  'gelişim', 'gelisim', 'eğitim', 'egitim', 'görev', 'gorev', 'takvim',
  'alışveriş', 'alisveris', 'hoş', 'hos', 'geldiniz', 'birlikte', 'hesabın',
  'oturum', 'yapmalısınız', 'başarısız', 'güçlü', 'tekrar', 'deneyin',
};

final _wordRe = RegExp(r'[a-zçğıöşü]+', unicode: true);

Map<String, String> _loadArb(String path) {
  final raw = jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>;
  final out = <String, String>{};
  raw.forEach((k, v) {
    if (k.startsWith('@')) return;
    if (v is String) out[k] = v;
  });
  return out;
}

Set<String> _loadAllowlist() {
  final f = File(_allowlistPath);
  if (!f.existsSync()) return {};
  return f
      .readAsLinesSync()
      .map((l) => l.trim())
      .where((l) => l.isNotEmpty && !l.startsWith('#'))
      .map((l) => l.split(RegExp(r'\s+')).first) // gerekçeyi at
      .toSet();
}

/// Değerin Türkçe olma gerekçesini döndürür, temizse null.
String? _turkishReason(String value) {
  if (_turkishChars.hasMatch(value)) {
    final ch = _turkishChars.firstMatch(value)!.group(0);
    return "Türkçe karakter '$ch'";
  }
  final lower = value.toLowerCase();
  for (final m in _wordRe.allMatches(lower)) {
    if (_turkishWords.contains(m.group(0))) {
      return "Türkçe kelime '${m.group(0)}'";
    }
  }
  return null;
}

void main() {
  if (!Directory(_l10nDir).existsSync()) {
    stderr.writeln('HATA: $_l10nDir bulunamadı.');
    exit(2);
  }
  final allow = _loadAllowlist();
  var leaks = 0;
  var allowed = 0;

  stdout.writeln('== i18n Türkçe-Sızıntı Tarama ==');
  stdout.writeln('Hedef diller: ${_targetLocales.join(", ")}');
  stdout.writeln('Allowlist: ${allow.length} girdi\n');

  for (final loc in _targetLocales) {
    final path = '$_l10nDir/app_$loc.arb';
    if (!File(path).existsSync()) {
      stderr.writeln('HATA: $path yok.');
      exit(2);
    }
    final map = _loadArb(path);
    final found = <String>[];
    map.forEach((key, value) {
      final reason = _turkishReason(value);
      if (reason == null) return;
      if (allow.contains('$loc:$key')) {
        allowed++;
        return;
      }
      found.add('  $loc:$key → "$value"  [$reason]');
    });
    stdout.writeln('--- $loc (${map.length} key) ---');
    if (found.isEmpty) {
      stdout.writeln('  ✓ sızıntı yok');
    } else {
      leaks += found.length;
      found.take(40).forEach(stdout.writeln);
      if (found.length > 40) stdout.writeln('  … +${found.length - 40} daha');
    }
    stdout.writeln('');
  }

  stdout.writeln('== Sonuç: $leaks sızıntı, $allowed allowlist ile geçildi ==');
  if (leaks > 0) {
    stderr.writeln('SIZINTI TARAMA BAŞARISIZ — Türkçe metin diğer dillerde.');
    exit(1);
  }
  stdout.writeln('SIZINTI YOK.');
}
