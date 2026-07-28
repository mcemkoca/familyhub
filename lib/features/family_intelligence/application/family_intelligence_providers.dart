import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../presentation/providers/app_providers.dart';
import '../domain/family_insight.dart';
import 'family_intelligence_engine.dart';

/// Mevcut modül provider'larından deterministik aile snapshot'ı toplar.
final familySnapshotProvider = Provider<FamilySnapshot>((ref) {
  final tasks = ref.watch(myTasksProvider).valueOrNull ?? const [];
  final events = ref.watch(upcomingEventsProvider).valueOrNull ?? const [];
  final shopping = ref.watch(shoppingItemsProvider).valueOrNull ?? const [];
  final members = ref.watch(familyMembersProvider);

  final now = DateTime.now();
  final todayStart = DateTime(now.year, now.month, now.day);
  final todayEnd = todayStart.add(const Duration(days: 1));

  final overdue = tasks
      .where((t) => t.dueDate != null && t.dueDate!.isBefore(todayStart))
      .length;
  final todayEvents = events
      .where((e) => !e.start.isBefore(todayStart) && e.start.isBefore(todayEnd))
      .length;
  final pendingShopping = shopping.where((i) => !i.isCompleted).length;

  return FamilySnapshot(
    overdueTasks: overdue,
    pendingTasks: tasks.length,
    todayEvents: todayEvents,
    pendingShoppingItems: pendingShopping,
    memberCount: members.length,
  );
});

/// Kural motorunun ürettiği içgörüler (öncelik sıralı, deduplicate).
final familyInsightsProvider = Provider<List<FamilyInsight>>((ref) {
  final snapshot = ref.watch(familySnapshotProvider);
  return const FamilyIntelligenceEngine().generate(snapshot);
});
