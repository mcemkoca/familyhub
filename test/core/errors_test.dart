import 'package:flutter_test/flutter_test.dart';
import 'package:familyhub/core/errors.dart';

void main() {
  group('Exception Classes', () {
    test('AppAuthException stores and returns message', () {
      final exception = AppAuthException('Auth failed');
      expect(exception.message, 'Auth failed');
      expect(exception.toString(), 'Auth failed');
    });

    test('NetworkException stores and returns message', () {
      final exception = NetworkException('No connection');
      expect(exception.message, 'No connection');
      expect(exception.toString(), 'No connection');
    });

    test('ValidationException stores and returns message', () {
      final exception = ValidationException('Invalid input');
      expect(exception.message, 'Invalid input');
      expect(exception.toString(), 'Invalid input');
    });

    test('AppDatabaseException stores and returns message', () {
      final exception = AppDatabaseException('DB error');
      expect(exception.message, 'DB error');
      expect(exception.toString(), 'DB error');
    });
  });

  group('friendlyErrorMessage', () {
    test('returns network message for socket errors', () {
      expect(
        friendlyErrorMessage('SocketException: Connection refused'),
        'İnternet bağlantınızı kontrol edin ve tekrar deneyin.',
      );
    });

    test('returns auth message for JWT errors', () {
      expect(
        friendlyErrorMessage('JWT expired'),
        'Oturum süreniz dolmuş olabilir. Lütfen tekrar giriş yapın.',
      );
    });

    test('returns RLS message for recursion errors', () {
      expect(
        friendlyErrorMessage('infinite recursion detected in RLS'),
        'Veritabanı güvenlik ayarları nedeniyle veriye erişilemiyor. Lütfen daha sonra tekrar deneyin.',
      );
    });

    test('returns family message for family_id errors', () {
      expect(
        friendlyErrorMessage('null value in column family_id'),
        'Aile bilginize ulaşılamıyor. Lütfen aile ayarlarından bir aile oluşturun veya davet kodu ile katılın.',
      );
    });

    test('returns generic message for unknown errors', () {
      expect(
        friendlyErrorMessage('Something weird happened'),
        'Bir şeyler yanlış gitti, lütfen tekrar deneyin.',
      );
    });

    test('returns generic message for null error', () {
      expect(
        friendlyErrorMessage(null),
        'Bir şeyler yanlış gitti, lütfen tekrar deneyin.',
      );
    });
  });
}
