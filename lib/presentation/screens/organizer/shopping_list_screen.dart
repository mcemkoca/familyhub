import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../config/constants.dart';
import '../../../domain/entities.dart';
import '../../providers/app_providers.dart';
import 'package:familyhub/l10n/app_localizations.dart';

class ShoppingListScreen extends ConsumerStatefulWidget {
  const ShoppingListScreen({super.key});

  @override
  ConsumerState<ShoppingListScreen> createState() => _ShoppingListScreenState();
}

class _ShoppingListScreenState extends ConsumerState<ShoppingListScreen> {
  final _nameController = TextEditingController();

  void _toggleItem(ShoppingItem item) {
    ref.read(shoppingItemsProvider.notifier).toggleItem(item);
  }

  void _addItem() {
    if (_nameController.text.isEmpty) return;
    ref.read(shoppingItemsProvider.notifier).addItem(_nameController.text);
    _nameController.clear();
    Navigator.pop(context);
  }

  void _deleteItem(String id) {
    ref.read(shoppingItemsProvider.notifier).deleteItem(id);
  }

  IconData _categoryIcon(ShoppingCategory cat) {
    switch (cat) {
      case ShoppingCategory.pharmacy: return Icons.local_pharmacy;
      case ShoppingCategory.stationery: return Icons.edit_note;
      case ShoppingCategory.household: return Icons.cleaning_services;
      default: return Icons.shopping_basket;
    }
  }

  @override
  Widget build(BuildContext context) {
    final itemsAsync = ref.watch(shoppingItemsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context).alisverisListesi),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(shoppingItemsProvider.notifier).loadItems(),
          ),
        ],
      ),
      body: itemsAsync.when(
        data: (items) {
          if (items.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.shopping_basket_outlined, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('Liste boş', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.grey)),
                  SizedBox(height: 8),
                  Text('Yeni ürün eklemek için + butonuna bas', style: TextStyle(fontSize: 14, color: Colors.grey)),
                ],
              ),
            );
          }

          final pending = items.where((i) => !i.isCompleted).toList();
          final done = items.where((i) => i.isCompleted).toList();

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              if (pending.isNotEmpty) ...[
                Text('Bekleyen (${pending.length})', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.grey.shade600)),
                const SizedBox(height: 12),
                ...pending.map((item) => _buildItemCard(item)),
              ],
              if (done.isNotEmpty) ...[
                const SizedBox(height: 20),
                Text('Tamamlanan (${done.length})', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.grey.shade600)),
                const SizedBox(height: 12),
                ...done.map((item) => _buildItemCard(item)),
              ],
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 12),
              Text('Yüklenemedi: $e', textAlign: TextAlign.center),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => ref.read(shoppingItemsProvider.notifier).loadItems(),
                child: Text(AppLocalizations.of(context).tryAgain),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
            builder: (_) => Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 24, right: 24, top: 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Ürün Ekle', style: Theme.of(context).textTheme.displaySmall),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _nameController,
                    autofocus: true,
                    decoration: const InputDecoration(labelText: 'Ürün Adı'),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _addItem,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.purple,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: const Text('Ekle', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          );
        },
        backgroundColor: AppColors.purple,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildItemCard(ShoppingItem item) {
    return Dismissible(
      key: Key(item.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(16)),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) => _deleteItem(item.id),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFF3F4F6)),
        ),
        child: ListTile(
          leading: GestureDetector(
            onTap: () => _toggleItem(item),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: item.isCompleted ? AppColors.green : Colors.transparent,
                shape: BoxShape.circle,
                border: Border.all(color: item.isCompleted ? AppColors.green : AppColors.border, width: 2),
              ),
              child: item.isCompleted ? const Icon(Icons.check, size: 16, color: Colors.white) : null,
            ),
          ),
          title: Text(
            item.name,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              decoration: item.isCompleted ? TextDecoration.lineThrough : null,
              color: item.isCompleted ? AppColors.gray : null,
            ),
          ),
          subtitle: item.quantity != null ? Text('Adet: ${item.quantity}', style: TextStyle(fontSize: 12, color: Colors.grey.shade500)) : null,
          trailing: Icon(_categoryIcon(item.category), color: AppColors.purple, size: 20),
        ),
      ),
    );
  }
}
