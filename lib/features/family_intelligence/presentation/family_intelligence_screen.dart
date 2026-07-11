import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:familyhub/l10n/app_localizations.dart';
import '../../../presentation/widgets/settings/screen_header.dart';
import '../../../services/notification_service.dart';
import '../application/family_intelligence_providers.dart';
import '../application/quiet_hours.dart';
import '../application/daily_summary_scheduler.dart';
import '../domain/family_insight.dart';

/// Aile Zekası — bağımsız bölüm. Kural tabanlı içgörüler (AI gerektirmez),
/// öncelik sıralı, her kartta "neden gösterildi" açıklaması ve aksiyon.
class FamilyIntelligenceScreen extends ConsumerWidget {
  const FamilyIntelligenceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final insights = ref.watch(familyInsightsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      appBar: ScreenHeader(
        title: t.familyIntelligenceTitle,
        showBack: true,
        onBack: () => context.pop(),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          Text(t.familyIntelligenceSubtitle,
              style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 13)),
          const SizedBox(height: 4),
          Text(t.fiRuleBasedNote,
              style: const TextStyle(
                  color: Color(0xFF6B7280),
                  fontSize: 11,
                  fontStyle: FontStyle.italic)),
          const SizedBox(height: 12),
          const _DailySummaryTile(),
          const SizedBox(height: 12),
          if (insights.isEmpty)
            _empty(t)
          else ...[
            // Öne çıkan (en yüksek öncelikli) içgörüyü bildir.
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () => _notifyTop(context, t, insights.first),
                icon: const Icon(Icons.notifications_active_outlined, size: 16),
                label: Text(t.fiNotifyTop),
                style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF8B5CF6)),
              ),
            ),
            for (final i in insights) _InsightCard(insight: i),
          ],
        ],
      ),
    );
  }

  Future<void> _notifyTop(
      BuildContext context, AppLocalizations t, FamilyInsight top) async {
    // Sessiz saatlere saygı — bu aralıkta bildirim gönderme.
    if (QuietHours.enabled && QuietHours.fromSettings().isQuietNow()) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(t.fiQuietHours),
          behavior: SnackBarBehavior.floating));
      return;
    }
    final title = FamilyIntelligenceStrings.resolve(t, top.titleKey, top.args);
    final body = FamilyIntelligenceStrings.resolve(t, top.bodyKey, top.args);
    await NotificationService.showInstantNotification(
        title: title, body: body, payload: 'fi:${top.id}');
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(t.fiNotified), behavior: SnackBarBehavior.floating),
    );
  }

  Widget _empty(AppLocalizations t) => Padding(
        padding: const EdgeInsets.only(top: 60),
        child: Column(
          children: [
            const Icon(Icons.check_circle_outline_rounded,
                size: 52, color: Color(0xFF10B981)),
            const SizedBox(height: 14),
            Text(t.fiEmptyTitle,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            Text(t.fiEmptyDesc,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Color(0xFF9CA3AF))),
          ],
        ),
      );
}

class _InsightCard extends StatefulWidget {
  final FamilyInsight insight;
  const _InsightCard({required this.insight});

  @override
  State<_InsightCard> createState() => _InsightCardState();
}

class _InsightCardState extends State<_InsightCard> {
  bool _showWhy = false;

  static ({Color color, String Function(AppLocalizations) label}) _priority(
      InsightPriority p) {
    return switch (p) {
      InsightPriority.critical => (
          color: const Color(0xFFEF4444),
          label: (t) => t.fiPriorityCritical
        ),
      InsightPriority.high => (
          color: const Color(0xFFF59E0B),
          label: (t) => t.fiPriorityHigh
        ),
      InsightPriority.normal => (
          color: const Color(0xFF6366F1),
          label: (t) => t.fiPriorityNormal
        ),
      InsightPriority.info => (
          color: const Color(0xFF10B981),
          label: (t) => t.fiPriorityInfo
        ),
    };
  }

