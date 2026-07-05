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
          Text('Kilometre Taşları', style: Theme.of(context).textTheme.displaySmall),
          const SizedBox(height: 12),
          _buildCard(title: 'İlk Adım', meta: '12 Mart 2024 • 11 ay'),
          _buildCard(title: 'İlk Kelime', meta: '5 Ocak 2024 • 9 ay'),
          _buildCard(title: 'İlk Diş', meta: '15 Ekim 2023 • 6 ay'),
          const SizedBox(height: 24),
          Text('Boy / Kilo Takibi', style: Theme.of(context).textTheme.displaySmall),
          const SizedBox(height: 12),
          _buildCard(title: 'Nisan 2026', meta: 'Boy: 85 cm • Kilo: 12.5 kg'),
          _buildCard(title: 'Mart 2026', meta: 'Boy: 84 cm • Kilo: 12.2 kg'),
        ],
      ),
    );
  }

  Widget _buildCard({required String title, required String meta}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: const Color(0xFF13131A), borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0x1EFFFFFF))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(meta, style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280))),
        ],
      ),
    );
  }
}
