import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../config/routes.dart';
import '../../family_intelligence/application/family_intelligence_providers.dart';
import '../domain/ai_action.dart';

/// Bağlamsal hızlı aksiyon önerisi (deterministik, AI GEREKTİRMEZ).
/// Tümü LOW-risk navigasyon aksiyonlarıdır (onay gerektirmez).
class AIQuickAction {
  final String labelKey;
  final AIAction action;
  const AIQuickAction({required this.labelKey, required this.action});
}

/// Aile durumuna göre değişen hızlı aksiyonlar — snapshot'tan türetilir.
final aiQuickActionsProvider = Provider<List<AIQuickAction>>((ref) {
  final s = ref.watch(familySnapshotProvider);
  final actions = <AIQuickAction>[];

  if (s.overdueTasks > 0 || s.pendingTasks > 0) {
    actions.add(const AIQuickAction(
      labelKey: 'fhaQuickReviewTasks',
      action: AIAction(type: AIActionType.openModule, route: AppRoutes.tasks),
    ));
  }
  if (s.pendingShoppingItems > 0) {
    actions.add(const AIQuickAction(
      labelKey: 'fhaQuickShopping',
      action:
          AIAction(type: AIActionType.openModule, route: AppRoutes.shopping),
    ));
  }
  if (s.todayEvents > 0) {
    actions.add(const AIQuickAction(
      labelKey: 'fhaQuickPlanDay',
      action:
          AIAction(type: AIActionType.openModule, route: AppRoutes.calendar),
    ));
  }
  // Her zaman kullanışlı sabit aksiyonlar.
  actions.add(const AIQuickAction(
    labelKey: 'fhaQuickBudget',
    action: AIAction(type: AIActionType.summarizeBudget, route: AppRoutes.budget),
  ));
  actions.add(const AIQuickAction(
    labelKey: 'fhaQuickLegal',
    action: AIAction(
        type: AIActionType.openModule, route: AppRoutes.legalBenefits),
  ));
  return actions;
});
