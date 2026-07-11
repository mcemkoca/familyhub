import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../config/constants.dart';
import 'package:familyhub/l10n/app_localizations.dart';
import '../../../services/hive_service.dart';
import '../../../services/auth_service.dart';
import '../../../services/content/meal_image_service.dart';
import '../../providers/app_providers.dart';
import '../../widgets/ds.dart';
import '../../../services/ai/ai_engine.dart';
import '../../../services/ai/ai_content_service.dart';

/// Tarife göre DOĞRU yemek fotoğrafı — TheMealDB'den adına göre çeker,
/// bulunamazsa nötr gradient + ikon (yanlış görsel göstermez).
class _RecipeThumb extends StatefulWidget {
  final Map<String, dynamic> recipe;
  final Color amber;
  const _RecipeThumb({required this.recipe, required this.amber});

  @override
  State<_RecipeThumb> createState() => _RecipeThumbState();
}

class _RecipeThumbState extends State<_RecipeThumb> {
  String? _url;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final t = (widget.recipe['title'] ?? '').toString();
    final c = (widget.recipe['category'] ?? '').toString();
    final url = await MealImageService.fetchThumb(t, c);
    if (mounted) setState(() { _url = url; _loading = false; });
  }

  Widget _fallback() => Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [widget.amber.withAlpha(35), widget.amber.withAlpha(12)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: _loading
              ? SizedBox(
                  width: 22, height: 22,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: widget.amber.withAlpha(150)))
              : Icon(Icons.restaurant_outlined,
                  size: 40, color: widget.amber.withAlpha(150)),
        ),
      );

  @override
  Widget build(BuildContext context) {
    if (_url == null) return _fallback();
    return Image.network(
      _url!,
      fit: BoxFit.cover,
      loadingBuilder: (c, ch, p) => p == null ? ch : _fallback(),
      errorBuilder: (c, e, s) => _fallback(),
    );
  }
}


class KitchenScreen extends StatefulWidget {
  const KitchenScreen({super.key});

  @override
  State<KitchenScreen> createState() => _KitchenScreenState();
}

