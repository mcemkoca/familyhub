import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../config/constants.dart';
import '../../../services/gamification_service.dart';
import '../../widgets/settings/screen_header.dart';
import 'package:familyhub/l10n/app_localizations.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  List<Map<String, dynamic>> _leaderboard = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final data = await GamificationService.getLeaderboard();
      if (mounted) setState(() => _leaderboard = data);
    } catch (_) {
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.cloudWhite,
      appBar: ScreenHeader(
        title: 'Lider Tablosu',
        showBack: true,
        onBack: () => context.pop(),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _leaderboard.isEmpty
              ? Center(child: Text(AppLocalizations.of(context).henuzVeriYok))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _leaderboard.length,
                  itemBuilder: (context, index) {
                    final user = _leaderboard[index];
                    final rank = index + 1;
                    final isTop3 = rank <= 3;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkCard : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isDark ? AppColors.darkBorder : AppColors.border,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: isTop3
                                  ? switch (rank) {
                                      1 => const Color(0xFFFFD700),
                                      2 => const Color(0xFFC0C0C0),
                                      _ => const Color(0xFFCD7F32),
                                    }
                                  : isDark
                                      ? AppColors.darkCard
                                      : Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Center(
                              child: Text(
                                '$rank',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: isTop3 ? Colors.white : null,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          CircleAvatar(
                            radius: 22,
                            backgroundImage: user['avatar_url'] != null
                                ? NetworkImage(user['avatar_url'] as String)
                                : null,
                            backgroundColor: AppColors.cobalt.withAlpha(30),
                            child: user['avatar_url'] == null
                                ? Text(
                                    ((user['display_name'] as String?) ?? '?')[0].toUpperCase(),
                                    style: const TextStyle(
                                      color: AppColors.cobalt,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  )
                                : null,
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  (user['display_name'] as String?) ?? 'Kullanıcı',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: isDark
                                        ? AppColors.darkTextPrimary
                                        : AppColors.dark,
                                  ),
                                ),
                                if ((user['badges'] as List?)?.isNotEmpty == true)
                                  Wrap(
                                    spacing: 4,
                                    children: (user['badges'] as List)
                                        .take(3)
                                        .map((b) => Icon(
                                              Icons.emoji_events,
                                              size: 14,
                                              color: AppColors.success,
                                            ))
                                        .toList(),
                                  ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.cobalt.withAlpha(15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${user['xp'] ?? 0} XP',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppColors.cobalt,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}
