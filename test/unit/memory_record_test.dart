import 'package:flutter_test/flutter_test.dart';
import 'package:familyhub/features/context_memory/domain/memory_enums.dart';
import 'package:familyhub/features/context_memory/domain/memory_record.dart';
import 'package:familyhub/features/context_memory/infrastructure/memory_keyspace.dart';

/// Context Memory Faz 2 — kayıt modeli + kullanıcı izolasyonu testleri.
void main() {
  MemoryRecord rec({
    String id = 'm1',
    String? userId = 'u1',
    String? childId,
    MemoryScope scope = MemoryScope.userPrivate,
    String key = 'food.disliked.mushroom',
    String module = 'kitchen',
    DateTime? expiresAt,
  }) =>
      MemoryRecord(
        id: id,
        userId: userId,
        childId: childId,
        scope: scope,
        kind: MemoryKind.preference,
        sensitivity: MemorySensitivity.normal,
        sourceType: MemorySourceType.userMessage,
        status: MemoryStatus.active,
        module: module,
        key: key,
        title: 'Mantar sevmiyor',
        content: 'Kullanıcı mantar sevmiyor.',
        normalizedContent: 'kullanici mantar sevmiyor.',
        createdAt: DateTime.utc(2026, 1, 1),
        updatedAt: DateTime.utc(2026, 1, 1),
        sourceId: 'msg_1',
        expiresAt: expiresAt,
      );

  group('serialization', () {
    test('json round-trip tüm kritik alanları korur', () {
      final r = rec().copyWith(
        confidence: 0.8,
        importance: 0.9,
        pinned: true,
        encrypted: true,
        syncState: MemorySyncState.pendingCreate,
        supersedesMemoryIds: ['old1'],
      );
      final back = MemoryRecord.fromJson(r.toJson());
      expect(back.id, 'm1');
      expect(back.confidence, 0.8);
      expect(back.pinned, isTrue);
      expect(back.encrypted, isTrue);
      expect(back.syncState, MemorySyncState.pendingCreate);
      expect(back.supersedesMemoryIds, ['old1']);
      expect(back.scope, MemoryScope.userPrivate);
    });

    test('bozuk/eksik alanlar güvenli varsayılana düşer (crash yok)', () {
      final back = MemoryRecord.fromJson({'id': 'x'});
      expect(back.id, 'x');
      expect(back.scope, MemoryScope.userPrivate); // güvenli varsayılan
      expect(back.status, MemoryStatus.candidate);
      expect(back.confidence, 1.0);
      expect(back.module, 'unknown');
    });

    test('bilinmeyen enum değerleri güvenli parse edilir', () {
      final back = MemoryRecord.fromJson({
        'id': 'x',
        'scope': 'martian',
        'kind': 'unknown_kind',
        'sensitivity': 'xx',
        'status': 'zz',
      });
      expect(back.scope, MemoryScope.userPrivate);
      expect(back.kind, MemoryKind.derivedInsight);
      expect(back.sensitivity, MemorySensitivity.private);
      expect(back.status, MemoryStatus.candidate);
    });
  });

  group('dedup ve süre', () {
    test('aynı kapsam+modül+anahtar+özne aynı dedupKey verir', () {
      expect(rec(id: 'a').dedupKey, rec(id: 'b').dedupKey);
    });

    test('farklı çocuk farklı dedupKey verir (çocuk karışmaz)', () {
      final a = rec(childId: 'c1', scope: MemoryScope.childPrivate);
      final b = rec(childId: 'c2', scope: MemoryScope.childPrivate);
      expect(a.dedupKey, isNot(b.dedupKey));
    });

    test('süresi dolmuş kayıt tespit edilir', () {
      final r = rec(expiresAt: DateTime.utc(2026, 1, 5));
      expect(r.isExpiredAt(DateTime.utc(2026, 1, 10)), isTrue);
      expect(r.isExpiredAt(DateTime.utc(2026, 1, 2)), isFalse);
    });

    test('expiresAt yoksa süresiz', () {
      expect(rec().isExpiredAt(DateTime.utc(2099)), isFalse);
    });
  });

  group('normalizeMemoryContent', () {
    test('Türkçe aksanları sadeleştirir', () {
      expect(normalizeMemoryContent('Yer Fıstığı ALERJİSİ'),
          'yer fistigi alerjisi');
    });

    test('Fransızca aksanları sadeleştirir', () {
      expect(normalizeMemoryContent('Allergie aux arachides — été'),
          'allergie aux arachides — ete');
    });

    test('fazla boşlukları temizler', () {
      expect(normalizeMemoryContent('  a    b  '), 'a b');
    });
  });

  group('KULLANICI İZOLASYONU (hesap değişimi sızıntısı)', () {
    test('anahtar sahibi doğru çıkarılır', () {
      final k = MemoryKeyspace.buildKey(userId: 'u1', recordId: 'm1');
      expect(MemoryKeyspace.ownerOf(k), 'u1');
      expect(MemoryKeyspace.recordIdOf(k), 'm1');
    });

    test('KRİTİK: kullanıcı A kaydı kullanıcı B için okunmaz', () {
      final k = MemoryKeyspace.buildKey(userId: 'userA', recordId: 'm1');
      expect(MemoryKeyspace.belongsTo(k, 'userA'), isTrue);
      expect(MemoryKeyspace.belongsTo(k, 'userB'), isFalse);
    });

    test('oturumsuz (anon) kayıt gerçek kullanıcıya görünmez', () {
      final k = MemoryKeyspace.buildKey(userId: null, recordId: 'm1');
      expect(MemoryKeyspace.belongsTo(k, null), isTrue);
      expect(MemoryKeyspace.belongsTo(k, 'userA'), isFalse);
    });

    test('filterKeys yalnızca sahibin anahtarlarını verir', () {
      final keys = [
        MemoryKeyspace.buildKey(userId: 'a', recordId: '1'),
        MemoryKeyspace.buildKey(userId: 'b', recordId: '2'),
        MemoryKeyspace.buildKey(userId: 'a', recordId: '3'),
      ];
      final mine = MemoryKeyspace.filterKeys(keys, 'a');
      expect(mine.length, 2);
      expect(mine.every((k) => MemoryKeyspace.belongsTo(k, 'a')), isTrue);
    });

    test('bozuk anahtar hiçbir kullanıcıya ait sayılmaz (güvenli)', () {
      expect(MemoryKeyspace.belongsTo('bozuk-anahtar', 'a'), isFalse);
      expect(MemoryKeyspace.ownerOf('bozuk'), isNull);
    });

    test('recordId içinde ayraç olsa bile sahip doğru kalır', () {
      final k = MemoryKeyspace.buildKey(userId: 'u1', recordId: 'a|b');
      expect(MemoryKeyspace.ownerOf(k), 'u1');
      expect(MemoryKeyspace.recordIdOf(k), 'a|b');
    });

    test('prefix taraması sahibe özeldir', () {
      expect(MemoryKeyspace.prefixFor('u1'), 'u:u1|');
      expect(MemoryKeyspace.prefixFor(null), 'u:_anon|');
    });
  });

  group('box adları merkezi', () {
    test('tüm box adları versiyonlu ve benzersiz', () {
      expect(MemoryBoxes.all.toSet().length, MemoryBoxes.all.length);
      expect(MemoryBoxes.all.every((b) => b.endsWith('_v1')), isTrue);
    });
  });
}
