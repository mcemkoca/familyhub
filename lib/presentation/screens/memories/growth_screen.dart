import 'package:flutter/material.dart';
import 'package:familyhub/l10n/app_localizations.dart';

class GrowthScreen extends StatelessWidget {
  const GrowthScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context).cocukGelisimi), centerTitle: true),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(AppLocalizations.of(context).kilometreTaslari, style: Theme.of(context).textTheme.displaySmall),
          const SizedBox(height: 12),
          _emptyCard('Henüz kilometre taşı eklenmedi. İlk adım, ilk kelime gibi '
              'anları buraya ekleyebilirsiniz.'),
          const SizedBox(height: 24),
          Text('Boy / Kilo Takibi', style: Theme.of(context).textTheme.displaySmall),
          const SizedBox(height: 12),
          _emptyCard('Henüz ölçüm eklenmedi. Boy ve kilo kayıtları burada '
              'listelenecek.'),
        ],
      ),
    );
  }

  Widget _emptyCard(String text) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: const Color(0xFF13131A), borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0x1EFFFFFF))),
      child: Row(
        children: [
          const Icon(Icons.child_care_rounded, color: Color(0xFF6B7280), size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(text, style: const TextStyle(fontSize: 13.5, color: Color(0xFF9CA3AF))),
          ),
        ],
      ),
    );
  }
}
