import 'package:flutter/material.dart';
import 'package:familyhub/l10n/app_localizations.dart';

class MemoryCreateScreen extends StatelessWidget {
  const MemoryCreateScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context).aniYaz), centerTitle: true),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              decoration: InputDecoration(labelText: 'Başlık', filled: true, fillColor: const Color(0xFF13131A), border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none)),
            ),
            const SizedBox(height: 16),
            TextField(
              maxLines: 6,
              decoration: InputDecoration(labelText: 'Bugün ailenle yaşadığın güzel bir anı yaz...', filled: true, fillColor: const Color(0xFF13131A), border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none)),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF8B5CF6), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                child: const Text('Kaydet', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
