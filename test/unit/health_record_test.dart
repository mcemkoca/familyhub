import 'package:flutter_test/flutter_test.dart';
import 'package:familyhub/domain/models/health_record.dart';

void main() {
  group('HealthRecord serialization', () {
    test('fromJson tüm alanları çözer', () {
      final r = HealthRecord.fromJson({
        'id': 'r1',
        'family_id': 'fam1',
        'member_id': 'child1',
        'member_type': 'child',
        'record_type': 'vaccine',
        'title': 'Grip aşısı',
        'description': 'Sezonluk',
        'doctor': 'Dr. X',
        'institution': 'AZ',
        'record_date': '2026-07-10',
        'privacy_level': 'family',
        'tags': ['aşı'],
      });
      expect(r.id, 'r1');
      expect(r.memberType, 'child');
      expect(r.recordType, 'vaccine');
      expect(r.title, 'Grip aşısı');
      expect(r.recordDate, DateTime(2026, 7, 10));
      expect(r.tags, ['aşı']);
    });

    test('eksik alanlar güvenli varsayılana düşer', () {
      final r = HealthRecord.fromJson({'title': 'X'});
      expect(r.memberType, 'adult');
      expect(r.recordType, 'note');
      expect(r.privacyLevel, 'family');
      expect(r.tags, isEmpty);
    });

    test('toInsert id/timestamp içermez, tarih yyyy-MM-dd', () {
      final r = HealthRecord(
        id: '',
        familyId: 'fam1',
        memberId: 'self',
        memberType: 'adult',
        recordType: 'exam',
        title: 'Kontrol',
        recordDate: DateTime(2026, 3, 5),
      );
      final ins = r.toInsert();
      expect(ins.containsKey('id'), isFalse);
      expect(ins.containsKey('created_at'), isFalse);
      expect(ins['record_date'], '2026-03-05');
      expect(ins['family_id'], 'fam1');
      // null alanlar (description vb.) map'e eklenmez
      expect(ins.containsKey('description'), isFalse);
    });
  });
}
