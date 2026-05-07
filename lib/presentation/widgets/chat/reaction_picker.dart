import 'package:flutter/material.dart';
import '../../../config/constants.dart';

class ReactionPicker extends StatelessWidget {
  final VoidCallback onClose;
  final Function(String emoji) onSelect;

  const ReactionPicker({
    super.key,
    required this.onClose,
    required this.onSelect,
  });

  static const _emojis = ['❤️', '😂', '👍', '😮', '😢', '🔥', '🎉', '👏'];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onClose,
      child: Container(
        color: Colors.black.withAlpha(40),
        child: Center(
          child: GestureDetector(
            onTap: () {},
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 40),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCard : Colors.white,
                borderRadius: BorderRadius.circular(40),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(20),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: _emojis.map((emoji) {
                  return GestureDetector(
                    onTap: () {
                      onSelect(emoji);
                      onClose();
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Text(
                        emoji,
                        style: const TextStyle(fontSize: 28),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
