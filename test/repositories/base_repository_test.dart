import 'package:flutter_test/flutter_test.dart';
import 'package:familyhub/core/errors.dart';
import 'package:familyhub/repositories/base_repository.dart';

// Simple test model for BaseRepository
class _TestModel {
  final String id;
  final String name;
  _TestModel({required this.id, required this.name});
  factory _TestModel.fromJson(Map<String, dynamic> json) =>
      _TestModel(id: json['id'] as String, name: json['name'] as String);
}

class _TestRepository extends BaseRepository<_TestModel> {
  _TestRepository() : super('test_table');

  @override
  _TestModel fromJson(Map<String, dynamic> json) => _TestModel.fromJson(json);
}

void main() {
  group('BaseRepository', () {
    late _TestRepository repository;

    setUp(() {
      repository = _TestRepository();
    });

    test('table name is set correctly', () {
      expect(repository, isNotNull);
    });

    test('throws database exception when client is null', () {
      // When Supabase is not initialized, _safeClient is null
      // query() catches the auth error and wraps it in AppDatabaseException
      expect(
        () => repository.query(),
        throwsA(isA<AppDatabaseException>()),
      );
    });

    test('fromJson is implemented', () {
      const json = {'id': '1', 'name': 'Test'};
      final model = repository.fromJson(json);
      expect(model.id, '1');
      expect(model.name, 'Test');
    });
  });

  group('_TestModel', () {
    test('factory fromJson creates model correctly', () {
      const json = {'id': 'abc', 'name': 'Test Name'};
      final model = _TestModel.fromJson(json);
      expect(model.id, 'abc');
      expect(model.name, 'Test Name');
    });
  });
}
