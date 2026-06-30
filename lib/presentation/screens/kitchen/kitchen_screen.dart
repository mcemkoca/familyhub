import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../config/constants.dart';

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
    _tabController = TabController(length: 2, vsync: this);
    _loadRecipes();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadRecipes() async {
    try {
      final raw = await rootBundle.loadString('assets/data/content/recipes.json');
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.darkBackground : AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(isDark),
            _buildSearch(isDark),
            _buildCategoryChips(isDark),
            const SizedBox(height: 8),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _filtered.isEmpty
                      ? _buildEmpty()
                      : _buildGrid(isDark),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFF97316), Color(0xFFEF4444)],
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.restaurant, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Mutfak',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: isDark
                          ? AppColors.darkTextPrimary
                          : AppColors.dark,
                    ),
              ),
              Text(
                '${_recipes.length} tarif & yemek önerisi',
                style: TextStyle(
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.slate,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const Spacer(),
          IconButton(
            onPressed: () {},
            icon: Icon(
              Icons.bookmark_outline,
              color: isDark ? AppColors.darkTextSecondary : AppColors.slate,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearch(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      child: TextField(
        onChanged: (v) {
          _searchQuery = v;
          _applyFilter();
        },
        style: TextStyle(
            color: isDark ? AppColors.darkTextPrimary : AppColors.dark),
        decoration: InputDecoration(
          hintText: 'Tarif ara...',
          prefixIcon: const Icon(Icons.search, size: 20),
          filled: true,
          fillColor: isDark ? AppColors.darkCard : Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }

  Widget _buildCategoryChips(bool isDark) {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: _categories.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final (id, label, icon) = _categories[i];
          final active = _selectedCategory == id;
          return GestureDetector(
            onTap: () {
              setState(() => _selectedCategory = id);
              _applyFilter();
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: active
                    ? AppColors.coral
                    : (isDark ? AppColors.darkCard : Colors.white),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: active
                      ? AppColors.coral
                      : (isDark
                          ? AppColors.darkBorder
                          : AppColors.border),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon,
                      size: 14,
                      color: active
                          ? Colors.white
                          : (isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.slate)),
                  const SizedBox(width: 6),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: active
                          ? FontWeight.w700
                          : FontWeight.w500,
                      color: active
                          ? Colors.white
                          : (isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.slate),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildGrid(bool isDark) {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.78,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: _filtered.length,
      itemBuilder: (context, i) => _RecipeCard(
        recipe: _filtered[i],
        isDark: isDark,
        onTap: () => _showRecipeDetail(_filtered[i]),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.search_off, size: 64, color: AppColors.slate),
          const SizedBox(height: 12),
          Text('Tarif bulunamadı',
              style: Theme.of(context).textTheme.titleMedium),
        ],
      ),
    );
  }

  void _showRecipeDetail(Map<String, dynamic> recipe) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => RecipeDetailSheet(recipe: recipe),
    );
  }
}

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
    final totalTime =
        (recipe['prep_time'] as int? ?? 0) + (recipe['cook_time'] as int? ?? 0);
    final rating = (recipe['rating'] as num?)?.toDouble() ?? 4.0;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(isDark ? 30 : 8),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image placeholder
            Container(
              height: 110,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.coral.withAlpha(60),
                    AppColors.orange.withAlpha(40),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Stack(
                children: [
                  Center(
                    child: Icon(
                      Icons.restaurant,
                      size: 44,
                      color: AppColors.coral.withAlpha(180),
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _difficultyColor.withAlpha(220),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        recipe['difficulty'] ?? '',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w700),
                      ),
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
                  Text(
                    recipe['title'] ?? '',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: isDark
                          ? AppColors.darkTextPrimary
                          : AppColors.dark,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(Icons.timer_outlined,
                          size: 12, color: AppColors.slate),
                      const SizedBox(width: 3),
                      Text(
                        '$totalTime dk',
                        style: const TextStyle(
                            fontSize: 11, color: AppColors.slate),
                      ),
                      const Spacer(),
                      Icon(Icons.star_rounded,
                          size: 13, color: AppColors.warning),
                      const SizedBox(width: 2),
                      Text(
                        rating.toStringAsFixed(1),
                        style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.slate),
                      ),
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
    final nutrition =
        recipe['nutrition'] as Map<String, dynamic>? ?? {};
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
            // Handle
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            // Hero area
            Container(
              margin: const EdgeInsets.all(16),
              height: 160,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFF97316), Color(0xFFEF4444)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
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
                        Text(
                          recipe['title'] ?? '',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            _InfoChip(
                                icon: Icons.timer,
                                label: '$totalTime dk'),
                            const SizedBox(width: 8),
                            _InfoChip(
                                icon: Icons.people,
                                label:
                                    '${recipe['servings'] ?? 4} kişi'),
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
            // Tabs
            TabBar(
              controller: _tab,
              labelColor: AppColors.coral,
              unselectedLabelColor: AppColors.slate,
              indicatorColor: AppColors.coral,
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
                  // Ingredients
                  ListView.separated(
                    controller: controller,
                    padding: const EdgeInsets.all(16),
                    itemCount: ingredients.length,
                    separatorBuilder: (_, _) =>
                        const Divider(height: 1),
                    itemBuilder: (_, i) {
                      final ing = ingredients[i];
                      return ListTile(
                        leading: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: AppColors.coral.withAlpha(30),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              '${i + 1}',
                              style: const TextStyle(
                                  color: AppColors.coral,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12),
                            ),
                          ),
                        ),
                        title: Text(ing['name'] ?? ''),
                        trailing: Text(
                          '${ing['amount']} ${ing['unit']}',
                          style: const TextStyle(
                              color: AppColors.slate, fontSize: 13),
                        ),
                      );
                    },
                  ),
                  // Instructions
                  ListView.builder(
                    controller: controller,
                    padding: const EdgeInsets.all(16),
                    itemCount: instructions.length,
                    itemBuilder: (_, i) => _StepTile(
                      step: i + 1,
                      text: instructions[i],
                      isDark: isDark,
                    ),
                  ),
                  // Tips
                  ListView.builder(
                    controller: controller,
                    padding: const EdgeInsets.all(16),
                    itemCount: tips.length,
                    itemBuilder: (_, i) => _TipTile(
                        tip: tips[i], isDark: isDark),
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
        borderRadius: BorderRadius.circular(8),
      ),
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

class _StepTile extends StatelessWidget {
  final int step;
  final String text;
  final bool isDark;
  const _StepTile(
      {required this.step, required this.text, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                  colors: [Color(0xFFF97316), Color(0xFFEF4444)]),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(
                '$step',
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 14),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14,
                height: 1.5,
                color: isDark
                    ? AppColors.darkTextPrimary
                    : AppColors.dark,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TipTile extends StatelessWidget {
  final String tip;
  final bool isDark;
  const _TipTile({required this.tip, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: AppColors.warning.withAlpha(30),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Center(
              child: Icon(Icons.lightbulb_outline,
                  size: 16, color: AppColors.warning),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(tip,
                style: TextStyle(
                    fontSize: 14,
                    height: 1.4,
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.dark)),
          ),
        ],
      ),
    );
  }
}
