import 'dart:io';
import 'package:flutter/material.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';

class EmojiPickerWidget extends StatelessWidget {
  final Function(String) onEmojiSelected;

  const EmojiPickerWidget({
    super.key,
    required this.onEmojiSelected,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return EmojiPicker(
      onEmojiSelected: (category, emoji) => onEmojiSelected(emoji.emoji),
      config: Config(
        height: 280,
        emojiViewConfig: EmojiViewConfig(
          columns: 7,
          emojiSizeMax: 32 * (Platform.isIOS ? 1.30 : 1.0),
          verticalSpacing: 0,
          horizontalSpacing: 0,
          gridPadding: EdgeInsets.zero,
          recentsLimit: 28,
          backgroundColor: colorScheme.surface,
          buttonMode: ButtonMode.MATERIAL,
          noRecents: Text(
            'Kullanılan yok',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
        categoryViewConfig: CategoryViewConfig(
          initCategory: Category.RECENT,
          backgroundColor: colorScheme.surface,
          indicatorColor: colorScheme.primary,
          iconColor: colorScheme.onSurfaceVariant,
          iconColorSelected: colorScheme.primary,
          recentTabBehavior: RecentTabBehavior.RECENT,
        ),
        skinToneConfig: const SkinToneConfig(
          enabled: true,
        ),
      ),
    );
  }
}
