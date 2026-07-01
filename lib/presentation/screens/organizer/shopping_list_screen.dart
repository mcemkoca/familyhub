import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../config/constants.dart';
import '../../../domain/entities.dart';
import '../../providers/app_providers.dart';
import 'package:familyhub/l10n/app_localizations.dart';

// Quick AI-suggested common items (tokensiz)
const _aiSuggestions = [
  ('🥛', 'Süt'),
  ('🍞', 'Ekmek'),
  ('🥚', 'Yumurta'),
  ('🧀', 'Peynir'),
  ('🍅', 'Domates'),
  ('🧅', 'Soğan'),
  ('🫒', 'Zeytinyağı'),
  ('🍗', 'Tavuk'),
  ('🌿', 'Maydanoz'),
  ('🍋', 'Limon'),
  ('🧴', 'Deterjan'),
  ('🧻', 'Tuvalet Kağıdı'),
];

class ShoppingListScreen extends ConsumerStatefulWidget {
  const ShoppingListScreen({super.key});

  @override
  ConsumerState<ShoppingListScreen> createState() =>
      _ShoppingListScreenState();
}

class _ShoppingListScreenState extends ConsumerState<ShoppingListScreen> {
  final _nameController = TextEditingController();
  final _quantityController = TextEditingController();
  ShoppingCategory _selectedCategory = ShoppingCategory.grocery;
  bool _showSuggestions = false;
  List<Map<String, dynamic>> _recipes = [];

  @override
  void initState() {
    super.initState();
    _loadRecipes();
  }

  Future<void> _loadRecipes() async {
    try {
      final raw = await rootBundle.loadString('assets/data/content/recipes.json');
      setState(() {
        _recipes = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
      });
    } catch (_) {}
  }

