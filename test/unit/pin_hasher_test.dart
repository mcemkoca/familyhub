import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:familyhub/features/security/domain/pin_hasher.dart';

void main() {
  group('PinHasher', () {
    test('doğru PIN doğrulanır, yanlış PIN reddedilir', () {
      final h = PinHasher.hash('1234');
      expect(PinHasher.verify('1234', h), isTrue);
      expect(PinHasher.verify('1235', h), isFalse);
      expect(PinHasher.verify('', h), isFalse);
    });

    test('düz metin PIN saklanmaz, format sürümlü + salt içerir', () {
      final h = PinHasher.hash('4242');
      expect(h.startsWith('v2\$'), isTrue);
      expect(h.contains('4242'), isFalse);
      expect(h.split(r'$').length, 4);
    });

    test('aynı PIN farklı salt → farklı hash (rainbow/precompute engeli)', () {
      final a = PinHasher.hash('0000');
      final b = PinHasher.hash('0000');
      expect(a, isNot(equals(b)));
      // Yine de ikisi de doğrulanır
      expect(PinHasher.verify('0000', a), isTrue);
      expect(PinHasher.verify('0000', b), isTrue);
    });

    test('sabit salt ile deterministik (test edilebilirlik)', () {
      final salt = List<int>.filled(16, 7);
      final a = PinHasher.hash('9999', salt: salt, iterations: 100);
      final b = PinHasher.hash('9999', salt: salt, iterations: 100);
      expect(a, equals(b));
    });

    test('bozuk/eksik format güvenle reddedilir', () {
      expect(PinHasher.verify('1234', 'v2\$abc'), isFalse);
      expect(PinHasher.verify('1234', 'v2\$0\$\$'), isFalse);
      expect(PinHasher.verify('1234', 'v9\$100\$AAAA\$BBBB'), isFalse);
      expect(PinHasher.verify('1234', ''), isFalse);
    });

    group('legacy (saltsız SHA-256) geriye uyum', () {
      String legacy(String pin) => sha256.convert(utf8.encode(pin)).toString();

      test('legacy format tespit edilir', () {
        expect(PinHasher.isLegacyFormat(legacy('1234')), isTrue);
        expect(PinHasher.isLegacyFormat(PinHasher.hash('1234')), isFalse);
      });

      test('legacy hash doğru PIN ile doğrulanır', () {
        final old = legacy('7777');
        expect(PinHasher.verify('7777', old), isTrue);
        expect(PinHasher.verify('0000', old), isFalse);
      });
    });
  });
}
