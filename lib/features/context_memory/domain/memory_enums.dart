/// Context Memory — çekirdek enum'ları (Faz 1).
///
/// Tüm enum'lar güvenli parse eder: bilinmeyen değer uygulamayı çökertmez,
/// güvenli varsayılana düşer (şema evrimi + bozuk kalıcı veri toleransı).
library;

/// Bir memory kaydının kime/neye ait olduğu.
enum MemoryScope {
  session,
  userPrivate,
  memberPrivate,
  childPrivate,
  familyShared,
  module,
  deviceLocal;

  static MemoryScope parse(String? raw) => values.firstWhere(
        (e) => e.name == raw,
        orElse: () => MemoryScope.userPrivate, // en kısıtlayıcı güvenli varsayılan
      );

  /// Bulut senkronizasyonuna uygun mu? (deviceLocal ve session ASLA gitmez.)
  bool get isSyncable =>
      this != MemoryScope.deviceLocal && this != MemoryScope.session;

  /// Aile üyeleriyle paylaşılabilir mi?
  bool get isFamilyVisible => this == MemoryScope.familyShared;
}

/// Bilginin türü.
enum MemoryKind {
  profileFact,
  preference,
  routine,
  decision,
  goal,
  restriction,
  healthFact,
  medicationFact,
  financialFact,
  legalContext,
  locationContext,
  relationship,
  episodicEvent,
  conversationSummary,
  correction,
  feedback,
  externalKnowledge,
  derivedInsight;

  static MemoryKind parse(String? raw) => values.firstWhere(
        (e) => e.name == raw,
        orElse: () => MemoryKind.derivedInsight,
      );
}

/// Hassasiyet sınıfı — saklama, şifreleme ve bağlama ekleme kararlarını sürer.
enum MemorySensitivity {
  normal,
  private,
  confidential,
  financial,
  health,
  minorData,
  preciseLocation,
  legal,
  credential,
  prohibited;

  static MemorySensitivity parse(String? raw) => values.firstWhere(
        (e) => e.name == raw,
        orElse: () => MemorySensitivity.private,
      );

  /// Yerel depoda şifrelenmesi ZORUNLU mu?
  bool get requiresEncryption => this != MemorySensitivity.normal;

  /// Hiçbir koşulda saklanamaz (parola, token, API anahtarı, kart no).
  bool get isNeverStorable =>
      this == MemorySensitivity.credential ||
      this == MemorySensitivity.prohibited;

  /// Saklanması için kullanıcının açık hassas-veri izni gerekir mi?
  bool get requiresExplicitConsent =>
      this == MemorySensitivity.health ||
      this == MemorySensitivity.minorData ||
      this == MemorySensitivity.financial ||
      this == MemorySensitivity.preciseLocation ||
      this == MemorySensitivity.confidential;
}

/// Kaydın yaşam döngüsü durumu.
enum MemoryStatus {
  candidate,
  active,
  superseded,
  disputed,
  rejected,
  archived,
  expired,
  deleted;

  static MemoryStatus parse(String? raw) => values.firstWhere(
        (e) => e.name == raw,
        orElse: () => MemoryStatus.candidate,
      );

  /// AI bağlamına eklenmeye uygun mu? (superseded/disputed/rejected ASLA.)
  bool get isUsableInContext => this == MemoryStatus.active;
}

/// Bilginin nereden geldiği — çelişki çözümünde otorite sırası belirler.
enum MemorySourceType {
  userMessage,
  applicationEvent,
  profile,
  familyMember,
  moduleRecord,
  importedData,
  externalSource,
  aiDerived,
  userCorrection;

  static MemorySourceType parse(String? raw) => values.firstWhere(
        (e) => e.name == raw,
        orElse: () => MemorySourceType.aiDerived,
      );

  /// Çelişki çözüm önceliği (yüksek = daha güvenilir). Prompt §7.1 sırası.
  int get authority => switch (this) {
        MemorySourceType.userCorrection => 100,
        MemorySourceType.profile => 90,
        MemorySourceType.familyMember => 85,
        MemorySourceType.moduleRecord => 80,
        MemorySourceType.userMessage => 70,
        MemorySourceType.applicationEvent => 60,
        MemorySourceType.importedData => 50,
        MemorySourceType.externalSource => 30,
        MemorySourceType.aiDerived => 10,
      };
}

/// Senkronizasyon durumu (offline-first kuyruk).
enum MemorySyncState {
  localOnly,
  pendingCreate,
  pendingUpdate,
  pendingDelete,
  synced,
  conflict,
  failed;

  static MemorySyncState parse(String? raw) => values.firstWhere(
        (e) => e.name == raw,
        orElse: () => MemorySyncState.localOnly,
      );

  bool get needsSync =>
      this == MemorySyncState.pendingCreate ||
      this == MemorySyncState.pendingUpdate ||
      this == MemorySyncState.pendingDelete ||
      this == MemorySyncState.failed;
}

/// AI aksiyonunun gerçek yürütme durumu (prompt §3.3).
/// Memory sistemi kullanıcı NİYETİNİ gerçek SONUÇ ile karıştırmaz.
enum ActionExecutionStatus {
  notRequested,
  awaitingConfirmation,
  executing,
  succeeded,
  partiallySucceeded,
  failed,
  cancelled;

  static ActionExecutionStatus parse(String? raw) => values.firstWhere(
        (e) => e.name == raw,
        orElse: () => ActionExecutionStatus.notRequested,
      );

  /// Kullanıcıya "tamamlandı" gösterilebilir mi?
  bool get isRealSuccess => this == ActionExecutionStatus.succeeded;
}
