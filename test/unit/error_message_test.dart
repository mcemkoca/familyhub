import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:familyhub/core/errors.dart';

void main() {
  group('friendlyErrorMessage', () {
    test('returns database fetch message for PostgrestException', () {
      final msg = friendlyErrorMessage('PostgrestException');
      expect(msg, contains('Veritabanından veri alınırken'));
    });

    test('returns family setup message for family_id errors', () {
      final msg = friendlyErrorMessage('null value in column "family_id"');
      expect(msg, contains('Aile bilginize ulaşılamıyor'));
    });

    test('returns connection message for SocketException', () {
      final msg = friendlyErrorMessage(const SocketException('connection refused'));
      expect(msg, contains('İnternet bağlantınızı'));
    });

    test('returns auth message for jwt errors', () {
      final msg = friendlyErrorMessage('jwt expired');
      expect(msg, contains('Oturum süreniz'));
    });

    test('returns generic message for unknown errors', () {
      final msg = friendlyErrorMessage('something weird');
      expect(msg, contains('Bir şeyler yanlış gitti'));
    });
  });
}
