import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/smart_reminder.dart';
import '../../domain/models/context_snapshot.dart';
import '../../domain/models/reminder_interaction.dart';
import '../../repositories/smart_reminder_repository.dart';
import '../../repositories/context_snapshot_repository.dart';
import '../../repositories/reminder_interaction_repository.dart';

final smartReminderRepositoryProvider = Provider((ref) => SmartReminderRepository());
final contextSnapshotRepositoryProvider = Provider((ref) => ContextSnapshotRepository());
final reminderInteractionRepositoryProvider = Provider((ref) => ReminderInteractionRepository());

// ── REMINDERS ──────────────────────────────────────────────────────────

final smartRemindersProvider = FutureProvider.family<List<SmartReminder>, String>(
  (ref, familyId) async {
    final repo = ref.watch(smartReminderRepositoryProvider);
    return repo.getReminders(familyId);
  },
);

final activeSmartRemindersProvider = FutureProvider.family<List<SmartReminder>, String>(
  (ref, familyId) async {
    final repo = ref.watch(smartReminderRepositoryProvider);
    return repo.getActiveReminders(familyId);
  },
);

final smartReminderByIdProvider = FutureProvider.family<SmartReminder, String>(
  (ref, id) async {
    final repo = ref.watch(smartReminderRepositoryProvider);
    return repo.getById(id);
  },
);

// ── CONTEXT ────────────────────────────────────────────────────────────

final latestContextProvider = FutureProvider.family<ContextSnapshot, String>(
  (ref, memberId) async {
    final repo = ref.watch(contextSnapshotRepositoryProvider);
    return repo.getLatestSnapshot(memberId);
  },
);

// ── INTERACTIONS ───────────────────────────────────────────────────────

final reminderInteractionsProvider = FutureProvider.family<List<ReminderInteraction>, String>(
  (ref, reminderId) async {
    final repo = ref.watch(reminderInteractionRepositoryProvider);
    return repo.getInteractionsForReminder(reminderId);
  },
);

final reminderAnalyticsProvider = FutureProvider.family<Map<String, dynamic>, String>(
  (ref, reminderId) async {
    final repo = ref.watch(reminderInteractionRepositoryProvider);
    return repo.getAnalytics(reminderId);
  },
);


