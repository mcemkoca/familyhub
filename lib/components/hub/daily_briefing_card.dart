import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../presentation/providers/app_providers.dart';
import '../../services/ai/ai_content_service.dart';
import '../../services/hive_service.dart';
import '../../services/weather_service.dart';

/// Günlük Zeka Özeti — hub'ın "beyni".
/// Hava durumu, aile üyeleri, bugünkü etkinlik/görev sayısı ve gün bilgisini
/// birleştirip Gemini ile kişiselleştirilmiş, sıcak bir günlük brifing +
/// önerilen aksiyonlar üretir. Günlük önbelleklidir (kota + çevrimdışı dostu).
class DailyBriefingCard extends ConsumerWidget {
  const DailyBriefingCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final familyName = HiveService.getSetting('family_name') ?? 'Ailem';
    final members = ref.watch(familyMembersProvider);
    final weather = ref.watch(weatherProvider).valueOrNull;
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
            Row(
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
              ],
            ),
            const SizedBox(height: 12),
            FutureBuilder<List<Map<String, dynamic>>>(
              future: AiContentService.dailyList(
                topic: 'daily_briefing',
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
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: actions
                            .map((a) => Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 7),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF8B5CF6)
                                        .withAlpha(28),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                        color: const Color(0x338B5CF6)),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.bolt_rounded,
                                          size: 14, color: Color(0xFFA5B4FC)),
                                      const SizedBox(width: 5),
                                      Text(a,
                                          style: const TextStyle(
                                              color: Color(0xFFD1D5DB),
                                              fontSize: 12.5,
                                              fontWeight: FontWeight.w600)),
                                    ],
                                  ),
                                ))
                            .toList(),
                      ),
                    ],
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
