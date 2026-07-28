import 'package:flutter_test/flutter_test.dart';
import 'package:familyhub/features/context_memory/domain/memory_enums.dart';
import 'package:familyhub/features/context_memory/domain/memory_record.dart';
import 'package:familyhub/features/context_memory/domain/memory_retrieval.dart';

/// Context Memory Faz 5 — retrieval, sıralama, izin filtresi, token bütçesi.
void main() {
  final now = DateTime.utc(2026, 7, 18);

  MemoryRecord rec({
    String id = 'm1',
    String? owner = 'u1',
    String? childId,
    MemoryScope scope = MemoryScope.userPrivate,
    MemoryKind kind = MemoryKind.preference,
    MemorySensitivity sensitivity = MemorySensitivity.normal,
    MemoryStatus status = MemoryStatus.active,
    MemorySourceType source = MemorySourceType.userMessage,
    String key = 'food.disliked.mushroom',
    String content = 'mantar sevmiyor',
    String module = 'kitchen',
    double importance = 0.5,
    double confidence = 1.0,
    bool pinned = false,
    DateTime? updatedAt,
    DateTime? expiresAt,
    DateTime? deletedAt,
    List<String> allowed = const [],
    List<String> denied = const [],
  }) =>
      MemoryRecord(
        id: id,
        userId: owner,
        childId: childId,
        scope: scope,
        kind: kind,
        sensitivity: sensitivity,
        sourceType: source,
        status: status,
        module: module,
        key: key,
        title: 't',
        content: content,
        normalizedContent: content,
        createdAt: DateTime.utc(2026, 1, 1),
        updatedAt: updatedAt ?? DateTime.utc(2026, 7, 1),
        sourceId: 's',
        importance: importance,
        confidence: confidence,
        pinned: pinned,
        expiresAt: expiresAt,
        deletedAt: deletedAt,
        allowedUserIds: allowed,
        deniedUserIds: denied,
      );

  MemoryQuery q({
    String query = 'mantar',
    String viewer = 'u1',
    bool sameFamily = true,
    bool parentOrAdmin = false,
    Set<String> modules = const {},
    String? childId,
  }) =>
      MemoryQuery(
        normalizedQuery: query,
        viewerUserId: viewer,
        now: now,
        viewerIsSameFamily: sameFamily,
        viewerIsParentOrAdmin: parentOrAdmin,
        modules: modules,
        childId: childId,
      );

  group('izin filtresi — yetkisiz kayıt HİÇ dönmez', () {
    test('kendi özel kaydını görür', () {
      final r = retrieveAndRank(all: [rec()], query: q());
      expect(r.length, 1);
    });

    test('KRİTİK: başka yetişkinin özel kaydı görünmez', () {
      final r = retrieveAndRank(
          all: [rec(owner: 'u2')], query: q(viewer: 'u1'));
      expect(r, isEmpty);
    });

    test('familyShared kayıt aile üyesine görünür', () {
      final r = retrieveAndRank(
        all: [rec(owner: 'u2', scope: MemoryScope.familyShared)],
        query: q(viewer: 'u1', sameFamily: true),
      );
      expect(r.length, 1);
    });

    test('familyShared kayıt aile DIŞINA görünmez', () {
      final r = retrieveAndRank(
        all: [rec(owner: 'u2', scope: MemoryScope.familyShared)],
        query: q(viewer: 'x', sameFamily: false),
      );
      expect(r, isEmpty);
    });

    test('çocuk kaydı yalnızca ebeveyn/admin tarafından görünür', () {
      final child = rec(
          owner: 'u2', childId: 'c1', scope: MemoryScope.childPrivate);
      expect(
          retrieveAndRank(
              all: [child], query: q(viewer: 'u1', parentOrAdmin: false)),
          isEmpty);
      expect(
          retrieveAndRank(
              all: [child], query: q(viewer: 'u1', parentOrAdmin: true)).length,
          1);
    });

    test('denied listesi allowed listesini ezer', () {
      final r = retrieveAndRank(
        all: [
          rec(owner: 'u2', allowed: ['u1'], denied: ['u1'])
        ],
        query: q(viewer: 'u1'),
      );
      expect(r, isEmpty);
    });
  });

  group('durum ve süre filtresi', () {
    test('superseded kayıt bağlama girmez', () {
      expect(
          retrieveAndRank(
              all: [rec(status: MemoryStatus.superseded)], query: q()),
          isEmpty);
    });

    test('rejected kayıt bağlama girmez', () {
      expect(
          retrieveAndRank(
              all: [rec(status: MemoryStatus.rejected)], query: q()),
          isEmpty);
    });

    test('süresi dolmuş kayıt bağlama girmez', () {
      expect(
          retrieveAndRank(
              all: [rec(expiresAt: DateTime.utc(2026, 6, 1))], query: q()),
          isEmpty);
    });

    test('silinmiş kayıt bağlama girmez', () {
      expect(
          retrieveAndRank(
              all: [rec(deletedAt: DateTime.utc(2026, 6))], query: q()),
          isEmpty);
    });

    test('düşük güvenli kayıt bağlama girmez', () {
      expect(
          retrieveAndRank(all: [rec(confidence: 0.2)], query: q()), isEmpty);
    });
  });

  group('çocuk izolasyonu', () {
    test('KRİTİK: başka çocuğun kaydı istenen çocuk bağlamına girmez', () {
      final r = retrieveAndRank(
        all: [
          rec(id: 'a', childId: 'c1', scope: MemoryScope.childPrivate),
          rec(id: 'b', childId: 'c2', scope: MemoryScope.childPrivate),
        ],
        query: q(childId: 'c1', parentOrAdmin: true),
      );
      expect(r.length, 1);
      expect(r.first.record.childId, 'c1');
    });
  });

  group('sıralama', () {
    test('anahtar eşleşmesi içerik eşleşmesinden yüksek skorlar', () {
      final keyMatch = rec(id: 'k', key: 'mantar.x', content: 'baska');
      final contentMatch = rec(id: 'c', key: 'x.y', content: 'mantar var');
      final r = retrieveAndRank(all: [contentMatch, keyMatch], query: q());
      expect(r.first.record.id, 'k');
    });

    test('sabitlenmiş kayıt öne çıkar', () {
      final pinned = rec(id: 'p', pinned: true);
      final normal = rec(id: 'n');
      final r = retrieveAndRank(all: [normal, pinned], query: q());
      expect(r.first.record.id, 'p');
    });

    test('daha yeni kayıt daha yüksek skorlar', () {
      final fresh = rec(id: 'f', updatedAt: DateTime.utc(2026, 7, 17));
      final old = rec(id: 'o', updatedAt: DateTime.utc(2026, 1, 2));
      final r = retrieveAndRank(all: [old, fresh], query: q());
      expect(r.first.record.id, 'f');
    });

    test('modül yakınlığı skoru artırır', () {
      final inModule = rec(id: 'i', module: 'kitchen');
      final other = rec(id: 'o', module: 'finance');
      final r = retrieveAndRank(
          all: [other, inModule], query: q(modules: {'kitchen'}));
      expect(r.first.record.id, 'i');
    });
  });

  group('context packet — bütçe ve öncelik', () {
    test('sağlık kısıtı restrictions listesine gider', () {
      final ranked = retrieveAndRank(
        all: [
          rec(id: 'h', sensitivity: MemorySensitivity.health, content: 'alerji')
        ],
        query: q(query: 'alerji'),
      );
      final p = buildContextPacket(ranked: ranked);
      expect(p.restrictions.length, 1);
      expect(p.preferences, isEmpty);
    });

    test('tercih preferences listesine gider', () {
      final ranked =
          retrieveAndRank(all: [rec(kind: MemoryKind.preference)], query: q());
      final p = buildContextPacket(ranked: ranked);
      expect(p.preferences.length, 1);
    });

    test('disputed kayıt ayrı listede — kesin bilgi sayılmaz', () {
      // disputed canIncludeInContext'ten geçmez; doğrudan packet'e veriyoruz.
      final disputed = rec(id: 'd', status: MemoryStatus.disputed);
      final p = buildContextPacket(
          ranked: [MemorySearchResult(record: disputed, score: 1.0)]);
      expect(p.unresolvedConflicts.length, 1);
      expect(p.confirmedFacts, isEmpty);
      expect(p.preferences, isEmpty);
    });

    test('maxMemories bütçesi aşılmaz', () {
      final all = List.generate(30, (i) => rec(id: 'm$i'));
      final ranked = retrieveAndRank(all: all, query: q());
      final p = buildContextPacket(
          ranked: ranked, budget: const ContextBudget(maxMemories: 5));
      expect(p.totalIncluded, lessThanOrEqualTo(5));
      expect(p.droppedCount, greaterThan(0));
    });

    test('maxCharacters bütçesi aşılmaz', () {
      final all = List.generate(
          10, (i) => rec(id: 'm$i', content: 'x' * 100));
      final ranked = retrieveAndRank(all: all, query: q(query: ''));
      final p = buildContextPacket(
          ranked: ranked, budget: const ContextBudget(maxCharacters: 250));
      expect(p.usedCharacters, lessThanOrEqualTo(250));
    });

    test('boş sonuç boş packet verir (crash yok)', () {
      final p = buildContextPacket(ranked: const []);
      expect(p.isEmpty, isTrue);
      expect(p.totalIncluded, 0);
    });
  });
}
