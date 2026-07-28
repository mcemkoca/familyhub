import 'package:flutter/material.dart';
import '../../widgets/settings/screen_header.dart';
import 'package:familyhub/l10n/app_localizations.dart';

class FamilySuggestionSettingsScreen extends StatelessWidget {
  const FamilySuggestionSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: const Color(0xFF0f172a),
      appBar: ScreenHeader(
        title: AppLocalizations.of(context).family,
        showBack: true,
        onBack: () => Navigator.pop(context),
      ),
      body: const Center(
        child: Text(
          'Yakında',
          style: TextStyle(
            fontSize: 16,
            color: Color(0xFF94a3b8),
          ),
        ),
      ),
    );
  }
}