class _KitchenScreenState extends State<KitchenScreen>
    with SingleTickerProviderStateMixin {
  bool get isDark => Theme.of(context).brightness == Brightness.dark;

  late TabController _tabController;
  List<Map<String, dynamic>> _recipes = [];
  List<Map<String, dynamic>> _filtered = [];
  String _selectedCategory = 'tümü';
  String _searchQuery = '';
  bool _loading = true;

  // Haftalık yemek planı: gün → yemek adı
  final Map<String, String?> _weeklyPlan = {
    'Pazartesi': null,
    'Salı': null,
    'Çarşamba': null,
    'Perşembe': null,
    'Cuma': null,
    'Cumartesi': null,
    'Pazar': null,
  };

  final _categories = [
    ('tümü', 'Tümü', Icons.restaurant_menu),
    ('kahvalti', 'Kahvaltı', Icons.free_breakfast),
    ('ana_yemek', 'Ana Yemek', Icons.dinner_dining),
    ('corba', 'Çorba', Icons.soup_kitchen),
    ('tatli', 'Tatlı', Icons.cake),
    ('salata', 'Salata', Icons.eco),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadWeeklyPlan();
    _loadRecipes();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadRecipes() async {
    try {
      final raw =
          await rootBundle.loadString('assets/data/content/recipes.json');
      final list = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
      final custom = _loadCustom();
      setState(() {
        _recipes = [...custom, ...list];
        _filtered = _recipes;
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  // Kullanıcı-izole anahtar — hesap değişiminde başka kullanıcının kendi
  // tarifleri görünmesin (yerel içerik; bulutla senkron değil).
  String get _customKey =>
      'custom_recipes_${AuthService.currentUserId ?? 'anon'}';

  // Haftalık plan da kullanıcı-izole + KALICI (önceden bellekte tutuluyordu →
  // ekran kapanınca kayboluyordu = veri kaybı).
  String get _weeklyPlanKey =>
      'weekly_plan_${AuthService.currentUserId ?? 'anon'}';

  void _loadWeeklyPlan() {
    try {
      final raw = HiveService.getSetting(_weeklyPlanKey);
      if (raw == null || raw.isEmpty) return;
      final map = jsonDecode(raw) as Map<String, dynamic>;
      for (final day in _weeklyPlan.keys) {
        final v = map[day];
        if (v is String) _weeklyPlan[day] = v;
      }
    } catch (_) {}
  }

  Future<void> _saveWeeklyPlan() async {
    // null değerleri de yaz (temizlenen günler korunsun).
    await HiveService.setSetting(_weeklyPlanKey, jsonEncode(_weeklyPlan));
  }

  List<Map<String, dynamic>> _loadCustom() {
    try {
      final raw = HiveService.getSetting(_customKey);
      if (raw == null || raw.isEmpty) return [];
      return (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
    } catch (_) {
      return [];
    }
  }

  Future<void> _saveCustom(Map<String, dynamic> recipe) async {
    final list = _loadCustom();
    list.insert(0, recipe);
    await HiveService.setSetting(_customKey, jsonEncode(list));
    setState(() {
      _recipes = [recipe, ..._recipes];
      _applyFilter();
    });
  }

  // "Yeni Yemek Fikri" — kendi tarifin ya da web'den tarif.
  void _showNewFoodIdea() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _NewFoodIdeaSheet(
        onOwn: () {
          Navigator.pop(context);
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (_) => _AddRecipeSheet(onSave: _saveCustom, fromWeb: false),
          );
        },
        onWeb: () {
          Navigator.pop(context);
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (_) => _AddRecipeSheet(onSave: _saveCustom, fromWeb: true),
          );
        },
      ),
    );
  }

  void _applyFilter() {
    setState(() {
      _filtered = _recipes.where((r) {
        final matchCat = _selectedCategory == 'tümü' ||
            (r['category'] as String?)?.toLowerCase() ==
                _selectedCategory.toLowerCase();
        final matchSearch = _searchQuery.isEmpty ||
            (r['title'] as String?)
                    ?.toLowerCase()
                    .contains(_searchQuery.toLowerCase()) ==
                true;
        return matchCat && matchSearch;
      }).toList();
    });
  }

  void _autoFillWeek() {
    if (_recipes.isEmpty) return;
    final rnd = Random();
    setState(() {
      for (final day in _weeklyPlan.keys) {
        final pick = _recipes[rnd.nextInt(_recipes.length)];
        _weeklyPlan[day] = pick['title'] as String?;
      }
    });
    _saveWeeklyPlan();
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(isDark),
            _buildTabBar(isDark),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _RecipesTab(
                    recipes: _recipes,
                    filtered: _filtered,
                    loading: _loading,
                    selectedCategory: _selectedCategory,
                    categories: _categories,
                    onCategoryChanged: (c) {
                      setState(() => _selectedCategory = c);
                      _applyFilter();
                    },
                    onSearch: (q) {
                      _searchQuery = q;
                      _applyFilter();
                    },
                    isDark: isDark,
                  ),
                  _WeeklyPlanTab(
                    plan: _weeklyPlan,
                    onAutoFill: _autoFillWeek,
                    onPickDay: (day) => _showPickForDay(day),
                    onClear: (day) {
                      setState(() => _weeklyPlan[day] = null);
                      _saveWeeklyPlan();
                    },
                    isDark: isDark,
                  ),
                  _MealShoppingTab(
                    plan: _weeklyPlan,
                    recipes: _recipes,
                    isDark: isDark,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    const amber = Color(0xFFF59E0B);
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 10, 12, 0),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A1200), Color(0xFF2D1A00)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: amber.withAlpha(50), width: 0.5),
        boxShadow: [
          BoxShadow(
            color: amber.withAlpha(40),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 50, height: 50,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(color: amber.withAlpha(80), blurRadius: 10),
              ],
            ),
            child: const Icon(Icons.restaurant_outlined, color: Colors.white, size: 26),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(AppLocalizations.of(context).kitchenTitle,
                    style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 19, color: Colors.white)),
                Text(AppLocalizations.of(context).kitchenRecipeCount('${_recipes.length}'),
                    style: TextStyle(fontSize: 11, color: Colors.white.withAlpha(120), fontWeight: FontWeight.w500)),
              ],
            ),
          ),
          // Tarif ekle butonu (her zaman görünür — shell nav çubuğu FAB'ı örtüyor)
          GestureDetector(
            onTap: _showNewFoodIdea,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [BoxShadow(color: amber.withAlpha(70), blurRadius: 8)],
              ),
              child: const Row(
                children: [
                  Icon(Icons.add, size: 16, color: Colors.white),
                  SizedBox(width: 4),
                  Text('Tarif',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 13)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar(bool isDark) {
    const amber = Color(0xFFF59E0B);
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      height: 44,
      decoration: BoxDecoration(
        color: Ds.glass,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Ds.glassBorder, width: 0.5),
      ),
      child: TabBar(
        controller: _tabController,
        labelColor: amber,
        unselectedLabelColor: Ds.textSub,
        indicatorColor: amber,
        indicatorSize: TabBarIndicatorSize.label,
        indicatorWeight: 2,
        dividerColor: Colors.transparent,
        labelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
        unselectedLabelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
        tabs: [
          Tab(icon: const Icon(Icons.restaurant_menu, size: 16), text: AppLocalizations.of(context).kitchenTabRecipes),
          Tab(icon: const Icon(Icons.calendar_view_week, size: 16), text: AppLocalizations.of(context).kitchenTabWeekly),
          Tab(icon: const Icon(Icons.shopping_cart_outlined, size: 16), text: AppLocalizations.of(context).kitchenTabShopping),
        ],
      ),
    );
  }

  void _showPickForDay(String day) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        height: MediaQuery.sizeOf(context).height * 0.7,
        decoration: const BoxDecoration(
          color: Color(0xFF13131A),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          border: Border(
            top: BorderSide(color: Ds.glassBorder, width: 0.5),
            left: BorderSide(color: Ds.glassBorder, width: 0.5),
            right: BorderSide(color: Ds.glassBorder, width: 0.5),
          ),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 36, height: 4,
              decoration: BoxDecoration(
                  color: Ds.textMuted,
                  borderRadius: BorderRadius.circular(2)),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Text('$day için yemek seç',
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17, color: Ds.text)),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                itemCount: _recipes.length,
                itemBuilder: (_, i) {
                  final r = _recipes[i];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: Ds.glass,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Ds.glassBorder, width: 0.5),
                    ),
                    child: ListTile(
                      onTap: () {
                        setState(() => _weeklyPlan[day] = r['title'] as String?);
                        _saveWeeklyPlan();
                        Navigator.pop(context);
                      },
                      leading: Container(
                        width: 40, height: 40,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: [Color(0xFFF59E0B), Color(0xFFD97706)]),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.restaurant, color: Colors.white, size: 20),
                      ),
                      title: Text((r['title'] ?? '').toString(),
                          style: const TextStyle(fontWeight: FontWeight.w600, color: Ds.text, fontSize: 13)),
                      subtitle: Text(
                          '${(r['prep_time'] as int? ?? 0) + (r['cook_time'] as int? ?? 0)} dk · ${r['difficulty'] ?? ''}',
                          style: const TextStyle(fontSize: 10, color: Ds.textSub)),
                      trailing: const Icon(Icons.add_circle_outline, color: Color(0xFFF59E0B), size: 20),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── TAB 1: Tarifler ────────────────────────────────────────────────────────

