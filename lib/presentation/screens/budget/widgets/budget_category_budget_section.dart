part of '../budget_screen.dart';


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
                Text(AppLocalizations.of(context).kategoriButceleri,
                  style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.white),
                ),
                Text('Düzenlemek için dokun',
                    style: TextStyle(
                        fontSize: 11.5, color: Colors.white.withAlpha(120))),
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
                                  '${NumberFormat.currency(symbol: '€', decimalDigits: 0).format(spent)} / ${NumberFormat.currency(symbol: '€', decimalDigits: 0).format(limit)}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: isOver ? AppColors.error : const Color(0xFF6B7280),
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
                                backgroundColor: const Color(0xFF262631),
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

