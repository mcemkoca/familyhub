import 'package:flutter_test/flutter_test.dart';
import 'package:familyhub/services/deep_link_service.dart';

void main() {
  group('DeepLinkService.extractInviteCode', () {
    String? code(String url) =>
        DeepLinkService.extractInviteCode(Uri.parse(url));

    test('path biçimi /invite/XXXX kodu çıkarır', () {
      expect(code('https://familyhub.app/invite/ABC123'), 'ABC123');
    });

    test('query ?code= kodu çıkarır', () {
      expect(code('https://familyhub.app/join?code=xyz789'), 'XYZ789');
    });

    test('query ?invite= kodu çıkarır', () {
      expect(code('https://familyhub.app/anything?invite=Qw12'), 'QW12');
    });

    test('özel şema com.familyhub.app://join?code= çalışır', () {
      expect(code('com.familyhub.app://join?code=deep99'), 'DEEP99');
    });

    test('kodu her zaman büyük harfe çevirir', () {
      expect(code('https://familyhub.app/invite/abcdef'), 'ABCDEF');
    });

    test('kod yoksa null döner', () {
      expect(code('https://familyhub.app/tasks'), isNull);
      expect(code('https://familyhub.app/settings'), isNull);
    });

    test('boş kod null döner', () {
      expect(code('https://familyhub.app/invite/'), isNull);
      expect(code('https://familyhub.app/join?code='), isNull);
    });
  });
}
