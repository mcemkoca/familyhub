import 'dart:convert';
import 'hive_service.dart';

/// Koca Ailesi başlangıç verisini (bir kez) yerel olarak kurar.
/// - Aile adı: "Koca" → uygulamada "Koca Ailesi" görünür.
/// - Ebeveynler: Mustafa Koca (baba, 40), Hilal Şahbaz (anne, 40) yerel olarak
///   saklanır; aile haritası/üye listesi Supabase boşken bunları kullanır.
///
/// Not: Çok cihazlı gerçek veri için ayrıca `063_seed_koca_family.sql`
/// Supabase'de çalıştırılmalıdır.
class KocaSeed {
  static const String _flag = 'koca_seeded_v1';

  /// Yerel olarak saklanan Koca aile üyeleri (ad, rol, yaş, çevrimiçi).
  static const List<Map<String, dynamic>> members = [
    {'name': 'Mustafa Koca', 'role': 'Baba', 'age': 40, 'online': true},
    {'name': 'Hilal Şahbaz', 'role': 'Anne', 'age': 40, 'online': true},
    {'name': 'Mirac Koca', 'role': 'Çocuk · 6 yaş', 'age': 6, 'online': false},
  ];

  static Future<void> ensure() async {
    // Aile adı varsayılan/boşsa "Koca" yap (kullanıcı adını ezmeden, idempotent).
    final current = HiveService.getSetting('family_name');
    if (current == null || current.trim().isEmpty || current == 'Ailem') {
      await HiveService.setSetting('family_name', 'Koca');
    }
    // Üyeleri bir kez seed'le.
    if (HiveService.getSetting(_flag) != 'true') {
      await HiveService.setSetting('koca_members', jsonEncode(members));
      await HiveService.setSetting(_flag, 'true');
    }
  }

  /// Yerelde saklanan Koca üyelerini döndürür (yoksa varsayılan listeyi).
  static List<Map<String, dynamic>> localMembers() {
    final raw = HiveService.getSetting('koca_members');
    if (raw == null || raw.isEmpty) return members;
    try {
      return (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
    } catch (_) {
      return members;
    }
  }

  /// Yerel üye listesini tümüyle günceller (Hive'a yazar).
  static Future<void> setMembers(List<Map<String, dynamic>> list) =>
      HiveService.setSetting('koca_members', jsonEncode(list));

  /// Yeni bir üye ekler (ad/rol/yaş). Aile Yönetimi'nden ebeveyn/çocuk girişi.
  static Future<void> addMember({
    required String name,
    required String role,
    int? age,
    bool online = false,
  }) async {
    final list = List<Map<String, dynamic>>.from(localMembers());
    list.add({
      'name': name,
      'role': role,
      'age': ?age,
      'online': online,
    });
    await setMembers(list);
  }

  /// [index] konumundaki üyeyi günceller.
  static Future<void> updateMemberAt(
    int index, {
    String? name,
    String? role,
    int? age,
  }) async {
    final list = List<Map<String, dynamic>>.from(localMembers());
    if (index < 0 || index >= list.length) return;
    final m = Map<String, dynamic>.from(list[index]);
    if (name != null) m['name'] = name;
    if (role != null) m['role'] = role;
    if (age != null) m['age'] = age;
    list[index] = m;
    await setMembers(list);
  }

  /// [index] konumundaki üyeyi siler.
  static Future<void> removeMemberAt(int index) async {
    final list = List<Map<String, dynamic>>.from(localMembers());
    if (index < 0 || index >= list.length) return;
    list.removeAt(index);
    await setMembers(list);
  }
}
