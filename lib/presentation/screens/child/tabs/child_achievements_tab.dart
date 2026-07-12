import 'package:flutter/material.dart';
import 'package:familyhub/l10n/app_localizations.dart';
import 'package:flutter/services.dart';

class ChildAchievementsTab extends StatefulWidget {
  final String childName;
  const ChildAchievementsTab({super.key, required this.childName});

  @override
  State<ChildAchievementsTab> createState() => _ChildAchievementsTabState();
}

class _ChildAchievementsTabState extends State<ChildAchievementsTab>
    with SingleTickerProviderStateMixin {
  bool get isDark => Theme.of(context).brightness == Brightness.dark;

  late AnimationController _starController;
  // Gerçek kazanılan rozetlerden hesaplanır (sahte sabit puan yok).
  int get _totalPoints =>
      _badges.where((b) => b.earned).fold<int>(0, (s, b) => s + b.points);
  int get _level => (_totalPoints ~/ 200) + 1;
  final int _pointsToNext = 200;

  static const _badges = [
    _Badge('Görev Ustası', '🏆', 50, false, Color(0xFFF59E0B),
        'İlk görevini tamamladın!'),
    _Badge('5 Gün Seri', '🔥', 100, false, Color(0xFFEF4444),
        '5 gün boyunca görevleri eksik yapmadın.'),
    _Badge('Süper Okuyucu', '📚', 75, false, Color(0xFF3B82F6),
        '10 kitap okudun!'),
    _Badge('Matematik Dâhi', '🔢', 120, false, Color(0xFF8B5CF6),
        '20 matematik aktivitesi tamamla.'),
    _Badge('Sporcu', '⚽', 80, false, Color(0xFF10B981),
        'Bir haftada her gün spor yaptın.'),
    _Badge('Sanatkâr', '🎨', 60, false, Color(0xFFEC4899),
        '5 sanat aktivitesi tamamla.'),
    _Badge('Yardımsever', '❤️', 90, false, Color(0xFFF97316),
        'Aile görevlerinde 10 kez yardım et.'),
    _Badge('Bilim İnsanı', '🔬', 150, false, Color(0xFF06B6D4),
        '5 STEM aktivitesi tamamla.'),
    _Badge('Dil Ustası', '🌍', 110, false, Color(0xFF6366F1),
        '7 gün boyunca dil öğrenimi yap.'),
    _Badge('Mutfak Şefi', '👨‍🍳', 85, false, Color(0xFFF97316),
        'Bir yemek tarifini tamamladın!'),
    _Badge('Ekip Oyuncusu', '🤝', 70, false, Color(0xFF10B981),
        'Ailece 3 aktivite tamamla.'),
    _Badge('Deha', '🧠', 200, false, Color(0xFF8B5CF6),
        'Tüm kategorilerde en az 1 aktivite tamamla.'),
  ];

  @override
  void initState() {
    super.initState();
    _starController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _starController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final earned = _badges.where((b) => b.earned).toList();
    final notEarned = _badges.where((b) => !b.earned).toList();

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(child: _buildLevelCard(isDark)),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Text(AppLocalizations.of(context).catEarned(earned.length),
                style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFE5E7EB))),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverGrid(
            delegate: SliverChildBuilderDelegate(
              (_, i) => _BadgeTile(badge: earned[i], isDark: isDark),
              childCount: earned.length,
            ),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 0.85,
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
            child: Text(AppLocalizations.of(context).catPending(notEarned.length),
                style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFE5E7EB))),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
          sliver: SliverGrid(
            delegate: SliverChildBuilderDelegate(
              (_, i) =>
                  _BadgeTile(badge: notEarned[i], isDark: isDark, locked: true),
              childCount: notEarned.length,
            ),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 0.85,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLevelCard(bool isDark) {
    final progress = (_totalPoints % 200) / 200.0;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
              colors: [Color(0xFF8B5CF6), Color(0xFF6366F1)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
                color: const Color(0xFF8B5CF6).withAlpha(60),
                blurRadius: 16,
                offset: const Offset(0, 4))
          ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                AnimatedBuilder(
                  animation: _starController,
                  builder: (_, _) => Transform.scale(
                    scale: 0.85 + _starController.value * 0.15,
                    child: Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(30),
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: Colors.white.withAlpha(80), width: 2),
                      ),
                      child: Center(
                        child: Text('$_level',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 28,
                                fontWeight: FontWeight.w900)),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(AppLocalizations.of(context).catLevel(_level),
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 12)),
                      const SizedBox(height: 2),
                      Text(widget.childName,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w800)),
                      const SizedBox(height: 6),
                      Text('$_totalPoints XP',
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 13)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(AppLocalizations.of(context).catNextLevel,
                    style: const TextStyle(color: Colors.white70, fontSize: 12)),
                Text('$_pointsToNext XP kaldı',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w700)),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: Colors.white.withAlpha(30),
                valueColor: const AlwaysStoppedAnimation(Colors.white),
                minHeight: 10,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _StatPill(
                    '${_badges.where((b) => b.earned).length}', 'Rozet'),
                const _StatPill('7', 'Gün Serisi'),
                const _StatPill('23', 'Görev'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _BadgeTile extends StatelessWidget {
  final _Badge badge;
  final bool isDark;
  final bool locked;
  const _BadgeTile(
      {required this.badge, required this.isDark, this.locked = false});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: Text('${badge.emoji} ${badge.name}'),
            content: Text(badge.description),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(AppLocalizations.of(context).catOk)),
            ],
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: locked
              ? (const Color(0xFF13131A))
              : badge.color.withAlpha(20),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: locked ? const Color(0x1EFFFFFF) : badge.color.withAlpha(60),
              width: locked ? 1 : 2),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            locked
                ? Stack(
                    alignment: Alignment.center,
                    children: [
                      Text(badge.emoji,
                          style: const TextStyle(fontSize: 28)),
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                            color: Colors.black.withAlpha(80),
                            shape: BoxShape.circle),
                        child: const Icon(Icons.lock,
                            color: Colors.white70, size: 16),
                      ),
                    ],
                  )
                : Text(badge.emoji, style: const TextStyle(fontSize: 28)),
            const SizedBox(height: 6),
            Text(badge.name,
                maxLines: 2,
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: locked
                        ? const Color(0xFF6B7280)
                        : (const Color(0xFFE5E7EB)))),
            const SizedBox(height: 3),
            Text('+${badge.points} XP',
                style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: locked ? const Color(0xFF6B7280) : badge.color)),
          ],
        ),
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  final String value, label;
  const _StatPill(this.value, this.label);

  @override
  Widget build(BuildContext context) => Column(
        children: [
          Text(value,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w900)),
          Text(label,
              style: const TextStyle(color: Colors.white70, fontSize: 10)),
        ],
      );
}

class _Badge {
  final String name, description, emoji;
  final int points;
  final bool earned;
  final Color color;
  const _Badge(this.name, this.emoji, this.points, this.earned, this.color,
      this.description);
}
