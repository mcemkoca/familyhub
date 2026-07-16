import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/supabase_client.dart';
import '../core/utils/repository_mixin.dart';
import '../core/streak_calculator.dart';
import 'child_streak_repository.dart' show StreakStats;

/// Aile geneli streak — `tasks` tablosunda `family_id` altında tamamlanan
/// görevlerin tarihlerinden hesaplanır (çocuk streak ile aynı saf mantık).
/// Gerçek veri; sahte değer YOK (spec §25).
class FamilyStreakRepository with RepositoryErrorHandler {
  static final FamilyStreakRepository _instance =
      FamilyStreakRepository._internal();
  factory FamilyStreakRepository() => _instance;
  FamilyStreakRepository._internal();

  SupabaseClient? get _client => SupabaseConfig.safeClient;

  /// Ailenin streak istatistikleri. Bağlantı yoksa boş (0) istatistik döner.
  Future<StreakStats> getStreakStats(String familyId) async {
    final client = _client;
    if (client == null || familyId.isEmpty) {
      return const StreakStats(
        currentStreak: 0,
        bestStreak: 0,
        totalCompleted: 0,
        weeklyView: {},
        lastCompleted: null,
      );
    }
    try {
      final response = await client
          .from('tasks')
          .select('completed_at')
          .eq('family_id', familyId)
          .eq('status', 'completed')
          .order('completed_at', ascending: false);

      final raw = <DateTime>[];
      for (final row in (response as List)) {
        final ca = (row as Map)['completed_at'];
        if (ca is String && ca.isNotEmpty) {
          final d = DateTime.tryParse(ca);
          if (d != null) raw.add(d);
        }
      }
      final dates = normalizeDates(raw);
      return StreakStats(
        currentStreak: calculateCurrentStreak(dates),
        bestStreak: calculateBestStreak(dates),
        totalCompleted: dates.length,
        weeklyView: buildWeeklyView(dates),
        lastCompleted: dates.isNotEmpty ? dates.first : null,
      );
    } catch (e) {
      if (kDebugMode) debugPrint('FamilyStreakRepository error: $e');
      return const StreakStats(
        currentStreak: 0,
        bestStreak: 0,
        totalCompleted: 0,
        weeklyView: {},
        lastCompleted: null,
      );
    }
  }
}
