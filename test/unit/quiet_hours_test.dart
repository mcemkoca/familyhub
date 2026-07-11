import 'package:flutter_test/flutter_test.dart';
import 'package:familyhub/features/family_intelligence/application/quiet_hours.dart';

void main() {
  group('QuietHours', () {
    test('gece yarısını geçen aralık (22:00–08:00)', () {
      const q = QuietHours(startHour: 22, endHour: 8);
      expect(q.isQuietHour(23), true);
      expect(q.isQuietHour(2), true);
      expect(q.isQuietHour(7), true);
      expect(q.isQuietHour(8), false); // end hariç
      expect(q.isQuietHour(12), false);
      expect(q.isQuietHour(21), false);
      expect(q.isQuietHour(22), true); // start dahil
    });

    test('aynı gün içi aralık (13:00–15:00)', () {
      const q = QuietHours(startHour: 13, endHour: 15);
      expect(q.isQuietHour(12), false);
      expect(q.isQuietHour(13), true);
      expect(q.isQuietHour(14), true);
      expect(q.isQuietHour(15), false);
    });

    test('start == end → aralık yok', () {
      const q = QuietHours(startHour: 9, endHour: 9);
      expect(q.isQuietHour(9), false);
      expect(q.isQuietHour(0), false);
    });

    test('isQuietNow verilen zamanı kullanır', () {
      const q = QuietHours(startHour: 22, endHour: 8);
      expect(q.isQuietNow(DateTime(2026, 7, 11, 23, 30)), true);
      expect(q.isQuietNow(DateTime(2026, 7, 11, 10, 0)), false);
    });
  });
}
