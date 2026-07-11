import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:familyhub/l10n/app_localizations.dart';
import '../../../presentation/widgets/settings/screen_header.dart';
import '../../../services/notification_service.dart';
import '../application/family_intelligence_providers.dart';
import '../application/quiet_hours.dart';
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
          const SizedBox(height: 16),
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
