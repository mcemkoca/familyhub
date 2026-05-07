import 'dart:math' show max;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../../config/constants.dart';
import '../../../domain/entities.dart';
import '../../providers/app_providers.dart';
import 'package:familyhub/l10n/app_localizations.dart';

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
    _Cat('Market', Icons.shopping_cart_outlined, const Color(0xFF4CAF50)),
    _Cat('Fatura', Icons.receipt_long_outlined, const Color(0xFF2196F3)),
    _Cat('Ulaşım', Icons.directions_car_outlined, const Color(0xFFFF9800)),
    _Cat('Sağlık', Icons.local_hospital_outlined, const Color(0xFFE91E63)),
    _Cat('Eğlence', Icons.movie_outlined, const Color(0xFF9C27B0)),
    _Cat('Giyim', Icons.checkroom_outlined, const Color(0xFF00BCD4)),
    _Cat('Eğitim', Icons.school_outlined, const Color(0xFF3F51B5)),
    _Cat('Diğer', Icons.more_horiz, const Color(0xFF607D8B)),
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
      backgroundColor: AppColors.cloudWhite,
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
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: AppColors.budgetGradient,
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
                backgroundColor: AppColors.green,
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
                        color: AppColors.cobalt,
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
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade600,
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
                  color: Colors.grey.shade300,
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
                    color: AppColors.purple.withAlpha(30),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.auto_awesome, color: AppColors.purple),
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
            _AIStatRow('Net Bakiye', totalIncome - totalExpense, AppColors.cobalt),
            const SizedBox(height: 8),
            _AIStatRow('En Yüksek Kategori', null, AppColors.purple,
                textValue: '$topCategory (${NumberFormat.currency(symbol: '₺', decimalDigits: 0).format(topAmount)})'),
            const Divider(height: 32),
            const Text(
              '💡 AI Önerileri',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            ...suggestions.map((s) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.cobalt.withAlpha(15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(s, style: const TextStyle(fontSize: 14, height: 1.4)),
                  ),
                )),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
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
            labelText: 'Aylık Limit (₺)',
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
        content: Text('${tr.category} - ${NumberFormat.currency(symbol: '₺').format(tr.amount)} silinecek. Emin misiniz?'),
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
            final isDark = Theme.of(ctx).brightness == Brightness.dark;
            return Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
              child: Container(
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkCard : Colors.white,
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
                          color: isDark ? AppColors.darkBorder : AppColors.border,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      isEdit ? 'İşlemi Düzenle' : 'Yeni İşlem Ekle',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: isDark ? AppColors.darkTextPrimary : AppColors.dark,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Income / Expense toggle
                    Container(
                      decoration: BoxDecoration(
                        color: isDark ? Colors.grey.shade800 : Colors.grey.shade100,
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
                        prefixText: '₺ ',
                        prefixStyle: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.dark),
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
                            color: isSelected ? Colors.white : AppColors.dark,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                          ),
                          backgroundColor: isDark ? Colors.grey.shade800 : Colors.grey.shade100,
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
                    const SizedBox(height: 24),

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

// ── WIDGETS ──

class _SummaryCard extends StatelessWidget {
  final String label;
  final double amount;
  final IconData icon;
  final Color color;
  final double delay;
  final AnimationController animController;

  const _SummaryCard({
    required this.label,
    required this.amount,
    required this.icon,
    required this.color,
    required this.delay,
    required this.animController,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: AnimatedBuilder(
        animation: animController,
        builder: (context, child) {
          final animValue = Curves.easeOut.transform(
            ((animController.value - delay) / 0.3).clamp(0.0, 1.0),
          );
          return Transform.translate(
            offset: Offset(0, 20 * (1 - animValue)),
            child: Opacity(
              opacity: animValue,
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: color.withAlpha(20),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: color.withAlpha(20),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(icon, size: 16, color: color),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      NumberFormat.currency(symbol: '₺', decimalDigits: 0).format(amount),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _MonthlyProgressCard extends StatelessWidget {
  final double totalIncome;
  final double totalExpense;
  final AsyncValue<Budget> budgetAsync;

  const _MonthlyProgressCard({
    required this.totalIncome,
    required this.totalExpense,
    required this.budgetAsync,
  });

  @override
  Widget build(BuildContext context) {
    final budget = budgetAsync.valueOrNull ??
        const Budget(id: '', totalAmount: 0, spentAmount: 0);
    final limit = budget.totalAmount > 0 ? budget.totalAmount : totalIncome * 1.2;
    final percent = limit > 0 ? (totalExpense / limit).clamp(0.0, 1.0) : 0.0;
    final remaining = limit - totalExpense;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.shade200,
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Aylık Harcama',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: percent > 0.9
                        ? AppColors.error.withAlpha(20)
                        : percent > 0.7
                            ? AppColors.orange.withAlpha(20)
                            : AppColors.green.withAlpha(20),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${(percent * 100).toStringAsFixed(0)}%',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: percent > 0.9
                          ? AppColors.error
                          : percent > 0.7
                              ? AppColors.orange
                              : AppColors.green,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: percent,
                backgroundColor: Colors.grey.shade100,
                valueColor: AlwaysStoppedAnimation(
                  percent > 0.9
                      ? AppColors.error
                      : percent > 0.7
                          ? AppColors.orange
                          : AppColors.green,
                ),
                minHeight: 10,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  NumberFormat.currency(symbol: '₺', decimalDigits: 0).format(totalExpense),
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                  ),
                ),
                Text(
                  'Kalan: ${NumberFormat.currency(symbol: '₺', decimalDigits: 0).format(remaining)}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.dark,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AIAnalysisCard extends StatelessWidget {
  final List<Transaction> transactions;
  final VoidCallback onTap;

  const _AIAnalysisCard({required this.transactions, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF667eea), Color(0xFF764ba2)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF667eea).withAlpha(60),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(30),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.auto_awesome, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 14),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'AI ile Bütçe Analizi',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Harcama alışkanlıklarınızı analiz edin, tasarruf önerileri alın.',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, color: Colors.white70, size: 16),
          ],
        ),
      ),
    );
  }
}

class _TrendChart extends StatelessWidget {
  final List<Transaction> transactions;

  const _TrendChart({required this.transactions});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final days = List.generate(7, (i) => now.subtract(Duration(days: 6 - i)));
    final dailyExpense = <DateTime, double>{};
    for (final t in transactions.where((t) => t.type == TransactionType.expense)) {
      final d = DateTime(t.createdAt.year, t.createdAt.month, t.createdAt.day);
      dailyExpense[d] = (dailyExpense[d] ?? 0) + t.amount;
    }
    final spots = days.asMap().entries.map((e) {
      final d = DateTime(e.value.year, e.value.month, e.value.day);
      return FlSpot(e.key.toDouble(), dailyExpense[d] ?? 0);
    }).toList();
    final maxY = spots.map((s) => s.y).fold(0.0, max) * 1.2;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.shade200,
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Son 7 Gün Trendi',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 140,
              child: LineChart(
                LineChartData(
                  gridData: const FlGridData(show: false),
                  titlesData: FlTitlesData(
                    leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: 1,
                        getTitlesWidget: (value, meta) {
                          final idx = value.toInt();
                          if (idx < 0 || idx >= days.length) return const SizedBox.shrink();
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              DateFormat('E', 'tr_TR').format(days[idx]).substring(0, 2),
                              style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  minX: 0,
                  maxX: 6,
                  minY: 0,
                  maxY: maxY > 0 ? maxY : 100,
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      color: AppColors.cobalt,
                      barWidth: 3,
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (spot, percent, bar, idx) =>
                            FlDotCirclePainter(
                          radius: 4,
                          color: AppColors.cobalt,
                          strokeWidth: 2,
                          strokeColor: Colors.white,
                        ),
                      ),
                      belowBarData: BarAreaData(
                        show: true,
                        color: AppColors.cobalt.withAlpha(20),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryBudgetSection extends StatelessWidget {
  final List<Transaction> transactions;
  final List<_Cat> categories;
  final Map<String, double> limits;
  final void Function(_Cat) onEditLimit;

  const _CategoryBudgetSection({
    required this.transactions,
    required this.categories,
    required this.limits,
    required this.onEditLimit,
  });

  @override
  Widget build(BuildContext context) {
    final catTotals = <String, double>{};
    for (final t in transactions.where((t) => t.type == TransactionType.expense)) {
      catTotals[t.category] = (catTotals[t.category] ?? 0) + t.amount;
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.shade200,
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Kategori Bütçeleri',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                ),
                TextButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.edit, size: 16),
                  label: const Text('Düzenle', style: TextStyle(fontSize: 12)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...categories.map((cat) {
              final spent = catTotals[cat.name] ?? 0;
              final limit = limits[cat.name] ?? 0;
              final pct = limit > 0 ? (spent / limit).clamp(0.0, 1.0) : 0.0;
              final isOver = spent > limit && limit > 0;

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: GestureDetector(
                  onTap: () => onEditLimit(cat),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: cat.color.withAlpha(20),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(cat.icon, size: 18, color: cat.color),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  cat.name,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  '${NumberFormat.currency(symbol: '₺', decimalDigits: 0).format(spent)} / ${NumberFormat.currency(symbol: '₺', decimalDigits: 0).format(limit)}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: isOver ? AppColors.error : Colors.grey.shade500,
                                    fontWeight: isOver ? FontWeight.bold : FontWeight.normal,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: pct,
                                backgroundColor: Colors.grey.shade100,
                                valueColor: AlwaysStoppedAnimation(
                                  isOver ? AppColors.error : cat.color,
                                ),
                                minHeight: 6,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _TransactionTile extends StatelessWidget {
  final Transaction transaction;
  final _Cat category;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _TransactionTile({
    required this.transaction,
    required this.category,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isIncome = transaction.type == TransactionType.income;
    return Dismissible(
      key: ValueKey(transaction.id),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.fromLTRB(20, 4, 20, 4),
        padding: const EdgeInsets.only(right: 20),
        alignment: Alignment.centerRight,
        decoration: BoxDecoration(
          color: AppColors.error,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Icon(Icons.delete, color: Colors.white),
            SizedBox(width: 8),
            Text('Sil', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
      confirmDismiss: (_) async {
        return await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: Text(AppLocalizations.of(context).islemiSil),
            content: Text('${transaction.category} işlemi silinecek. Emin misiniz?'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, false), child: Text(AppLocalizations.of(context).cancel)),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Sil', style: TextStyle(color: AppColors.error)),
              ),
            ],
          ),
        );
      },
      onDismissed: (_) => onDelete(),
      child: Container(
        margin: const EdgeInsets.fromLTRB(20, 4, 20, 4),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.shade100,
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: isIncome ? AppColors.green.withAlpha(20) : category.color.withAlpha(20),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                isIncome ? Icons.arrow_downward : category.icon,
                color: isIncome ? AppColors.green : category.color,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    transaction.category,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  if (transaction.description != null && transaction.description!.isNotEmpty)
                    Text(
                      transaction.description!,
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${isIncome ? '+' : '-'}${NumberFormat.currency(symbol: '₺').format(transaction.amount)}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: isIncome ? AppColors.green : AppColors.dark,
                  ),
                ),
                Text(
                  DateFormat('HH:mm').format(transaction.createdAt),
                  style: TextStyle(fontSize: 10, color: Colors.grey.shade400),
                ),
              ],
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: onEdit,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.cobalt.withAlpha(15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.edit, size: 16, color: AppColors.cobalt),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PickerButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _PickerButton({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: AppColors.cobalt),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }
}

class _AIStatRow extends StatelessWidget {
  final String label;
  final double? value;
  final Color color;
  final String? textValue;

  const _AIStatRow(this.label, this.value, this.color, {this.textValue});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 14, color: Colors.grey.shade600)),
          Text(
            textValue ?? NumberFormat.currency(symbol: '₺').format(value ?? 0),
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color),
          ),
        ],
      ),
    );
  }
}

class _Cat {
  final String name;
  final IconData icon;
  final Color color;
  const _Cat(this.name, this.icon, this.color);
}
