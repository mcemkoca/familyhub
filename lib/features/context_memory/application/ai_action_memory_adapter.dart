/// Context Memory — AI aksiyonlarını hafızaya bağlayan adapter.
///
/// KRİTİK KURAL (prompt §3.3): yalnızca GERÇEKTEN BAŞARILI olmuş aksiyonlar
/// hatırlanır. AI'ın "yaptım" demesi yeterli değildir; executor `done`
/// döndürmediyse episodik kayıt üretilmez.
library;

import '../../familyhub_ai/application/ai_action_executor.dart';
import '../../familyhub_ai/domain/ai_action.dart';
import '../domain/memory_enums.dart';
import '../domain/memory_event.dart';

/// Bir aksiyon sonucunun hafızaya yazılıp yazılmayacağı.
///
/// `done` dışındaki tüm sonuçlar (invalid/unsupported/failed) hatırlanmaz —
/// başarısız işlem "yapıldı" gibi bağlama girmemelidir.
bool actionShouldBeRemembered(AIExecResult result) =>
    result == AIExecResult.done;

/// Aksiyon tipinin hangi modüle ait olduğu.
String moduleForAction(AIActionType type) => switch (type) {
      AIActionType.addShoppingItems => 'shopping',
      AIActionType.createCalendarEvent => 'calendar',
      AIActionType.createTask => 'tasks',
      AIActionType.createReminder => 'reminders',
      AIActionType.summarizeBudget => 'finance',
      AIActionType.openLegalBenefit => 'legal',
      AIActionType.openModule || AIActionType.openEntity => 'navigation',
    };

/// Salt-gezinme aksiyonları hatırlanmaz (gürültü — kalıcı değer taşımaz).
bool actionIsWorthRemembering(AIActionType type) => switch (type) {
      AIActionType.openModule ||
      AIActionType.openEntity ||
      AIActionType.summarizeBudget ||
      AIActionType.openLegalBenefit =>
        false,
      AIActionType.createTask ||
      AIActionType.createReminder ||
      AIActionType.createCalendarEvent ||
      AIActionType.addShoppingItems =>
        true,
    };

/// Başarılı bir aksiyondan episodik hafıza adayı üretir.
///
/// Dönen liste boşsa hiçbir şey saklanmaz (başarısız veya değersiz aksiyon).
List<MemoryCandidate> candidatesForCompletedAction({
  required AIAction action,
  required AIExecResult result,
  String? summary,
}) {
  // 1) Gerçekten başarılı mı? (model iddiası değil, executor sonucu)
  if (!actionShouldBeRemembered(result)) return const [];
  // 2) Hatırlanmaya değer mi?
  if (!actionIsWorthRemembering(action.type)) return const [];

  final module = moduleForAction(action.type);
  final label = summary?.trim().isNotEmpty == true
      ? summary!.trim()
      : _defaultLabel(action.type);

  return [
    MemoryCandidate(
      kind: MemoryKind.episodicEvent,
      // Aile eylemleri (görev/takvim/alışveriş) aile bağlamındadır.
      scope: MemoryScope.familyShared,
      sensitivity: MemorySensitivity.normal,
      // Uygulama olayı — kullanıcı beyanı DEĞİL (otorite farkı korunur).
      sourceType: MemorySourceType.applicationEvent,
      module: module,
      key: 'action.${action.type.name}.completed',
      title: label,
      content: label,
      structuredData: {
        'actionType': action.type.name,
        'module': module,
      },
      confidence: 1.0, // gerçekleşmiş olay — kesin
      importance: 0.45, // yakın geçmiş bağlamı; kalıcı tercih değil
      explicit: false,
    ),
  ];
}

String _defaultLabel(AIActionType type) => switch (type) {
      AIActionType.createTask => 'Görev oluşturuldu',
      AIActionType.createReminder => 'Hatırlatıcı kuruldu',
      AIActionType.createCalendarEvent => 'Takvime etkinlik eklendi',
      AIActionType.addShoppingItems => 'Alışveriş listesine ürün eklendi',
      _ => 'İşlem tamamlandı',
    };

/// Aksiyon sonrası memory olayı.
MemoryEvent aiActionMemoryEvent({
  required String eventId,
  required AIActionType type,
  String? userId,
  String? familyId,
  String? conversationId,
  DateTime? occurredAt,
}) =>
    MemoryEvent(
      id: eventId,
      eventType: 'ai_action_completed',
      module: moduleForAction(type),
      sourceId: 'ai_action_${type.name}',
      userId: userId,
      familyId: familyId,
      conversationId: conversationId,
      occurredAt: occurredAt ?? DateTime.now(),
      // Sistem olayı: kullanıcı "hatırla" demedi.
      userInitiated: false,
    );
