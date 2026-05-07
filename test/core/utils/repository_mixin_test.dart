import 'package:flutter_test/flutter_test.dart';
import 'package:familyhub/core/utils/repository_mixin.dart';

void main() {
  group('RepositoryErrorHandler', () {
    test('handleRepositoryCall returns success result', () async {
      final handler = _TestRepository();
      final result = await handler.handleRepositoryCall(
        () async => 'success',
        'testOperation',
      );
      expect(result, equals('success'));
    });

    test('handleRepositoryCall throws RepositoryException on error', () async {
      final handler = _TestRepository();
      expect(
        () => handler.handleRepositoryCall(
          () async => throw Exception('test error'),
          'testOperation',
        ),
        throwsA(isA<RepositoryException>()),
      );
    });
  });
}

class _TestRepository with RepositoryErrorHandler {}
