part of '../budget_screen.dart';


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
          color: const Color(0xFF13131A),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFF262631)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(AppLocalizations.of(context).aylikHarcama,
                  style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.white),
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
                backgroundColor: const Color(0xFF262631),
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
                  NumberFormat.currency(symbol: '€', decimalDigits: 0).format(totalExpense),
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF6B7280),
                  ),
                ),
                Text(
                  'Kalan: ${NumberFormat.currency(symbol: '€', decimalDigits: 0).format(remaining)}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFE5E7EB),
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

