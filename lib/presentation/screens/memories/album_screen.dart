import 'package:flutter/material.dart';
import 'package:familyhub/l10n/app_localizations.dart';

class AlbumScreen extends StatelessWidget {
  const AlbumScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context).album), centerTitle: true),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.photo_library_outlined,
                  color: Color(0xFF6B7280), size: 56),
              SizedBox(height: 16),
              Text(
                'Bu albümde henüz fotoğraf yok.\nGaleriden fotoğraf ekleyerek başlayın.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 14),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
