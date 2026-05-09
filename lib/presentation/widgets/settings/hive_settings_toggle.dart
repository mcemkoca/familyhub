import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../config/constants.dart';
import '../../../services/hive_service.dart';

class HiveSettingsToggle extends StatefulWidget {
  final String settingsKey;
  final String title;
  final String? subtitle;
  final bool defaultValue;
  final Future<void> Function(bool)? onSupabaseSync;

  const HiveSettingsToggle({
    super.key,
    required this.settingsKey,
    required this.title,
    this.subtitle,
    this.defaultValue = false,
    this.onSupabaseSync,
  });

  @override
  State<HiveSettingsToggle> createState() => _HiveSettingsToggleState();
}

class _HiveSettingsToggleState extends State<HiveSettingsToggle> {
  late bool _value;

  @override
  void initState() {
    super.initState();
    _value = HiveService.getBoolSetting(widget.settingsKey, defaultValue: widget.defaultValue);
  }

  Future<void> _onChanged(bool newValue) async {
    setState(() => _value = newValue);

    await HiveService.setBoolSetting(widget.settingsKey, newValue);

    if (widget.onSupabaseSync != null) {
      try {
        await widget.onSupabaseSync!(newValue);
      } catch (e) {
        debugPrint('Settings sync error: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Semantics(
      button: true,
      label: widget.title,
      hint: widget.subtitle,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: isDark ? AppColors.darkTextPrimary : AppColors.dark,
                    ),
                  ),
                  if (widget.subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      widget.subtitle!,
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? AppColors.darkTextSecondary : AppColors.slate,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Switch.adaptive(
              value: _value,
              onChanged: (v) {
                HapticFeedback.selectionClick();
                _onChanged(v);
              },
              activeTrackColor: AppColors.cobalt,
              activeThumbColor: Colors.white,
              inactiveTrackColor: isDark ? AppColors.darkBorder : const Color(0xFFE2E8F0),
              inactiveThumbColor: Colors.white,
            ),
          ],
        ),
      ),
    );
  }
}
