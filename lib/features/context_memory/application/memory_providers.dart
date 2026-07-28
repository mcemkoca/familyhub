/// Context Memory — Faz 8: Riverpod provider'ları.
///
/// UI doğrudan Hive/Supabase çağırmaz; bu katmandan okur.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../services/auth_service.dart';
import '../domain/memory_enums.dart';
import '../domain/memory_record.dart';
import '../infrastructure/memory_repository.dart';

/// Aktif kullanıcının memory kayıtları (silinmiş hariç, yeni → eski).
final memoryRecordsProvider = Provider<List<MemoryRecord>>((ref) {
  final userId = AuthService.currentUserId;
  if (userId == null) return const [];
  final records = MemoryRepository.instance
      .recordsFor(userId)
      .where((r) => r.deletedAt == null && r.status != MemoryStatus.deleted)
      .toList()
    ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  return records;
});

/// Hafıza Merkezi sekmeleri.
enum MemoryTab { mine, family, children, preferences, derived, archive }

/// Seçili sekme.
final memoryTabProvider = StateProvider<MemoryTab>((ref) => MemoryTab.mine);

/// Arama metni.
final memorySearchProvider = StateProvider<String>((ref) => '');

/// Bir kaydın hangi sekmeye ait olduğunu belirler (saf — test edilebilir).
bool memoryMatchesTab(MemoryRecord r, MemoryTab tab) {
  return switch (tab) {
    MemoryTab.mine => r.scope == MemoryScope.userPrivate &&
        r.status == MemoryStatus.active,
    MemoryTab.family => (r.scope == MemoryScope.familyShared ||
            r.scope == MemoryScope.module) &&
        r.status == MemoryStatus.active,
    MemoryTab.children =>
      r.scope == MemoryScope.childPrivate && r.status == MemoryStatus.active,
    MemoryTab.preferences =>
      r.kind == MemoryKind.preference && r.status == MemoryStatus.active,
    // AI çıkarımları + çelişkiler: kullanıcı doğrulasın diye ayrı sekme.
    MemoryTab.derived => r.sourceType == MemorySourceType.aiDerived ||
        r.status == MemoryStatus.disputed,
    MemoryTab.archive => r.status == MemoryStatus.superseded ||
        r.status == MemoryStatus.archived ||
        r.status == MemoryStatus.expired ||
        r.status == MemoryStatus.rejected,
  };
}

/// Sekme + aramaya göre süzülmüş kayıtlar (saf yardımcı).
List<MemoryRecord> filterMemories({
  required List<MemoryRecord> all,
  required MemoryTab tab,
  required String query,
}) {
  final q = normalizeMemoryContent(query);
  return all.where((r) {
    if (!memoryMatchesTab(r, tab)) return false;
    if (q.isEmpty) return true;
    return r.normalizedContent.contains(q) ||
        r.key.contains(q) ||
        r.title.toLowerCase().contains(q) ||
        r.module.contains(q);
  }).toList();
}

/// Ekranda gösterilecek süzülmüş liste.
final filteredMemoriesProvider = Provider<List<MemoryRecord>>((ref) {
  return filterMemories(
    all: ref.watch(memoryRecordsProvider),
    tab: ref.watch(memoryTabProvider),
    query: ref.watch(memorySearchProvider),
  );
});
