import 'package:flutter_test/flutter_test.dart';
import 'package:familyhub/features/context_memory/domain/memory_enums.dart';
import 'package:familyhub/features/context_memory/domain/memory_event.dart';
import 'package:familyhub/features/context_memory/domain/memory_reconciler.dart';
import 'package:familyhub/features/context_memory/domain/memory_record.dart';

/// Context Memory Faz 4 — ingestion pipeline (scope, hassasiyet, önem,
/// dedup, çelişki, unut) testleri.
void main() {
  group('resolveScope — kapsam sızıntısı önleme', () {
    test('çocuk verisi childPrivate olur (aileye sızmaz)', () {
      expect(
        resolveScope(
            childId: 'c1',
            memberId: 'm1',
            familyId: 'f1',
            sharedWithFamily: true),
        MemoryScope.childPrivate,
      );
    });

    test('üye verisi memberPrivate olur', () {
      expect(
        resolveScope(
            childId: null,
            memberId: 'm1',
            familyId: 'f1',
            sharedWithFamily: true),
        MemoryScope.memberPrivate,
      );
    });

    test('açıkça paylaşılan aile verisi familyShared olur', () {
      expect(
        resolveScope(
            childId: null,
            memberId: null,
            familyId: 'f1',
            sharedWithFamily: true),
        MemoryScope.familyShared,
      );
    });

    test('varsayılan userPrivate — otomatik aileye açılmaz', () {
      expect(
        resolveScope(
            childId: null,
            memberId: null,
            familyId: 'f1',
            sharedWithFamily: false),
        MemoryScope.userPrivate,
      );
    });
  });

  group('classifySensitivity — koruyucu sınıflandırma', () {
    test('KRİTİK: şifre/token içeriği credential → asla saklanmaz', () {
      final s = classifySensitivity(
          module: 'ai', normalizedContent: 'sifre 1234 olsun');
      expect(s, MemorySensitivity.credential);
      expect(s.isNeverStorable, isTrue);
    });

    test('IBAN/kart bilgisi credential sayılır', () {
      expect(
          classifySensitivity(
              module: 'finance', normalizedContent: 'iban be68 5390'),
          MemorySensitivity.credential);
    });

    test('sağlık modülü health olur', () {
      expect(
          classifySensitivity(module: 'health', normalizedContent: 'kontrol'),
          MemorySensitivity.health);
    });

    test('ÇOCUK sağlık verisi minorData (daha korumalı)', () {
      expect(
          classifySensitivity(
              module: 'health', normalizedContent: 'kontrol', childId: 'c1'),
          MemorySensitivity.minorData);
    });

    test('alerji içeriği normal modülde bile sağlık sayılır', () {
      expect(
          classifySensitivity(
              module: 'kitchen', normalizedContent: 'yer fistigi alerjisi var'),
          MemorySensitivity.health);
    });

    test('çocuğa ait her kayıt en az minorData', () {
      expect(
          classifySensitivity(
              module: 'kitchen',
              normalizedContent: 'brokoli sevmiyor',
              childId: 'c1'),
          MemorySensitivity.minorData);
    });

    test('finans/konum/hukuk modülleri doğru sınıflanır', () {
      expect(classifySensitivity(module: 'finance', normalizedContent: 'x'),
          MemorySensitivity.financial);
      expect(classifySensitivity(module: 'location', normalizedContent: 'x'),
          MemorySensitivity.preciseLocation);
      expect(classifySensitivity(module: 'legal', normalizedContent: 'x'),
          MemorySensitivity.legal);
    });

    test('sıradan mutfak tercihi normal kalır', () {
      expect(
          classifySensitivity(
              module: 'kitchen', normalizedContent: 'mantar sevmiyor'),
          MemorySensitivity.normal);
    });
  });

  group('scoreImportance', () {
    double s({
      bool explicit = false,
      bool confirmed = false,
      int recurrence = 0,
      bool crossModule = false,
      bool temporary = false,
      double confidence = 1.0,
      MemorySensitivity sensitivity = MemorySensitivity.normal,
    }) =>
        scoreImportance(
          explicitRememberRequest: explicit,
          confirmed: confirmed,
          recurrenceCount: recurrence,
          crossModule: crossModule,
          temporary: temporary,
          confidence: confidence,
          sensitivity: sensitivity,
        );

    test('açık "hatırla" isteği önemi yükseltir', () {
      expect(s(explicit: true), greaterThan(s()));
    });

    test('geçici bilgi önemi düşürür', () {
      expect(s(temporary: true), lessThan(s()));
    });

    test('belirsizlik önemi düşürür', () {
      expect(s(confidence: 0.5), lessThan(s(confidence: 1.0)));
    });

    test('tekrar önemi yükseltir', () {
      expect(s(recurrence: 4), greaterThan(s(recurrence: 0)));
    });

    test('hassas veri otomatik olarak en önemli sayılmaz', () {
      expect(s(sensitivity: MemorySensitivity.health), lessThan(s()));
    });

    test('skor daima 0..1 aralığında', () {
      final hi = s(
          explicit: true,
          confirmed: true,
          recurrence: 99,
          crossModule: true);
      final lo = s(temporary: true, confidence: 0.0);
      expect(hi, inInclusiveRange(0.0, 1.0));
      expect(lo, inInclusiveRange(0.0, 1.0));
    });
  });

  group('reconcile — dedup ve çelişki', () {
    MemoryRecord existing({
      String id = 'old1',
      String content = 'kullanici mantar sevmiyor',
      MemorySourceType source = MemorySourceType.userMessage,
      MemoryStatus status = MemoryStatus.active,
    }) =>
        MemoryRecord(
          id: id,
          userId: 'u1',
          scope: MemoryScope.userPrivate,
          kind: MemoryKind.preference,
          sensitivity: MemorySensitivity.normal,
          sourceType: source,
          status: status,
          module: 'kitchen',
          key: 'food.disliked.mushroom',
          title: 't',
          content: content,
          normalizedContent: content,
          createdAt: DateTime.utc(2026),
          updatedAt: DateTime.utc(2026),
          sourceId: 's1',
        );

    MemoryCandidate cand({
      MemorySourceType source = MemorySourceType.userMessage,
    }) =>
        MemoryCandidate(
          kind: MemoryKind.preference,
          scope: MemoryScope.userPrivate,
          sensitivity: MemorySensitivity.normal,
          sourceType: source,
          module: 'kitchen',
          key: 'food.disliked.mushroom',
          title: 't',
          content: 'x',
        );

    test('mevcut kayıt yoksa create', () {
      final d = reconcile(
          candidate: cand(),
          existing: const [],
          candidateNormalizedContent: 'yeni');
      expect(d.action, ReconcileAction.create);
    });

    test('AYNI içerik duplicate üretmez', () {
      final d = reconcile(
        candidate: cand(),
        existing: [existing()],
        candidateNormalizedContent: 'kullanici mantar sevmiyor',
      );
      expect(d.action, ReconcileAction.skipDuplicate);
    });

    test('KULLANICI DÜZELTMESİ eski kaydı supersede eder (silmez)', () {
      final d = reconcile(
        candidate: cand(source: MemorySourceType.userCorrection),
        existing: [existing()],
        candidateNormalizedContent: 'farkli deger',
      );
      expect(d.action, ReconcileAction.supersede);
      expect(d.targetMemoryId, 'old1');
    });

    test('AI çıkarımı kullanıcı beyanını EZEMEZ → disputed', () {
      final d = reconcile(
        candidate: cand(source: MemorySourceType.aiDerived),
        existing: [existing(source: MemorySourceType.userMessage)],
        candidateNormalizedContent: 'farkli deger',
      );
      expect(d.action, ReconcileAction.dispute);
    });

    test('aynı otorite → güncelle', () {
      final d = reconcile(
        candidate: cand(source: MemorySourceType.userMessage),
        existing: [existing(source: MemorySourceType.userMessage)],
        candidateNormalizedContent: 'farkli deger',
      );
      expect(d.action, ReconcileAction.update);
    });

    test('superseded kayıtlar çelişki sayılmaz', () {
      final d = reconcile(
        candidate: cand(),
        existing: [existing(status: MemoryStatus.superseded)],
        candidateNormalizedContent: 'yeni',
      );
      expect(d.action, ReconcileAction.create);
    });

    test('markSuperseded silmez, durumu değiştirir', () {
      final r = markSuperseded(existing(), now: DateTime.utc(2026, 6));
      expect(r.status, MemoryStatus.superseded);
      expect(r.deletedAt, isNull); // SİLİNMEDİ — audit korunur
      expect(r.syncState, MemorySyncState.pendingUpdate);
    });

    test('linkSupersedes ilişki kurar', () {
      final r = linkSupersedes(existing(id: 'new1'), ['old1', 'old2']);
      expect(r.supersedesMemoryIds, containsAll(['old1', 'old2']));
    });
  });

  group('selectForForget — "bunu unut" güvenliği', () {
    MemoryRecord rec(String id, String owner, String content) => MemoryRecord(
          id: id,
          userId: owner,
          scope: MemoryScope.userPrivate,
          kind: MemoryKind.preference,
          sensitivity: MemorySensitivity.normal,
          sourceType: MemorySourceType.userMessage,
          status: MemoryStatus.active,
          module: 'kitchen',
          key: 'k',
          title: 't',
          content: content,
          normalizedContent: content,
          createdAt: DateTime.utc(2026),
          updatedAt: DateTime.utc(2026),
          sourceId: 's',
        );

    test('kendi kaydını unutabilir', () {
      final found = selectForForget(
        candidates: [rec('1', 'u1', 'mantar sevmiyorum')],
        requesterUserId: 'u1',
        normalizedQuery: 'mantar',
      );
      expect(found.length, 1);
    });

    test('KRİTİK: başkasının kaydını unutturamaz', () {
      final found = selectForForget(
        candidates: [rec('1', 'u2', 'mantar sevmiyorum')],
        requesterUserId: 'u1',
        normalizedQuery: 'mantar',
      );
      expect(found, isEmpty);
    });

    test('boş sorgu hiçbir şey silmez (kaza koruması)', () {
      final found = selectForForget(
        candidates: [rec('1', 'u1', 'mantar')],
        requesterUserId: 'u1',
        normalizedQuery: '   ',
      );
      expect(found, isEmpty);
    });
  });
}