class _RecipesTab extends StatelessWidget {
  final List<Map<String, dynamic>> recipes;
  final List<Map<String, dynamic>> filtered;
  final bool loading;
  final String selectedCategory;
  final List<(String, String, IconData)> categories;
  final ValueChanged<String> onCategoryChanged;
  final ValueChanged<String> onSearch;
  final bool isDark;

  const _RecipesTab({
    required this.recipes,
    required this.filtered,
    required this.loading,
    required this.selectedCategory,
    required this.categories,
    required this.onCategoryChanged,
    required this.onSearch,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 8),
        _buildSearch(context),
        _buildCategoryChips(context),
        const _AiRecipeStrip(),
        const SizedBox(height: 8),
        Expanded(
          child: loading
              ? const Center(child: CircularProgressIndicator())
              : filtered.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.search_off, size: 64, color: Color(0xFF6B7280)),
                          SizedBox(height: 12),
                          Text('Tarif bulunamadı'),
                        ],
                      ),
                    )
                  : _buildGrid(context),
        ),
      ],
    );
  }

  Widget _buildSearch(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      child: DsInput(
        hint: AppLocalizations.of(context).kitchenSearchHint,
        prefixIcon: Icons.search,
        onChanged: onSearch,
      ),
    );
  }

  Widget _buildCategoryChips(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: categories.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final (id, label, icon) = categories[i];
          final active = selectedCategory == id;
          return DsChip(
            label: label,
            selected: active,
            onTap: () => onCategoryChanged(id),
            icon: icon,
            accent: const Color(0xFFF59E0B),
          );
        },
      ),
    );
  }

  Widget _buildGrid(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      // İçeriğe uygun sabit kart yüksekliği — childAspectRatio ile kartlar
      // çok uzun oluyor ve altta boşluk kalıyordu.
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisExtent: 218,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: filtered.length,
      itemBuilder: (context, i) => _RecipeCard(
        recipe: filtered[i],
        isDark: isDark,
        onTap: () => showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (_) => RecipeDetailSheet(recipe: filtered[i]),
        ),
      ),
    );
  }
}

// ─── TAB 2: Haftalık Plan ───────────────────────────────────────────────────

class _WeeklyPlanTab extends StatelessWidget {
  final Map<String, String?> plan;
  final VoidCallback onAutoFill;
  final ValueChanged<String> onPickDay;
  final ValueChanged<String> onClear;
  final bool isDark;

