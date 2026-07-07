import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';
import '../../config/constants.dart';
import '../../config/routes.dart';
import '../../core/analytics/analytics_service.dart';
import '../../domain/entities.dart';
import '../../domain/models/ai_suggestion.dart';
import '../../presentation/providers/app_providers.dart';
import '../../repositories/hub_repository.dart';
import '../../services/ai/ai_engine.dart';
import '../../services/ai/ai_prompts.dart';
import '../../services/billing/subscription_service.dart';
import '../../services/content/daily_suggestions_pool.dart';
import '../../repositories/child_account_repository.dart';
import '../../services/content/family_suggestions_pool.dart';
import '../../services/hive_service.dart';


/// AI-powered smart suggestions widget for the Hub screen.
/// Phase 2: Rich cards with badges, nutrition info, steps, alternatives,
/// postpone, share, comment, and progress tracking.
class AISuggestionsWidget extends ConsumerStatefulWidget {
  const AISuggestionsWidget({super.key});

  @override
  ConsumerState<AISuggestionsWidget> createState() =>
      _AISuggestionsWidgetState();
}

class _AISuggestionsWidgetState extends ConsumerState<AISuggestionsWidget> {
  bool get isDark => Theme.of(context).brightness == Brightness.dark;

  List<AISuggestion> _suggestions = [];
  bool _loading = false;
  String? _error;
  bool _expanded = false; // varsayılan kapalı — butonlar görünsün, tek tıkla açılır


  @override
  void initState() {
    super.initState();
    _loadSuggestions();
  }

  Future<void> _loadSuggestions() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final familyId = await ref.read(familyIdProvider.future);

      // familyId yoksa local pool'dan öneri göster (aile gerektirmiyor)
      final String? resolvedFamilyId = familyId;

      final today = DateTime.now();
      final shownIds = HiveService.getShownSuggestionIds();

      // Pick daily suggestions from pool (no-repeat logic)
      final daily = DailySuggestionsPool.pickDaily(
        date: today,
        excludedIds: shownIds,
        count: 8,
      );

      // Pick family suggestions from new 1000+ pool
      List<AISuggestion> familySuggestions = [];
      if (HiveService.getFamilySuggestionsEnabled()) {
        try {
          final enabledCats = HiveService.getFamilySuggestionsCategories().toSet();
          final perDay = HiveService.getFamilySuggestionsPerDay();
          // Get child's age for age-filtered suggestions
          int? childAge;
          try {
            if (resolvedFamilyId != null) {
              final children = await ChildAccountRepository().getChildrenForFamily(resolvedFamilyId);
              if (children.isNotEmpty) {
                final active = children.where((c) => c.isActive).toList();
                childAge = (active.isNotEmpty ? active.first : children.first).age;
              }
            }
          } catch (e) { debugPrint('AI suggestions error: $e'); }
          familySuggestions = FamilySuggestionsPool.instance.pickDaily(
            date: today,
            enabledCategories: enabledCats,
            excludedIds: shownIds,
            count: perDay,
            childAge: childAge,
          );
        } catch (e) { debugPrint('AI suggestions error: $e'); }
      }

      // Also load AI suggestions as bonus
      List<AISuggestion> aiSuggestions = [];
      final canUseAI = SubscriptionService.canUseAI();
      if (canUseAI) {
        try {
          TodaySummary hubData;
          try {
            final repo = HubRepository();
            hubData = resolvedFamilyId != null
                ? await repo.getTodaySummary(resolvedFamilyId)
                : const TodaySummary(eventCount: 0, taskCount: 0, unreadMessages: 0, onlineMembers: 0, totalMembers: 0);
          } catch (e) {
            hubData = const TodaySummary(
              eventCount: 0,
              taskCount: 0,
              unreadMessages: 0,
              onlineMembers: 0,
              totalMembers: 0,
            );
          }
          final prompt = AIPrompts.buildHubPrompt(hubData);
          final response = await AIEngine.generate(
            prompt: prompt,
            systemPrompt: AIPrompts.hubSystemPrompt,
            format: AIResponseFormat.json,
            maxTokens: 1500,
            temperature: 0.7,
          );
          final data = jsonDecode(response.content) as Map<String, dynamic>;
          final rawSuggestions = data['suggestions'] as List<dynamic>? ?? [];
          for (final raw in rawSuggestions) {
            try {
              if (raw is Map<String, dynamic>) {
                aiSuggestions.add(AISuggestion.fromJson(raw));
              }
            } catch (e) { debugPrint('AI suggestions error: $e'); }
          }
        } catch (e) { debugPrint('AI suggestions error: $e'); }
      }

