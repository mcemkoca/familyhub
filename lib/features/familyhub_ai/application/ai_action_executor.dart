import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../presentation/providers/app_providers.dart';
import '../domain/ai_action.dart';

/// Aksiyon yürütme sonucu.
enum AIExecResult { done, invalid, unsupported }

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
        final notifier = ref.read(shoppingItemsProvider.notifier);
        for (final name in items) {
          await notifier.addItem(name);
        }
        return AIExecResult.done;

      // Bu aksiyonlar için henüz güvenli write yolu bağlanmadı —
      // sahte yürütme YAPMA; ilgili modüle yönlendir (kullanıcı kendi yapar).
      case AIActionType.createTask:
      case AIActionType.createReminder:
      case AIActionType.createCalendarEvent:
        return AIExecResult.unsupported;
    }
  }
}
