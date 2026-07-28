/// Context Memory — hassas kayıtlar için AES şifreleme (Faz 2 tamamlayıcı).
///
/// `evaluateStoragePolicy` bir kaydı `requiresEncryption` işaretlediğinde
/// içerik burada şifrelenir. Anahtar cihazda `flutter_secure_storage` içinde
/// tutulur; ASLA loglanmaz, ASLA sunucuya gönderilmez.
library;

import 'dart:convert';
import 'dart:math';

import 'package:encrypt/encrypt.dart' as enc;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../core/app_logger.dart';

/// Şifreli yük biçimi: `v1:<base64 iv>:<base64 ciphertext>`.
/// Sürüm öneki ileride algoritma değişimini mümkün kılar.
const String memoryCryptoVersion = 'v1';

/// Şifreli yükün biçimsel geçerliliği (saf — test edilebilir).
bool isEncryptedPayload(String? value) {
  if (value == null || value.isEmpty) return false;
  final parts = value.split(':');
  return parts.length == 3 && parts[0] == memoryCryptoVersion;
}

/// Yükten sürüm çıkarır; geçersizse null.
String? cryptoVersionOf(String? value) {
  if (!isEncryptedPayload(value)) return null;
  return value!.split(':').first;
}

/// Hassas memory içeriğini şifreler/çözer.
class MemoryCrypto {
  MemoryCrypto._();
  static final MemoryCrypto instance = MemoryCrypto._();

  static const _storage = FlutterSecureStorage();
  static const _keyName = 'context_memory_aes_key_v1';

  enc.Encrypter? _encrypter;

  /// Cihaza özel anahtarı yükler; yoksa üretip güvenli depoya yazar.
  Future<enc.Encrypter> _ensureKey() async {
    final cached = _encrypter;
    if (cached != null) return cached;

    var base64Key = await _storage.read(key: _keyName);
    if (base64Key == null || base64Key.isEmpty) {
      final rnd = Random.secure();
      final bytes = List<int>.generate(32, (_) => rnd.nextInt(256));
      base64Key = base64Encode(bytes);
      await _storage.write(key: _keyName, value: base64Key);
    }

    final key = enc.Key.fromBase64(base64Key);
    final e = enc.Encrypter(enc.AES(key, mode: enc.AESMode.cbc));
    _encrypter = e;
    return e;
  }

  /// Düz metni şifreler. Hata olursa null döner — çağıran ASLA düz metni
  /// hassas alana yazmamalıdır (kaydı reddetmelidir).
  Future<String?> encrypt(String plainText) async {
    try {
      final encrypter = await _ensureKey();
      final iv = enc.IV.fromSecureRandom(16);
      final encrypted = encrypter.encrypt(plainText, iv: iv);
      return '$memoryCryptoVersion:${iv.base64}:${encrypted.base64}';
    } catch (e) {
      // İçerik loglanmaz — yalnızca işlem adı.
      AppLogger.logError(e, module: 'memory', operation: 'encrypt');
      return null;
    }
  }

  /// Şifreli yükü çözer. Biçim bozuksa veya anahtar uyuşmazsa null.
  Future<String?> decrypt(String payload) async {
    if (!isEncryptedPayload(payload)) return null;
    try {
      final parts = payload.split(':');
      final encrypter = await _ensureKey();
      return encrypter.decrypt64(parts[2], iv: enc.IV.fromBase64(parts[1]));
    } catch (e) {
      AppLogger.logBestEffort(e, module: 'memory', operation: 'decrypt');
      return null;
    }
  }

  /// Hesap silme / güvenlik sıfırlama: anahtarı yok eder.
  /// Anahtar gidince eski şifreli kayıtlar çözülemez (amaçlanan davranış).
  Future<void> destroyKey() async {
    _encrypter = null;
    await _storage.delete(key: _keyName);
  }
}
