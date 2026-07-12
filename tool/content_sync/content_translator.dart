// Çeviri sağlayıcı soyutlaması + hash tabanlı çeviri belleği (translation memory).
// Gerçek API anahtarı SECRET'tan gelir; anahtar yoksa içerik "pending" kalır
// (sahte "çevrildi" iddiası YOK). Placeholder/URL/kurum adları korunur.

import 'dart:convert';
import 'package:crypto/crypto.dart';

/// Tek bir çeviri isteği.
class TranslationRequest {
  final String text;
  final String sourceLocale;
  final String targetLocale;
  final String? terminologyContext; // ör. "child_health"
  final String? countryContext; // ör. "BE"
  const TranslationRequest(
    this.text, {
    required this.sourceLocale,
    required this.targetLocale,
    this.terminologyContext,
    this.countryContext,
  });

  /// Aynı metin+dil çifti için stabil bellek anahtarı (yeniden çeviriyi önler).
  String get memoKey {
    final raw = '$sourceLocale>$targetLocale|$text';
    return sha256.convert(utf8.encode(raw)).toString();
  }
}

/// ICU placeholder ({name}), URL ve büyük harfli kısaltmaları korumak için
/// çeviri öncesi/sonrası doğrulama.
class TranslationGuards {
  static final _placeholder = RegExp(r'\{(\w+)\}');
  static Set<String> placeholders(String s) =>
      _placeholder.allMatches(s).map((m) => m.group(1)!).toSet();

  /// Çeviri, kaynak placeholder kümesini korumuş mu?
  static bool placeholdersPreserved(String source, String translated) =>
      placeholders(source).difference(placeholders(translated)).isEmpty;
}

abstract class TranslationProvider {
  /// Yapılandırılmış mı? (API anahtarı vb.)
  bool get isConfigured;

  /// Tek metin çevirir. Yapılandırılmamışsa TranslationUnavailable fırlatır.
  Future<String> translate(TranslationRequest req);
}

class TranslationUnavailable implements Exception {
  final String message;
  TranslationUnavailable(this.message);
  @override
  String toString() => 'TranslationUnavailable: $message';
}

/// Varsayılan sağlayıcı — API anahtarı yoksa devrede. HİÇBİR şey çevirmez;
/// içeriği pending bırakır. Böylece secret'sız ortamda yanlış çeviri üretilmez.
class PendingTranslationProvider implements TranslationProvider {
  @override
  bool get isConfigured => false;

  @override
  Future<String> translate(TranslationRequest req) async =>
      throw TranslationUnavailable(
          'Çeviri sağlayıcı yapılandırılmamış (ARB_TRANSLATE_API_KEY yok).');
}

/// Hash tabanlı çeviri belleği — aynı metni tekrar çevirmez.
class TranslationMemory {
  final Map<String, String> _memo;
  TranslationMemory([Map<String, String>? initial]) : _memo = {...?initial};

  String? get(TranslationRequest req) => _memo[req.memoKey];
  void put(TranslationRequest req, String translated) =>
      _memo[req.memoKey] = translated;

  Map<String, String> toJson() => Map.unmodifiable(_memo);
}
