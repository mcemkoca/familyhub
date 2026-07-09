import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../config/routes.dart';
import '../../domain/entities.dart';
import '../../presentation/providers/app_providers.dart';

/// Hub'da aile üyelerinin GÜNCEL ruh halini gösteren şerit. Veri kaynağı
/// mood_entries (gerçek, realtime moodEntriesProvider) — her üyenin en son
/// emojisi gösterilir. Dokununca ruh hali ekranına gider.
class FamilyMoodStrip extends ConsumerWidget {
  const FamilyMoodStrip({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entries = ref.watch(moodEntriesProvider);
    final members = ref.watch(familyMembersProvider);
    if (members.isEmpty) return const SizedBox.shrink();

    // Her üye için en son ruh hali emojisi (varsa).
    final latestByUser = <String, MoodEntry>{};
    for (final e in entries) {
      final cur = latestByUser[e.userId];
      if (cur == null || e.createdAt.isAfter(cur.createdAt)) {
        latestByUser[e.userId] = e;
      }
    }
    // Hiç ruh hali girişi yoksa şeridi gösterme.
    if (latestByUser.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 4),
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        decoration: BoxDecoration(
          color: Colors.white.withAlpha(10),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white.withAlpha(18), width: 0.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.mood_rounded,
                    size: 16, color: Color(0xFF14B8A6)),
                const SizedBox(width: 6),
                const Expanded(
                  child: Text('Ailenin Ruh Hali',
                      style: TextStyle(
                          color: Color(0xFFE5E7EB),
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700)),
                ),
                GestureDetector(
                  onTap: () => context.push(AppRoutes.mood),
                  child: const Text('Ekle',
                      style: TextStyle(
                          color: Color(0xFF14B8A6),
                          fontSize: 12,
                          fontWeight: FontWeight.w700)),
                ),
              ],
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 62,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: members.length,
                separatorBuilder: (_, _) => const SizedBox(width: 12),
                itemBuilder: (_, i) {
                  final m = members[i];
                  final mood = latestByUser[m.id];
                  return _MoodAvatar(member: m, emoji: mood?.emoji);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MoodAvatar extends StatelessWidget {
  final FamilyMember member;
  final String? emoji;
  const _MoodAvatar({required this.member, this.emoji});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 52,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: member.color.withAlpha(45),
                  border: Border.all(color: member.color.withAlpha(120)),
                ),
                clipBehavior: Clip.antiAlias,
                child: member.avatarUrl != null
                    ? Image.network(member.avatarUrl!, fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => _initial())
                    : _initial(),
              ),
              Positioned(
                right: -4,
                bottom: -4,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: const BoxDecoration(
                    color: Color(0xFF13131A),
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    emoji ?? '➕',
                    style: TextStyle(fontSize: emoji != null ? 15 : 11),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            member.name.split(' ').first,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 10),
          ),
        ],
      ),
    );
  }

  Widget _initial() => Center(
        child: Text(member.initial,
            style: TextStyle(
                color: member.color,
                fontWeight: FontWeight.bold,
                fontSize: 15)),
      );
}
