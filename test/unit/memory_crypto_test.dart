import 'package:flutter_test/flutter_test.dart';
import 'package:familyhub/features/context_memory/infrastructure/memory_crypto.dart';

/// Context Memory — şifreli yük biçimi (saf fonksiyonlar).
///
/// Not: gerçek şifreleme flutter_secure_storage (platform kanalı) gerektirir,
/// bu yüzden burada biçim/sürüm doğrulaması test edilir; uçtan uca şifreleme
/// cihaz testinde doğrulanmalıdır.
void main() {
  group('isEncryptedPayload', () {
    test('geçerli v1 yükü tanınır', () {
      expect(isEncryptedPayload('v1:aXZiYXNlNjQ=:Y2lwaGVy'), isTrue);
    });

    test('düz metin şifreli sayılmaz', () {
      expect(isEncryptedPayload('mantar sevmiyor'), isFalse);
    });

    test('boş/null şifreli sayılmaz', () {
      expect(isEncryptedPayload(null), isFalse);
      expect(isEncryptedPayload(''), isFalse);
    });

    test('eksik parça şifreli sayılmaz', () {
      expect(isEncryptedPayload('v1:onlyone'), isFalse);
    });

    test('bilinmeyen sürüm reddedilir (ileri uyumluluk koruması)', () {
      expect(isEncryptedPayload('v99:iv:data'), isFalse);
    });

    test('iki nokta içeren düz metin yanlışlıkla şifreli sayılmaz', () {
      expect(isEncryptedPayload('saat 12:30:00'), isFalse);
    });
  });

  group('cryptoVersionOf', () {
    test('geçerli yükten sürüm çıkarılır', () {
      expect(cryptoVersionOf('v1:iv:data'), 'v1');
    });

    test('geçersiz yükte null', () {
      expect(cryptoVersionOf('düz metin'), isNull);
    });
  });

  group('sürüm sabiti', () {
    test('mevcut sürüm v1', () {
      expect(memoryCryptoVersion, 'v1');
    });
  });
}