  const _WeeklyPlanTab({
    required this.plan,
    required this.onAutoFill,
    required this.onPickDay,
    required this.onClear,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final days = plan.keys.toList();
    final today = _todayName();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        // AI otomatik doldur
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
                colors: [Color(0xFFF97316), Color(0xFFEF4444)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              const Icon(Icons.auto_awesome, color: Colors.white, size: 28),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Haftalık Plan Oluştur',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 15)),
                    SizedBox(height: 2),
                    Text('AI tüm haftayı otomatik doldursun',
                        style:
                            TextStyle(color: Colors.white70, fontSize: 12)),
                  ],
                ),
              ),
              ElevatedButton(
                onPressed: onAutoFill,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFFF97316),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 8),
                  elevation: 0,
                ),
                child: const Text('Doldur',
                    style: TextStyle(fontWeight: FontWeight.w800)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        ...days.map((day) {
          final meal = plan[day];
          final isToday = day == today;
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: GestureDetector(
              onTap: () => onPickDay(day),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isToday
                      ? const Color(0xFFF59E0B).withAlpha(15)
                      : Ds.glass,
                  borderRadius: BorderRadius.circular(16),
                  border: isToday
                      ? Border.all(color: const Color(0xFFF59E0B), width: 1.5)
                      : Border.all(color: Ds.glassBorder, width: 0.5),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: isToday
                            ? const Color(0xFFF97316)
                            : (isDark
                                ? const Color(0xFF0A0A0F)
                                : const Color(0xFF0A0A0F)),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          day.substring(0, 3),
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: isToday
                                  ? Colors.white
                                  : (const Color(0xFF6B7280))),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: meal != null
                          ? Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(meal,
                                    style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFFE5E7EB))),
                                const SizedBox(height: 2),
                                const Text('Değiştirmek için dokun',
                                    style: TextStyle(
                                        fontSize: 11,
                                        color: Color(0xFF6B7280))),
                              ],
                            )
                          : const Text('Yemek seç...',
                              style: TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF6B7280))),
                    ),
                    if (meal != null)
                      IconButton(
                        onPressed: () => onClear(day),
                        icon: const Icon(Icons.close,
                            size: 18, color: Color(0xFF6B7280)),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      )
                    else
                      const Icon(Icons.add_circle_outline,
                          color: Color(0xFFF97316), size: 22),
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  String _todayName() {
    const days = [
      'Pazartesi', 'Salı', 'Çarşamba', 'Perşembe',
      'Cuma', 'Cumartesi', 'Pazar'
    ];
    return days[DateTime.now().weekday - 1];
  }
}

// ─── TAB 3: Alışveriş (haftanın yemeklerinden malzeme listesi) ─────────────

class _MealShoppingTab extends StatelessWidget {
  final Map<String, String?> plan;
  final List<Map<String, dynamic>> recipes;
  final bool isDark;

  const _MealShoppingTab({
    required this.plan,
    required this.recipes,
    required this.isDark,
  });

  List<Map<String, dynamic>> _buildIngredientList() {
    final ingredientMap = <String, Map<String, dynamic>>{};
    for (final meal in plan.values) {
      if (meal == null) continue;
      final recipe = recipes.where((r) => r['title'] == meal).firstOrNull;
      if (recipe == null) continue;
      final ings =
          (recipe['ingredients'] as List?)?.cast<Map<String, dynamic>>() ??
              [];
      for (final ing in ings) {
        final name = ing['name'] as String? ?? '';
        if (ingredientMap.containsKey(name)) {
          // Just mark as needed multiple times
          ingredientMap[name]!['count'] =
              (ingredientMap[name]!['count'] as int) + 1;
        } else {
          ingredientMap[name] = {
            'name': name,
            'amount': ing['amount'],
            'unit': ing['unit'],
            'count': 1,
            'checked': false,
          };
        }
      }
    }
    return ingredientMap.values.toList()
      ..sort((a, b) => (a['name'] as String).compareTo(b['name'] as String));
  }

  @override
  Widget build(BuildContext context) {
    final mealCount = plan.values.where((v) => v != null).length;

    if (mealCount == 0) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.calendar_view_week,
                size: 72, color: const Color(0xFF6B7280).withAlpha(100)),
            const SizedBox(height: 16),
            Text(AppLocalizations.of(context).kitchenFillWeeklyFirst,
                style: const TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            Text(AppLocalizations.of(context).kitchenAutoIngredientList,
                style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280))),
          ],
        ),
      );
    }

    final ingredients = _buildIngredientList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFF97316).withAlpha(20),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
                color: const Color(0xFFF97316).withAlpha(80)),
          ),
          child: Row(
            children: [
              const Icon(Icons.shopping_cart,
                  color: Color(0xFFF97316), size: 20),
              const SizedBox(width: 10),
              Text(
                '$mealCount yemek için ${ingredients.length} malzeme',
                style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFF97316),
                    fontSize: 13),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // Mutfak → Alışveriş senkron butonu
        Consumer(
          builder: (context, ref, _) => SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                final notifier = ref.read(shoppingItemsProvider.notifier);
                // Duplicate koruması: listede bekleyen aynı adlı ürünü tekrar
                // ekleme (alışveriş ekranıyla aynı normalize mantığı).
                final existing = ref.read(shoppingItemsProvider).valueOrNull ?? [];
                final pending = existing
                    .where((i) => !i.isCompleted)
                    .map((i) => i.name.trim().toLowerCase())
                    .toSet();
                var added = 0;
                for (final ing in ingredients) {
                  final name = (ing['name'] ?? '').toString().trim();
                  if (name.isEmpty) continue;
                  if (!pending.add(name.toLowerCase())) continue; // zaten var
                  notifier.addItem(name, quantity: ing['count'] as int? ?? 1);
                  added++;
                }
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text(
                        '$added malzeme alışveriş listesine eklendi'),
                    behavior: SnackBarBehavior.floating));
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              icon: const Icon(Icons.add_shopping_cart, color: Colors.white),
              label: Text(AppLocalizations.of(context).kitchenAddAllToShopping,
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w700)),
            ),
          ),
        ),
        const SizedBox(height: 12),
        ...ingredients.map((ing) => _IngredientTile(
              ingredient: ing,
              isDark: isDark,
            )),
      ],
    );
  }
}

