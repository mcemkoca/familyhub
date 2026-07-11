import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';

/// PIN'ler için salt'lı + iterasyonlu KDF ve sabit-zamanlı karşılaştırma.
///
/// Neden: Düz SHA-256 saltsızdır; 4-6 haneli PIN'lerde tüm uzay (10k–1M)
/// önceden hesaplanabilir ve aynı PIN aynı hash'i üretir. Salt + iterasyon
/// bunu engeller; sabit-zamanlı karşılaştırma zamanlama sızıntısını kapatır.
///
/// Kodlanmış format (geri-uyumluluk için sürümlü):
///   `v2$<iterations>$<saltBase64>$<hashBase64>`
/// Eski kayıtlar 64 karakterlik ham hex SHA-256 olarak tanınır (isLegacy).
class PinHasher {
  const PinHasher._();

  static const _version = 'v2';
  static const defaultIterations = 12000;

  /// [pin]'i hashler. [salt] verilmezse güvenli rastgele 16 bayt üretir.
  static String hash(
    String pin, {
    List<int>? salt,
    int iterations = defaultIterations,
  }) {
    final s = salt ?? _randomSalt(16);
    final digest = _derive(pin, s, iterations);
    return '$_version\$$iterations\$${base64.encode(s)}\$${base64.encode(digest)}';
  }

  /// [pin]'in [encoded] ile eşleşip eşleşmediğini sabit-zamanlı doğrular.
  /// Eski (saltsız hex) formatı da doğrular — çağıran isLegacyFormat ile
  /// tespit edip başarılı doğrulamada yeni formata yeniden yazmalıdır.
  static bool verify(String pin, String encoded) {
    if (isLegacyFormat(encoded)) {
      final legacy = sha256.convert(utf8.encode(pin)).toString();
      return _constantTimeEquals(
          utf8.encode(legacy), utf8.encode(encoded.toLowerCase()));
    }
    final parts = encoded.split(r'$');
    if (parts.length != 4 || parts[0] != _version) return false;
    final iterations = int.tryParse(parts[1]);
    if (iterations == null || iterations <= 0) return false;
    final List<int> salt;
    final List<int> expected;
    try {
      salt = base64.decode(parts[2]);
      expected = base64.decode(parts[3]);
    } catch (_) {
      return false;
    }
    final actual = _derive(pin, salt, iterations);
    return _constantTimeEquals(actual, expected);
  }

  /// Eski saltsız SHA-256 hex (64 karakter, yalnızca hex) mi?
  static bool isLegacyFormat(String encoded) =>
      encoded.length == 64 && RegExp(r'^[0-9a-fA-F]{64}$').hasMatch(encoded);

  /// Salt'lı iterasyonlu türetme: h₀=sha256(salt|pin), hₙ=sha256(hₙ₋₁|salt).
  static List<int> _derive(String pin, List<int> salt, int iterations) {
    var current = sha256.convert([...salt, ...utf8.encode(pin)]).bytes;
    for (var i = 1; i < iterations; i++) {
      current = sha256.convert([...current, ...salt]).bytes;
    }
    return current;
  }

  static List<int> _randomSalt(int length) {
    final rng = Random.secure();
    return List<int>.generate(length, (_) => rng.nextInt(256));
  }

  /// Uzunluk + içerik farkını erken çıkışsız karşılaştırır (timing-safe).
  static bool _constantTimeEquals(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    var diff = 0;
    for (var i = 0; i < a.length; i++) {
      diff |= a[i] ^ b[i];
    }
    return diff == 0;
  }
}
