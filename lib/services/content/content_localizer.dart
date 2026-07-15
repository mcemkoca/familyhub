/// İçerik JSON'u aktif dile göre normalize eder.
///
/// Kullanıcı içerik dosyalarını çok-dilli hale getirdi:
///   "title": {"tr":"...","nl":"...","fr":"...","en":"..."}
///   "category": {"key":"okul_oncesi","label":{"tr":"...",...}}
///
/// Eski ekran/servis kodu bu alanları düz String bekliyor. Bu normalize
/// fonksiyonu, `jsonDecode` sonrası ham veriyi gezerek:
///   1) Yalnızca dil-kodu anahtarları içeren map → aktif dildeki metin (fallback
///      dil → en → tr → ilk değer).
///   2) {key, label} objesi → `key` (filtre/karşılaştırma semantiği korunur).
///   3) Diğer map/list → özyinelemeli.
/// Böylece ekran kodu DEĞİŞMEDEN çok-dilli içerik doğru dilde görünür.
library;

const _langCodes = {'tr', 'nl', 'fr', 'en', 'de'};

/// [value]'yu [lang] diline göre normalize eder.
dynamic normalizeContent(dynamic value, String lang) {
  if (value is Map) {
    final keys = value.keys.map((k) => k.toString()).toSet();

    // 1) Saf dil-map'i → aktif dildeki metin.
    if (keys.isNotEmpty && keys.every(_langCodes.contains)) {
      return _pickLang(value, lang);
    }

    // 2) {key, label} objesi → key (string). label çevirisi başka yerde
    //    (kategori etiketleri) zaten var; item'daki category bir filtre anahtarı.
    if (keys.contains('key') && keys.contains('label') && keys.length <= 3) {
      return value['key'];
    }

    // 3) Diğer map → değerleri özyinelemeli normalize et.
    final out = <String, dynamic>{};
    value.forEach((k, v) => out[k.toString()] = normalizeContent(v, lang));
    return out;
  }

  if (value is List) {
    return value.map((e) => normalizeContent(e, lang)).toList();
  }

  return value;
}

String _pickLang(Map<dynamic, dynamic> value, String lang) {
  for (final code in [lang, 'en', 'tr']) {
    final v = value[code];
    if (v is String && v.isNotEmpty) return v;
  }
  final first = value.values.firstWhere(
    (v) => v is String && v.isNotEmpty,
    orElse: () => '',
  );
  return first as String;
}

/// Liste tipi içerik için kısayol: her elemanı normalize eder.
List<Map<String, dynamic>> normalizeContentList(
  List<dynamic> raw,
  String lang,
) {
  return raw
      .map((e) => normalizeContent(e, lang))
      .whereType<Map<String, dynamic>>()
      .toList();
}
