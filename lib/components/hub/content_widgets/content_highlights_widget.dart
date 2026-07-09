import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../config/constants.dart';
import '../../../config/routes.dart';
import '../../../services/content/content_engine.dart';
import '../../../services/content/content_models.dart';
import '../../../services/hive_service.dart';

/// Horizontal scrollable content highlights for the Hub screen.
/// Shows: daily meal, household tip, budget tip, emergency contacts.
class ContentHighlightsWidget extends StatefulWidget {
  const ContentHighlightsWidget({super.key});

  @override
  State<ContentHighlightsWidget> createState() => _ContentHighlightsWidgetState();
}

class _ContentHighlightsWidgetState extends State<ContentHighlightsWidget> {
  bool get isDark => Theme.of(context).brightness == Brightness.dark;

  late bool _expanded =
      HiveService.getBoolSetting('kesfet_expanded', defaultValue: true);

  void _toggle() {
    setState(() => _expanded = !_expanded);
    HiveService.setBoolSetting('kesfet_expanded', _expanded);
  }

  void _cycleAll() {
    final engine = ContentEngine.instance;
    engine.nextRecipe();
    engine.nextTip();
    engine.nextTask();
    engine.nextSavingTip();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final engine = ContentEngine.instance;

    final items = <Widget>[
      _buildMealCard(engine, isDark),
      _buildChildDevCard(engine, isDark),
      _buildHouseholdCard(engine, isDark),
      _buildBudgetCard(engine, isDark),
      _buildEmergencyCard(engine, isDark),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.md,
            AppSpacing.md,
            AppSpacing.sm,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: InkWell(
                  onTap: _toggle,
                  borderRadius: BorderRadius.circular(8),
                  child: Row(
                    children: [
                      Text(
                        'Keşfet',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 4),
                      AnimatedRotation(
                        turns: _expanded ? 0.5 : 0,
                        duration: const Duration(milliseconds: 200),
                        child: const Icon(Icons.keyboard_arrow_down_rounded,
                            size: 22, color: Color(0xFF9CA3AF)),
                      ),
                    ],
                  ),
                ),
              ),
              if (_expanded)
                TextButton.icon(
                  onPressed: _cycleAll,
                  icon: const Icon(Icons.shuffle, size: 18),
                  label: const Text('Başka Öneri'),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF6366F1),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ),
            ],
          ),
        ),
        if (_expanded)
          SizedBox(
            height: 140,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              scrollDirection: Axis.horizontal,
              itemCount: items.length,
              separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
              itemBuilder: (context, index) => items[index],
            ),
          ),
      ],
    );
  }

  Widget _buildMealCard(ContentEngine engine, bool isDark) {
    final recipe = engine.dailyRecipe;
    final todayMeals = engine.todayMeals;

    return _HighlightCard(
      icon: Icons.restaurant_menu,
      iconColor: AppColors.orange,
      title: 'Bugünün Yemeği',
      subtitle: recipe?.name ?? todayMeals?.dinner ?? '—',
      detail: recipe != null
          ? '${recipe.prepTime} hazırlık · ${recipe.costEstimateEur.toStringAsFixed(0)}€'
          : null,
      isDark: isDark,
      onTap: (context) => _showRecipeDetail(context, recipe),
      onCycle: () => setState(() => engine.nextRecipe()),
    );
  }

  Widget _buildChildDevCard(ContentEngine engine, bool isDark) {
    final activity = engine.dailyActivity;
    final ageGroup = engine.dailyActivityAgeGroup;

    return _HighlightCard(
      icon: Icons.child_care,
      iconColor: const Color(0xFF8B5CF6),
      title: 'Çocuk Gelişimi',
      subtitle: activity?.name ?? '—',
      detail: ageGroup != null ? '$ageGroup · ${activity?.durationMinutes ?? 15} dk' : null,
      isDark: isDark,
      onTap: (context) => _showChildDevDetail(context, activity),
      onCycle: () => setState(() {}),
    );
  }

  Widget _buildHouseholdCard(ContentEngine engine, bool isDark) {
    final task = engine.todayCleaningTask;
    final tip = engine.dailyHouseholdTip;

    return _HighlightCard(
      icon: Icons.cleaning_services,
      iconColor: AppColors.cyan,
      title: 'Ev İşleri',
      subtitle: task ?? '—',
      detail: tip,
      isDark: isDark,
      onTap: (context) => _showHouseholdDetail(context, task, tip),
      onCycle: () => setState(() { engine.nextTask(); engine.nextTip(); }),
    );
  }

  Widget _buildBudgetCard(ContentEngine engine, bool isDark) {
    final tip = engine.dailySavingTip;

    return _HighlightCard(
      icon: Icons.savings,
      iconColor: AppColors.green,
      title: 'Tasarruf İpucu',
      subtitle: tip?.tip ?? '—',
      detail: tip != null ? '~${tip.monthlySavingsEur}€/ay tasarruf' : null,
      isDark: isDark,
      onTap: (context) => _showBudgetDetail(context, tip),
      onCycle: () => setState(() => engine.nextSavingTip()),
    );
  }

  Widget _buildEmergencyCard(ContentEngine engine, bool isDark) {
    final contacts = engine.emergencyContacts;
    final emergency = contacts.isNotEmpty ? contacts.first : null;

    return _HighlightCard(
      icon: Icons.emergency,
      iconColor: AppColors.error,
      title: 'Acil Durum',
      subtitle: emergency?.name ?? '—',
      detail: emergency?.number,
      isDark: isDark,
      onTap: (context) => _showEmergencyDetail(context, contacts),
    );
  }

  /// Detay sayfasını kapatıp ilgili gerçek bölüme gider (Keşfet senkronu).
  Widget _goToSectionButton(BuildContext ctx, String route, String label) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: SizedBox(
        width: double.infinity,
        height: 50,
        child: ElevatedButton.icon(
          onPressed: () {
            Navigator.pop(ctx);
            ctx.go(route);
          },
          icon: const Icon(Icons.arrow_forward_rounded, size: 20),
          label: Text(label),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF6366F1),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14)),
            textStyle:
                const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
          ),
        ),
      ),
    );
  }

  // ── Detail Bottom Sheets ────────────────────────────────────────────────

  void _showRecipeDetail(BuildContext context, Recipe? recipe) {
    if (recipe == null) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF0A0A0F),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (_, scrollController) {
          return SingleChildScrollView(
            controller: scrollController,
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFF9CA3AF),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.orange.withAlpha(40),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(Icons.restaurant_menu, color: AppColors.orange, size: 28),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            recipe.name,
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${recipe.prepTime} hazırlık · ${recipe.cookTime} pişirme · ${recipe.servings} kişilik · ${recipe.difficulty}',
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF6B7280),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (recipe.description.isNotEmpty)
                  Text(
                    recipe.description,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF6B7280),
                      height: 1.5,
                    ),
                  ),
                const SizedBox(height: 20),
                _buildDetailSection(context, 'Malzemeler', [
                  ...recipe.ingredients.map((i) => '• ${i.item} — ${i.amount}${i.alternative != null ? ' (veya ${i.alternative})' : ''}'),
                ]),
                const SizedBox(height: 20),
                _buildDetailSection(context, 'Hazırlanış', recipe.instructions.map((s) => '• $s').toList()),
                if (recipe.kidFriendlyModifications.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  _buildDetailSection(context, 'Çocuklar İçin', ['• ${recipe.kidFriendlyModifications}']),
                ],
                if (recipe.nutritionalHighlights.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  _buildDetailSection(context, 'Besin Değerleri', recipe.nutritionalHighlights.map((s) => '• $s').toList()),
                ],
                const SizedBox(height: 12),
                _goToSectionButton(ctx, AppRoutes.kitchen, 'Mutfağa Git'),
                const SizedBox(height: 20),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showHouseholdDetail(BuildContext context, String? task, String? tip) {
    if (task == null && tip == null) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0A0A0F),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFF9CA3AF),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.cyan.withAlpha(40),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(Icons.cleaning_services, color: AppColors.cyan, size: 28),
                ),
                const SizedBox(width: 16),
                Text(
                  'Ev İşleri Detayı',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFFE5E7EB),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (task != null && task.isNotEmpty)
              _buildDetailSection(context, 'Bugünkü Görev', ['• $task']),
            if (tip != null && tip.isNotEmpty) ...[
              const SizedBox(height: 16),
              _buildDetailSection(context, 'Ev İşi İpucu', ['• $tip']),
            ],
            const SizedBox(height: 12),
            _goToSectionButton(ctx, AppRoutes.subscriptions, 'Ev Giderlerine Git'),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  void _showBudgetDetail(BuildContext context, CostCuttingTip? tip) {
    if (tip == null) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0A0A0F),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFF9CA3AF),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.green.withAlpha(40),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(Icons.savings, color: AppColors.green, size: 28),
                ),
                const SizedBox(width: 16),
                Text(
                  'Tasarruf Detayı',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFFE5E7EB),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildDetailSection(context, 'İpucu', ['• ${tip.tip}']),
            const SizedBox(height: 16),
            _buildDetailSection(context, 'Kategori', ['• ${tip.category}']),
            const SizedBox(height: 16),
            _buildDetailSection(context, 'Tahmini Tasarruf', ['• ~${tip.monthlySavingsEur}€/ay']),
            const SizedBox(height: 12),
            _goToSectionButton(ctx, AppRoutes.budget, 'Bütçeye Git'),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  void _showEmergencyDetail(BuildContext context, List<EmergencyContact> contacts) {
    if (contacts.isEmpty) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0A0A0F),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFF9CA3AF),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.error.withAlpha(40),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(Icons.emergency, color: AppColors.error, size: 28),
                ),
                const SizedBox(width: 16),
                Text(
                  'Acil Durum Kişileri',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFFE5E7EB),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...contacts.map((c) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF13131A),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0x1EFFFFFF).withAlpha(30),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.phone, color: AppColors.error, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            c.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                              color: Color(0xFFE5E7EB),
                            ),
                          ),
                          Text(
                            c.role,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF6B7280),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      c.number,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: AppColors.error,
                      ),
                    ),
                  ],
                ),
              ),
            )),
            const SizedBox(height: 12),
            _goToSectionButton(ctx, AppRoutes.emergency, 'Acil Duruma Git'),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  void _showChildDevDetail(BuildContext context, Activity? activity) {
    if (activity == null) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0A0A0F),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFF9CA3AF),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF8B5CF6).withAlpha(40),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(Icons.child_care, color: Color(0xFF8B5CF6), size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    activity.name,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFFE5E7EB),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              activity.description,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF6B7280),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 16),
            _buildDetailSection(context, 'Malzemeler', activity.materials.map((m) => '• $m').toList()),
            const SizedBox(height: 16),
            _buildDetailSection(context, 'Kazanım', ['• ${activity.learningOutcome}']),
            if (activity.turkishCulturalContext != null) ...[
              const SizedBox(height: 16),
              _buildDetailSection(context, 'Türk Kültürü', ['• ${activity.turkishCulturalContext}']),
            ],
            const SizedBox(height: 16),
            _buildDetailSection(context, 'Güvenlik', ['• ${activity.safetyNotes}']),
            const SizedBox(height: 12),
            _goToSectionButton(ctx, AppRoutes.childDevelopment, 'Gelişime Git'),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailSection(BuildContext context, String title, List<String> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        ...items.map((item) => Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Text(
            item,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF6B7280),
              height: 1.4,
            ),
          ),
        )),
      ],
    );
  }
}

