import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../config/routes.dart';
import 'package:familyhub/l10n/app_localizations.dart';

class MemoriesScreen extends StatelessWidget {
  const MemoriesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context).anilar), centerTitle: true),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Row(
            children: [
              _ActionChip(icon: Icons.photo_album, label: 'Albümler', onTap: () => context.push(AppRoutes.album)),
              const SizedBox(width: 12),
              _ActionChip(icon: Icons.edit, label: 'Anı Yaz', onTap: () => context.push(AppRoutes.memoryCreate)),
              const SizedBox(width: 12),
              _ActionChip(icon: Icons.trending_up, label: 'Gelişim', onTap: () => context.push(AppRoutes.growth)),
            ],
          ),
          const SizedBox(height: 24),
          Text('Albümler', style: Theme.of(context).textTheme.displaySmall),
          const SizedBox(height: 12),
          const _AlbumCard(name: 'Aile Tatili 2025', count: 24),
          const _AlbumCard(name: 'Mirac\'ın Doğum Günü', count: 18),
          const SizedBox(height: 24),
          Text('Son Anılar', style: Theme.of(context).textTheme.displaySmall),
          const SizedBox(height: 12),
          const _MemoryCard(title: 'İlk Adım', date: '12 Mart 2024', excerpt: 'Mirac bugün ilk adımını attı...'),
          const _MemoryCard(title: 'Yılbaşı 2026', date: '1 Ocak 2026', excerpt: 'Tüm aile bir aradaydık...'),
        ],
      ),
    );
  }
}

class _ActionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _ActionChip({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(color: const Color(0xFF13131A), borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0x1EFFFFFF))),
          child: Column(
            children: [Icon(icon, color: const Color(0xFF8B5CF6)), const SizedBox(height: 8), Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600))],
          ),
        ),
      ),
    );
  }
}

class _AlbumCard extends StatelessWidget {
  final String name;
  final int count;
  const _AlbumCard({required this.name, required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: const Color(0xFF13131A), borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0x1EFFFFFF))),
      child: Row(
        children: [
          Container(width: 56, height: 56, decoration: BoxDecoration(color: const Color(0xFF0A0A0F), borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.image, color: Color(0xFF9CA3AF))),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [Text(name, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)), Text('$count fotoğraf', style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)))],
          ),
        ],
      ),
    );
  }
}

class _MemoryCard extends StatelessWidget {
  final String title;
  final String date;
  final String excerpt;
  const _MemoryCard({required this.title, required this.date, required this.excerpt});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: const Color(0xFF13131A), borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0x1EFFFFFF))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(date, style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
          const SizedBox(height: 8),
          Text(excerpt, style: const TextStyle(fontSize: 14, color: Color(0xFF6B7280))),
        ],
      ),
    );
  }
}
