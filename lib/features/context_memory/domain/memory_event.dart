/// Context Memory — Faz 4: ingestion olay modeli ve adaylar.
///
/// Her modül (mutfak, sağlık, takvim…) memory'ye DOĞRUDAN yazmaz; ortak bir
/// [MemoryEvent] gönderir. Pipeline kimliği çözer, hassasiyeti sınıflar,
/// izni kontrol eder, bilgiyi çıkarır ve ancak sonra saklar.
library;

import 'memory_enums.dart';

/// Bir modülden gelen ham olay.
class MemoryEvent {
  final String id;
  final String eventType;
  final String module;
  final String sourceId;

  final String? userId;
  final String? familyId;
  final String? memberId;
  final String? childId;
  final String? conversationId;

  final Map<String, dynamic> payload;
  final DateTime occurredAt;

  /// Kullanıcının kendi eylemi mi (otomatik sistem olayı değil)?
  final bool userInitiated;

  /// Kullanıcı açıkça "bunu hatırla" dedi mi?
  final bool explicitRememberRequest;

  /// Kullanıcı açıkça "bunu unut" dedi mi?
  final bool explicitForgetRequest;

  const MemoryEvent({
    required this.id,
    required this.eventType,
    required this.module,
    required this.sourceId,
    required this.occurredAt,
    this.userId,
    this.familyId,
    this.memberId,
    this.childId,
    this.conversationId,
    this.payload = const {},
    this.userInitiated = true,
    this.explicitRememberRequest = false,
    this.explicitForgetRequest = false,
  });
}

/// Pipeline'ın ürettiği, HENÜZ SAKLANMAMIŞ aday bilgi.
///
/// Aday ≠ kayıt. Politika reddederse asla [MemoryRecord] olmaz (prompt §6.2).
class MemoryCandidate {
  final MemoryKind kind;
  final MemoryScope scope;
  final MemorySensitivity sensitivity;
  final MemorySourceType sourceType;

  final String module;

  /// Dile bağımsız kanonik anahtar (ör. `food.allergy.peanut`).
  final String key;
  final String title;
  final String content;
  final Map<String, dynamic> structuredData;

  final double confidence;
  final double importance;
  final bool explicit;

  /// Geçici bilgi mi? ("bu hafta şeker yemeyeceğim")
  final bool temporary;

  const MemoryCandidate({
    required this.kind,
    required this.scope,
    required this.sensitivity,
    required this.sourceType,
    required this.module,
    required this.key,
    required this.title,
    required this.content,
    this.structuredData = const {},
    this.confidence = 1.0,
    this.importance = 0.5,
    this.explicit = false,
    this.temporary = false,
  });
}

/// Pipeline'ın bir olay için ürettiği sonuç (kabul + red gerekçeleri).
class MemoryIngestionResult {
  final List<MemoryCandidate> accepted;
  final Map<String, String> rejected; // key → reason

  const MemoryIngestionResult({
    this.accepted = const [],
    this.rejected = const {},
  });

  bool get hasAccepted => accepted.isNotEmpty;
}

/// Bir olayın hangi kapsama ait olduğunu çözer (prompt §6).
///
/// Sıra ÖNEMLİ: çocuk > üye > aile > kullanıcı. Yanlış sıra bir çocuğun
/// verisinin aile geneline sızmasına yol açar.
MemoryScope resolveScope({
  required String? childId,
  required String? memberId,
  required String? familyId,
  required bool sharedWithFamily,
}) {
  if (childId != null && childId.isNotEmpty) return MemoryScope.childPrivate;
  if (memberId != null && memberId.isNotEmpty) return MemoryScope.memberPrivate;
  if (sharedWithFamily && familyId != null && familyId.isNotEmpty) {
    return MemoryScope.familyShared;
  }
  return MemoryScope.userPrivate;
}

/// İçerikten hassasiyet sınıfı çıkarır (kural tabanlı, deterministik).
///
/// AI'ya bırakılmaz: hassas veri sınıflandırması yanlış olursa gizlilik ihlali
/// olur. Şüpheli durumda DAHA KORUYUCU sınıf seçilir.
MemorySensitivity classifySensitivity({
  required String module,
  required String normalizedContent,
  String? childId,
}) {
  final c = normalizedContent;

  // Kimlik bilgisi → asla saklanmaz.
  const credentialHints = [
    'sifre', 'password', 'pin kodu', 'api key', 'token', 'kart numarasi',
    'cvv', 'iban', 'wachtwoord', 'mot de passe',
  ];
  if (credentialHints.any(c.contains)) return MemorySensitivity.credential;

  // Modül bazlı taban sınıf.
  const healthModules = {'health', 'medication', 'development'};
  const financeModules = {'finance', 'subscriptions', 'budget'};
  const legalModules = {'legal'};
  const locationModules = {'location', 'security'};

  if (healthModules.contains(module)) {
    // Çocuğa ait sağlık verisi en korumalı sınıf.
    return (childId != null && childId.isNotEmpty)
        ? MemorySensitivity.minorData
        : MemorySensitivity.health;
  }
  if (financeModules.contains(module)) return MemorySensitivity.financial;
  if (legalModules.contains(module)) return MemorySensitivity.legal;
  if (locationModules.contains(module)) {
    return MemorySensitivity.preciseLocation;
  }

  // İçerik ipuçları (modül normal olsa bile).
  const healthHints = ['alerji', 'allergie', 'allergy', 'ilac', 'ilaç',
    'medication', 'tansiyon', 'diyabet', 'hamile', 'tesh', 'diagnos'];
  if (healthHints.any(c.contains)) {
    return (childId != null && childId.isNotEmpty)
        ? MemorySensitivity.minorData
        : MemorySensitivity.health;
  }

  // Çocukla ilgili her kayıt en az minorData korumasında.
  if (childId != null && childId.isNotEmpty) return MemorySensitivity.minorData;

  return MemorySensitivity.normal;
}

/// Önem skoru (0..1) — prompt §6.3 formülünün deterministik uygulaması.
double scoreImportance({
  required bool explicitRememberRequest,
  required bool confirmed,
  required int recurrenceCount,
  required bool crossModule,
  required bool temporary,
  required double confidence,
  required MemorySensitivity sensitivity,
}) {
  var score = 0.3; // taban

  if (explicitRememberRequest) score += 0.35;
  if (confirmed) score += 0.15;
  if (crossModule) score += 0.10;
  score += (recurrenceCount.clamp(0, 5)) * 0.04; // tekrar → kalıcılık sinyali

  if (temporary) score -= 0.25;
  score -= (1.0 - confidence) * 0.20; // belirsizlik cezası

  // Hassas veri otomatik olarak "çok önemli" sayılmaz (§6.3 sonu).
  if (sensitivity.requiresExplicitConsent) score -= 0.05;

  return score.clamp(0.0, 1.0);
}
