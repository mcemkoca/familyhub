import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/app_providers.dart';

class MoodScreen extends ConsumerWidget {
  const MoodScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final moods = ref.watch(moodEntriesProvider);
    final members = ref.watch(familyMembersProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Aile Ruh Hali'), centerTitle: true),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text('Bugün nasıl hissediyorsun?', style: Theme.of(context).textTheme.displaySmall),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: ['😊', '😢', '😠', '😴', '🤒', '🥳'].map((emoji) {
              return GestureDetector(
                onTap: () async {
                  await ref.read(moodEntriesProvider.notifier).addEntry(emoji);
                },
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: const Color(0xFF13131A),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0x1EFFFFFF)),
                  ),
                  child: Center(child: Text(emoji, style: const TextStyle(fontSize: 28))),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 32),
          Text('Aile Ruh Hali', style: Theme.of(context).textTheme.displaySmall),
          const SizedBox(height: 12),
          ...moods.map((mood) {
            final member = members.firstWhere((m) => m.id == mood.userId, orElse: () => members.first);
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF13131A),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0x1EFFFFFF)),
              ),
              child: Row(
                children: [
                  Text(mood.emoji, style: const TextStyle(fontSize: 32)),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(member.name, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                        if (mood.note != null) Text(mood.note!, style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280))),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
