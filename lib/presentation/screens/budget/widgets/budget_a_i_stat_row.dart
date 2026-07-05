part of '../budget_screen.dart';


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
          Text(label, style: const TextStyle(fontSize: 14, color: Color(0xFF6B7280))),
          Text(
            textValue ?? NumberFormat.currency(symbol: '€').format(value ?? 0),
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color),
          ),
        ],
      ),
    );
  }
}

