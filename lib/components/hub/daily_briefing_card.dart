import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../config/routes.dart';
import '../../presentation/providers/app_providers.dart';
import '../../services/ai/ai_content_service.dart';
import '../../services/hive_service.dart';
import '../../services/weather_service.dart';

/// Günlük Zeka Özeti — hub'ın "beyni".
/// Hava durumu, aile üyeleri, bugünkü etkinlik/görev sayısı ve gün bilgisini
/// birleştirip Gemini ile kişiselleştirilmiş, sıcak bir günlük brifing +
/// önerilen aksiyonlar üretir. Günlük önbelleklidir (kota + çevrimdışı dostu).
class DailyBriefingCard extends ConsumerStatefulWidget {
  const DailyBriefingCard({super.key});

  @override
  ConsumerState<DailyBriefingCard> createState() => _DailyBriefingCardState();
}

class _DailyBriefingCardState extends ConsumerState<DailyBriefingCard> {
  late bool _expanded =
      HiveService.getBoolSetting('briefing_expanded', defaultValue: true);

  void _toggle() {
    setState(() => _expanded = !_expanded);
    HiveService.setBoolSetting('briefing_expanded', _expanded);
  }

  /// Öneri metnindeki anahtar kelimeye göre ilgili bölüme yönlendirir.
  void _openAction(String action) {
    final a = action.toLowerCase();
    String route;
    if (a.contains('alışver') || a.contains('market') || a.contains('malzeme')) {
      route = AppRoutes.shopping;
    } else if (a.contains('görev') || a.contains('yapılacak')) {
      route = AppRoutes.tasks;
    } else if (a.contains('etkinlik') ||
        a.contains('takvim') ||
        a.contains('plan') ||
        a.contains('randevu')) {
      route = AppRoutes.calendar;
    } else if (a.contains('bütçe') ||
        a.contains('harca') ||
        a.contains('gider') ||
        a.contains('para')) {
      route = AppRoutes.budget;
    } else if (a.contains('yemek') ||
        a.contains('tarif') ||
        a.contains('mutfak') ||
        a.contains('kahvaltı') ||
        a.contains('akşam')) {
      route = AppRoutes.kitchen;
    } else if (a.contains('sağlık') ||
        a.contains('ilaç') ||
        a.contains('doktor')) {
      route = AppRoutes.familyHealth;
    } else if (a.contains('çocuk') ||
        a.contains('gelişim') ||
        a.contains('eğitim') ||
        a.contains('ödev')) {
      route = AppRoutes.education;
    } else {
      route = AppRoutes.calendar;
    }
    context.push(route);
  }