  @override
  void dispose() {
    _nameController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  void _toggleItem(ShoppingItem item) {
    HapticFeedback.selectionClick();
    ref.read(shoppingItemsProvider.notifier).toggleItem(item);
  }

  void _addItem([String? quickName]) {
    final name = quickName ?? _nameController.text.trim();
    if (name.isEmpty) return;
    ref.read(shoppingItemsProvider.notifier).addItem(
          name,
          quantity: _quantityController.text.isNotEmpty
              ? int.tryParse(_quantityController.text)
              : null,
          category: _selectedCategory,
        );
    _nameController.clear();
    _quantityController.clear();
    if (quickName == null) Navigator.pop(context);
  }

  void _deleteItem(String id) {
    ref.read(shoppingItemsProvider.notifier).deleteItem(id);
  }

  IconData _categoryIcon(ShoppingCategory cat) {
    switch (cat) {
      case ShoppingCategory.pharmacy:
        return Icons.local_pharmacy_outlined;
      case ShoppingCategory.stationery:
        return Icons.edit_note_outlined;
      case ShoppingCategory.household:
        return Icons.cleaning_services_outlined;
      case ShoppingCategory.grocery:
        return Icons.shopping_basket_outlined;
      default:
        return Icons.category_outlined;
    }
  }

  Color _categoryColor(ShoppingCategory cat) {
    switch (cat) {
      case ShoppingCategory.pharmacy:
        return AppColors.error;
      case ShoppingCategory.stationery:
        return AppColors.cobalt;
      case ShoppingCategory.household:
        return AppColors.softMint;
      default:
        return AppColors.orange;
    }
  }

  String _categoryLabel(ShoppingCategory cat) {
    switch (cat) {
      case ShoppingCategory.pharmacy:
        return 'Eczane';
      case ShoppingCategory.stationery:
        return 'Kırtasiye';
      case ShoppingCategory.household:
        return 'Ev';
      case ShoppingCategory.grocery:
        return 'Market';
      default:
        return 'Diğer';
    }
  }

  @override
  Widget build(BuildContext context) {
    final itemsAsync = ref.watch(shoppingItemsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.darkBackground : AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context, isDark, itemsAsync),
            // AI Suggestions toggle
            if (_showSuggestions) _buildAISuggestions(isDark),
            Expanded(
              child: itemsAsync.when(
                data: (items) => _buildList(items, isDark),
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('Hata: $e')),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddSheet(context),
        backgroundColor: AppColors.softMint,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Ekle',
            style:
                TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isDark,
      AsyncValue<List<ShoppingItem>> itemsAsync) {
    final total = itemsAsync.valueOrNull?.length ?? 0;
    final done =
        itemsAsync.valueOrNull?.where((i) => i.isCompleted).length ?? 0;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      color: isDark ? AppColors.darkCard : Colors.white,
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.softMint, AppColors.cobalt],
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.shopping_cart,
                    color: Colors.white, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Alışveriş Listesi',
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    if (total > 0)
                      Text(
                        '$done / $total tamamlandı',
                        style: TextStyle(
                            fontSize: 12,
                            color: isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.slate),
                      ),
                  ],
                ),
              ),
              IconButton(
                onPressed: _showRecipePicker,
                icon: const Icon(Icons.restaurant_menu_outlined),
                color: AppColors.orange,
                tooltip: 'Tarife Göre Ekle',
              ),
              IconButton(
                onPressed: () =>
                    setState(() => _showSuggestions = !_showSuggestions),
                icon: Icon(
                  Icons.auto_awesome,
                  color: _showSuggestions
                      ? AppColors.softMint
                      : AppColors.slate,
                ),
                tooltip: 'Hızlı Ekle',
              ),
              IconButton(
                onPressed: () =>
                    ref.read(shoppingItemsProvider.notifier).loadItems(),
                icon: const Icon(Icons.refresh, color: AppColors.slate),
              ),
            ],
          ),
          if (total > 0) ...[
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: total == 0 ? 0 : done / total,
                backgroundColor: AppColors.border,
                valueColor: const AlwaysStoppedAnimation(AppColors.softMint),
                minHeight: 6,
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showRecipePicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        final searchCtrl = TextEditingController();
        return StatefulBuilder(
          builder: (ctx, setLocal) {
            final query = searchCtrl.text.toLowerCase();
            final filtered = _recipes.where((r) {
              final title = (r['title'] as String? ?? '').toLowerCase();
              final cat = (r['category'] as String? ?? '').toLowerCase();
              return query.isEmpty || title.contains(query) || cat.contains(query);
            }).toList();

            return DraggableScrollableSheet(
              initialChildSize: 0.85,
              maxChildSize: 0.95,
              minChildSize: 0.5,
              builder: (_, scrollCtrl) => Container(
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkCard : Colors.white,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: Column(
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 12, bottom: 4),
                      width: 40, height: 4,
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkBorder : AppColors.border,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Tarife Göre Alışveriş',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700,
                              color: isDark ? AppColors.darkTextPrimary : AppColors.dark)),
                          const SizedBox(height: 4),
                          Text('${_recipes.length} Türk tarifi',
                            style: TextStyle(fontSize: 12, color: isDark ? AppColors.darkTextSecondary : AppColors.slate)),
                          const SizedBox(height: 12),
                          TextField(
                            controller: searchCtrl,
                            decoration: InputDecoration(
                              hintText: 'Tarif ara...',
                              prefixIcon: const Icon(Icons.search, size: 20),
                              filled: true,
                              fillColor: isDark ? AppColors.darkBackground : AppColors.cloudWhite,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                              contentPadding: const EdgeInsets.symmetric(vertical: 10),
                            ),
                            onChanged: (_) => setLocal(() {}),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: ListView.separated(
                        controller: scrollCtrl,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: filtered.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (_, i) {
                          final recipe = filtered[i];
                          final title = recipe['title'] as String? ?? '';
                          final time = (recipe['cook_time'] ?? recipe['prep_time'] ?? 0).toString();
                          final ingredientCount = (recipe['ingredients'] as List?)?.length ?? 0;
                          final cat = _categoryEmoji(recipe['category'] as String? ?? '');
                          return ListTile(
                            leading: Text(cat, style: const TextStyle(fontSize: 24)),
                            title: Text(title, style: TextStyle(fontWeight: FontWeight.w600, color: isDark ? AppColors.darkTextPrimary : AppColors.dark)),
                            subtitle: Text('$time dk • $ingredientCount malzeme',
                              style: TextStyle(fontSize: 12, color: isDark ? AppColors.darkTextSecondary : AppColors.slate)),
                            trailing: ElevatedButton.icon(
                              onPressed: () {
                                Navigator.pop(ctx);
                                _addFromRecipe(recipe);
                              },
                              icon: const Icon(Icons.add, size: 16),
                              label: const Text('Ekle'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.softMint,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                minimumSize: Size.zero,
                                textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  String _categoryEmoji(String cat) {
    return switch (cat) {
      'kahvalti' => '🍳',
      'corba' => '🍲',
      'ana_yemek' => '🍖',
      'tatli' => '🍮',
      'salata' => '🥗',
      'meze' => '🫙',
      'pilav' => '🍚',
      'hamur_isi' => '🥙',
      'dolma_sarma' => '🫑',
      'makarna' => '🍝',
      'balik' => '🐟',
      'atistirmalik' => '🥨',
      'icecek' => '🥤',
      'sebze_yemegi' => '🥦',
      _ => '🍽️',
    };
  }

  void _addFromRecipe(Map<String, dynamic> recipe) {
    final ingredients = (recipe['ingredients'] as List?) ?? [];
    int added = 0;
    for (final ing in ingredients) {
      final name = ing['name'] as String? ?? '';
      if (name.isNotEmpty) {
        ref.read(shoppingItemsProvider.notifier).addItem(
          name,
          category: ShoppingCategory.grocery,
        );
        added++;
      }
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('✅ ${recipe['title']} için $added malzeme eklendi'),
        duration: const Duration(seconds: 2),
        backgroundColor: AppColors.softMint,
      ),
    );
  }

  Widget _buildAISuggestions(bool isDark) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
      color: isDark
          ? AppColors.darkCard.withAlpha(200)
          : AppColors.softMint.withAlpha(15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome,
                  size: 14, color: AppColors.softMint),
              const SizedBox(width: 6),
              Text(
                'Hızlı Ekle',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.slate),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _aiSuggestions.map((s) {
              final (emoji, name) = s;
              return GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  _addItem(name);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkCard : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border:
                        Border.all(color: AppColors.softMint.withAlpha(80)),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withAlpha(6), blurRadius: 6)
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(emoji, style: const TextStyle(fontSize: 14)),
                      const SizedBox(width: 5),
                      Text(name,
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? AppColors.darkTextPrimary
                                  : AppColors.dark)),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildList(List<ShoppingItem> items, bool isDark) {
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.shopping_cart_outlined,
                size: 72, color: AppColors.slate.withAlpha(100)),
            const SizedBox(height: 16),
            const Text('Liste boş',
                style:
                    TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            const Text('+ butonuna bas veya ✨ hızlı ekle',
                style: TextStyle(fontSize: 13, color: AppColors.slate)),
          ],
        ),
      );
    }

    final pending = items.where((i) => !i.isCompleted).toList();
    final done = items.where((i) => i.isCompleted).toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
      children: [
        if (pending.isNotEmpty) ...[
          _sectionLabel('Bekleyen', pending.length, isDark),
          const SizedBox(height: 8),
          ...pending.map((item) => _buildItemCard(item, isDark)),
        ],
        if (done.isNotEmpty) ...[
          const SizedBox(height: 16),
          _sectionLabel('Tamamlanan', done.length, isDark,
              color: AppColors.softMint),
          const SizedBox(height: 8),
          ...done.map((item) => _buildItemCard(item, isDark)),
        ],
      ],
    );
  }

  Widget _sectionLabel(String label, int count, bool isDark,
      {Color color = AppColors.slate}) {
    return Row(
      children: [
        Text(
          '$label ($count)',
          style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color:
                  isDark ? AppColors.darkTextSecondary : AppColors.slate),
        ),
      ],
    );
  }

  Widget _buildItemCard(ShoppingItem item, bool isDark) {
    final catColor = _categoryColor(item.category);
    return Dismissible(
      key: Key(item.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
            color: AppColors.error, borderRadius: BorderRadius.circular(16)),
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      onDismissed: (_) => _deleteItem(item.id),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withAlpha(isDark ? 20 : 6),
                blurRadius: 8,
                offset: const Offset(0, 2)),
          ],
        ),
        child: ListTile(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          leading: GestureDetector(
            onTap: () => _toggleItem(item),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: item.isCompleted ? AppColors.softMint : Colors.transparent,
                shape: BoxShape.circle,
                border: Border.all(
                    color: item.isCompleted
                        ? AppColors.softMint
                        : AppColors.border,
                    width: 2),
              ),
              child: item.isCompleted
                  ? const Icon(Icons.check, size: 16, color: Colors.white)
                  : null,
            ),
          ),
          title: Text(
            item.name,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              decoration:
                  item.isCompleted ? TextDecoration.lineThrough : null,
              color: item.isCompleted
                  ? AppColors.slate
                  : (isDark ? AppColors.darkTextPrimary : AppColors.dark),
            ),
          ),
          subtitle: item.quantity != null
              ? Text('${item.quantity} adet',
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.slate))
              : null,
          trailing: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: catColor.withAlpha(25),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(_categoryIcon(item.category), size: 12, color: catColor),
                const SizedBox(width: 4),
                Text(_categoryLabel(item.category),
                    style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: catColor)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showAddSheet(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setModal) => Container(
          padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
              left: 20,
              right: 20,
              top: 20),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCard : Colors.white,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(2)),
                ),
              ),
              Text('Ürün Ekle',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800)),
              const SizedBox(height: 16),
              TextField(
                controller: _nameController,
                autofocus: true,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  hintText: 'Ürün adı',
                  prefixIcon: const Icon(Icons.shopping_basket_outlined),
                  filled: true,
                  fillColor:
                      isDark ? AppColors.darkBackground : AppColors.background,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _quantityController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        hintText: 'Adet (isteğe bağlı)',
                        prefixIcon: const Icon(Icons.numbers),
                        filled: true,
                        fillColor: isDark
                            ? AppColors.darkBackground
                            : AppColors.background,
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide.none),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Category picker
              Text('Kategori',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.slate)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: ShoppingCategory.values.map((cat) {
                  final active = _selectedCategory == cat;
                  final color = _categoryColor(cat);
                  return GestureDetector(
                    onTap: () => setModal(
                        () => setState(() => _selectedCategory = cat)),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: active
                            ? color
                            : color.withAlpha(25),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(_categoryIcon(cat),
                              size: 13,
                              color: active ? Colors.white : color),
                          const SizedBox(width: 5),
                          Text(_categoryLabel(cat),
                              style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color:
                                      active ? Colors.white : color)),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _addItem,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.softMint,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  child: const Text('Listeye Ekle',
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w700)),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
