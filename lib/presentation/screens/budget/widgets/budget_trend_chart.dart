part of '../budget_screen.dart';


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
          color: const Color(0xFF13131A),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFF262631)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(AppLocalizations.of(context).son7GunTrendi,
              style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.white),
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
                              style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280)),
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
                      color: const Color(0xFF6366F1),
                      barWidth: 3,
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (spot, percent, bar, idx) =>
                            FlDotCirclePainter(
                          radius: 4,
                          color: const Color(0xFF6366F1),
                          strokeWidth: 2,
                          strokeColor: Colors.white,
                        ),
                      ),
                      belowBarData: BarAreaData(
                        show: true,
                        color: const Color(0xFF6366F1).withAlpha(20),
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

