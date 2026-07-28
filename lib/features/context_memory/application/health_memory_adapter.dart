/// Context Memory — sağlık/çocuk modülü adapter'ı (prompt §21).
///
/// Sağlık verisi normal tercih gibi işlenmez. Bu adapter:
///  - sağlık kayıtlarını `health`/`minorData` hassasiyetinde sınıflar,
///  - kadın sağlığını ASLA otomatik aile paylaşımına açmaz,
///  - çocuk kaydını yalnızca çocuk kapsamında tutar,
///  - alerjiyi kritik kısıt (restriction) olarak işaretler,
///  - teşhis/çıkarım üretmez (yalnızca kullanıcının verdiği bilgi).
library;

import '../domain/memory_enums.dart';
import '../domain/memory_event.dart';
import '../domain/memory_record.dart';

/// Sağlık verisinin alt türü — kapsam ve hassasiyet bundan türer.
enum HealthDataKind {
  allergy,
  medication,
  appointment,
  condition,
  measurement,
  womensHealth,
}

/// Sağlık verisi için doğru hassasiyet sınıfı.
///
/// Çocuk verisi HER ZAMAN `minorData`; kadın sağlığı `confidential`.
MemorySensitivity healthSensitivityFor({
  required HealthDataKind kind,
  String? childId,
}) {
  if (childId != null && childId.isNotEmpty) return MemorySensitivity.minorData;
  if (kind == HealthDataKind.womensHealth) {
    return MemorySensitivity.confidential;
  }
  return MemorySensitivity.health;
}

/// Sağlık verisi için doğru kapsam.
///
/// KRİTİK: sağlık verisi ASLA otomatik `familyShared` olmaz — bir yetişkinin
/// kaydı diğer yetişkine otomatik görünmemelidir (prompt §21).
MemoryScope healthScopeFor({String? childId}) {
  if (childId != null && childId.isNotEmpty) return MemoryScope.childPrivate;
  return MemoryScope.userPrivate;
}

/// Bu sağlık türü tarif/öneri bağlamında kritik kısıt mı?
///
/// Alerji ve ilaç, yemek önerilerinde MUTLAKA dikkate alınmalıdır.
bool isCriticalHealthRestriction(HealthDataKind kind) =>
    kind == HealthDataKind.allergy || kind == HealthDataKind.medication;

String healthMemoryKey({
  required HealthDataKind kind,
  required String subject,
}) {
  final slug = normalizeMemoryContent(subject).replaceAll(' ', '_');
  return 'health.${kind.name}.$slug';
}

/// Sağlık kaydından memory adayı üretir.
///
/// [subject] = alerjen/ilaç/durum adı. Boşsa aday üretilmez (tutucu).
List<MemoryCandidate> healthCandidates({
  required HealthDataKind kind,
  required String subject,
  required String content,
  String? childId,
}) {
  if (subject.trim().isEmpty || content.trim().isEmpty) return const [];

  final critical = isCriticalHealthRestriction(kind);
  return [
    MemoryCandidate(
      // Alerji/ilaç kısıttır; diğerleri sağlık gerçeğidir.
      kind: critical ? MemoryKind.restriction : MemoryKind.healthFact,
      scope: healthScopeFor(childId: childId),
      sensitivity: healthSensitivityFor(kind: kind, childId: childId),
      // Modül kaydı — kullanıcı beyanı otoritesinde değil, ama güvenilir.
      sourceType: MemorySourceType.moduleRecord,
      module: kind == HealthDataKind.medication ? 'medication' : 'health',
      key: healthMemoryKey(kind: kind, subject: subject),
      title: _title(kind, subject),
      content: content.trim(),
      structuredData: {'kind': kind.name, 'subject': subject},
      confidence: 1.0,
      // Kritik kısıtlar bağlamda öncelikli olmalı.
      importance: critical ? 0.95 : 0.7,
      explicit: true,
    ),
  ];
}

String _title(HealthDataKind kind, String subject) => switch (kind) {
      HealthDataKind.allergy => 'Alerji: $subject',
      HealthDataKind.medication => 'İlaç: $subject',
      HealthDataKind.appointment => 'Randevu: $subject',
      HealthDataKind.condition => 'Sağlık durumu: $subject',
      HealthDataKind.measurement => 'Ölçüm: $subject',
      HealthDataKind.womensHealth => 'Kadın sağlığı',
    };

/// Sağlık modülünden memory olayı.
MemoryEvent healthMemoryEvent({
  required String eventId,
  required String sourceId,
  required HealthDataKind kind,
  String? userId,
  String? familyId,
  String? childId,
  DateTime? occurredAt,
}) =>
    MemoryEvent(
      id: eventId,
      eventType: 'health_record',
      module: kind == HealthDataKind.medication ? 'medication' : 'health',
      sourceId: sourceId,
      userId: userId,
      familyId: familyId,
      childId: childId,
      occurredAt: occurredAt ?? DateTime.now(),
    );
