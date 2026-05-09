part of '../budget_screen.dart';


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

