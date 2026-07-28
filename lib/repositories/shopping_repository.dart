import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../core/supabase_client.dart';
import '../core/utils/repository_mixin.dart';
import '../domain/entities.dart';
import '../services/auth_service.dart';
import '../services/hive_service.dart';

class ShoppingRepository with RepositoryErrorHandler {
  static final ShoppingRepository _instance = ShoppingRepository._internal();
  factory ShoppingRepository() => _instance;
  ShoppingRepository._internal();
  final _client = SupabaseConfig.client;

  Future<String?> _getFamilyId() async {
    return handleRepositoryCall(() async {
      final user = _client.auth.currentUser;
      if (user == null) return null;
      final profile = await _client
          .from('profiles')
          .select('family_id')
          .eq('id', user.id)
          .maybeSingle();
      return profile?['family_id'] as String?;
    }, '_getFamilyId');
  }

  Future<List<ShoppingItem>> getItems() async {
    String? familyId;
    try {
      familyId = await _getFamilyId();
    } catch (_) {
      familyId = null;
    }
    // Aile/oturum yoksa yerel (Hive) — çevrimdışı.
    if (familyId == null) return HiveService.getShoppingItems();

    // Bulut-öncelikli: başka üyelerin değişiklikleri senkron olsun. Buluttan
    // çek, yerel-only (senkronlanmamış) öğeleri koru, cache'i tazele.
    try {
      final response = await _client
          .from('shopping_items')
          .select('*')
          .eq('family_id', familyId)
          .order('created_at', ascending: false);
      final cloud = (response as List)
          .map((e) => _fromJson(e as Map<String, dynamic>))
          .toList();
      final locals = HiveService.getShoppingItems()
          .where((i) => i.id.startsWith('local_'))
          .toList();
      final merged = [...locals, ...cloud];
      await HiveService.saveShoppingItems(merged);
      return merged;
    } catch (e) {
      debugPrint('getItems cloud failed, using cache: $e');
      return HiveService.getShoppingItems();
    }
  }

  Future<ShoppingItem> createItem(
    String name, {
    ShoppingCategory category = ShoppingCategory.grocery,
    int quantity = 1,
    ShoppingUnit unit = ShoppingUnit.piece,
  }) async {
    final userId = AuthService.currentUserId;
    String? familyId;
    try {
      familyId = await _getFamilyId();
    } catch (_) {
      familyId = null;
    }

    // Aile/oturum yoksa ya da bulut yazma başarısızsa yerel (Hive) öğe üret —
    // özellik çevrimdışı da çalışsın, kullanıcıya hata gösterme.
    ShoppingItem localItem() => ShoppingItem(
          id: 'local_${const Uuid().v4()}',
          name: name,
          quantity: quantity.toString(),
          unit: unit,
          category: category,
          requestedBy: userId ?? '',
          isCompleted: false,
        );

    Future<ShoppingItem> saveLocal() async {
      final item = localItem();
      final all = HiveService.getShoppingItems();
      await HiveService.saveShoppingItems([...all, item]);
      return item;
    }

    if (familyId == null) return saveLocal();

    // Temel payload — 'unit' kolonu migration uygulanmamış DB'lerde olmayabilir.
    // Önce unit ile dene; kolon yoksa unit'siz tekrar dene (bulut akışını bozma).
    final base = <String, dynamic>{
      'family_id': familyId,
      'name': name,
      'category': _categoryToString(category),
      'quantity': quantity,
      'requested_by': userId,
    };

    Future<ShoppingItem> insert(Map<String, dynamic> payload) async {
      final response = await _client
          .from('shopping_items')
          .insert(payload)
          .select()
          .single();
      // Bulut 'unit' döndürmezse yerel seçimi koru.
      final created = _fromJson(response).copyWithUnit(unit);
      final all = HiveService.getShoppingItems();
      await HiveService.saveShoppingItems([...all, created]);
      return created;
    }

    try {
      return await insert({...base, 'unit': unit.name});
    } catch (_) {
      // 'unit' kolonu yok olabilir — unit'siz tekrar dene.
      try {
        return await insert(base);
      } catch (e) {
        debugPrint('createItem cloud failed, saving local: $e');
        return saveLocal();
      }
    }
  }

  Future<void> toggleItem(String itemId, bool isCompleted) async {
    final userId = AuthService.currentUserId;
    // Yerel öğe — sadece Hive güncelle.
    if (itemId.startsWith('local_')) {
      final all = HiveService.getShoppingItems();
      await HiveService.saveShoppingItems(all
          .map((i) => i.id == itemId
              ? i.copyWith(
                  isCompleted: isCompleted,
                  completedBy: isCompleted ? userId : null)
              : i)
          .toList());
      return;
    }
    return handleRepositoryCall(() async {
      await _client
          .from('shopping_items')
          .update({
            'is_completed': isCompleted,
            'completed_by': isCompleted ? userId : null,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', itemId);

      final all = await getItems();
      final updated = all
          .map(
            (i) => i.id == itemId
                ? i.copyWith(
                    isCompleted: isCompleted,
                    completedBy: isCompleted ? userId : null,
                  )
                : i,
          )
          .toList();
      await HiveService.saveShoppingItems(updated);
    }, 'toggleItem');
  }

  Future<void> deleteItem(String itemId) async {
    if (itemId.startsWith('local_')) {
      final all = HiveService.getShoppingItems();
      await HiveService.saveShoppingItems(
          all.where((i) => i.id != itemId).toList());
      return;
    }
    return handleRepositoryCall(() async {
      await _client.from('shopping_items').delete().eq('id', itemId);
      final all = await getItems();
      await HiveService.saveShoppingItems(
        all.where((i) => i.id != itemId).toList(),
      );
    }, 'deleteItem');
  }

  Stream<List<ShoppingItem>> watchItems() {
    try {
      // Note: family_id is required for proper filtering.
      // For simplicity, we return all changes and filter client-side.
      return _client
          .from('shopping_items')
          .stream(primaryKey: ['id'])
          .map((data) => data.map((e) => _fromJson(e)).toList());
    } catch (e) {
      debugPrint('ShoppingRepository.watchItems error: $e');
      return Stream.error(RepositoryException('Beklenmeyen hata [watchItems]: $e'));
    }
  }

  ShoppingItem _fromJson(Map<String, dynamic> json) {
    return ShoppingItem(
      id: json['id'] as String,
      name: json['name'] as String,
      quantity: json['quantity']?.toString(),
      unit: shoppingUnitFromKey(json['unit'] as String?),
      category: _categoryFromString(json['category'] as String?),
      requestedBy: json['requested_by'] as String? ?? '',
      isCompleted: json['is_completed'] as bool? ?? false,
      completedBy: json['completed_by'] as String?,
    );
  }

  static ShoppingCategory _categoryFromString(String? val) {
    return switch (val) {
      'pharmacy' => ShoppingCategory.pharmacy,
      'stationery' => ShoppingCategory.stationery,
      'household' => ShoppingCategory.household,
      _ => ShoppingCategory.grocery,
    };
  }

  static String _categoryToString(ShoppingCategory cat) {
    return switch (cat) {
      ShoppingCategory.pharmacy => 'pharmacy',
      ShoppingCategory.stationery => 'stationery',
      ShoppingCategory.household => 'household',
      _ => 'grocery',
    };
  }
}
