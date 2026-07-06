import 'dart:convert';
import 'dart:math' show max;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// ignore: unused_import
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../../config/constants.dart';
import '../../../domain/entities.dart';
import '../../providers/app_providers.dart';
import '../../../services/ai/ai_engine.dart';
import 'package:familyhub/l10n/app_localizations.dart';

part 'widgets/budget_summary_card.dart';
part 'widgets/budget_monthly_progress_card.dart';
part 'widgets/budget_a_i_analysis_card.dart';
part 'widgets/budget_trend_chart.dart';
part 'widgets/budget_category_budget_section.dart';
part 'widgets/budget_transaction_tile.dart';
part 'widgets/budget_picker_button.dart';
part 'widgets/budget_a_i_stat_row.dart';
part 'widgets/budget_models.dart';

class BudgetScreen extends ConsumerStatefulWidget {
  const BudgetScreen({super.key});

  @override
  ConsumerState<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends ConsumerState<BudgetScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;

  // Category definitions with icons & colors
  final _categories = [
    const _Cat('Market', Icons.shopping_cart_outlined, Color(0xFF4CAF50)),
    const _Cat('Fatura', Icons.receipt_long_outlined, Color(0xFF2196F3)),
    const _Cat('Ulaşım', Icons.directions_car_outlined, Color(0xFFFF9800)),
    const _Cat('Sağlık', Icons.local_hospital_outlined, Color(0xFFE91E63)),
    const _Cat('Eğlence', Icons.movie_outlined, Color(0xFF9C27B0)),
    const _Cat('Giyim', Icons.checkroom_outlined, Color(0xFF00BCD4)),
    const _Cat('Eğitim', Icons.school_outlined, Color(0xFF3F51B5)),
    const _Cat('Diğer', Icons.more_horiz, Color(0xFF607D8B)),
  ];

