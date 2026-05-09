import 'package:flutter/foundation.dart';

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
    return handleRepositoryCall(() async {
      final cached = HiveService.getShoppingItems();
      if (cached.isNotEmpty) return cached;

      final familyId = await _getFamilyId();
      if (familyId == null) return [];

      final response = await _client
          .from('shopping_items')
          .select('*')
          .eq('family_id', familyId)
          .order('created_at', ascending: false);

      final items = (response as List).map((e) => _fromJson(e as Map<String, dynamic>)).toList();
      await HiveService.saveShoppingItems(items);
      return items;
    }, 'getItems');
  }

  Future<ShoppingItem> createItem(
    String name, {
    ShoppingCategory category = ShoppingCategory.grocery,
    int quantity = 1,
  }) async {
    return handleRepositoryCall(() async {
      final familyId = await _getFamilyId();
      final userId = AuthService.currentUserId;
      if (familyId == null) throw Exception('Aile bilgisi bulunamadı');

      final response = await _client
          .from('shopping_items')
          .insert({
            'family_id': familyId,
            'name': name,
            'category': _categoryToString(category),
            'quantity': quantity,
            'requested_by': userId,
          })
          .select()
          .single();

      final created = _fromJson(response);
      final all = await getItems();
      await HiveService.saveShoppingItems([...all, created]);
      return created;
    }, 'createItem');
  }

  Future<void> toggleItem(String itemId, bool isCompleted) async {
    return handleRepositoryCall(() async {
      final userId = AuthService.currentUserId;
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
