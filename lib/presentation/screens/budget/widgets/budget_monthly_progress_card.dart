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

