import 'dart:convert';
import 'package:flutter/material.dart';
import '../../../services/hive_service.dart';

/// Sağlık bölümü için yerel veri deposu (ruh hali, günlük metrikler, döngü,
/// semptomlar, çocuk büyüme) + günlük öneri havuzu.
class HealthStore {
  static String _dayKey(String prefix) {
    final n = DateTime.now();
    return '${prefix}_${n.year}${n.month.toString().padLeft(2, '0')}${n.day.toString().padLeft(2, '0')}';
  }

  // ── Günlük ruh hali (0-4) ────────────────────────────────────────────────
  static int? todayMood() {
    final v = HiveService.getSetting(_dayKey('health_mood'));
    return v == null ? null : int.tryParse(v);
  }

  static Future<void> setMood(int index) =>
      HiveService.setSetting(_dayKey('health_mood'), '$index');

  // ── Günlük metrikler (adım/su/uyku/stres) ────────────────────────────────
  static double metric(String key, double fallback) {
    return HiveService.getDoubleSetting('health_${_dayKey(key)}') ?? fallback;
  }

  static Future<void> setMetric(String key, double value) =>
      HiveService.setDoubleSetting('health_${_dayKey(key)}', value);

  // ── Döngü takibi ─────────────────────────────────────────────────────────
  static const int cycleLength = 28;
  static const int periodLength = 5;

  static DateTime cycleStart() {
    final raw = HiveService.getSetting('health_cycle_start');
    if (raw != null) {
      final d = DateTime.tryParse(raw);
      if (d != null) return d;
    }
    // Varsayılan: bu ayın başından bir döngü.
    final now = DateTime.now();
    return DateTime(now.year, now.month, 1);
  }

  static Future<void> setCycleStart(DateTime d) =>
      HiveService.setSetting('health_cycle_start', d.toIso8601String());

  /// Bugün döngünün kaçıncı günü (1..cycleLength).
  static int cycleDay() {
    final start = cycleStart();
    final today = DateTime.now();
    final diff = DateTime(today.year, today.month, today.day)
        .difference(DateTime(start.year, start.month, start.day))
        .inDays;
    return (diff % cycleLength) + 1;
  }

  // ── Semptomlar (bugün) ───────────────────────────────────────────────────
  static Set<String> symptomsToday() {
    final raw = HiveService.getSetting(_dayKey('health_sym'));
    if (raw == null || raw.isEmpty) return {};
    try {
      return (jsonDecode(raw) as List).map((e) => e.toString()).toSet();
    } catch (_) {
      return {};
    }
  }

  static Future<void> toggleSymptom(String key) async {
    final s = symptomsToday();
    if (!s.add(key)) s.remove(key);
    await HiveService.setSetting(_dayKey('health_sym'), jsonEncode(s.toList()));
  }

  // ── Çocuk büyüme (boy/kilo) ──────────────────────────────────────────────
  static ({double height, double weight}) childGrowth(String childId) {
    final h = HiveService.getDoubleSetting('health_h_$childId') ?? 102;
    final w = HiveService.getDoubleSetting('health_w_$childId') ?? 16.2;
    return (height: h, weight: w);
  }

  static Future<void> setChildGrowth(
      String childId, double height, double weight) async {
    await HiveService.setDoubleSetting('health_h_$childId', height);
    await HiveService.setDoubleSetting('health_w_$childId', weight);
  }

  // ── Günlük öneri havuzu (dönüşümlü) ──────────────────────────────────────
  static const _tips = [
    'Günde en az 8 bardak su içmeyi unutma! 💧 Küçük adımlar, büyük fark yaratır.',
    'Her gün 30 dakika yürüyüş kalp sağlığını güçlendirir.',
    'Ekran süresini akşam azaltmak uyku kalitesini artırır.',
    'Renkli sebze ve meyveler bağışıklığı destekler.',
    'Derin nefes egzersizleri stresi azaltmaya yardımcı olur.',
    'Düzenli uyku saatleri enerjinizi dengeler.',
    'Öğün atlamamak gün boyu dengeli enerji sağlar.',
  ];

  static String dailyTip() {
    final n = DateTime.now();
    final idx = (n.year * 366 + n.month * 31 + n.day) % _tips.length;
    return _tips[idx];
  }
}

/// Sağlık ekranları için ortak başlık (ikon + başlık + alt başlık + zil).
class HealthHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final List<Color> gradient;
  final bool showBack;
  const HealthHeader({
    super.key,
    required this.title,
    required this.subtitle,
    this.icon = Icons.monitor_heart_rounded,
    this.gradient = const [Color(0xFF14B8A6), Color(0xFF0D9488)],
    this.showBack = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        children: [
          if (showBack)
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                width: 42,
                height: 42,
                margin: const EdgeInsets.only(right: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A24),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.arrow_back,
                    color: Colors.white, size: 20),
              ),
            )
          else
            Container(
              width: 46,
              height: 46,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: gradient),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(color: gradient.first.withAlpha(90), blurRadius: 10),
                ],
              ),
              child: Icon(icon, color: Colors.white, size: 24),
            ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.w900)),
                Text(subtitle,
                    style: const TextStyle(
                        color: Color(0xFF9CA3AF), fontSize: 13.5)),
              ],
            ),
          ),
          Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
              color: Color(0xFF1A1A24),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.notifications_none_rounded,
                color: Color(0xFF9CA3AF), size: 22),
          ),
        ],
      ),
    );
  }
}