class _IngredientTile extends StatefulWidget {
  final Map<String, dynamic> ingredient;
  final bool isDark;
  const _IngredientTile({required this.ingredient, required this.isDark});

  @override
  State<_IngredientTile> createState() => _IngredientTileState();
}

class _IngredientTileState extends State<_IngredientTile> {
  bool _checked = false;

  @override
  Widget build(BuildContext context) {
    final ing = widget.ingredient;
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _checked = !_checked);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF13131A),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withAlpha(20),
                blurRadius: 6,
                offset: const Offset(0, 2))
          ],
        ),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: _checked
                    ? const Color(0xFF10B981)
                    : Colors.transparent,
                shape: BoxShape.circle,
                border: Border.all(
                    color:
                        _checked ? const Color(0xFF10B981) : const Color(0x1EFFFFFF),
                    width: 2),
              ),
              child: _checked
                  ? const Icon(Icons.check, size: 14, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                ing['name'] as String,
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    decoration:
                        _checked ? TextDecoration.lineThrough : null,
                    color: _checked
                        ? const Color(0xFF6B7280)
                        : (const Color(0xFFE5E7EB))),
              ),
            ),
            Text(
              '${ing['amount']} ${ing['unit']}',
              style: const TextStyle(
                  fontSize: 12, color: Color(0xFF6B7280)),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Recipe Card & Detail Sheet (unchanged from before) ─────────────────────

class _RecipeCard extends StatelessWidget {
  final Map<String, dynamic> recipe;
  final bool isDark;
  final VoidCallback onTap;

  const _RecipeCard(
      {required this.recipe, required this.isDark, required this.onTap});

  Color get _difficultyColor {
    switch (recipe['difficulty']) {
      case 'kolay':
        return const Color(0xFF10B981);
      case 'orta':
        return const Color(0xFFF59E0B);
      default:
        return AppColors.error;
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalTime = (recipe['prep_time'] as int? ?? 0) +
        (recipe['cook_time'] as int? ?? 0);
    final rating = (recipe['rating'] as num?)?.toDouble() ?? 4.0;

    const amber = Color(0xFFF59E0B);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Ds.glass,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Ds.glassBorder, width: 0.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(40),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 100,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [amber.withAlpha(30), amber.withAlpha(10)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
                border: Border(bottom: BorderSide(color: amber.withAlpha(30), width: 0.5)),
              ),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(18)),
                    child: _RecipeThumb(recipe: recipe, amber: amber),
                  ),
                  Positioned(
                    top: 8, right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                          color: _difficultyColor.withAlpha(220),
                          borderRadius: BorderRadius.circular(8)),
                      child: Text((recipe['difficulty'] ?? '').toString(),
                          style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w700)),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text((recipe['title'] ?? '').toString(),
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Ds.text),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.timer_outlined, size: 12, color: Ds.textSub),
                      const SizedBox(width: 3),
                      Text('$totalTime dk', style: const TextStyle(fontSize: 11, color: Ds.textSub)),
                      const Spacer(),
                      const Icon(Icons.star_rounded, size: 14, color: Color(0xFFFBBF24)),
                      const SizedBox(width: 2),
                      Text(rating.toStringAsFixed(1),
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Ds.textSub)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  // Malzeme listesi önizlemesi
                  Builder(builder: (_) {
                    final ings = (recipe['ingredients'] as List?)
                            ?.map((e) => (e is Map ? e['name'] : e).toString())
                            .where((e) => e.isNotEmpty)
                            .toList() ??
                        [];
                    if (ings.isEmpty) return const SizedBox.shrink();
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.shopping_basket_outlined,
                            size: 12, color: Color(0xFF10B981)),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            ings.take(4).join(', '),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontSize: 10.5,
                                height: 1.3,
                                color: Color(0xFF9CA3AF)),
                          ),
                        ),
                      ],
                    );
                  }),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class RecipeDetailSheet extends StatefulWidget {
  final Map<String, dynamic> recipe;
  const RecipeDetailSheet({super.key, required this.recipe});

  @override
  State<RecipeDetailSheet> createState() => _RecipeDetailSheetState();
}