  @override
  Widget build(BuildContext context) {
    final ref = this.ref;
    final familyName = HiveService.getSetting('family_name') ?? 'Ailem';
    final members = ref.watch(familyMembersProvider);
    final weatherAsync = ref.watch(weatherProvider);
    final weather = weatherAsync.valueOrNull;
    // Hava durumu hâlâ yükleniyorsa brifingi üretmeyi beklet — böylece hava
    // bilgisi (ör. Brüksel) brifinge dahil olur (yalnızca genişletilmişken önemli).
    final weatherSettled = !weatherAsync.isLoading;
    final events = ref.watch(upcomingEventsProvider).valueOrNull ?? const [];
    final tasks = ref.watch(myTasksProvider).valueOrNull ?? const [];

    final now = DateTime.now();
    final dayName = DateFormat('EEEE', 'tr').format(now);
    final greeting = now.hour < 11
        ? 'Günaydın'
        : now.hour < 18
            ? 'İyi günler'
            : 'İyi akşamlar';
    final weatherStr = weather != null
        ? '${weather.temperature.round()}°C, ${WeatherService.weatherDescription(weather.weatherCode)}'
        : 'bilinmiyor';

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 4),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF1A1330), Color(0xFF141225)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0x2A8B5CF6)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              onTap: _toggle,
              borderRadius: BorderRadius.circular(12),
              child: Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                          colors: [Color(0xFF8B5CF6), Color(0xFF6366F1)]),
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: const Icon(Icons.auto_awesome_rounded,
                        color: Colors.white, size: 19),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Günlük Zeka Özeti',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w800)),
                        Text('$greeting · $dayName',
                            style: const TextStyle(
                                color: Color(0xFF9CA3AF), fontSize: 12)),
                      ],
                    ),
                  ),
                  AnimatedRotation(
                    turns: _expanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: const Icon(Icons.keyboard_arrow_down_rounded,
                        color: Color(0xFF9CA3AF), size: 24),
                  ),
                ],
              ),
            ),
            if (!_expanded)
              const SizedBox.shrink()
            else if (!weatherSettled) ...[
              const SizedBox(height: 12),
              const Row(children: [
                SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Color(0xFF8B5CF6))),
                SizedBox(width: 10),
                Text('Bugünü senin için hazırlıyorum…',
                    style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 13)),
              ]),
            ] else ...[
            const SizedBox(height: 12),
            FutureBuilder<List<Map<String, dynamic>>>(
              future: AiContentService.dailyList(
                topic: 'daily_briefing_v2',
                prompt: '''
Bir aile uygulaması için bugünün kişiselleştirilmiş sabah brifingini üret.
Aile: $familyName (${members.length} üye).
Gün: $dayName. Hava: $weatherStr.
Bugün planlı etkinlik: ${events.length}, bekleyen görev: ${tasks.length}.
Sıcak, kısa bir günlük özet (2 cümle) ve 3 uygulanabilir öneri yaz.
Sadece JSON döndür: {"items":[{"summary":"...","actions":["...","...","..."]}]}
Türkçe, samimi bir dille. Havaya uygun bir öneri ekle (ör. yağmurluysa şemsiye).''',
                listKey: 'items',
                fallback: [
                  {
                    'summary':
                        '$greeting! $familyName için güzel bir $dayName. '
                            'Bugünü planlamak için harika bir zaman.',
                    'actions': [
                      if (events.isEmpty)
                        'Takvime bir etkinlik ekle'
                      else
                        '${events.length} etkinliğini gözden geçir',
                      if (tasks.isNotEmpty)
                        '${tasks.length} görevini tamamla'
                      else
                        'Aileye bir görev oluştur',
                      'Alışveriş listeni güncelle',
                    ],
                  }
                ],
                maxTokens: 500,
              ),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Color(0xFF8B5CF6)),
                        ),
                        SizedBox(width: 10),
                        Text('Bugünü senin için özetliyorum…',
                            style: TextStyle(
                                color: Color(0xFF9CA3AF), fontSize: 13)),
                      ],
                    ),
                  );
                }
                final data = (snap.data != null && snap.data!.isNotEmpty)
                    ? snap.data!.first
                    : const <String, dynamic>{};
                final summary = data['summary']?.toString() ?? '';
                final actions = (data['actions'] as List?)
                        ?.map((e) => e.toString())
                        .where((e) => e.isNotEmpty)
                        .toList() ??
                    const [];
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (summary.isNotEmpty)
                      Text(summary,
                          style: const TextStyle(
                              color: Color(0xFFE5E7EB),
                              fontSize: 13.5,
                              height: 1.5)),
                    if (actions.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      for (final a in actions)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () => _openAction(a),
                              borderRadius: BorderRadius.circular(14),
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 10),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF8B5CF6).withAlpha(28),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                      color: const Color(0x338B5CF6)),
                                ),
                                child: Row(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.bolt_rounded,
                                        size: 15, color: Color(0xFFA5B4FC)),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(a,
                                          style: const TextStyle(
                                              color: Color(0xFFD1D5DB),
                                              fontSize: 12.5,
                                              height: 1.35,
                                              fontWeight: FontWeight.w600)),
                                    ),
                                    const Icon(Icons.chevron_right_rounded,
                                        size: 18, color: Color(0xFF8B8FA3)),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ],
                );
              },
            ),
            ],
          ],
        ),
      ),
    );
  }
}
