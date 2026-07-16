import 'package:flutter_test/flutter_test.dart';
import 'package:familyhub/core/streak_calculator.dart';

void main() {
  final today = DateTime(2026, 7, 17);
  DateTime d(int day) => DateTime(2026, 7, day);

  group('calculateCurrentStreak', () {
    test('boş liste → 0', () {
      expect(calculateCurrentStreak(const [], today: today), 0);
    });

    test('bugün + dün + evvelsi gün kesintisiz → 3', () {
      final dates = normalizeDates([d(17), d(16), d(15)]);
      expect(calculateCurrentStreak(dates, today: today), 3);
    });

    test('dünden başlayan seri (bugün yok) sayılır', () {
      final dates = normalizeDates([d(16), d(15)]);
      expect(calculateCurrentStreak(dates, today: today), 2);
    });

    test('tek günlük boşluğa toleranslı (mevcut davranış)', () {
      // 16 eksik ama algoritma tek-gün boşluğu tolere eder → seri devam.
      final dates = normalizeDates([d(17), d(15), d(14)]);
      expect(calculateCurrentStreak(dates, today: today), 3);
    });

    test('iki günlük boşluk seriyi keser', () {
      final dates = normalizeDates([d(17), d(14), d(13)]); // 16,15 eksik
      expect(calculateCurrentStreak(dates, today: today), 1);
    });

    test('çok eski tarih → 0', () {
      final dates = normalizeDates([d(10)]);
      expect(calculateCurrentStreak(dates, today: today), 0);
    });

    test('aynı gün tekrarı seriyi şişirmez', () {
      final dates = normalizeDates([d(17), d(17), d(16)]);
      expect(calculateCurrentStreak(dates, today: today), 2);
    });
  });

  group('calculateBestStreak', () {
    test('en uzun kesintisiz dizi', () {
      // 1,2,3 (3) ... 10,11 (2) → en uzun 3
      final dates = [d(1), d(2), d(3), d(10), d(11)];
      expect(calculateBestStreak(dates), 3);
    });

    test('tek gün → 1', () {
      expect(calculateBestStreak([d(5)]), 1);
    });

    test('boş → 0', () {
      expect(calculateBestStreak(const []), 0);
    });
  });

  group('buildWeeklyView', () {
    test('7 gün anahtarı döner (1..7)', () {
      final v = buildWeeklyView([d(17)], today: today);
      expect(v.keys.toSet(), {1, 2, 3, 4, 5, 6, 7});
    });
  });

  group('normalizeDates', () {
    test('saat sıfırlanır, benzersizleşir, yeni→eski sıralanır', () {
      final out = normalizeDates([
        DateTime(2026, 7, 15, 9),
        DateTime(2026, 7, 17, 23),
        DateTime(2026, 7, 17, 1),
      ]);
      expect(out, [d(17), d(15)]);
    });
  });
}