class _RecipeDetailSheetState extends State<RecipeDetailSheet>
    with SingleTickerProviderStateMixin {
  late TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final recipe = widget.recipe;
    final ingredients =
        (recipe['ingredients'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    // instructions bazı verilerde 'steps' altında; her ikisini de dene
    final instructions = ((recipe['instructions'] ?? recipe['steps']) as List?)
            ?.map((e) => e.toString())
            .toList() ??
        [];
    // tips String de olabilir List de — ikisini de destekle
    final rawTips = recipe['tips'];
    final tips = rawTips is List
        ? rawTips.map((e) => e.toString()).toList()
        : (rawTips is String && rawTips.trim().isNotEmpty
            ? [rawTips]
            : <String>[]);
    final nutrition = recipe['nutrition'] as Map<String, dynamic>? ?? {};
    final totalTime = (recipe['prep_time'] as int? ?? 0) +
        (recipe['cook_time'] as int? ?? 0);

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      builder: (_, controller) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFF13131A),
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          children: [
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: const Color(0x1EFFFFFF),
                    borderRadius: BorderRadius.circular(2)),
              ),
            ),
            Container(
              margin: const EdgeInsets.all(16),
              height: 160,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: [Color(0xFFF97316), Color(0xFFEF4444)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Tarife özel gerçek yemek görseli (bulunamazsa gradient kalır).
                  _RecipeThumb(recipe: recipe, amber: const Color(0xFFF97316)),
                  // Başlığın okunması için alt karartma katmanı.
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.transparent, Color(0xCC000000)],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 16,
                    left: 16,
                    right: 16,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text((recipe['title'] ?? '').toString(),
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w800)),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            _InfoChip(
                                icon: Icons.timer,
                                label: '$totalTime dk'),
                            const SizedBox(width: 8),
                            _InfoChip(
                                icon: Icons.people,
                                label: '${recipe['servings'] ?? 4} kişi'),
                            const SizedBox(width: 8),
                            _InfoChip(
                                icon: Icons.local_fire_department,
                                label:
                                    '${nutrition['calories'] ?? 0} kcal'),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            TabBar(
              controller: _tab,
              labelColor: const Color(0xFFF97316),
              unselectedLabelColor: const Color(0xFF6B7280),
              indicatorColor: const Color(0xFFF97316),
              tabs: const [
                Tab(text: 'Malzemeler'),
                Tab(text: 'Yapılış'),
                Tab(text: 'İpuçları'),
              ],
            ),
            Expanded(
              child: TabBarView(
                controller: _tab,
                children: [
                  ListView.separated(
                    controller: controller,
                    padding: const EdgeInsets.all(16),
                    itemCount: ingredients.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (_, i) {
                      final ing = ingredients[i];
                      return ListTile(
                        leading: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                              color: const Color(0xFFF97316).withAlpha(30),
                              shape: BoxShape.circle),
                          child: Center(
                            child: Text('${i + 1}',
                                style: const TextStyle(
                                    color: Color(0xFFF97316),
                                    fontWeight: FontWeight.w700,
                                    fontSize: 12)),
                          ),
                        ),
                        title: Text((ing['name'] ?? '').toString()),
                        trailing: Text(
                            '${ing['amount']} ${ing['unit']}',
                            style: const TextStyle(
                                color: Color(0xFF6B7280), fontSize: 13)),
                      );
                    },
                  ),
                  ListView.builder(
                    controller: controller,
                    padding: const EdgeInsets.all(16),
                    itemCount: instructions.length,
                    itemBuilder: (_, i) => Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 34,
                            height: 34,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(colors: [
                                Color(0xFFF97316),
                                Color(0xFFEF4444)
                              ]),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Center(
                              child: Text('${i + 1}',
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 13)),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(instructions[i],
                                style: const TextStyle(
                                    fontSize: 14,
                                    height: 1.5,
                                    color: Color(0xFFE5E7EB))),
                          ),
                        ],
                      ),
                    ),
                  ),
                  ListView.builder(
                    controller: controller,
                    padding: const EdgeInsets.all(16),
                    itemCount: tips.length,
                    itemBuilder: (_, i) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                            color: const Color(0xFFF59E0B).withAlpha(20),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: const Color(0xFFF59E0B).withAlpha(60))),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.lightbulb_outline,
                                size: 16, color: Color(0xFFF59E0B)),
                            const SizedBox(width: 8),
                            Expanded(
                                child: Text(tips[i],
                                    style: const TextStyle(
                                        fontSize: 13,
                                        height: 1.4,
                                        color: Color(0xFFE5E7EB)))),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
          color: Colors.white.withAlpha(40),
          borderRadius: BorderRadius.circular(8)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Colors.white),
          const SizedBox(width: 4),
          Text(label,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// "Yeni Yemek Fikri" seçim sheet'i (FamilyWall tarzı)
// ═══════════════════════════════════════════════════════════════════════════
class _NewFoodIdeaSheet extends StatelessWidget {
  final VoidCallback onOwn;
  final VoidCallback onWeb;
  const _NewFoodIdeaSheet({required this.onOwn, required this.onWeb});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF13131A),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(40),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              const Text('Yeni Yemek Fikri',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w800)),
              const SizedBox(height: 16),
              _IdeaCard(
                color: const Color(0xFF4F7DF3),
                icon: Icons.restaurant,
                title: 'Kendi Tarifini Ekle',
                subtitle:
                    'Anneannenin elmalı turtası ya da kendi yaratımın olsun.',
                onTap: onOwn,
              ),
              const SizedBox(height: 12),
              _IdeaCard(
                color: const Color(0xFFF07167),
                icon: Icons.link,
                title: 'Web Tarifi Ekle',
                subtitle: 'Web\'de bulduğun güzel bir tarifin linkini yapıştır.',
                onTap: onWeb,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _IdeaCard extends StatelessWidget {
  final Color color;
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  const _IdeaCard({
    required this.color,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w800)),
                  const SizedBox(height: 4),
                  Text(subtitle,
                      style: TextStyle(
                          color: Colors.white.withAlpha(220),
                          fontSize: 12.5,
                          height: 1.3)),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(40),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: Colors.white, size: 24),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Tarif ekleme formu — kendi tarifin veya web linki
// ═══════════════════════════════════════════════════════════════════════════
class _AddRecipeSheet extends StatefulWidget {
  final Future<void> Function(Map<String, dynamic>) onSave;
  final bool fromWeb;
  const _AddRecipeSheet({required this.onSave, required this.fromWeb});

  @override
  State<_AddRecipeSheet> createState() => _AddRecipeSheetState();
}

class _AddRecipeSheetState extends State<_AddRecipeSheet> {
  final _title = TextEditingController();
  final _url = TextEditingController();
  final _ingredients = TextEditingController();
  final _steps = TextEditingController();
  String _category = 'ana_yemek';
  bool _generating = false;

  static const _cats = [
    ('kahvalti', 'Kahvaltı'),
    ('ana_yemek', 'Ana Yemek'),
    ('corba', 'Çorba'),
    ('tatli', 'Tatlı'),
    ('salata', 'Salata'),
  ];

  @override
  void dispose() {
    _title.dispose();
    _url.dispose();
    _ingredients.dispose();
    _steps.dispose();
    super.dispose();
  }

  Future<void> _generateWithAI() async {
    final title = _title.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Önce tarif adını yazın, AI gerisini doldursun')),
      );
      return;
    }
    setState(() => _generating = true);
    final catLabel = _cats.firstWhere((c) => c.$1 == _category).$2;
    final prompt = '''
"$title" ($catLabel) için bir aile tarifi oluştur.
Sadece JSON döndür:
{"ingredients": ["2 su bardağı un", "1 çay kaşığı tuz"], "steps": ["Malzemeleri karıştır.", "Fırında 20 dk pişir."]}
Malzemeler miktarıyla, adımlar kısa ve net olsun. Türkçe.''';
    try {
      final res = await AIEngine.generate(
        prompt: prompt,
        format: AIResponseFormat.json,
        maxTokens: 700,
        temperature: 0.6,
      );
      var s = res.content.trim();
      final start = s.indexOf('{');
      final end = s.lastIndexOf('}');
      if (start >= 0 && end > start) s = s.substring(start, end + 1);
      final obj = jsonDecode(s);
      final ings = (obj is Map ? obj['ingredients'] : null);
      final steps = (obj is Map ? obj['steps'] : null);
      if (ings is List && ings.isNotEmpty) {
        _ingredients.text = ings.map((e) => e.toString()).join('\n');
      }
      if (steps is List && steps.isNotEmpty) {
        _steps.text = steps.map((e) => e.toString()).join('\n');
      }
      if (mounted && (ings is! List || ings.isEmpty)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('AI şu an yanıt veremedi, elle doldurabilirsin')),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('AI şu an yanıt veremedi, elle doldurabilirsin')),
        );
      }
    } finally {
      if (mounted) setState(() => _generating = false);
    }
  }

  Future<void> _save() async {
    final title = _title.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen bir tarif adı girin')),
      );
      return;
    }
    if (widget.fromWeb && _url.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen tarif linkini yapıştırın')),
      );
      return;
    }

    final ingredients = _ingredients.text
        .split('\n')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .map((e) => {'name': e, 'amount': '', 'unit': ''})
        .toList();
    final steps = _steps.text
        .split('\n')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    final recipe = <String, dynamic>{
      'id': 'custom_${DateTime.now().millisecondsSinceEpoch}',
      'title': title,
      'category': _category,
      'custom': true,
      'ingredients': ingredients,
      'steps': steps,
      'tips': const <String>[],
      if (widget.fromWeb) 'source_url': _url.text.trim(),
    };

    await widget.onSave(recipe);
    if (!mounted) return;
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('"$title" tarif kutuna eklendi')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: DraggableScrollableSheet(
        initialChildSize: 0.85,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        expand: false,
        builder: (_, ctrl) => Container(
          decoration: const BoxDecoration(
            color: Color(0xFF13131A),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: ListView(
            controller: ctrl,
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                      color: Colors.white.withAlpha(40),
                      borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 16),
              Text(widget.fromWeb ? 'Web Tarifi Ekle' : 'Kendi Tarifini Ekle',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w800)),
              const SizedBox(height: 16),
              _field('Tarif Adı', _title, hint: 'Örn: Mercimek Çorbası'),
              if (widget.fromWeb) ...[
                const SizedBox(height: 12),
                _field('Tarif Linki (URL)', _url,
                    hint: 'https://...', keyboard: TextInputType.url),
              ],
              const SizedBox(height: 12),
              const Text('Kategori',
                  style: TextStyle(
                      color: Color(0xFFD1D5DB),
                      fontSize: 13,
                      fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _cats.map((c) {
                  final sel = _category == c.$1;
                  return GestureDetector(
                    onTap: () => setState(() => _category = c.$1),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: sel
                            ? const Color(0xFFF59E0B)
                            : const Color(0xFF1A1A24),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(c.$2,
                          style: TextStyle(
                              color: sel
                                  ? Colors.white
                                  : const Color(0xFF9CA3AF),
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600)),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 46,
                child: OutlinedButton.icon(
                  onPressed: _generating ? null : _generateWithAI,
                  icon: _generating
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Color(0xFF8B5CF6)),
                        )
                      : const Icon(Icons.auto_awesome,
                          size: 18, color: Color(0xFF8B5CF6)),
                  label: Text(
                      _generating
                          ? 'AI hazırlıyor…'
                          : 'AI ile malzeme & adımları doldur',
                      style: const TextStyle(color: Color(0xFF8B5CF6))),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFF8B5CF6)),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              _field('Malzemeler (her satıra bir tane)', _ingredients,
                  hint: '2 su bardağı un\n1 çay kaşığı tuz', lines: 4),
              const SizedBox(height: 12),
              _field('Hazırlanışı (her satıra bir adım)', _steps,
                  hint: 'Malzemeleri karıştırın.\nFırında 20 dk pişirin.',
                  lines: 5),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF59E0B),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text('Kaydet',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _field(String label, TextEditingController ctrl,
      {String? hint, int lines = 1, TextInputType? keyboard}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                color: Color(0xFFD1D5DB),
                fontSize: 13,
                fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        TextField(
          controller: ctrl,
          keyboardType: keyboard,
          maxLines: lines,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Color(0xFF6B7280)),
            filled: true,
            fillColor: const Color(0xFF1A1A24),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }
}

/// Bu haftaya özel, AI (internet) tarif önerileri — yatay şerit.
/// Karta dokununca tam tarif (malzeme + adımlar) alttan açılır.
class _AiRecipeStrip extends StatelessWidget {
  const _AiRecipeStrip();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: AiContentService.weeklyList(
        topic: 'recipe_ideas',
        prompt:
            'Belçika\'da yaşayan bir aile için bu haftaya özel, pratik ve '
            'sağlıklı 6 yemek önerisi üret. Sadece JSON döndür: {"items":['
            '{"title":"...","category":"...","time":"25 dk",'
            '"ingredients":["..."],"steps":["..."]}]}. Türkçe.',
        listKey: 'items',
        fallback: const [],
        maxTokens: 1500,
      ),
      builder: (context, snap) {
        final items = snap.data ?? const [];
        if (items.isEmpty) return const SizedBox.shrink();
        return Container(
          margin: const EdgeInsets.only(top: 4),
          height: 96,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 0, 16, 6),
                child: Row(
                  children: [
                    Icon(Icons.auto_awesome,
                        size: 15, color: Color(0xFFF59E0B)),
                    SizedBox(width: 6),
                    Text('Bu Haftanın AI Önerileri',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
              Expanded(
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: items.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (context, i) {
                    final m = items[i];
                    final title = m['title']?.toString() ?? 'Tarif';
                    final time = m['time']?.toString() ?? '';
                    return GestureDetector(
                      onTap: () => _showDetail(context, m),
                      child: Container(
                        width: 150,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1A1A24),
                          borderRadius: BorderRadius.circular(14),
                          border:
                              Border.all(color: const Color(0xFF262631)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700)),
                            const SizedBox(height: 4),
                            Text(time,
                                style: const TextStyle(
                                    color: Color(0xFF9CA3AF), fontSize: 11.5)),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showDetail(BuildContext context, Map<String, dynamic> m) {
    final ings = (m['ingredients'] as List?)?.map((e) => e.toString()).toList() ??
        const [];
    final steps =
        (m['steps'] as List?)?.map((e) => e.toString()).toList() ?? const [];
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.92,
        minChildSize: 0.4,
        expand: false,
        builder: (_, ctrl) => Container(
          decoration: const BoxDecoration(
            color: Color(0xFF13131A),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: ListView(
            controller: ctrl,
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                      color: Colors.white.withAlpha(40),
                      borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 16),
              Text(m['title']?.toString() ?? 'Tarif',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w900)),
              const SizedBox(height: 4),
              Text(
                  '${m['category'] ?? ''}${m['time'] != null ? ' · ${m['time']}' : ''}',
                  style: const TextStyle(color: Color(0xFF9CA3AF))),
              if (ings.isNotEmpty) ...[
                const SizedBox(height: 18),
                const Text('Malzemeler',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w800)),
                const SizedBox(height: 8),
                for (final ing in ings)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Text('• $ing',
                        style: const TextStyle(
                            color: Color(0xFFD1D5DB), fontSize: 14)),
                  ),
              ],
              if (steps.isNotEmpty) ...[
                const SizedBox(height: 14),
                const Text('Hazırlanışı',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w800)),
                const SizedBox(height: 8),
                for (var i = 0; i < steps.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text('${i + 1}. ${steps[i]}',
                        style: const TextStyle(
                            color: Color(0xFFD1D5DB),
                            fontSize: 14,
                            height: 1.4)),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