      // Merge: pool suggestions first, family pool, then AI bonus
      final all = <AISuggestion>[...daily, ...familySuggestions, ...aiSuggestions];
      final newIds = all.map((s) => s.id).toList();

      // Save shown IDs
      await HiveService.addShownSuggestionIds(newIds);

      if (mounted) {
        setState(() {
          _suggestions = all.take(8).toList();
          _loading = false;
        });
      }

      await _cacheSuggestions(resolvedFamilyId, all, 'local_pool');

      AnalyticsService.track(
        'ai_suggestions_loaded',
        properties: {
          'count': all.length,
          'poolCount': daily.length,
          'aiCount': aiSuggestions.length,
          'provider': 'local_pool',
        },
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
      AnalyticsService.track('ai_suggestions_error', properties: {'error': e.toString()});
    }
  }

  int _refreshTick = 0;

  // "Yenile": her dokunuşta farklı bir set üretir ve mevcut listeyi DEĞİŞTİRİR
  // (havuz tükense bile boş kalmaz).
  void _refreshSuggestions() {
    _refreshTick++;
    final seedDate = DateTime.now().add(Duration(days: _refreshTick * 11));
    final daily = DailySuggestionsPool.pickMore(
      date: seedDate,
      alreadyShownIds: const [],
      count: 6,
    );
    List<AISuggestion> family = [];
    if (HiveService.getFamilySuggestionsEnabled()) {
      try {
        final cats = HiveService.getFamilySuggestionsCategories().toSet();
        family = FamilySuggestionsPool.instance.pickMore(
          date: seedDate,
          enabledCategories: cats,
          alreadyShownIds: const [],
          count: 4,
        );
      } catch (_) {}
    }
    final all = [...daily, ...family]..shuffle();
    if (all.isEmpty) return;
    setState(() {
      _suggestions = all.take(8).toList();
    });
  }

  Future<void> _cacheSuggestions(
    String? familyId,
    List<AISuggestion> suggestions,
    String provider,
  ) async {
    if (familyId == null) return;
    try {
      await HubRepository().cacheSuggestions(
        familyId,
        suggestions.map((s) => s.toJson()).toList(),
        provider: provider,
      );
    } catch (e) { debugPrint('AI suggestions error: $e'); }
  }

  void _showDetailModal(AISuggestion suggestion) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _SuggestionDetailSheet(
        suggestion: suggestion,
        onAddToShoppingList: _addToShoppingList,
        onToggleFavorite: _toggleFavorite,
        onDismiss: _dismissSuggestion,
        onAction: () => _executeAction(suggestion.action),
        onPostpone: (minutes) => _postponeSuggestion(suggestion.id, minutes),
        onShare: () => _shareSuggestion(suggestion),
        onAddComment: (comment) => _addComment(suggestion.id, comment),
        onShowAlternatives: suggestion.allowAlternatives
            ? () => _showAlternatives(suggestion)
            : null,
        onProgressUpdate: (progress) =>
            _updateProgress(suggestion.id, progress),
      ),
    );
  }

  void _addToShoppingList(List<Ingredient> missing) {
    final newItems = missing
        .map((i) => ShoppingItem(
              id: 'ai_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(1000)}',
              name: i.name,
              quantity: i.amount,
              requestedBy: 'AI Öneri',
            ))
        .toList();
    ref.read(shoppingItemsProvider.notifier).addItems(newItems);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${newItems.length} ürün alışveriş listesine eklendi'),
        backgroundColor: const Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
      ),
    );
    AnalyticsService.track('ai_suggestion_add_to_shopping');
  }

  void _toggleFavorite(String id) {
    setState(() {
      _suggestions = _suggestions.map((s) {
        if (s.id == id) return s.copyWith(isFavorite: !s.isFavorite);
        return s;
      }).toList();
    });
    AnalyticsService.track('ai_suggestion_toggle_favorite');
  }

  void _dismissSuggestion(String id) {
    setState(() {
      _suggestions = _suggestions.where((s) => s.id != id).toList();
    });
    AnalyticsService.track('ai_suggestion_dismiss');
  }

  void _postponeSuggestion(String id, int minutes) {
    setState(() {
      _suggestions = _suggestions.where((s) => s.id != id).toList();
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$minutes dakika sonra hatırlatılacak'),
        behavior: SnackBarBehavior.floating,
      ),
    );
    AnalyticsService.track(
      'ai_suggestion_postpone',
      properties: {'minutes': minutes},
    );
  }

  void _shareSuggestion(AISuggestion suggestion) {
    // In a real app, this would open a share dialog or send to chat
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Aile grubuna paylaşıldı'),
        behavior: SnackBarBehavior.floating,
      ),
    );
    AnalyticsService.track('ai_suggestion_share');
  }

  void _addComment(String id, String comment) {
    setState(() {
      _suggestions = _suggestions.map((s) {
        if (s.id == id) return s.copyWith(userComment: comment);
        return s;
      }).toList();
    });
    AnalyticsService.track('ai_suggestion_comment');
  }

  void _updateProgress(String id, int progress) {
    setState(() {
      _suggestions = _suggestions.map((s) {
        if (s.id == id) return s.copyWith(progress: progress);
        return s;
      }).toList();
    });
    AnalyticsService.track(
      'ai_suggestion_progress',
      properties: {'progress': progress},
    );
  }

  void _showAlternatives(AISuggestion suggestion) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.8,
        expand: false,
        builder: (context, scrollController) {
          final color = _getColorForType(suggestion.type);
          return Container(
            decoration: const BoxDecoration(
              color: Color(0xFF0A0A0F),
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(AppRadius.large),
              ),
            ),
            child: Column(
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 8),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0x1EFFFFFF),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Text(
                    'Alternatif Öneriler',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    controller: scrollController,
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.lg),
                    itemCount: suggestion.alternativeOptions.length,
                    itemBuilder: (context, index) {
                      final alt = suggestion.alternativeOptions[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: AppSpacing.md),
                        color: const Color(0xFF13131A),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(AppRadius.medium),
                          side: BorderSide(
                            color: isDark
                                ? const Color(0x1EFFFFFF)
                                : const Color(0x1EFFFFFF),
                          ),
                        ),
                        child: ListTile(
                          leading: Icon(Icons.swap_horiz, color: color),
                          title: Text(alt.title),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(alt.description),
                              if (alt.reason != null)
                                Text(
                                  alt.reason!,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: color,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                            ],
                          ),
                          isThreeLine: alt.reason != null,
                          onTap: () {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('"${alt.title}" seçildi'),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
    AnalyticsService.track('ai_suggestion_alternatives_shown');
  }

  @override
  Widget build(BuildContext context) {

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(isDark),
          if (_expanded) ...[
            const SizedBox(height: 16),
            if (_loading && _suggestions.isEmpty)
              _buildSkeleton()
            else if (_error != null)
              _buildError(isDark)
            else if (_suggestions.isEmpty)
              _buildEmpty(isDark)
            else
              _buildGrid(isDark),
          ] else
            _buildCollapsedHint(isDark),
        ],
      ),
    );
  }

  Widget _buildCollapsedHint(bool isDark) {
    final count = _suggestions.isEmpty ? 8 : _suggestions.length;
    return GestureDetector(
      onTap: () => setState(() => _expanded = true),
      child: Container(
        margin: const EdgeInsets.only(top: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [
            const Color(0xFF6366F1).withAlpha(30),
            const Color(0xFFEC4899).withAlpha(24),
          ]),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFF6366F1).withAlpha(60)),
        ),
        child: Row(
          children: [
            const Icon(Icons.auto_awesome, size: 18, color: Color(0xFF8B5CF6)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                '$count kişisel öneri hazır — göstermek için dokun',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFC7CBD4),
                ),
              ),
            ),
            const Icon(Icons.keyboard_arrow_down_rounded,
                color: Color(0xFF8B5CF6)),
          ],
        ),
      ),
    );
  }

  Widget _buildGrid(bool isDark) {
    // hub padding(12*2) + widget margin(8*2) + spacing(12) = 56
    final width = (MediaQuery.sizeOf(context).width - 56) / 2;
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: _suggestions.take(8).map((s) {
        return SizedBox(
          width: width,
          child: _buildSuggestionCard(s, isDark),
        );
      }).toList(),
    );
  }

  Widget _buildHeader(bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => setState(() => _expanded = !_expanded),
            child: Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF6366F1), Color(0xFFEC4899)],
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.auto_awesome, size: 13, color: Colors.white),
                      SizedBox(width: 4),
                      Text(
                        'AI',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  'Günlük Öneriler',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                ),
                const SizedBox(width: 4),
                AnimatedRotation(
                  turns: _expanded ? 0.5 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: const Icon(Icons.keyboard_arrow_down_rounded,
                      color: Color(0xFF8B5CF6)),
                ),
              ],
            ),
          ),
        ),
        if (_expanded)
          GestureDetector(
            onTap: _refreshSuggestions,
            child: const Row(
              children: [
                Icon(Icons.refresh, size: 16, color: Color(0xFF6366F1)),
                SizedBox(width: 4),
                Text(
                  'Yenile',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF6366F1),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildSuggestionCard(AISuggestion s, bool isDark) {
    final color = _getColorForType(s.type);
    final icon = _getIconForType(s.type);
    final categoryLabel = _getCategoryLabel(s.type);

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF13131A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0x1EFFFFFF),
        ),
      ),
      child: InkWell(
        onTap: () => _showDetailModal(s),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top row: colored circle icon + category + arrow button
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: color.withAlpha(50),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: color, size: 22),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      categoryLabel,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: color,
                      ),
                    ),
                  ),
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: color.withAlpha(40),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.arrow_forward,
                      color: color,
                      size: 16,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Title
              Text(
                s.title,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: isDark ? const Color(0xFFE5E7EB) : const Color(0xFF111827),
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 6),

              // Description
              Text(
                s.description,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF9CA3AF),
                  height: 1.35,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),

              const SizedBox(height: 10),

              // Footer row
              Row(
                children: [
                  if (s.durationMinutes != null) ...[
                    Icon(Icons.schedule, size: 14, color: color),
                    const SizedBox(width: 4),
                    Text(
                      '${s.durationMinutes} dk',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                  ],
                  if (s.durationMinutes != null &&
                      (s.minAge != null || s.difficulty != null))
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 8),
                      width: 1,
                      height: 12,
                      color: isDark
                          ? const Color(0x1EFFFFFF)
                          : const Color(0xFFD1D5DB),
                    ),
                  if (s.minAge != null && s.maxAge != null) ...[
                    Icon(Icons.calendar_today, size: 14, color: color),
                    const SizedBox(width: 4),
                    Text(
                      '${s.minAge}-${s.maxAge} yaş',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                  ] else if (s.difficulty != null) ...[
                    Icon(Icons.trending_up, size: 14, color: color),
                    const SizedBox(width: 4),
                    Text(
                      s.difficulty!,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getCategoryLabel(String type) {
    switch (type) {
      case 'recipe':
        return 'Bugünün Yemeği';
      case 'education':
        return 'Çocuk Gelişimi';
      case 'finance':
        return 'Tasarruf Önerileri';
      case 'chore':
        return 'Ev İşleri';
      case 'health':
        return 'Sağlık';
      case 'social':
        return 'Sosyal';
      case 'safety':
        return 'Güvenlik';
      default:
        return 'Öneri';
    }
  }



  Widget _buildSkeleton() {
    final baseColor = const Color(0xFF13131A);
    final highlightColor = const Color(0x1EFFFFFF);

    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        children: List.generate(4, (index) {
          final width = (MediaQuery.sizeOf(context).width - 56) / 2;
          return SizedBox(width: width, child: _buildSkeletonCard());
        }),
      ),
    );
  }

  Widget _buildSkeletonCard() {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: const Color(0xFF13131A),
        borderRadius: BorderRadius.circular(AppRadius.large),
        border: Border.all(color: const Color(0xFF262631)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(width: 44, height: 44, color: const Color(0xFF262631)),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: double.infinity,
                      height: 16,
                      color: Colors.white,
                    ),
                    const SizedBox(height: 8),
                    Container(width: 120, height: 12, color: Colors.white),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(width: double.infinity, height: 14, color: Colors.white),
          const SizedBox(height: 8),
          Container(width: 200, height: 14, color: Colors.white),
        ],
      ),
    );
  }

  Widget _buildError(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.error.withAlpha(30),
        borderRadius: BorderRadius.circular(AppRadius.medium),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppColors.error, size: 20),
          const SizedBox(width: AppSpacing.sm),
          const Expanded(
            child: Text(
              'Öneriler yüklenirken bir hata oluştu. Tekrar deneyin.',
              style: TextStyle(color: AppColors.error, fontSize: 13),
            ),
          ),
          TextButton(
            onPressed: _loadSuggestions,
            child: const Text('Tekrar Dene'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: const Color(0xFF13131A),
        borderRadius: BorderRadius.circular(AppRadius.medium),
        border: Border.all(
          color: const Color(0x1EFFFFFF),
        ),
      ),
      child: const Row(
        children: [
          Icon(
            Icons.lightbulb_outline,
            color: Color(0xFF6B7280),
            size: 20,
          ),
          SizedBox(width: AppSpacing.sm),
          Text(
            'Henüz öneri yok. Yenilemeyi deneyin.',
            style: TextStyle(
              color: Color(0xFF6B7280),
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  void _executeAction(String action) {
    AnalyticsService.track(
      'ai_suggestion_tapped',
      properties: {'action': action},
    );

    switch (action) {
      case 'create_event':
        context.push(AppRoutes.calendar);
        break;
      case 'create_task':
        context.push(AppRoutes.tasks);
        break;
      case 'navigate_chat':
        context.go(AppRoutes.chat);
        break;
      case 'navigate_calendar':
        context.go(AppRoutes.calendar);
        break;
      case 'navigate_budget':
        context.go(AppRoutes.budget);
        break;
      case 'navigate_safety':
        context.go(AppRoutes.safety);
        break;
      case 'navigate_tasks':
        context.go(AppRoutes.tasks);
        break;
      case 'navigate_health':
        context.push(AppRoutes.healthCard);
        break;
      case 'show_detail':
      default:
        break;
    }
  }

  Color _getColorForType(String type) {
    switch (type) {
      case 'recipe':
        return AppColors.orange;
      case 'chore':
        return const Color(0xFF6366F1);
      case 'health':
        return AppColors.green;
      case 'social':
        return const Color(0xFF8B5CF6);
      case 'finance':
        return const Color(0xFF10B981);
      case 'education':
        return Colors.teal;
      case 'event':
        return AppColors.blue;
      case 'task':
        return const Color(0xFFEC4899);
      case 'budget':
        return AppColors.mint;
      case 'safety':
        return AppColors.red;
      case 'general':
      default:
        return const Color(0xFF6366F1);
    }
  }

  IconData _getIconForType(String type) {
    switch (type) {
      case 'recipe':
        return Icons.restaurant;
      case 'chore':
        return Icons.cleaning_services;
      case 'health':
        return Icons.favorite;
      case 'social':
        return Icons.people;
      case 'finance':
        return Icons.savings;
      case 'education':
        return Icons.school;
      case 'event':
        return Icons.event;
      case 'task':
        return Icons.check_circle_outline;
      case 'budget':
        return Icons.account_balance_wallet;
      case 'safety':
        return Icons.shield;
      case 'general':
      default:
        return Icons.lightbulb;
    }
  }
}

// ── Detail Bottom Sheet ───────────────────────────────────────────────────

class _SuggestionDetailSheet extends StatefulWidget {
  final AISuggestion suggestion;
  final void Function(List<Ingredient>) onAddToShoppingList;
  final void Function(String) onToggleFavorite;
  final void Function(String) onDismiss;
  final VoidCallback onAction;
  final void Function(int minutes) onPostpone;
  final VoidCallback onShare;
  final void Function(String comment) onAddComment;
  final VoidCallback? onShowAlternatives;
  final void Function(int progress) onProgressUpdate;

  const _SuggestionDetailSheet({
    required this.suggestion,
    required this.onAddToShoppingList,
    required this.onToggleFavorite,
    required this.onDismiss,
    required this.onAction,
    required this.onPostpone,
    required this.onShare,
    required this.onAddComment,
    required this.onShowAlternatives,
    required this.onProgressUpdate,
  });

  @override
  State<_SuggestionDetailSheet> createState() =>
      _SuggestionDetailSheetState();
}

class _SuggestionDetailSheetState extends State<_SuggestionDetailSheet> {
  bool get isDark => Theme.of(context).brightness == Brightness.dark;

  late int _currentProgress;
  final _commentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _currentProgress = widget.suggestion.progress;
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = _sheetColorForType(widget.suggestion.type);
    final missing =
        widget.suggestion.ingredients.where((i) => !i.inStock).toList();

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFF0A0A0F),
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(AppRadius.large),
            ),
          ),
          child: Column(
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.only(top: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0x1EFFFFFF),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  children: [
                    // Header
                    Row(
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: color.withAlpha(40),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Icon(
                            _sheetIconForType(widget.suggestion.type),
                            color: color,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.suggestion.title,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleLarge
                                    ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                              const SizedBox(height: 4),
                              Wrap(
                                spacing: 6,
                                children: [
                                  if (widget.suggestion.durationMinutes !=
                                      null)
                                    _buildMetaChip(
                                        '⏱️ ${widget.suggestion.durationMinutes} dk',
                                        isDark),
                                  if (widget.suggestion.calories != null)
                                    _buildMetaChip(
                                        '🔥 ${widget.suggestion.calories} kcal',
                                        isDark),
                                  if (widget.suggestion.difficulty != null)
                                    _buildMetaChip(
                                        '📊 ${widget.suggestion.difficulty}',
                                        isDark),
                                  if (widget.suggestion.badge != null)
                                    _buildBadgeChip(
                                        widget.suggestion.badge!, color),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    // Description
                    Text(
                      widget.suggestion.description,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: const Color(0xFF6B7280),
                            height: 1.6,
                          ),
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    // Nutrition info
                    if (widget.suggestion.nutritionInfo?.hasAnyValue ==
                        true) ...[
                      _buildSectionTitle(context, '🥗 Besin Değerleri'),
                      const SizedBox(height: AppSpacing.sm),
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF13131A)
                              : const Color(0xFF13131A),
                          borderRadius:
                              BorderRadius.circular(AppRadius.medium),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            if (widget.suggestion.nutritionInfo!.protein !=
                                null)
                              _buildNutrientColumn(
                                  'Protein',
                                  '${widget.suggestion.nutritionInfo!.protein!.toStringAsFixed(0)}g',
                                  AppColors.green),
                            if (widget.suggestion.nutritionInfo!.carbs !=
                                null)
                              _buildNutrientColumn(
                                  'Karbonhidrat',
                                  '${widget.suggestion.nutritionInfo!.carbs!.toStringAsFixed(0)}g',
                                  AppColors.orange),
                            if (widget.suggestion.nutritionInfo!.fat != null)
                              _buildNutrientColumn(
                                  'Yağ',
                                  '${widget.suggestion.nutritionInfo!.fat!.toStringAsFixed(0)}g',
                                  const Color(0xFFEC4899)),
                            if (widget.suggestion.nutritionInfo!.fiber !=
                                null)
                              _buildNutrientColumn(
                                  'Lif',
                                  '${widget.suggestion.nutritionInfo!.fiber!.toStringAsFixed(0)}g',
                                  const Color(0xFF6366F1)),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                    ],

                    // Ingredients / Materials
                    if (widget.suggestion.ingredients.isNotEmpty) ...[
                      _buildSectionTitle(context, '📋 Malzemeler'),
                      const SizedBox(height: AppSpacing.sm),
                      ...widget.suggestion.ingredients.map((i) {
                        return ListTile(
                          dense: true,
                          leading: Icon(
                            i.inStock ? Icons.check_circle : Icons.cancel,
                            color: i.inStock
                                ? const Color(0xFF10B981)
                                : AppColors.error,
                            size: 20,
                          ),
                          title: Text(i.name),
                          subtitle: Text(i.amount),
                          trailing: !i.inStock
                              ? Chip(
                                  label: const Text('Eksik',
                                      style: TextStyle(fontSize: 10)),
                                  backgroundColor:
                                      AppColors.error.withAlpha(20),
                                  side: BorderSide.none,
                                )
                              : null,
                        );
                      }),
                      if (missing.isNotEmpty)
                        Padding(
                          padding:
                              const EdgeInsets.only(top: AppSpacing.sm),
                          child: SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () {
                                widget.onAddToShoppingList(missing);
                                Navigator.pop(context);
                              },
                              icon: const Icon(Icons.shopping_cart,
                                  size: 18),
                              label: Text(
                                  '${missing.length} eksik malzemeyi listeye ekle'),
                            ),
                          ),
                        ),
                      const SizedBox(height: AppSpacing.lg),
                    ],

                    // Steps
                    if (widget.suggestion.steps?.isNotEmpty == true) ...[
                      _buildSectionTitle(context, '🔢 Adımlar'),
                      const SizedBox(height: AppSpacing.sm),
                      ...(widget.suggestion.steps ?? []).asMap().entries.map((e) {
                        final idx = e.key + 1;
                        final step = e.value;
                        return Padding(
                          padding: const EdgeInsets.only(
                              bottom: AppSpacing.sm),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  color: color.withAlpha(30),
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Text(
                                    '$idx',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: color,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              Expanded(
                                child: Text(
                                  step,
                                  style: TextStyle(
                                    color: isDark
                                        ? const Color(0xFFE5E7EB)
                                        : const Color(0xFF374151),
                                    height: 1.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                      const SizedBox(height: AppSpacing.lg),
                    ],

                    // Tips
                    if (widget.suggestion.tips.isNotEmpty) ...[
                      _buildSectionTitle(context, '💡 AI İpuçları'),
                      const SizedBox(height: AppSpacing.sm),
                      ...widget.suggestion.tips.map((tip) {
                        return Padding(
                          padding: const EdgeInsets.only(
                              bottom: AppSpacing.sm),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(Icons.lightbulb,
                                  color: color, size: 18),
                              const SizedBox(width: AppSpacing.sm),
                              Expanded(
                                child: Text(
                                  tip,
                                  style: TextStyle(
                                    color: isDark
                                        ? const Color(0xFFE5E7EB)
                                        : const Color(0xFF374151),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                      const SizedBox(height: AppSpacing.lg),
                    ],

                    // Assignment & context
                    if (widget.suggestion.assignedTo != null ||
                        widget.suggestion.lastDone != null ||
                        widget.suggestion.weatherContext != null ||
                        widget.suggestion.estimatedCost != null)
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF13131A)
                              : const Color(0xFF13131A),
                          borderRadius:
                              BorderRadius.circular(AppRadius.medium),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (widget.suggestion.assignedTo != null)
                              Row(
                                children: [
                                  const Icon(Icons.person, size: 18),
                                  const SizedBox(width: AppSpacing.sm),
                                  Text('Sıra: ${widget.suggestion.assignedTo}'),
                                ],
                              ),
                            if (widget.suggestion.lastDone != null) ...[
                              const SizedBox(height: AppSpacing.sm),
                              Row(
                                children: [
                                  const Icon(Icons.history, size: 18),
                                  const SizedBox(width: AppSpacing.sm),
                                  Text(
                                      'Son yapılma: ${widget.suggestion.lastDone}'),
                                ],
                              ),
                            ],
                            if (widget.suggestion.weatherContext != null) ...[
                              const SizedBox(height: AppSpacing.sm),
                              Row(
                                children: [
                                  const Icon(Icons.wb_sunny, size: 18),
                                  const SizedBox(width: AppSpacing.sm),
                                  Text(
                                      'Hava: ${widget.suggestion.weatherContext}'),
                                ],
                              ),
                            ],
                            if (widget.suggestion.estimatedCost != null) ...[
                              const SizedBox(height: AppSpacing.sm),
                              Row(
                                children: [
                                  const Icon(Icons.euro, size: 18),
                                  const SizedBox(width: AppSpacing.sm),
                                  Text(
                                      'Tahmini maliyet: ${widget.suggestion.estimatedCost}'),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),

                    const SizedBox(height: AppSpacing.lg),

                    // Progress slider
                    _buildSectionTitle(context, '📊 İlerleme'),
                    const SizedBox(height: AppSpacing.sm),
                    Row(
                      children: [
                        Expanded(
                          child: Slider(
                            value: _currentProgress.toDouble(),
                            min: 0,
                            max: 100,
                            divisions: 10,
                            label: '%$_currentProgress',
                            onChanged: (value) {
                              setState(() {
                                _currentProgress = value.round();
                              });
                            },
                            onChangeEnd: (value) {
                              widget.onProgressUpdate(value.round());
                            },
                          ),
                        ),
                        Text(
                          '%$_currentProgress',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    // Comment input
                    _buildSectionTitle(context, '💬 Yorum Ekle'),
                    const SizedBox(height: AppSpacing.sm),
                    TextField(
                      controller: _commentController,
                      decoration: InputDecoration(
                        hintText: 'Bu öneri hakkında düşünceleriniz...',
                        border: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(AppRadius.medium),
                        ),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.send),
                          onPressed: () {
                            if (_commentController.text.trim().isNotEmpty) {
                              widget.onAddComment(
                                  _commentController.text.trim());
                              _commentController.clear();
                              FocusScope.of(context).unfocus();
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Yorum kaydedildi'),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            }
                          },
                        ),
                      ),
                      maxLines: 2,
                    ),
                    if (widget.suggestion.userComment != null) ...[
                      const SizedBox(height: AppSpacing.sm),
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(
                          color: color.withAlpha(15),
                          borderRadius:
                              BorderRadius.circular(AppRadius.small),
                        ),
                        child: Text(
                          widget.suggestion.userComment!,
                          style: const TextStyle(
                            fontStyle: FontStyle.italic,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                      ),
                    ],

                    const SizedBox(height: AppSpacing.xl),

                    // Primary action
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              widget.onAction();
                              Navigator.pop(context);
                            },
                            icon: const Icon(Icons.check),
                            label: const Text('Kabul Et'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),

                    // Secondary actions row 1
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              _showPostponePicker();
                            },
                            icon: const Icon(Icons.snooze),
                            label: const Text('Ertele'),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              widget.onShare();
                              Navigator.pop(context);
                            },
                            icon: const Icon(Icons.share),
                            label: const Text('Paylaş'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),

                    // Secondary actions row 2
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              widget.onToggleFavorite(
                                  widget.suggestion.id);
                              Navigator.pop(context);
                            },
                            icon: Icon(
                              widget.suggestion.isFavorite
                                  ? Icons.favorite
                                  : Icons.favorite_border,
                              color: widget.suggestion.isFavorite
                                  ? AppColors.error
                                  : null,
                            ),
                            label: Text(
                              widget.suggestion.isFavorite
                                  ? 'Favorilerden Çıkar'
                                  : 'Favorilere Ekle',
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        if (widget.onShowAlternatives != null)
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () {
                                Navigator.pop(context);
                                widget.onShowAlternatives!();
                              },
                              icon: const Icon(Icons.swap_horiz),
                              label: const Text('Değiştir'),
                            ),
                          )
                        else
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () {
                                widget.onDismiss(widget.suggestion.id);
                                Navigator.pop(context);
                              },
                              icon: const Icon(Icons.hide_source),
                              label: const Text('Daha Az Göster'),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xl),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showPostponePicker() {
    final options = [15, 30, 60, 120, 1440]; // minutes
    final labels = ['15 dk', '30 dk', '1 saat', '2 saat', '1 gün'];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFF0A0A0F),
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(AppRadius.large),
            ),
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 8),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0x1EFFFFFF),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Text(
                    'Ne zaman hatırlatayım?',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
                ...options.asMap().entries.map((e) {
                  return ListTile(
                    leading: const Icon(Icons.access_time),
                    title: Text(labels[e.key]),
                    onTap: () {
                      Navigator.pop(context);
                      widget.onPostpone(e.value);
                      Navigator.pop(context);
                    },
                  );
                }),
                const SizedBox(height: AppSpacing.md),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
    );
  }

  Widget _buildMetaChip(String label, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF13131A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0x1EFFFFFF),
        ),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 12,
          color: Color(0xFF6B7280),
        ),
      ),
    );
  }

  Widget _buildBadgeChip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(30),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  Widget _buildNutrientColumn(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(fontSize: 11),
        ),
      ],
    );
  }

  Color _sheetColorForType(String type) {
    switch (type) {
      case 'recipe':
        return AppColors.orange;
      case 'chore':
        return const Color(0xFF6366F1);
      case 'health':
        return AppColors.green;
      case 'social':
        return const Color(0xFF8B5CF6);
      case 'finance':
        return const Color(0xFF10B981);
      case 'education':
        return Colors.teal;
      default:
        return const Color(0xFF6366F1);
    }
  }

  IconData _sheetIconForType(String type) {
    switch (type) {
      case 'recipe':
        return Icons.restaurant;
      case 'chore':
        return Icons.cleaning_services;
      case 'health':
        return Icons.favorite;
      case 'social':
        return Icons.people;
      case 'finance':
        return Icons.savings;
      case 'education':
        return Icons.school;
      default:
        return Icons.lightbulb;
    }
  }
}
