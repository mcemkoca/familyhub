/// Context Memory — kullanıcı-izole anahtar alanı (Faz 2).
///
/// DENETİM BULGUSU: mevcut Hive box'ları (`tasks`, `chat`, ...) kullanıcıya
/// göre namespace'lenmiyor. Aynı cihazda hesap değiştiğinde önceki kullanıcının
/// verisi yenisine görünebilir. Memory sistemi bu hatayı TEKRARLAMAZ: her kayıt
/// anahtarı sahibinin kimliğini taşır ve okuma bu önekle filtrelenir.
library;

/// Memory kalıcılığı için Hive box adları (merkezi — dağınık string yok).
class MemoryBoxes {
  const MemoryBoxes._();

  static const records = 'memory_records_v1';
  static const consents = 'memory_consents_v1';
  static const syncQueue = 'memory_sync_queue_v1';
  static const tombstones = 'memory_tombstones_v1';
  static const audit = 'memory_audit_v1';

  static const all = <String>[records, consents, syncQueue, tombstones, audit];
}

/// Bir kaydın hangi kullanıcıya ait olduğunu anahtarda taşır.
///
/// Biçim: `u:<userId>|<recordId>`. Kullanıcısız (cihaz-yerel) kayıtlar
/// `u:_anon|<recordId>` kullanır ve hesap değişiminde okunmaz.
class MemoryKeyspace {
  const MemoryKeyspace._();

  static const _anon = '_anon';
  static const _sep = '|';

  /// Kayıt için kalıcı anahtar üretir.
  static String buildKey({required String? userId, required String recordId}) {
    final owner = (userId == null || userId.isEmpty) ? _anon : userId;
    return 'u:$owner$_sep$recordId';
  }

  /// Bir kullanıcının tüm kayıtlarını taramak için önek.
  static String prefixFor(String? userId) {
    final owner = (userId == null || userId.isEmpty) ? _anon : userId;
    return 'u:$owner$_sep';
  }

  /// Anahtardan sahip kullanıcıyı çıkarır; biçim bozuksa null.
  static String? ownerOf(String key) {
    if (!key.startsWith('u:')) return null;
    final i = key.indexOf(_sep);
    if (i <= 2) return null;
    final owner = key.substring(2, i);
    return owner.isEmpty ? null : owner;
  }

  /// Anahtardan kayıt id'sini çıkarır; biçim bozuksa null.
  static String? recordIdOf(String key) {
    final i = key.indexOf(_sep);
    if (i < 0 || i + 1 >= key.length) return null;
    return key.substring(i + 1);
  }

  /// KRİTİK: bu anahtar bu kullanıcıya mı ait? Okuma filtresi bunu kullanır —
  /// başka kullanıcının kaydı ASLA döndürülmez (hesap değişimi sızıntısı yok).
  static bool belongsTo(String key, String? userId) {
    final owner = ownerOf(key);
    if (owner == null) return false;
    final expected = (userId == null || userId.isEmpty) ? _anon : userId;
    return owner == expected;
  }

  /// Bir kullanıcının anahtarlarını süzer (logout/hesap silme temizliği için).
  static List<String> filterKeys(Iterable<String> keys, String? userId) =>
      keys.where((k) => belongsTo(k, userId)).toList();
}
