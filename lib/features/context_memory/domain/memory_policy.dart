/// Context Memory — saklama / çelişki / bağlam politikaları (Faz 1).
///
/// Tümü SAF fonksiyondur: yan etkisiz, tam test edilebilir. Pipeline ve
/// Context Builder bu kararları kullanır.
library;

import 'memory_enums.dart';

/// Bir memory adayının saklanıp saklanamayacağı kararı.
class MemoryPolicyDecision {
  final bool allowed;
  final String reason;
  final bool requiresEncryption;
  final Duration? retention;

  const MemoryPolicyDecision({
    required this.allowed,
    required this.reason,
    this.requiresEncryption = false,
    this.retention,
  });
}

/// Kullanıcının memory izinleri (GDPR consent, prompt §11).
class MemoryConsentSnapshot {
  final bool memoryEnabled;
  final bool conversationExtractionEnabled;
  final bool familySharedMemoryEnabled;
  final bool sensitiveMemoryEnabled;
  final Set<String> enabledModules;

  const MemoryConsentSnapshot({
    this.memoryEnabled = true,
    this.conversationExtractionEnabled = true,
    this.familySharedMemoryEnabled = true,
    this.sensitiveMemoryEnabled = false, // hassas veri VARSAYILAN KAPALI
    this.enabledModules = const {},
  });

  /// Tüm memory kapalı — hiçbir şey saklanmaz.
  static const disabled = MemoryConsentSnapshot(
    memoryEnabled: false,
    conversationExtractionEnabled: false,
    familySharedMemoryEnabled: false,
    sensitiveMemoryEnabled: false,
  );
}

/// Bir adayın saklanıp saklanamayacağına karar verir (prompt §3.1, §11).
///
/// Sıra önemlidir: mutlak yasaklar önce, sonra consent, sonra güven eşiği.
MemoryPolicyDecision evaluateStoragePolicy({
  required MemoryKind kind,
  required MemorySensitivity sensitivity,
  required MemoryScope scope,
  required MemorySourceType sourceType,
  required double confidence,
  required String module,
  required MemoryConsentSnapshot consent,
  bool explicitRememberRequest = false,
}) {
  // 1) MUTLAK YASAK — credential/prohibited hiçbir koşulda saklanmaz.
  if (sensitivity.isNeverStorable) {
    return const MemoryPolicyDecision(
      allowed: false,
      reason: 'credential_or_prohibited_never_stored',
    );
  }

  // 2) Kullanıcı memory'yi tamamen kapatmışsa hiçbir şey saklanmaz.
  if (!consent.memoryEnabled) {
    return const MemoryPolicyDecision(
      allowed: false,
      reason: 'memory_disabled_by_user',
    );
  }

  // 3) Sohbetten otomatik çıkarım kapalıysa, açık "hatırla" hariç saklama.
  if (sourceType == MemorySourceType.userMessage &&
      !consent.conversationExtractionEnabled &&
      !explicitRememberRequest) {
    return const MemoryPolicyDecision(
      allowed: false,
      reason: 'conversation_extraction_disabled',
    );
  }

  // 4) Hassas veri, açık izin olmadan saklanmaz (yüksek önemli olsa bile).
  if (sensitivity.requiresExplicitConsent && !consent.sensitiveMemoryEnabled) {
    return MemoryPolicyDecision(
      allowed: false,
      reason: 'sensitive_memory_consent_missing:${sensitivity.name}',
    );
  }

  // 5) Aile paylaşımı kapalıysa familyShared kayıt oluşturulmaz.
  if (scope == MemoryScope.familyShared && !consent.familySharedMemoryEnabled) {
    return const MemoryPolicyDecision(
      allowed: false,
      reason: 'family_shared_memory_disabled',
    );
  }

  // 6) Modül bazlı izin (liste boşsa tüm modüller açık kabul edilir).
  if (consent.enabledModules.isNotEmpty &&
      !consent.enabledModules.contains(module)) {
    return MemoryPolicyDecision(
      allowed: false,
      reason: 'module_disabled:$module',
    );
  }

  // 7) Doğrulanmamış AI çıkarımı düşük güvenle kalıcı saklanmaz (§3.2).
  if (sourceType == MemorySourceType.aiDerived && confidence < 0.75) {
    return const MemoryPolicyDecision(
      allowed: false,
      reason: 'derived_low_confidence',
    );
  }

  return MemoryPolicyDecision(
    allowed: true,
    reason: 'ok',
    requiresEncryption: sensitivity.requiresEncryption,
    retention: defaultRetention(kind: kind, sensitivity: sensitivity),
  );
}

