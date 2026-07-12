part of '../budget_screen.dart';


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
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            const Icon(Icons.delete, color: Colors.white),
            const SizedBox(width: 8),
            Text(AppLocalizations.of(context).budDelete, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
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
                child: Text(AppLocalizations.of(context).budDelete, style: const TextStyle(color: AppColors.error)),
              ),
            ],
          ),
        );
      },
      onDismissed: (_) => onDelete(),
      child: Builder(
        builder: (context) {
          final isDark = Theme.of(context).brightness == Brightness.dark;
          return Container(
        margin: const EdgeInsets.fromLTRB(20, 4, 20, 4),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF13131A) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: isDark
              ? Border.all(color: Colors.white.withAlpha(15), width: 0.5)
              : null,
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? Colors.black.withAlpha(60)
                  : const Color(0xFF9CA3AF).withAlpha(80),
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
                      style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280)),
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
                  '${isIncome ? '+' : '-'}${NumberFormat.currency(symbol: '€').format(transaction.amount)}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: isIncome ? AppColors.green : const Color(0xFFE5E7EB),
                  ),
                ),
                Text(
                  DateFormat('HH:mm').format(transaction.createdAt),
                  style: const TextStyle(fontSize: 10, color: Color(0xFF9CA3AF)),
                ),
              ],
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: onEdit,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFF6366F1).withAlpha(15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.edit, size: 16, color: Color(0xFF6366F1)),
              ),
            ),
          ],
        ),
      );
        },
      ),
    );
  }
}

