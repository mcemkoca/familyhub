import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:familyhub/services/google_drive_service.dart';

void main() {
  group('GoogleDriveService.classifyError', () {
    test('iptal → cancelled', () {
      expect(GoogleDriveService.classifyError(const GoogleSignInCancelled()),
          GoogleAuthError.cancelled);
      expect(
          GoogleDriveService.classifyError(
              PlatformException(code: 'sign_in_canceled')),
          GoogleAuthError.cancelled);
    });

    test('yapılandırma hatası (sign_in_failed = DEVELOPER_ERROR)', () {
      expect(
          GoogleDriveService.classifyError(
              PlatformException(code: 'sign_in_failed')),
          GoogleAuthError.configuration);
    });

    test('ağ hatası', () {
      expect(
          GoogleDriveService.classifyError(
              PlatformException(code: 'network_error')),
          GoogleAuthError.network);
      expect(GoogleDriveService.classifyError(Exception('network unreachable')),
          GoogleAuthError.network);
    });

    test('bilinmeyen → unknown', () {
      expect(GoogleDriveService.classifyError(Exception('weird')),
          GoogleAuthError.unknown);
    });
  });
}
