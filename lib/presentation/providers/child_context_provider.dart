import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/child_account.dart';
import '../../repositories/child_account_repository.dart';
import '../../services/auth_service.dart';
import '../../services/hive_service.dart';
import 'app_providers.dart';

/// Merkezi AKTİF ÇOCUK context'i.
///
/// Sorun: her ekran kendi lokal `_selectedChild`'ını tutuyordu; seçilen çocuk
/// bölümler arasında paylaşılmıyordu. Bu katman tek kaynaktır: aile çocukları
/// yüklenir, seçili çocuk kullanıcı-izole Hive'da saklanır ve tüm bölümler
/// aynı çocuğu okur.
///
/// Kullanım:
///   final child = ref.watch(activeChildProvider);           // ChildAccount?
///   ref.read(activeChildIdProvider.notifier).select(id);    // seçimi değiştir

/// Aktif ailedeki çocuk hesapları (familyId değişince yeniden yüklenir).
final familyChildrenProvider = FutureProvider<List<ChildAccount>>((ref) async {
  final familyId = await ref.watch(familyIdProvider.future) ??
      ChildAccountRepository.localFamilyId;
  return ChildAccountRepository().getChildrenForFamily(familyId);
});

/// Seçili çocuk id'si — kullanıcı-izole, kalıcı (Hive). null → "ilk çocuk".
final activeChildIdProvider =
    StateNotifierProvider<ActiveChildIdNotifier, String?>((ref) {
  return ActiveChildIdNotifier();
});

class ActiveChildIdNotifier extends StateNotifier<String?> {
  ActiveChildIdNotifier() : super(_read());

  static String get _key {
    final uid = AuthService.currentUserId ?? 'anon';
    return 'active_child_$uid';
  }

  static String? _read() {
    // Hive hazır olmayabilir (erken init/test) → çökme yerine null.
    try {
      final v = HiveService.getSetting(_key);
      return (v == null || v.isEmpty) ? null : v;
    } catch (_) {
      return null;
    }
  }

  /// Çocuğu aktif seç (kalıcı).
  Future<void> select(String? childId) async {
    state = childId;
    try {
      await HiveService.setSetting(_key, childId ?? '');
    } catch (_) {
      // Kalıcılık başarısızsa bellek içi seçim yine geçerli.
    }
  }
}

/// Çözülmüş aktif çocuk. Seçili id yoksa/geçersizse ilk çocuğa düşer,
/// hiç çocuk yoksa null (ekran "çocuk seç/ekle" akışını gösterebilir).
final activeChildProvider = Provider<ChildAccount?>((ref) {
  final children = ref.watch(familyChildrenProvider).asData?.value ??
      const <ChildAccount>[];
  if (children.isEmpty) return null;
  final selectedId = ref.watch(activeChildIdProvider);
  if (selectedId != null) {
    for (final c in children) {
      if (c.id == selectedId) return c;
    }
  }
  return children.first; // geçersiz/eski seçim → ilk çocuk
});

/// Ailede en az bir çocuk var mı? (onboarding/"çocuk ekle" akışları için.)
final hasChildrenProvider = Provider<bool>((ref) {
  final children = ref.watch(familyChildrenProvider).asData?.value;
  return children != null && children.isNotEmpty;
});
