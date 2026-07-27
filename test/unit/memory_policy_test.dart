import 'package:flutter_test/flutter_test.dart';
import 'package:familyhub/features/context_memory/domain/memory_enums.dart';
import 'package:familyhub/features/context_memory/domain/memory_policy.dart';

/// Context Memory Faz 1 — politika testleri.
/// Prompt §3 (temel kurallar), §7 (çelişki), §8 (retention), §10.2 (gizlilik),
/// §11 (consent) senaryolarını kilitler.
void main() {
  MemoryPolicyDecision decide({
    MemoryKind kind = MemoryKind.preference,
    MemorySensitivity sensitivity = MemorySensitivity.normal,
    MemoryScope scope = MemoryScope.userPrivate,
    MemorySourceType source = MemorySourceType.userMessage,
    double confidence = 1.0,
    String module = 'kitchen',
    MemoryConsentSnapshot? consent,
    bool explicitRemember = false,
  }) =>
      evaluateStoragePolicy(
        kind: kind,
        sensitivity: sensitivity,
        scope: scope,
        sourceType: source,
        confidence: confidence,
        module: module,
        consent: consent ?? const MemoryConsentSnapshot(),
        explicitRememberRequest: explicitRemember,
      );

  group('§3.1 — mutlak yasaklar', () {
    test('credential ASLA saklanmaz (consent açık olsa bile)', () {
      final d = decide(
        sensitivity: MemorySensitivity.credential,
        consent: const MemoryConsentSnapshot(sensitiveMemoryEnabled: true),
      );
      expect(d.allowed, isFalse);
      expect(d.reason, contains('never_stored'));
    });

    test('prohibited ASLA saklanmaz', () {
      expect(decide(sensitivity: MemorySensitivity.prohibited).allowed, isFalse);
    });
  });

  group('§11 — consent', () {
    test('memory kapalıysa hiçbir şey saklanmaz', () {
      expect(decide(consent: MemoryConsentSnapshot.disabled).allowed, isFalse);
    });

    test('sohbet çıkarımı kapalı → normal mesaj saklanmaz', () {
      final d = decide(
        consent: const MemoryConsentSnapshot(
            conversationExtractionEnabled: false),
      );
      expect(d.allowed, isFalse);
    });

    test('sohbet çıkarımı kapalı AMA "bunu hatırla" dediyse saklanır', () {
      final d = decide(
        consent: const MemoryConsentSnapshot(
            conversationExtractionEnabled: false),
        explicitRemember: true,
      );
      expect(d.allowed, isTrue);
    });

    test('hassas veri izni yoksa sağlık bilgisi saklanmaz', () {
      final d = decide(
        kind: MemoryKind.healthFact,
        sensitivity: MemorySensitivity.health,
      );
      expect(d.allowed, isFalse);
      expect(d.reason, contains('sensitive_memory_consent_missing'));
    });

    test('hassas izin açıkken sağlık saklanır ve ŞİFRELENİR', () {
      final d = decide(
        kind: MemoryKind.healthFact,
        sensitivity: MemorySensitivity.health,
        consent: const MemoryConsentSnapshot(sensitiveMemoryEnabled: true),
      );
      expect(d.allowed, isTrue);
      expect(d.requiresEncryption, isTrue);
    });

    test('modül kapalıysa o modülün kaydı saklanmaz', () {
      final d = decide(
        module: 'health',
        consent: const MemoryConsentSnapshot(enabledModules: {'kitchen'}),
      );
      expect(d.allowed, isFalse);
    });
  });

  group('§3.2 — AI çıkarımı gerçek bilgi değildir', () {
    test('düşük güvenli aiDerived saklanmaz', () {
      final d = decide(source: MemorySourceType.aiDerived, confidence: 0.5);
      expect(d.allowed, isFalse);
      expect(d.reason, 'derived_low_confidence');
    });

    test('yüksek güvenli aiDerived saklanabilir', () {
      expect(decide(source: MemorySourceType.aiDerived, confidence: 0.9).allowed,
          isTrue);
    });
  });

  group('§8 — retention', () {
    test('kesin konum en kısa sürede unutulur (24s)', () {
      final r = defaultRetention(
          kind: MemoryKind.locationContext,
          sensitivity: MemorySensitivity.preciseLocation);
      expect(r, const Duration(hours: 24));
    });

    test('doğrulanmış tercih süresizdir', () {
      expect(
          defaultRetention(
              kind: MemoryKind.preference,
              sensitivity: MemorySensitivity.normal),
          isNull);
    });

    test('harici bilgi kısa ömürlüdür', () {
      expect(
          defaultRetention(
              kind: MemoryKind.externalKnowledge,
              sensitivity: MemorySensitivity.normal),
          const Duration(days: 7));
    });
  });

  group('§7.1 — çelişki çözümü', () {
    final t0 = DateTime.utc(2026, 1, 1);
    final t1 = DateTime.utc(2026, 6, 1);

    test('kullanıcı düzeltmesi AI çıkarımını ezer', () {
      expect(
          newRecordSupersedes(
            existingSource: MemorySourceType.aiDerived,
            existingUpdatedAt: t1,
            incomingSource: MemorySourceType.userCorrection,
            incomingUpdatedAt: t0, // daha ESKİ ama otoritesi yüksek
          ),
          isTrue);
    });

    test('AI çıkarımı kullanıcı düzeltmesini EZEMEZ', () {
      expect(
          newRecordSupersedes(
            existingSource: MemorySourceType.userCorrection,
            existingUpdatedAt: t0,
            incomingSource: MemorySourceType.aiDerived,
            incomingUpdatedAt: t1,
          ),
          isFalse);
    });

    test('aynı otoritede daha yeni kazanır', () {
      expect(
          newRecordSupersedes(
            existingSource: MemorySourceType.userMessage,
            existingUpdatedAt: t0,
            incomingSource: MemorySourceType.userMessage,
            incomingUpdatedAt: t1,
          ),
          isTrue);
    });
  });

  group('§25 — bağlama ekleme kontrolü', () {
    test('superseded kayıt bağlama EKLENMEZ', () {
      expect(
          canIncludeInContext(
            status: MemoryStatus.superseded,
            sensitivity: MemorySensitivity.normal,
            confidence: 1.0,
            viewerHasAccess: true,
          ),
          isFalse);
    });

    test('disputed kayıt bağlama EKLENMEZ', () {
      expect(
          canIncludeInContext(
            status: MemoryStatus.disputed,
            sensitivity: MemorySensitivity.normal,
            confidence: 1.0,
            viewerHasAccess: true,
          ),
          isFalse);
    });

    test('süresi dolmuş kayıt EKLENMEZ', () {
      expect(
          canIncludeInContext(
            status: MemoryStatus.active,
            sensitivity: MemorySensitivity.normal,
            confidence: 1.0,
            viewerHasAccess: true,
            expiresAt: DateTime.utc(2026, 1, 1),
            now: DateTime.utc(2026, 6, 1),
          ),
          isFalse);
    });

    test('erişimi olmayan izleyici için EKLENMEZ', () {
      expect(
          canIncludeInContext(
            status: MemoryStatus.active,
            sensitivity: MemorySensitivity.normal,
            confidence: 1.0,
            viewerHasAccess: false,
          ),
          isFalse);
    });

    test('geçerli aktif kayıt eklenir', () {
      expect(
          canIncludeInContext(
            status: MemoryStatus.active,
            sensitivity: MemorySensitivity.normal,
            confidence: 0.9,
            viewerHasAccess: true,
          ),
          isTrue);
    });
  });

  group('§10.2 — gizlilik / erişim', () {
    test('kendi özel kaydını görür', () {
      expect(
          viewerCanAccess(
            scope: MemoryScope.userPrivate,
            ownerUserId: 'u1',
            viewerUserId: 'u1',
            viewerIsSameFamily: true,
            viewerIsParentOrAdmin: true,
          ),
          isTrue);
    });

    test('başka yetişkinin özel kaydını GÖREMEZ (aynı ailede bile)', () {
      expect(
          viewerCanAccess(
            scope: MemoryScope.userPrivate,
            ownerUserId: 'u1',
            viewerUserId: 'u2',
            viewerIsSameFamily: true,
            viewerIsParentOrAdmin: true,
          ),
          isFalse);
    });

    test('familyShared aile üyesine görünür', () {
      expect(
          viewerCanAccess(
            scope: MemoryScope.familyShared,
            ownerUserId: 'u1',
            viewerUserId: 'u2',
            viewerIsSameFamily: true,
            viewerIsParentOrAdmin: false,
          ),
          isTrue);
    });

    test('familyShared BAŞKA aileye görünmez (izolasyon)', () {
      expect(
          viewerCanAccess(
            scope: MemoryScope.familyShared,
            ownerUserId: 'u1',
            viewerUserId: 'dis_kullanici',
            viewerIsSameFamily: false,
            viewerIsParentOrAdmin: true,
          ),
          isFalse);
    });

    test('çocuk kaydını yalnızca ebeveyn/admin görür', () {
      expect(
          viewerCanAccess(
            scope: MemoryScope.childPrivate,
            ownerUserId: 'child1',
            viewerUserId: 'parent',
            viewerIsSameFamily: true,
            viewerIsParentOrAdmin: true,
          ),
          isTrue);
      expect(
          viewerCanAccess(
            scope: MemoryScope.childPrivate,
            ownerUserId: 'child1',
            viewerUserId: 'baska_uye',
            viewerIsSameFamily: true,
            viewerIsParentOrAdmin: false,
          ),
          isFalse);
    });

    test('deniedUserIds allowedUserIds üzerinde önceliklidir', () {
      expect(
          viewerCanAccess(
            scope: MemoryScope.familyShared,
            ownerUserId: 'u1',
            viewerUserId: 'u2',
            viewerIsSameFamily: true,
            viewerIsParentOrAdmin: true,
            allowedUserIds: const ['u2'],
            deniedUserIds: const ['u2'],
          ),
          isFalse);
    });
  });

  group('enum güvenli parse + davranış', () {
    test('bilinmeyen değer güvenli varsayılana düşer', () {
      expect(MemoryScope.parse('martian'), MemoryScope.userPrivate);
      expect(MemoryStatus.parse(null), MemoryStatus.candidate);
      expect(MemorySensitivity.parse('xx'), MemorySensitivity.private);
    });

    test('deviceLocal ve session senkronize EDİLMEZ', () {
      expect(MemoryScope.deviceLocal.isSyncable, isFalse);
      expect(MemoryScope.session.isSyncable, isFalse);
      expect(MemoryScope.familyShared.isSyncable, isTrue);
    });

    test('ActionExecutionStatus yalnızca succeeded gerçek başarıdır', () {
      expect(ActionExecutionStatus.succeeded.isRealSuccess, isTrue);
      for (final s in [
        ActionExecutionStatus.executing,
        ActionExecutionStatus.awaitingConfirmation,
        ActionExecutionStatus.partiallySucceeded,
        ActionExecutionStatus.failed,
        ActionExecutionStatus.cancelled,
      ]) {
        expect(s.isRealSuccess, isFalse, reason: s.name);
      }
    });
  });
}