  // Budget limits per category (planning feature)
  final Map<String, double> _categoryLimits = {
    'Market': 5000,
    'Fatura': 3000,
    'Ulaşım': 2000,
    'Sağlık': 1500,
    'Eğlence': 1000,
    'Giyim': 1000,
    'Eğitim': 2000,
    'Diğer': 500,
  };

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final transactionsAsync = ref.watch(transactionsProvider);
    final budgetAsync = ref.watch(budgetProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      body: transactionsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Hata: $e')),
        data: (transactions) {
          final totalIncome = transactions
              .where((t) => t.type == TransactionType.income)
              .fold(0.0, (s, t) => s + t.amount);
          final totalExpense = transactions
              .where((t) => t.type == TransactionType.expense)
              .fold(0.0, (s, t) => s + t.amount);
          final balance = totalIncome - totalExpense;

          return CustomScrollView(
            slivers: [
              // App bar with gradient
              SliverAppBar(
                expandedHeight: 160,
                pinned: true,
                backgroundColor: const Color(0xFF0A0A0F),
                surfaceTintColor: Colors.transparent,
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF0D1F12), Color(0xFF0A2818)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Aile Bütçesi',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    DateFormat('MMMM yyyy', 'tr_TR')
                                        .format(DateTime.now()),
                                    style: TextStyle(
                                      color: Colors.white.withAlpha(200),
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            GestureDetector(
                              onTap: () => _showAddTransaction(context),
                              child: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.white.withAlpha(40),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.add, color: Colors.white, size: 24),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // Summary Cards
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Row(
                    children: [
                      _SummaryCard(
                        label: 'Gelir',
                        amount: totalIncome,
                        icon: Icons.arrow_downward,
                        color: AppColors.green,
                        delay: 0,
                        animController: _animController,
                      ),
                      const SizedBox(width: 10),
                      _SummaryCard(
                        label: 'Gider',
                        amount: totalExpense,
                        icon: Icons.arrow_upward,
                        color: AppColors.error,
                        delay: 0.1,
                        animController: _animController,
                      ),
                      const SizedBox(width: 10),
                      _SummaryCard(
                        label: 'Bakiye',
                        amount: balance,
                        icon: Icons.account_balance_wallet,
                        color: const Color(0xFF6366F1),
                        delay: 0.2,
                        animController: _animController,
                      ),
                    ],
                  ),
                ),
              ),

              // Monthly Progress
              SliverToBoxAdapter(
                child: _MonthlyProgressCard(
                  totalIncome: totalIncome,
                  totalExpense: totalExpense,
                  budgetAsync: budgetAsync,
                ),
              ),

              // AI Analysis Card
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  child: _AIAnalysisCard(
                    transactions: transactions,
                    onTap: () => _showAIAnalysis(context, transactions),
                  ),
                ),
              ),

              // Trend Chart
              SliverToBoxAdapter(
                child: _TrendChart(transactions: transactions),
              ),

              // Category Budget Planning
              SliverToBoxAdapter(
                child: _CategoryBudgetSection(
                  transactions: transactions,
                  categories: _categories,
                  limits: _categoryLimits,
                  onEditLimit: (cat) => _showLimitEditor(context, cat),
                ),
              ),

              // Recent Transactions Header
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'İşlemler',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () => _showAddTransaction(context),
                        icon: const Icon(Icons.add_circle, size: 18),
                        label: Text(AppLocalizations.of(context).add),
                      ),
                    ],
                  ),
                ),
              ),

              // Transaction List (grouped by date)
              _buildGroupedTransactionList(transactions),

              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          );
        },
      ),
      floatingActionButton: null,
    );
  }

  Widget _buildGroupedTransactionList(List<Transaction> transactions) {
    final grouped = <String, List<Transaction>>{};
    final now = DateTime.now();
    for (final t in transactions) {
      final key = _groupKey(t.createdAt, now);
      grouped.putIfAbsent(key, () => []).add(t);
    }
    final sortedKeys = grouped.keys.toList()
      ..sort((a, b) => _groupSort(b).compareTo(_groupSort(a)));

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final key = sortedKeys[index];
          final txs = grouped[key]!;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
                child: Text(
                  key,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ),
              ...txs.map((t) => _TransactionTile(
                    transaction: t,
                    category: _categories.firstWhere(
                      (c) => c.name == t.category,
                      orElse: () => _categories.last,
                    ),
                    onEdit: () => _editTransaction(context, t),
                    onDelete: () => _confirmDelete(context, t),
                  )),
            ],
          );
        },
        childCount: sortedKeys.length,
      ),
    );
  }

  String _groupKey(DateTime date, DateTime now) {
    if (_isSameDay(date, now)) return 'Bugün';
    if (_isSameDay(date, now.subtract(const Duration(days: 1)))) return 'Dün';
    if (date.isAfter(now.subtract(const Duration(days: 7)))) return 'Bu Hafta';
    return DateFormat('dd MMMM', 'tr_TR').format(date);
  }

  int _groupSort(String key) {
    const order = {'Bugün': 4, 'Dün': 3, 'Bu Hafta': 2};
    return order[key] ?? 1;
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  void _showAIAnalysis(BuildContext context, List<Transaction> txs) {
    final expenseTxs = txs.where((t) => t.type == TransactionType.expense).toList();
    final incomeTxs = txs.where((t) => t.type == TransactionType.income).toList();
    final totalExpense = expenseTxs.fold(0.0, (s, t) => s + t.amount);
    final totalIncome = incomeTxs.fold(0.0, (s, t) => s + t.amount);

    // Category analysis
    final catTotals = <String, double>{};
    for (final t in expenseTxs) {
      catTotals[t.category] = (catTotals[t.category] ?? 0) + t.amount;
    }
    final sortedCats = catTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final topCategory = sortedCats.isNotEmpty ? sortedCats.first.key : 'Veri yok';
    final topAmount = sortedCats.isNotEmpty ? sortedCats.first.value : 0.0;

    // AI suggestions
    final suggestions = <String>[];
    if (totalExpense > totalIncome * 0.9) {
      suggestions.add('💡 Harcamalarınız gelirinize çok yaklaşıyor. Giderlerinizi gözden geçirmenizi öneririz.');
    }
    if (sortedCats.isNotEmpty && sortedCats.first.value > totalExpense * 0.4) {
      suggestions.add('💡 $topCategory kategorisi toplam harcamanızın %${((topAmount / totalExpense) * 100).toStringAsFixed(0)}\'ini oluşturuyor.');
    }
    if (expenseTxs.length > 10) {
      suggestions.add('💡 Küçük tutarlı çok sayıda işlem tespit edildi. Bu harcamaları birleştirmeyi düşünebilirsiniz.');
    }
    if (totalIncome > totalExpense * 1.5) {
      suggestions.add('🎉 Harika! Gelirinizin %${(((totalIncome - totalExpense) / totalIncome) * 100).toStringAsFixed(0)}\'ini tasarruf ediyorsunuz.');
    }
    if (suggestions.isEmpty) {
      suggestions.add('💡 Daha fazla veri toplandıkça kişiselleştirilmiş öneriler sunacağız.');
    }

    // Gemini için özet veri.
    final catBreakdown = sortedCats
        .take(6)
        .map((e) =>
            '${e.key}: ${NumberFormat.currency(symbol: '€', decimalDigits: 0).format(e.value)}')
        .join(', ');
    final aiFuture = _fetchBudgetInsights(
      totalIncome: totalIncome,
      totalExpense: totalExpense,
      catBreakdown: catBreakdown,
      txCount: expenseTxs.length,
      localFallback: suggestions,
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: Theme.of(ctx).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
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
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF8B5CF6).withAlpha(30),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.auto_awesome, color: Color(0xFF8B5CF6)),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'AI Bütçe Analizi',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _AIStatRow('Toplam Gelir', totalIncome, AppColors.green),
            _AIStatRow('Toplam Gider', totalExpense, AppColors.error),
            _AIStatRow('Net Bakiye', totalIncome - totalExpense, const Color(0xFF6366F1)),
            const SizedBox(height: 8),
            _AIStatRow('En Yüksek Kategori', null, const Color(0xFF8B5CF6),
                textValue: '$topCategory (${NumberFormat.currency(symbol: '€', decimalDigits: 0).format(topAmount)})'),
            const Divider(height: 32),
            const Row(
              children: [
                Text(
                  '💡 AI Önerileri',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                SizedBox(width: 8),
                Icon(Icons.auto_awesome, size: 15, color: Color(0xFF8B5CF6)),
              ],
            ),
            const SizedBox(height: 12),
            FutureBuilder<List<String>>(
              future: aiFuture,
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Color(0xFF8B5CF6)),
                        ),
                        SizedBox(width: 12),
                        Text('Gemini analiz ediyor…',
                            style: TextStyle(
                                fontSize: 14, color: Color(0xFF9CA3AF))),
                      ],
                    ),
                  );
                }
                final tips = (snap.data == null || snap.data!.isEmpty)
                    ? suggestions
                    : snap.data!;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: tips
                      .map((s) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFF6366F1).withAlpha(15),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(s,
                                  style: const TextStyle(
                                      fontSize: 14, height: 1.4)),
                            ),
                          ))
                      .toList(),
                );
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  /// Gemini'den kişiselleştirilmiş bütçe önerileri çeker. Başarısız olursa
  /// kural tabanlı [localFallback] listesi döner.
  Future<List<String>> _fetchBudgetInsights({
    required double totalIncome,
    required double totalExpense,
    required String catBreakdown,
    required int txCount,
    required List<String> localFallback,
  }) async {
    final net = totalIncome - totalExpense;
    final prompt = '''
Bir Belçika'da yaşayan ailenin aylık bütçesini analiz et. Para birimi Euro.
Toplam gelir: €${totalIncome.toStringAsFixed(0)}
Toplam gider: €${totalExpense.toStringAsFixed(0)}
Net bakiye: €${net.toStringAsFixed(0)}
İşlem sayısı: $txCount
Kategori dağılımı: ${catBreakdown.isEmpty ? 'veri yok' : catBreakdown}

Bu verilere göre 3-4 kısa, uygulanabilir tasarruf/bütçe önerisi ver.
Sadece JSON döndür: {"suggestions": ["...", "..."]}. Her öneri tek cümle, Türkçe, başına uygun bir emoji koy.''';

    try {
      final res = await AIEngine.generate(
        prompt: prompt,
        format: AIResponseFormat.json,
        maxTokens: 500,
        temperature: 0.6,
      );
      final parsed = _parseSuggestions(res.content);
      return parsed.isEmpty ? localFallback : parsed;
    } catch (_) {
      return localFallback;
    }
  }

  List<String> _parseSuggestions(String raw) {
    try {
      var s = raw.trim();
      final start = s.indexOf('{');
      final end = s.lastIndexOf('}');
      if (start >= 0 && end > start) s = s.substring(start, end + 1);
      final obj = jsonDecode(s);
      final list = obj is Map ? obj['suggestions'] : null;
      if (list is List) {
        return list
            .map((e) => e.toString().trim())
            .where((e) => e.isNotEmpty)
            .toList();
      }
    } catch (_) {}
    return const [];
  }

  /// Açıklama metninden Gemini ile en uygun kategoriyi seçer.
  Future<String?> _suggestCategory(String desc, List<String> categories) async {
    final prompt = '''
Bir harcama açıklaması: "$desc"
Aşağıdaki kategorilerden EN uygun olanı seç ve SADECE kategori adını yaz:
${categories.join(', ')}''';
    try {
      final res = await AIEngine.generate(
        prompt: prompt,
        maxTokens: 30,
        temperature: 0.2,
      );
      final answer = res.content.trim().toLowerCase();
      for (final c in categories) {
        if (answer.contains(c.toLowerCase())) return c;
      }
    } catch (_) {}
    return null;
  }

  void _showLimitEditor(BuildContext context, _Cat category) {
    final controller = TextEditingController(
      text: (_categoryLimits[category.name] ?? 0).toStringAsFixed(0),
    );
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('${category.name} Limiti'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Aylık Limit (€)',
            prefixIcon: Icon(Icons.payments_outlined),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(AppLocalizations.of(context).cancel),
          ),
          ElevatedButton(
            onPressed: () {
              final val = double.tryParse(controller.text) ?? 0;
              setState(() => _categoryLimits[category.name] = val);
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.green),
            child: const Text('Kaydet', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showAddTransaction(BuildContext context) {
    _showTransactionModal(context);
  }

  void _editTransaction(BuildContext context, Transaction tr) {
    _showTransactionModal(context, existing: tr);
  }

  void _confirmDelete(BuildContext context, Transaction tr) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(AppLocalizations.of(context).islemiSil),
        content: Text('${tr.category} - ${NumberFormat.currency(symbol: '€').format(tr.amount)} silinecek. Emin misiniz?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(AppLocalizations.of(context).cancel)),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sil', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (ok == true) {
      HapticFeedback.mediumImpact();
      ref.read(transactionsProvider.notifier).deleteTransaction(tr.id);
    }
  }

  void _showTransactionModal(BuildContext context, {Transaction? existing}) {
    final isEdit = existing != null;
    String selectedCategory = isEdit ? existing.category : _categories.first.name;
    TransactionType type = isEdit ? existing.type : TransactionType.expense;
    DateTime selectedDate = isEdit ? existing.createdAt : DateTime.now();
    String repeatMode = 'Bir Kerelik';

    final amountController = TextEditingController(
      text: isEdit ? existing.amount.toStringAsFixed(2).replaceAll('.', ',') : '',
    );
    final descController = TextEditingController(text: isEdit ? (existing.description ?? '') : '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
              child: Container(
                decoration: const BoxDecoration(
                  color: Color(0xFF13131A),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                ),
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
                          color: const Color(0x1EFFFFFF),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      isEdit ? 'İşlemi Düzenle' : 'Yeni İşlem Ekle',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFE5E7EB),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Income / Expense toggle
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF1F2937),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () => setModalState(() => type = TransactionType.expense),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                decoration: BoxDecoration(
                                  color: type == TransactionType.expense
                                      ? AppColors.error.withAlpha(30)
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.arrow_upward,
                                        color: type == TransactionType.expense
                                            ? AppColors.error
                                            : Colors.grey,
                                        size: 18),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Gider',
                                      style: TextStyle(
                                        color: type == TransactionType.expense
                                            ? AppColors.error
                                            : Colors.grey,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: GestureDetector(
                              onTap: () => setModalState(() => type = TransactionType.income),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                decoration: BoxDecoration(
                                  color: type == TransactionType.income
                                      ? AppColors.green.withAlpha(30)
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.arrow_downward,
                                        color: type == TransactionType.income
                                            ? AppColors.green
                                            : Colors.grey,
                                        size: 18),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Gelir',
                                      style: TextStyle(
                                        color: type == TransactionType.income
                                            ? AppColors.green
                                            : Colors.grey,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Amount
                    TextField(
                      controller: amountController,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                      decoration: InputDecoration(
                        labelText: 'Tutar',
                        prefixText: '€ ',
                        prefixStyle: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFFE5E7EB)),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Category Grid
                    const Text('Kategori', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _categories.map((cat) {
                        final isSelected = selectedCategory == cat.name;
                        return ChoiceChip(
                          avatar: Icon(cat.icon, size: 18, color: isSelected ? Colors.white : cat.color),
                          label: Text(cat.name),
                          selected: isSelected,
                          onSelected: (_) => setModalState(() => selectedCategory = cat.name),
                          selectedColor: cat.color,
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.white : const Color(0xFFE5E7EB),
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                          ),
                          backgroundColor: const Color(0xFF1F2937),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),

                    // Date & Repeat row
                    Row(
                      children: [
                        Expanded(
                          child: _PickerButton(
                            icon: Icons.calendar_today_outlined,
                            label: DateFormat('dd MMM', 'tr_TR').format(selectedDate),
                            onTap: () async {
                              final picked = await showDatePicker(
                                context: ctx,
                                initialDate: selectedDate,
                                firstDate: DateTime(2023),
                                lastDate: DateTime(2027),
                              );
                              if (picked != null) {
                                setModalState(() => selectedDate = picked);
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _PickerButton(
                            icon: Icons.repeat,
                            label: repeatMode,
                            onTap: () {
                              showModalBottomSheet(
                                context: ctx,
                                builder: (_) => SafeArea(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: ['Bir Kerelik', 'Her Ay', 'Her Yıl'].map((mode) => ListTile(
                                      title: Text(mode),
                                      trailing: repeatMode == mode
                                          ? const Icon(Icons.check, color: AppColors.green)
                                          : null,
                                      onTap: () {
                                        setModalState(() => repeatMode = mode);
                                        Navigator.pop(ctx);
                                      },
                                    )).toList(),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Description
                    TextField(
                      controller: descController,
                      decoration: InputDecoration(
                        labelText: 'Açıklama (opsiyonel)',
                        prefixIcon: const Icon(Icons.notes_outlined),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // AI kategori önerisi
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                        onPressed: () async {
                          final text = descController.text.trim();
                          if (text.isEmpty) {
                            ScaffoldMessenger.of(ctx).showSnackBar(
                              const SnackBar(
                                  content: Text(
                                      'Önce açıklama yazın, AI kategoriyi bulsun.')),
                            );
                            return;
                          }
                          final cat = await _suggestCategory(
                              text, _categories.map((c) => c.name).toList());
                          if (cat != null) {
                            setModalState(() => selectedCategory = cat);
                            if (ctx.mounted) {
                              ScaffoldMessenger.of(ctx).showSnackBar(
                                SnackBar(content: Text('AI önerisi: $cat')),
                              );
                            }
                          }
                        },
                        icon: const Icon(Icons.auto_awesome,
                            size: 18, color: Color(0xFF8B5CF6)),
                        label: const Text('AI ile kategori öner',
                            style: TextStyle(color: Color(0xFF8B5CF6))),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Save Button
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: () {
                          final amount = double.tryParse(
                                  amountController.text.replaceAll(',', '.')) ??
                              0;
                          if (amount <= 0) return;
                          final tx = Transaction(
                            id: isEdit
                                ? existing.id
                                : 'tr${DateTime.now().millisecondsSinceEpoch}',
                            amount: amount,
                            type: type,
                            category: selectedCategory,
                            description: descController.text.isEmpty
                                ? null
                                : descController.text,
                            createdBy: isEdit ? existing.createdBy : '',
                            createdAt: selectedDate,
                            attachments: const [],
                          );
                          if (isEdit) {
                            ref.read(transactionsProvider.notifier).updateTransaction(tx);
                          } else {
                            ref.read(transactionsProvider.notifier).addTransaction(tx);
                          }
                          Navigator.of(ctx).pop();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.green,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Text(
                          isEdit ? 'Güncelle' : 'Kaydet',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                        ),
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
}


