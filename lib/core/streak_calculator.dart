/// Tamamlanma tarihlerinden streak (seri) hesaplayan saf fonksiyonlar.
///
/// Hem çocuk (ChildStreakRepository) hem aile (FamilyStreakRepository) streak'i
/// aynı mantığı kullanır — tek kaynak, test edilebilir.
library;

/// Verilen tarih listesini (yalnızca gün) normalize eder: saat sıfırlanır,
/// benzersizleştirilir, en yeni → en eski sıralanır.
List<DateTime> normalizeDates(Iterable<DateTime> raw) {
  final set = <DateTime>{};
  for (final d in raw) {
    set.add(DateTime(d.year, d.month, d.day));
  }
  final list = set.toList()..sort((a, b) => b.compareTo(a)); // yeni → eski
  return list;
}

/// Güncel seri: bugün veya dün ile başlayıp geriye doğru kesintisiz gün sayısı.
/// [today] test için enjekte edilebilir (varsayılan: bugün).
int calculateCurrentStreak(List<DateTime> datesDescending, {DateTime? today}) {
  if (datesDescending.isEmpty) return 0;
  final now = today ?? DateTime.now();
  final todayDate = DateTime(now.year, now.month, now.day);

  int streak = 0;
  DateTime expected = todayDate;

  for (final date in datesDescending) {
    if (date == expected ||
        date == expected.subtract(const Duration(days: 1))) {
      streak++;
      expected = date.subtract(const Duration(days: 1));
    } else if (date.isBefore(expected.subtract(const Duration(days: 1)))) {
      break;
    }
  }
  return streak;
}

/// En uzun seri: herhangi bir kesintisiz gün dizisinin en büyüğü.
int calculateBestStreak(List<DateTime> dates) {
  if (dates.isEmpty) return 0;
  final sorted = [...dates]..sort((a, b) => a.compareTo(b)); // eski → yeni

  int best = 0;
  int current = 1;
  for (int i = 1; i < sorted.length; i++) {
    final diff = sorted[i].difference(sorted[i - 1]).inDays;
    if (diff == 1) {
      current++;
    } else if (diff > 1) {
      if (current > best) best = current;
      current = 1;
    }
    // diff == 0 (aynı gün) → yoksay
  }
  return current > best ? current : best;
}

/// Bu haftanın (Pzt–Paz) her günü için tamamlanma var mı? (1=Pzt … 7=Paz)
Map<int, bool> buildWeeklyView(List<DateTime> dates, {DateTime? today}) {
  final now = today ?? DateTime.now();
  final monday = now.subtract(Duration(days: now.weekday - 1));
  final result = <int, bool>{};
  for (int i = 0; i < 7; i++) {
    final day = DateTime(monday.year, monday.month, monday.day + i);
    result[day.weekday] = dates.any(
        (d) => d.year == day.year && d.month == day.month && d.day == day.day);
  }
  return result;
}
