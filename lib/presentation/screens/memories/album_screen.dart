import 'package:flutter/material.dart';
import 'package:familyhub/l10n/app_localizations.dart';

class AlbumScreen extends StatelessWidget {
  const AlbumScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context).album), centerTitle: true),
      body: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, crossAxisSpacing: 8, mainAxisSpacing: 8),
        itemCount: 12,
        itemBuilder: (context, index) {
          return Container(
            decoration: BoxDecoration(color: const Color(0xFF0A0A0F), borderRadius: BorderRadius.circular(12)),
            child: const Center(child: Icon(Icons.image, color: Color(0xFF9CA3AF))),
          );
        },
      ),
    );
  }
}
