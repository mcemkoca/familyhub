import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../presentation/providers/app_providers.dart';
import '../../../services/notification_service.dart';
import '../../../services/auth_service.dart';
import '../../../repositories/task_repository.dart';
import '../../../repositories/calendar_repository.dart';
import '../../../domain/entities.dart';
import '../domain/ai_action.dart';

/// Aksiyon yürütme sonucu.
/// [failed] = backend write GERÇEKTEN başarısız (sahte "tamamlandı" YOK, spec §4.4).
enum AIExecResult { done, invalid, unsupported, failed }

/// AIAction'ları GÜVENLİ biçimde yürütür.
/// - Şema doğrulamadan geçmeyen aksiyon reddedilir (invalid).
/// - Onay gerektiren aksiyonlar bu çağrıdan ÖNCE onaylanmış olmalıdır
///   (çağıran katman preview+confirm gösterir).
/// - AI doğrudan kritik işlem yapamaz; yalnızca allowlist türleri.
class AIActionExecutor {
  const AIActionExecutor();

  Future<AIExecResult> execute(
    AIAction action,
    WidgetRef ref,
    BuildContext context,
  ) async {
    if (!AIActionPolicy.isValid(action)) return AIExecResult.invalid;

    switch (action.type) {
      case AIActionType.openModule:
      case AIActionType.openEntity:
      case AIActionType.summarizeBudget:
        final r = action.route;
        if (r == null) return AIExecResult.invalid;
        context.push(r);
        return AIExecResult.done;

      case AIActionType.openLegalBenefit:
        // Resmî kaynak açma navigasyonla ele alınır (route verilirse).
        final r = action.route;
        if (r != null) {
          context.push(r);
          return AIExecResult.done;
        }
        return AIExecResult.unsupported;

      case AIActionType.addShoppingItems:
        final items = (action.payload['items'] as List)
            .map((e) => e.toString().trim())
            .where((e) => e.isNotEmpty)
            .toList();
        try {
          final notifier = ref.read(shoppingItemsProvider.notifier);
          for (final name in items) {
            await notifier.addItem(name);
          }
          return AIExecResult.done;
        } catch (_) {
          return AIExecResult.failed;
        }

      case AIActionType.createReminder:
        // Güvenli write: yerel bildirim planla. Geçmiş-tarih guard.
        final title = (action.payload['title'] as String).trim();
        final days = (action.payload['days'] as int?) ?? 1;
        if (days <= 0) return AIExecResult.invalid;
        final when = DateTime.now().add(Duration(days: days));
        if (!when.isAfter(DateTime.now())) return AIExecResult.invalid;
        try {
          await NotificationService.scheduleNotification(
            id: ('fha_reminder_$title').hashCode & 0x7fffffff,
            title: title,
            body: (action.payload['body'] as String?) ?? title,
            scheduledDate: when,
            payload: 'fha_reminder',
          );
          return AIExecResult.done;
        } catch (_) {
          return AIExecResult.failed;
        }

      case AIActionType.createTask:
        // Gerçek görev oluştur; başarı yalnızca backend dönüşüne göre (spec §4.4).
        final title = (action.payload['title'] as String).trim();
        final familyId = await ref.read(familyIdProvider.future);
        if (familyId == null || familyId.isEmpty) return AIExecResult.failed;
        try {
          final created = await TaskRepository().createTask(
            Task(
              id: '',
              title: title,
              description: action.payload['description'] as String?,
              assignedTo: (action.payload['assignedTo'] as String?) ??
                  (AuthService.currentUserId ?? ''),
              status: TaskStatus.pending,
              priority: (action.payload['priority'] as String?) ?? 'medium',
            ),
            familyId,
          );
          return created.id.isEmpty ? AIExecResult.failed : AIExecResult.done;
        } catch (_) {
          return AIExecResult.failed;
        }

      case AIActionType.createCalendarEvent:
        // Gerçek takvim etkinliği oluştur. date payload'ı ISO string.
        final title = (action.payload['title'] as String).trim();
        final start = DateTime.tryParse(action.payload['date'] as String);
        if (start == null) return AIExecResult.invalid;
        try {
          final created = await CalendarRepository().createEvent(
            CalendarEvent(
              id: '',
              title: title,
              start: start,
              end: start.add(const Duration(hours: 1)),
              description: action.payload['description'] as String?,
            ),
          );
          return created.id.isEmpty ? AIExecResult.failed : AIExecResult.done;
        } catch (_) {
          return AIExecResult.failed;
        }
    }
  }
}