/// Tür + hassasiyete göre varsayılan saklama süresi (prompt §8).
/// `null` = süresiz (kullanıcı silene kadar).
Duration? defaultRetention({
  required MemoryKind kind,
  required MemorySensitivity sensitivity,
}) {
  // Kesin konum mümkün olan en kısa sürede unutulur.
  if (sensitivity == MemorySensitivity.preciseLocation) {
    return const Duration(hours: 24);
  }
  return switch (kind) {
    MemoryKind.conversationSummary => const Duration(days: 90),
    MemoryKind.episodicEvent => const Duration(days: 180),
    MemoryKind.externalKnowledge => const Duration(days: 7),
    MemoryKind.derivedInsight => const Duration(days: 30),
    MemoryKind.feedback => const Duration(days: 30),
    // Doğrulanmış kalıcı bilgiler: süresiz.
    MemoryKind.profileFact ||
    MemoryKind.preference ||
    MemoryKind.routine ||
    MemoryKind.restriction ||
    MemoryKind.healthFact ||
    MemoryKind.medicationFact ||
    MemoryKind.relationship ||
    MemoryKind.correction =>
      null,
    _ => const Duration(days: 365),
  };
}

/// İki çelişen kayıttan hangisinin kazandığını belirler (prompt §7.1).
///
/// Dönen: `true` → YENİ kayıt kazanır (eski `superseded` olur).
/// `false` → mevcut kayıt korunur. Otorite eşitse daha yeni olan kazanır.
bool newRecordSupersedes({
  required MemorySourceType existingSource,
  required DateTime existingUpdatedAt,
  required MemorySourceType incomingSource,
  required DateTime incomingUpdatedAt,
}) {
  final a = incomingSource.authority;
  final b = existingSource.authority;
  if (a != b) return a > b;
  return incomingUpdatedAt.isAfter(existingUpdatedAt);
}

/// Bir kaydın AI bağlamına eklenip eklenemeyeceği (prompt §25 dört kontrol).
///
/// - Durum kullanılabilir olmalı (superseded/disputed/rejected ASLA),
/// - Süresi dolmamış olmalı,
/// - Erişim izni olmalı,
/// - Güven eşiğini geçmeli.
bool canIncludeInContext({
  required MemoryStatus status,
  required MemorySensitivity sensitivity,
  required double confidence,
  required bool viewerHasAccess,
  DateTime? expiresAt,
  DateTime? now,
  double minConfidence = 0.5,
}) {
  if (!status.isUsableInContext) return false;
  if (!viewerHasAccess) return false;
  if (sensitivity.isNeverStorable) return false;
  final ts = now ?? DateTime.now();
  if (expiresAt != null && !expiresAt.isAfter(ts)) return false;
  return confidence >= minConfidence;
}

/// Erişim kontrolü: bu izleyici bu kaydı görebilir mi? (prompt §10.2)
///
/// Kural: kendi özel kaydını görür; familyShared'ı aile üyesi görür;
/// çocuk kaydını yalnızca yetkili ebeveyn/admin görür; başka yetişkinin
/// özel kaydı OTOMATİK görünmez.
bool viewerCanAccess({
  required MemoryScope scope,
  required String? ownerUserId,
  required String viewerUserId,
  required bool viewerIsSameFamily,
  required bool viewerIsParentOrAdmin,
  List<String> allowedUserIds = const [],
  List<String> deniedUserIds = const [],
}) {
  if (deniedUserIds.contains(viewerUserId)) return false;
  if (allowedUserIds.contains(viewerUserId)) return true;

  return switch (scope) {
    MemoryScope.deviceLocal ||
    MemoryScope.session ||
    MemoryScope.userPrivate ||
    MemoryScope.memberPrivate =>
      ownerUserId == viewerUserId,
    MemoryScope.childPrivate => viewerIsSameFamily && viewerIsParentOrAdmin,
    MemoryScope.familyShared || MemoryScope.module => viewerIsSameFamily,
  };
}
