import 'package:flutter_test/flutter_test.dart';
import 'package:familyhub/core/app_logger.dart';

/// FH-03 güvenlik-kritik: log'a hassas veri SIZMAMALI.
void main() {
  group('AppLogger.sanitize — sır maskeleme', () {
    test('JWT benzeri token maskelenir', () {
      final out = AppLogger.sanitize(
          'Auth failed: eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9abcdef');
      expect(out, contains('<redacted>'));
      expect(out.contains('eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9abcdef'), isFalse);
    });

    test('OpenAI (sk-) ve Google (AIza) anahtarları maskelenir', () {
      expect(AppLogger.sanitize('key sk-abcdefghij1234567890'),
          contains('<redacted>'));
      expect(AppLogger.sanitize('key AIzaSyABCDEFGHIJ1234567890'),
          contains('<redacted>'));
    });

    test('key=value biçimindeki şifre/token maskelenir', () {
      final out = AppLogger.sanitize('password=Gizli123, user=ali');
      expect(out.contains('Gizli123'), isFalse);
      expect(out, contains('<redacted>'));
      // Hassas olmayan alan korunur
      expect(out, contains('ali'));
    });

    test('GPS koordinatı maskelenir', () {
      final out = AppLogger.sanitize('lat=50.8503, lng=4.3517');
      expect(out.contains('50.8503'), isFalse);
      expect(out.contains('4.3517'), isFalse);
    });

    test('zararsız metin bozulmaz', () {
      expect(AppLogger.sanitize('Kayıt oluşturulamadı'), 'Kayıt oluşturulamadı');
    });
  });

  group('AppLogger.safeContext — metadata maskeleme', () {
    test('hassas anahtarlar <redacted>, güvenli olanlar kalır', () {
      final ctx = AppLogger.safeContext({
        'module': 'health',
        'access_token': 'eyJabc123456789012',
        'latitude': 50.8503,
        'recordId': 'r-123',
        'diagnosis': 'gizli tıbbi bilgi',
      });
      expect(ctx['module'], 'health');
      expect(ctx['recordId'], 'r-123');
      expect(ctx['access_token'], '<redacted>');
      expect(ctx['latitude'], '<redacted>');
      expect(ctx['diagnosis'], '<redacted>');
    });

    test('null context boş map döner', () {
      expect(AppLogger.safeContext(null), isEmpty);
    });
  });
}
