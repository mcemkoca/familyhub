import 'package:flutter_test/flutter_test.dart';
import 'package:familyhub/features/context_memory/application/memory_providers.dart';
import 'package:familyhub/features/context_memory/domain/memory_enums.dart';
import 'package:familyhub/features/context_memory/domain/memory_record.dart';

/// Context Memory Faz 8 — Hafıza Merkezi sekme/arama filtreleri.
void main() {
  MemoryRecord rec({
    String id = 'm1',
    MemoryScope scope = MemoryScope.userPrivate,
    MemoryKind kind = MemoryKind.preference,
    MemoryStatus status = MemoryStatus.active,
    MemorySourceType source = MemorySourceType.userMessage,
    String content = 'mantar sevmiyor',
    String module = 'kitchen',
    String key = 'food.disliked.mushroom',
  }) =>
      MemoryRecord(
        id: id,
        userId: 'u1',
        scope: scope,
        kind: kind,
        sensitivity: MemorySensitivity.normal,
        sourceType: source,
        status: status,
        module: module,
        key: key,
        title: 'Tercih',
        content: content,
        normalizedContent: content,
        createdAt: DateTime.utc(2026),
        updatedAt: DateTime.utc(2026),
        sourceId: 's',
      );

  group('sekme eşleşmesi', () {
    test('Benim sekmesi yalnızca kişisel aktif kayıtları gösterir', () {
      expect(memoryMatchesTab(rec(), MemoryTab.mine), isTrue);
      expect(
          memoryMatchesTab(
              rec(scope: MemoryScope.familyShared), MemoryTab.mine),
          isFalse);
    });

    test('Aile sekmesi paylaşılan kayıtları gösterir', () {
      expect(
          memoryMatchesTab(
              rec(scope: MemoryScope.familyShared), MemoryTab.family),
          isTrue);
      expect(memoryMatchesTab(rec(), MemoryTab.family), isFalse);
    });

    test('Çocuklar sekmesi yalnızca çocuk kapsamını gösterir', () {
      expect(
          memoryMatchesTab(
              rec(scope: MemoryScope.childPrivate), MemoryTab.children),
          isTrue);
      expect(memoryMatchesTab(rec(), MemoryTab.children), isFalse);
    });

    test('KRİTİK: AI çıkarımları ayrı sekmede (kullanıcı doğrulasın)', () {
      expect(
          memoryMatchesTab(
              rec(source: MemorySourceType.aiDerived), MemoryTab.derived),
          isTrue);
      expect(memoryMatchesTab(rec(), MemoryTab.derived), isFalse);
    });

    test('çelişkili kayıt da AI Çıkarımları sekmesinde görünür', () {
      expect(
          memoryMatchesTab(
              rec(status: MemoryStatus.disputed), MemoryTab.derived),
          isTrue);
    });

    test('superseded/rejected kayıtlar Arşiv sekmesinde', () {
      expect(
          memoryMatchesTab(
              rec(status: MemoryStatus.superseded), MemoryTab.archive),
          isTrue);
      expect(
          memoryMatchesTab(
              rec(status: MemoryStatus.rejected), MemoryTab.archive),
          isTrue);
      expect(memoryMatchesTab(rec(), MemoryTab.archive), isFalse);
    });

    test('KRİTİK: superseded kayıt aktif sekmelerde GÖRÜNMEZ', () {
      final old = rec(status: MemoryStatus.superseded);
      expect(memoryMatchesTab(old, MemoryTab.mine), isFalse);
      expect(memoryMatchesTab(old, MemoryTab.preferences), isFalse);
    });
  });

  group('arama', () {
    // normalizedContent pipeline'da normalizeMemoryContent ile üretilir;
    // burada gerçek davranışı taklit ediyoruz (aksansız, küçük harf).
    final all = [
      rec(id: 'a', content: 'mantar sevmiyor'),
      rec(id: 'b', content: 'brokoli seviyor', key: 'food.liked.broccoli'),
      rec(
        id: 'c',
        content: 'yer fistigi alerjisi',
        module: 'health',
      ),
    ];

    test('boş sorgu tüm sekme kayıtlarını verir', () {
      final r = filterMemories(all: all, tab: MemoryTab.mine, query: '');
      expect(r.length, 3);
    });

    test('içerikte arama çalışır', () {
      final r = filterMemories(all: all, tab: MemoryTab.mine, query: 'brokoli');
      expect(r.single.id, 'b');
    });

    test('kanonik anahtarda arama çalışır', () {
      final r =
          filterMemories(all: all, tab: MemoryTab.mine, query: 'broccoli');
      expect(r.single.id, 'b');
    });

    test('modülde arama çalışır', () {
      final r = filterMemories(all: all, tab: MemoryTab.mine, query: 'health');
      expect(r.single.id, 'c');
    });

    test('Türkçe aksan duyarsız arama', () {
      final r =
          filterMemories(all: all, tab: MemoryTab.mine, query: 'YER FISTIGI');
      expect(r.single.id, 'c');
    });

    test('eşleşme yoksa boş liste (crash yok)', () {
      final r = filterMemories(all: all, tab: MemoryTab.mine, query: 'xyzzy');
      expect(r, isEmpty);
    });

    test('sekme filtresi arama ile birlikte uygulanır', () {
      final withArchived = [...all, rec(id: 'd', content: 'mantar eski', status: MemoryStatus.superseded)];
      final mine =
          filterMemories(all: withArchived, tab: MemoryTab.mine, query: 'mantar');
      expect(mine.single.id, 'a'); // arşivdeki 'd' gelmez
      final archive = filterMemories(
          all: withArchived, tab: MemoryTab.archive, query: 'mantar');
      expect(archive.single.id, 'd');
    });
  });
}