// ── Internal Card Widget ────────────────────────────────────────────────

class _HighlightCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final String? detail;
  final bool isDark;
  final void Function(BuildContext context)? onTap;
  final VoidCallback? onCycle;

  const _HighlightCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    this.detail,
    required this.isDark,
    this.onTap,
    this.onCycle,
  });

  @override
  Widget build(BuildContext context) {
    final card = Container(
      width: 220,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: const Color(0xFF13131A),
        borderRadius: BorderRadius.circular(AppRadius.medium),
        border: Border.all(
          color: const Color(0x1EFFFFFF),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: iconColor.withAlpha(40),
                  borderRadius: BorderRadius.circular(AppRadius.small - 4),
                ),
                child: Icon(icon, color: iconColor, size: 18),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: const Color(0xFF6B7280),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (onCycle != null)
                GestureDetector(
                  onTap: onCycle,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: iconColor.withAlpha(30),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Icon(
                      Icons.refresh,
                      size: 14,
                      color: iconColor,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Expanded(
            child: Text(
              subtitle,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: const Color(0xFFE5E7EB),
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (detail != null && detail!.isNotEmpty)
            Text(
              detail!,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: isDark
                    ? const Color(0xFF6B7280)
                    : const Color(0xFF9CA3AF),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
        ],
      ),
    );

    if (onTap == null) return card;

    return InkWell(
      onTap: () => onTap!(context),
      borderRadius: BorderRadius.circular(AppRadius.medium),
      child: card,
    );
  }
}
