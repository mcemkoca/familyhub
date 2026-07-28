import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart' show PlatformException;
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:familyhub/services/auth/auth_error_mapper.dart';

void main() {
  group('classifyAuthError', () {
    test('AuthRetryableFetchException → serverUnavailable (retryable)', () {
      final f = classifyAuthError(AuthRetryableFetchException(message: 'x'));
      expect(f.kind, AuthFailureKind.serverUnavailable);
      expect(isRetryableKind(f.kind), isTrue);
    });

    test('400 AuthApiException → invalidCredentials (not retryable)', () {
      final f = classifyAuthError(
        AuthApiException('Invalid login credentials', statusCode: '400'),
      );
      expect(f.kind, AuthFailureKind.invalidCredentials);
      expect(isRetryableKind(f.kind), isFalse);
    });

    test('email not confirmed → emailNotConfirmed', () {
      final f = classifyAuthError(
        AuthApiException('Email not confirmed', statusCode: '400'),
      );
      expect(f.kind, AuthFailureKind.emailNotConfirmed);
    });

    test('429 → rateLimited (not retryable)', () {
      final f = classifyAuthError(
        AuthApiException('too many', statusCode: '429'),
      );
      expect(f.kind, AuthFailureKind.rateLimited);
      expect(isRetryableKind(f.kind), isFalse);
    });

    test('5xx AuthApiException → serverUnavailable (retryable)', () {
      final f = classifyAuthError(AuthApiException('boom', statusCode: '503'));
      expect(f.kind, AuthFailureKind.serverUnavailable);
      expect(isRetryableKind(f.kind), isTrue);
    });

    test('SocketException → offline (retryable)', () {
      final f = classifyAuthError(const SocketException('no net'));
      expect(f.kind, AuthFailureKind.offline);
      expect(isRetryableKind(f.kind), isTrue);
    });

    test('HandshakeException → serverUnavailable (retryable)', () {
      final f = classifyAuthError(const HandshakeException('tls'));
      expect(f.kind, AuthFailureKind.serverUnavailable);
      expect(isRetryableKind(f.kind), isTrue);
    });

    test('TimeoutException → serverUnavailable (retryable)', () {
      final f = classifyAuthError(TimeoutException('slow'));
      expect(f.kind, AuthFailureKind.serverUnavailable);
    });

    test(
      'Google DEVELOPER_ERROR (10) → configurationError (NOT retryable)',
      () {
        final f = classifyAuthError(PlatformException(code: '10'));
        expect(f.kind, AuthFailureKind.configurationError);
        expect(isRetryableKind(f.kind), isFalse);
      },
    );

    test('Google cancellation (12501) → cancelled, empty message', () {
      final f = classifyAuthError(PlatformException(code: 'sign_in_canceled'));
      expect(f.kind, AuthFailureKind.cancelled);
      expect(f.isCancellation, isTrue);
      expect(f.userMessage, isEmpty);
    });

    test('Google network_error (7) → offline (retryable)', () {
      final f = classifyAuthError(PlatformException(code: '7'));
      expect(f.kind, AuthFailureKind.offline);
      expect(isRetryableKind(f.kind), isTrue);
    });

    test('already-classified AuthFailure passes through', () {
      const original = AuthFailure(AuthFailureKind.rateLimited, 'x');
      expect(identical(classifyAuthError(original), original), isTrue);
    });
  });

  group('retryAuth', () {
    test('valid first attempt returns immediately (no retry)', () async {
      var calls = 0;
      final r = await retryAuth(() async {
        calls++;
        return 'ok';
      }, sleep: (_) async {});
      expect(r, 'ok');
      expect(calls, 1);
    });

    test('transient error then success on retry', () async {
      var calls = 0;
      final r = await retryAuth(() async {
        calls++;
        if (calls == 1) throw const SocketException('down');
        return 'ok';
      }, sleep: (_) async {});
      expect(r, 'ok');
      expect(calls, 2);
    });

    test(
      'persistent transient error → fails after 2 retries (3 calls)',
      () async {
        var calls = 0;
        await expectLater(
          retryAuth(() async {
            calls++;
            throw const SocketException('down');
          }, sleep: (_) async {}),
          throwsA(
            isA<AuthFailure>().having(
              (e) => e.kind,
              'kind',
              AuthFailureKind.offline,
            ),
          ),
        );
        expect(calls, 3); // 1 ilk + 2 retry
      },
    );

    test('non-retryable 4xx auth error is NOT retried', () async {
      var calls = 0;
      await expectLater(
        retryAuth(() async {
          calls++;
          throw AuthApiException(
            'Invalid login credentials',
            statusCode: '400',
          );
        }, sleep: (_) async {}),
        throwsA(
          isA<AuthFailure>().having(
            (e) => e.kind,
            'kind',
            AuthFailureKind.invalidCredentials,
          ),
        ),
      );
      expect(calls, 1);
    });

    test('Google cancellation is NOT retried', () async {
      var calls = 0;
      await expectLater(
        retryAuth(() async {
          calls++;
          throw PlatformException(code: 'sign_in_canceled');
        }, sleep: (_) async {}),
        throwsA(
          isA<AuthFailure>().having(
            (e) => e.isCancellation,
            'isCancellation',
            isTrue,
          ),
        ),
      );
      expect(calls, 1);
    });
  });
}
