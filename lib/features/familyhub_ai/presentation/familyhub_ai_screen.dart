import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:familyhub/l10n/app_localizations.dart';
import '../../../presentation/widgets/settings/screen_header.dart';
import '../../family_intelligence/application/family_intelligence_providers.dart';
import '../application/familyhub_ai_providers.dart';
import '../application/ai_action_executor.dart';
import '../domain/ai_action.dart';

/// FamilyHub AI — bağımsız bölüm. Bağlamsal (deterministik) hızlı aksiyonlar,
/// veri minimizasyonu notu ve güvenlik disclaimer'ı. Kritik aksiyonlar
/// onay gerektirir; LOW-risk navigasyon aksiyonları doğrudan çalışır.
class FamilyHubAIScreen extends ConsumerWidget {
  const FamilyHubAIScreen({super.key});

  String _label(AppLocalizations t, String key) => switch (key) {
        'fhaQuickReviewTasks' => t.fhaQuickReviewTasks,
        'fhaQuickRemindTasks' => t.fhaQuickRemindTasks,
        'fhaQuickShopping' => t.fhaQuickShopping,
        'fhaQuickPlanDay' => t.fhaQuickPlanDay,
        'fhaQuickBudget' => t.fhaQuickBudget,
        'fhaQuickLegal' => t.fhaQuickLegal,
        'fhaQuickAddItems' => t.fhaQuickAddItems,
        _ => key,
      };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final s = ref.watch(familySnapshotProvider);
    final quick = ref.watch(aiQuickActionsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      appBar: ScreenHeader(
        title: t.familyHubAITitle,
        showBack: true,
        onBack: () => context.pop(),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
        children: [
          Text(t.familyHubAISubtitle,
              style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 13)),
          const SizedBox(height: 16),
          // Bağlam özeti (sayısal — hassas veri yok)
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                  colors: [Color(0xFF1A1330), Color(0xFF141225)]),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0x2A8B5CF6)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  const Icon(Icons.auto_awesome_rounded,
                      color: Color(0xFF8B5CF6), size: 18),
                  const SizedBox(width: 8),
                  Text(t.fhaSummaryTitle,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w800)),
                ]),
                const SizedBox(height: 10),
                Wrap(spacing: 8, runSpacing: 8, children: [
                  _stat('${s.pendingTasks}', Icons.check_circle_outline),
                  _stat('${s.todayEvents}', Icons.event_outlined),
                  _stat('${s.pendingShoppingItems}',
                      Icons.shopping_cart_outlined),
                  _stat('${s.memberCount}', Icons.people_outline),
                ]),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Text(t.fhaQuickActionsTitle,
              style: const TextStyle(
                  color: Color(0xFF9CA3AF),
                  fontSize: 13,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          for (final q in quick) _actionTile(context, ref, t, q),
          const SizedBox(height: 16),
          // Sohbet henüz yok — dürüst bilgilendirme
          _note(t.fhaChatComingSoon, const Color(0xFF6366F1),
              Icons.chat_bubble_outline_rounded),
          const SizedBox(height: 10),
          _note(t.fhaContextInfo, const Color(0xFF10B981),
              Icons.privacy_tip_outlined),
          const SizedBox(height: 10),
          _note(t.fhaDisclaimer, const Color(0xFFF59E0B),
              Icons.info_outline_rounded),
        ],
      ),
    );
  }

  /// Aksiyonu ele alır: onay gerekiyorsa önce preview dialogu gösterir,
  /// sonra güvenli executor ile yürütür. AI doğrudan kritik işlem yapamaz.
  Future<void> _onAction(BuildContext context, WidgetRef ref,
      AppLocalizations t, AIAction rawAction) async {
    // createReminder metnini aktif dile göre enjekte et (provider'da context yok).
    final a = rawAction.type == AIActionType.createReminder
        ? AIAction(type: AIActionType.createReminder, payload: {
            ...rawAction.payload,
            'title': t.fhaRemindTasksNotifTitle,
            'body': t.fhaRemindTasksNotifBody,
          })
        : rawAction;

    if (!AIActionPolicy.isValid(a)) {
      _snack(context, t.fhaActionFailed);
      return;
    }

    if (a.requiresConfirmation) {
      final confirmed = await _showPreview(context, t, a);
      if (confirmed != true) return;
    }

    if (!context.mounted) return;
    final result =
        await const AIActionExecutor().execute(a, ref, context);
    if (!context.mounted) return;
    switch (result) {
      case AIExecResult.done:
        if (a.type == AIActionType.addShoppingItems) {
          final n = (a.payload['items'] as List).length;
          _snack(context, t.fhaAddedItems(n));
        } else if (a.type == AIActionType.createReminder) {
          _snack(context, t.fhaReminderSet);
        }
        break;
      case AIExecResult.invalid:
        _snack(context, t.fhaActionFailed);
        break;
      case AIExecResult.unsupported:
        _snack(context, t.fhaActionUnsupported);
        break;
    }
  }

  /// Onay öncesi işlem önizlemesi (ne yapılacağını açıkça gösterir).
  Future<bool?> _showPreview(
      BuildContext context, AppLocalizations t, AIAction a) {
    final items = a.type == AIActionType.addShoppingItems
        ? (a.payload['items'] as List).map((e) => e.toString()).toList()
        : const <String>[];
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF13131A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text(t.fhaConfirmTitle,
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (a.type == AIActionType.createReminder) ...[
              Text(t.fhaReminderPreview,
                  style: const TextStyle(color: Color(0xFFD1D5DB))),
              const SizedBox(height: 8),
              Row(children: [
                const Icon(Icons.notifications_active,
                    size: 14, color: Color(0xFFF59E0B)),
                const SizedBox(width: 6),
                Expanded(
                  child: Text('${a.payload['title']}',
                      style: const TextStyle(color: Colors.white)),
                ),
              ]),
            ],
            if (items.isNotEmpty) ...[
              Text(t.fhaPreviewAddItems,
                  style: const TextStyle(color: Color(0xFFD1D5DB))),
              const SizedBox(height: 8),
              for (final i in items)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(children: [
                    const Icon(Icons.check, size: 14, color: Color(0xFF10B981)),
                    const SizedBox(width: 6),
                    Text(i, style: const TextStyle(color: Colors.white)),
                  ]),
                ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(t.fhaCancel,
                style: const TextStyle(color: Color(0xFF9CA3AF))),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF8B5CF6)),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(t.fhaConfirm),
          ),
        ],
      ),
    );
  }

  void _snack(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating),
    );
  }

  Widget _stat(String value, IconData icon) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0x14FFFFFF),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 15, color: const Color(0xFF8B5CF6)),
          const SizedBox(width: 6),
          Text(value,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w800)),
        ]),
      );

  Widget _actionTile(
      BuildContext context, WidgetRef ref, AppLocalizations t, AIQuickAction q) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => _onAction(context, ref, t, q.action),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              color: const Color(0xFF13131A),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0x1AFFFFFF)),
            ),
            child: Row(children: [
              const Icon(Icons.bolt_rounded,
                  size: 18, color: Color(0xFFA5B4FC)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(_label(t, q.labelKey),
                    style: const TextStyle(
                        color: Color(0xFFE5E7EB),
                        fontSize: 14,
                        fontWeight: FontWeight.w600)),
              ),
              const Icon(Icons.chevron_right_rounded,
                  size: 20, color: Color(0xFF6B7280)),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _note(String text, Color color, IconData icon) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withAlpha(20),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withAlpha(60)),
        ),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text,
                style: const TextStyle(
                    color: Color(0xFFD1D5DB), fontSize: 11.5, height: 1.4)),
          ),
        ]),
      );
}