  IconData _icon(InsightType type) => switch (type) {
        InsightType.warning => Icons.warning_amber_rounded,
        InsightType.reminder => Icons.notifications_active_outlined,
        InsightType.recommendation => Icons.lightbulb_outline_rounded,
        InsightType.summary => Icons.summarize_outlined,
        InsightType.achievement => Icons.emoji_events_outlined,
        InsightType.planning => Icons.event_note_outlined,
      };

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final i = widget.insight;
    final pr = _priority(i.priority);
    final title = FamilyIntelligenceStrings.resolve(t, i.titleKey, i.args);
    final body = FamilyIntelligenceStrings.resolve(t, i.bodyKey, i.args);
    final reason = FamilyIntelligenceStrings.resolve(t, i.reasonKey, i.args);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF13131A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0x1AFFFFFF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(_icon(i.type), size: 18, color: pr.color),
              const SizedBox(width: 8),
              Expanded(
                child: Text(title,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14.5,
                        fontWeight: FontWeight.w800)),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: pr.color.withAlpha(30),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(pr.label(t),
                    style: TextStyle(
                        color: pr.color,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(body,
              style: const TextStyle(
                  color: Color(0xFFD1D5DB), fontSize: 13, height: 1.4)),
          const SizedBox(height: 8),
          Row(
            children: [
              GestureDetector(
                onTap: () => setState(() => _showWhy = !_showWhy),
                child: Row(
                  children: [
                    Icon(
                        _showWhy
                            ? Icons.expand_less_rounded
                            : Icons.help_outline_rounded,
                        size: 15,
                        color: const Color(0xFF9CA3AF)),
                    const SizedBox(width: 4),
                    Text(t.fiWhyShown,
                        style: const TextStyle(
                            color: Color(0xFF9CA3AF),
                            fontSize: 12,
                            fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              const Spacer(),
              if (i.actionRoute != null)
                TextButton(
                  onPressed: () => context.push(i.actionRoute!),
                  style: TextButton.styleFrom(
                      foregroundColor: pr.color,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      minimumSize: const Size(0, 40)),
                  child: const Icon(Icons.arrow_forward_rounded, size: 18),
                ),
            ],
          ),
          if (_showWhy)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(reason,
                  style: const TextStyle(
                      color: Color(0xFF6B7280),
                      fontSize: 12,
                      height: 1.4,
                      fontStyle: FontStyle.italic)),
            ),
        ],
      ),
    );
  }
}

/// Günlük özet bildirimi — aç/kapa + saat seçimi (tekrarlayan bildirim).
class _DailySummaryTile extends StatefulWidget {
  const _DailySummaryTile();

  @override
  State<_DailySummaryTile> createState() => _DailySummaryTileState();
}

class _DailySummaryTileState extends State<_DailySummaryTile> {
  final _sched = DailySummaryScheduler.instance;

  Future<void> _toggle(bool on, AppLocalizations t) async {
    if (on) {
      await _sched.enable(
        hour: _sched.hour,
        title: t.fiDailySummaryNotifTitle,
        body: t.fiDailySummaryNotifBody,
      );
    } else {
      await _sched.disable();
    }
    if (mounted) setState(() {});
  }

  Future<void> _pickHour(AppLocalizations t) async {
    final picked = await showModalBottomSheet<int>(
      context: context,
      backgroundColor: const Color(0xFF13131A),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: SizedBox(
          height: 320,
          child: GridView.count(
            crossAxisCount: 4,
            padding: const EdgeInsets.all(16),
            children: [
              for (var h = 0; h < 24; h++)
                GestureDetector(
                  onTap: () => Navigator.pop(ctx, h),
                  child: Container(
                    margin: const EdgeInsets.all(4),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: h == _sched.hour
                          ? const Color(0xFF8B5CF6)
                          : const Color(0xFF1A1A24),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text('$h:00',
                        style: const TextStyle(color: Colors.white)),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
    if (picked == null) return;
    await _sched.enable(
      hour: picked,
      title: t.fiDailySummaryNotifTitle,
      body: t.fiDailySummaryNotifBody,
    );
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final on = _sched.isEnabled;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF13131A),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0x1AFFFFFF)),
      ),
      child: Row(
        children: [
          const Icon(Icons.schedule_rounded, size: 20, color: Color(0xFF8B5CF6)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(t.fiDailySummary,
                    style: const TextStyle(
                        color: Color(0xFFE5E7EB),
                        fontSize: 14,
                        fontWeight: FontWeight.w600)),
                GestureDetector(
                  onTap: on ? () => _pickHour(t) : null,
                  child: Text(
                      on
                          ? t.fiDailySummaryOn(_sched.hour.toString())
                          : t.fiDailySummaryDesc,
                      style: TextStyle(
                          color: on
                              ? const Color(0xFF8B5CF6)
                              : const Color(0xFF6B7280),
                          fontSize: 11.5)),
                ),
              ],
            ),
          ),
          Switch(
            value: on,
            activeTrackColor: const Color(0xFF8B5CF6),
            activeThumbColor: Colors.white,
            onChanged: (v) => _toggle(v, t),
          ),
        ],
      ),
    );
  }
}

/// Kural motorunun stable key'lerini localization getter'larına eşler.
/// (Generated AppLocalizations dinamik key lookup sağlamadığı için açık eşleme.)
class FamilyIntelligenceStrings {
  static String resolve(
      AppLocalizations t, String key, Map<String, String> args) {
    final count = args['count'] ?? '';
    final days = args['days'] ?? '';
    return switch (key) {
      'fiInsightOverdueTitle' => t.fiInsightOverdueTitle,
      'fiInsightOverdueBody' => t.fiInsightOverdueBody(count),
      'fiReasonOverdue' => t.fiReasonOverdue,
      'fiInsightPaymentTitle' => t.fiInsightPaymentTitle,
      'fiInsightPaymentBody' => t.fiInsightPaymentBody(days),
      'fiReasonPayment' => t.fiReasonPayment,
      'fiInsightTodayEventsTitle' => t.fiInsightTodayEventsTitle,
      'fiInsightTodayEventsBody' => t.fiInsightTodayEventsBody(count),
      'fiReasonTodayEvents' => t.fiReasonTodayEvents,
      'fiInsightShoppingTitle' => t.fiInsightShoppingTitle,
      'fiInsightShoppingBody' => t.fiInsightShoppingBody(count),
      'fiReasonShopping' => t.fiReasonShopping,
      'fiInsightPendingTasksTitle' => t.fiInsightPendingTasksTitle,
      'fiInsightPendingTasksBody' => t.fiInsightPendingTasksBody(count),
      'fiReasonPendingTasks' => t.fiReasonPendingTasks,
      'fiInsightAllClearTitle' => t.fiInsightAllClearTitle,
      'fiInsightAllClearBody' => t.fiInsightAllClearBody,
      'fiReasonAllClear' => t.fiReasonAllClear,
      'fiInsightBusyDayTitle' => t.fiInsightBusyDayTitle,
      'fiInsightBusyDayBody' =>
        t.fiInsightBusyDayBody(args['events'] ?? '', args['tasks'] ?? ''),
      'fiReasonBusyDay' => t.fiReasonBusyDay,
      'fiInsightShareShoppingTitle' => t.fiInsightShareShoppingTitle,
      'fiInsightShareShoppingBody' =>
        t.fiInsightShareShoppingBody(args['count'] ?? ''),
      'fiReasonShareShopping' => t.fiReasonShareShopping,
      _ => key,
    };
  }
}
