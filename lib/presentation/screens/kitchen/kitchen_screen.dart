import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../config/constants.dart';
import '../../widgets/ds.dart';

class KitchenScreen extends StatefulWidget {
  const KitchenScreen({super.key});

  @override
  State<KitchenScreen> createState() => _KitchenScreenState();
}

class _KitchenScreenState extends State<KitchenScreen>
    with SingleTickerProviderStateMixin {
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
      setState(() {
        _recipes = list;
        _filtered = list;
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
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
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: AppColors.darkBackground,
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
                    onClear: (day) => setState(() => _weeklyPlan[day] = null),
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
                const Text('Aile Mutfağı',
                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 19, color: Colors.white)),
                Text('${_recipes.length} tarif · haftalık plan',
                    style: TextStyle(fontSize: 11, color: Colors.white.withAlpha(120), fontWeight: FontWeight.w500)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: amber.withAlpha(25),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: amber.withAlpha(60)),
            ),
            child: Row(
              children: [
                Icon(Icons.star_rounded, size: 14, color: amber),
                const SizedBox(width: 4),
                Text('12', style: TextStyle(color: amber, fontWeight: FontWeight.w900, fontSize: 13)),
              ],
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
        tabs: const [
          Tab(icon: Icon(Icons.restaurant_menu, size: 16), text: 'Tarifler'),
          Tab(icon: Icon(Icons.calendar_view_week, size: 16), text: 'Haftalık'),
          Tab(icon: Icon(Icons.shopping_cart_outlined, size: 16), text: 'Alışveriş'),
        ],
      ),
    );
  }

  void _showPickForDay(String day) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: BoxDecoration(
          color: AppColors.darkCard,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: const Border(
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
                      title: Text(r['title'] ?? '',
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
        const SizedBox(height: 8),
        Expanded(
          child: loading
              ? const Center(child: CircularProgressIndicator())
              : filtered.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.search_off, size: 64, color: AppColors.slate),
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
        hint: 'Tarif ara...',
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
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.78,
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
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
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
                                ? AppColors.darkBackground
                                : AppColors.background),
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
                                  : (isDark
                                      ? AppColors.darkTextSecondary
                                      : AppColors.slate)),
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
                                    style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: isDark
                                            ? AppColors.darkTextPrimary
                                            : AppColors.dark)),
                                const SizedBox(height: 2),
                                Text('Değiştirmek için dokun',
                                    style: const TextStyle(
                                        fontSize: 11,
                                        color: AppColors.slate)),
                              ],
                            )
                          : Text('Yemek seç...',
                              style: TextStyle(
                                  fontSize: 13,
                                  color: isDark
                                      ? AppColors.darkTextSecondary
                                      : AppColors.slate)),
                    ),
                    if (meal != null)
                      IconButton(
                        onPressed: () => onClear(day),
                        icon: const Icon(Icons.close,
                            size: 18, color: AppColors.slate),
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
                size: 72, color: AppColors.slate.withAlpha(100)),
            const SizedBox(height: 16),
            const Text('Önce Haftalık Plan sekmesini doldur',
                style:
                    TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            const Text('Malzeme listesi otomatik oluşturulur',
                style: TextStyle(fontSize: 13, color: AppColors.slate)),
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
          color: widget.isDark ? AppColors.darkCard : Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withAlpha(widget.isDark ? 20 : 6),
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
                    ? AppColors.softMint
                    : Colors.transparent,
                shape: BoxShape.circle,
                border: Border.all(
                    color:
                        _checked ? AppColors.softMint : AppColors.border,
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
                        ? AppColors.slate
                        : (widget.isDark
                            ? AppColors.darkTextPrimary
                            : AppColors.dark)),
              ),
            ),
            Text(
              '${ing['amount']} ${ing['unit']}',
              style: const TextStyle(
                  fontSize: 12, color: AppColors.slate),
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
        return AppColors.success;
      case 'orta':
        return AppColors.warning;
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
                children: [
                  Center(child: Icon(Icons.restaurant_outlined, size: 40, color: amber.withAlpha(150))),
                  Positioned(
                    top: 8, right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                          color: _difficultyColor.withAlpha(200),
                          borderRadius: BorderRadius.circular(8)),
                      child: Text(recipe['difficulty'] ?? '',
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
                  Text(recipe['title'] ?? '',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Ds.text),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.timer_outlined, size: 12, color: Ds.textSub),
                      const SizedBox(width: 3),
                      Text('$totalTime dk', style: const TextStyle(fontSize: 10, color: Ds.textSub)),
                      const Spacer(),
                      const Icon(Icons.star_rounded, size: 13, color: Color(0xFFFBBF24)),
                      const SizedBox(width: 2),
                      Text(rating.toStringAsFixed(1),
                          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Ds.textSub)),
                    ],
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final recipe = widget.recipe;
    final ingredients =
        (recipe['ingredients'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    final instructions =
        (recipe['instructions'] as List?)?.cast<String>() ?? [];
    final tips = (recipe['tips'] as List?)?.cast<String>() ?? [];
    final nutrition = recipe['nutrition'] as Map<String, dynamic>? ?? {};
    final totalTime = (recipe['prep_time'] as int? ?? 0) +
        (recipe['cook_time'] as int? ?? 0);

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      builder: (_, controller) => Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : Colors.white,
          borderRadius:
              const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          children: [
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2)),
              ),
            ),
            Container(
              margin: const EdgeInsets.all(16),
              height: 160,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: [Color(0xFFF97316), Color(0xFFEF4444)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Stack(
                children: [
                  Center(
                    child: Icon(Icons.restaurant,
                        size: 72,
                        color: Colors.white.withAlpha(80)),
                  ),
                  Positioned(
                    bottom: 16,
                    left: 16,
                    right: 16,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(recipe['title'] ?? '',
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
              unselectedLabelColor: AppColors.slate,
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
                        title: Text(ing['name'] ?? ''),
                        trailing: Text(
                            '${ing['amount']} ${ing['unit']}',
                            style: const TextStyle(
                                color: AppColors.slate, fontSize: 13)),
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
                                style: TextStyle(
                                    fontSize: 14,
                                    height: 1.5,
                                    color: isDark
                                        ? AppColors.darkTextPrimary
                                        : AppColors.dark)),
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
                            color: AppColors.warning.withAlpha(20),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: AppColors.warning.withAlpha(60))),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.lightbulb_outline,
                                size: 16, color: AppColors.warning),
                            const SizedBox(width: 8),
                            Expanded(
                                child: Text(tips[i],
                                    style: TextStyle(
                                        fontSize: 13,
                                        height: 1.4,
                                        color: isDark
                                            ? AppColors.darkTextPrimary
                                            : AppColors.dark))),
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
