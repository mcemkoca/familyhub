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
          const _EmptyCard(
              icon: Icons.photo_album_outlined,
              text: 'Henüz albüm yok. "Albümler"den yeni bir albüm '
                  'oluşturabilirsiniz.'),
          const SizedBox(height: 24),
          Text('Son Anılar', style: Theme.of(context).textTheme.displaySmall),
          const SizedBox(height: 12),
          const _EmptyCard(
              icon: Icons.auto_stories_outlined,
              text: 'Henüz anı yazılmadı. "Anı Yaz" ile ilk anınızı '
                  'ekleyebilirsiniz.'),
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

class _EmptyCard extends StatelessWidget {
  final IconData icon;
  final String text;
  const _EmptyCard({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: const Color(0xFF13131A), borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0x1EFFFFFF))),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF6B7280), size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text(text, style: const TextStyle(fontSize: 13.5, color: Color(0xFF9CA3AF))),
          ),
        ],
      ),
    );
  }
}
