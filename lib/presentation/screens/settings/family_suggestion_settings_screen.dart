import 'package:flutter/material.dart';
import '../../widgets/settings/screen_header.dart';
import 'package:familyhub/l10n/app_localizations.dart';

class FamilySuggestionSettingsScreen extends StatelessWidget {
  const FamilySuggestionSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0f172a) : const Color(0xFFF8FAFC),
      appBar: ScreenHeader(
        title: AppLocalizations.of(context).family,
        showBack: true,
        onBack: () => Navigator.pop(context),
      ),
      body: Center(
        child: Text(
          'Yakında',
          style: TextStyle(
            fontSize: 16,
            color: isDark ? const Color(0xFF94a3b8) : const Color(0xFF475569),
          ),
        ),
      ),
    );
  }
}
