import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../config/routes.dart';
import '../../../core/supabase_client.dart';
import '../../providers/app_providers.dart';
import '../../../domain/entities.dart';
import '../../../services/hive_service.dart';
import '../../widgets/notification_prompt.dart';
import '../../../components/hub/ai_suggestions_widget.dart';
import '../../../components/hub/hub_ai_panel.dart';
import '../../../components/hub/daily_briefing_card.dart';
import '../../../components/hub/smart_insights_card.dart';
import '../../../components/hub/legal_benefits_card.dart';
import '../../../components/hub/family_mood_strip.dart';
import '../../../services/location_tracking_service.dart';

// ─── Notification model ───────────────────────────────────────────────────────
class _HubNotif {
  final IconData icon;
  final Color color;
  final String title;
  final String source;
  final String time;
  const _HubNotif({
    required this.icon,
    required this.color,
    required this.title,
    required this.source,
    required this.time,
  });
}

// ─── Quick-access feature model ───────────────────────────────────────────────
class _Feature {
  final IconData icon;
  final String label;
  final List<Color> gradient;
  final Color shadow;
  final String route;
  final String? asset; // premium PNG tile (varsa gradient+ikon yerine kullanılır)
  const _Feature(this.icon, this.label, this.gradient, this.shadow, this.route,
      {this.asset});
}

// ─── Hub Screen ───────────────────────────────────────────────────────────────
class HubScreen extends ConsumerStatefulWidget {
  const HubScreen({super.key});
  @override
  ConsumerState<HubScreen> createState() => _HubScreenState();
}

class _HubScreenState extends ConsumerState<HubScreen>
    with TickerProviderStateMixin {

  // notification ticker
  int _notifIdx = 0;
  bool _notifExpanded = false;
  // Gerçek verilerden üretilen canlı bildirimler (build'de doldurulur).
  List<_HubNotif> _liveNotifs = const [];
  late Timer _tickerTimer;
  late AnimationController _tickerFade;

  // sample notifications (will come from Supabase / FCM in production)


  static final _features = <_Feature>[
    const _Feature(Icons.shopping_bag_rounded,     'Alışveriş',   [Color(0xFF10B981), Color(0xFF059669)], Color(0xFF064E3B), AppRoutes.shopping, asset: 'assets/icons/tiles/shopping.png'),
    const _Feature(Icons.ramen_dining_rounded,     'Mutfak',      [Color(0xFFF59E0B), Color(0xFFD97706)], Color(0xFF78350F), AppRoutes.kitchen, asset: 'assets/icons/tiles/kitchen.png'),
    const _Feature(Icons.child_care_rounded,       'Çocuk',       [Color(0xFF06B6D4), Color(0xFF0891B2)], Color(0xFF164E63), AppRoutes.childManagement, asset: 'assets/icons/tiles/child.png'),
    const _Feature(Icons.emoji_nature_rounded,     'Gelişim',     [Color(0xFFF43F5E), Color(0xFFE11D48)], Color(0xFF881337), AppRoutes.childDevelopment, asset: 'assets/icons/tiles/growth.png'),
    const _Feature(Icons.favorite_rounded,         'Sağlık',      [Color(0xFF14B8A6), Color(0xFF0D9488)], Color(0xFF134E4A), AppRoutes.familyHealth, asset: 'assets/icons/tiles/health.png'),
    const _Feature(Icons.location_on_rounded,      'Konum',       [Color(0xFF3B82F6), Color(0xFF2563EB)], Color(0xFF1E3A8A), AppRoutes.familyMap, asset: 'assets/icons/tiles/location.png'),
    const _Feature(Icons.emergency_rounded,        'Acil',        [Color(0xFFEF4444), Color(0xFFDC2626)], Color(0xFF7F1D1D), AppRoutes.emergency, asset: 'assets/icons/tiles/emergency.png'),
    const _Feature(Icons.savings_rounded,          'Bütçe',       [Color(0xFFA855F7), Color(0xFF9333EA)], Color(0xFF581C87), AppRoutes.budget, asset: 'assets/icons/tiles/budget.png'),
    const _Feature(Icons.receipt_long_rounded,     'Ev Giderleri',[Color(0xFF6366F1), Color(0xFF4F46E5)], Color(0xFF312E81), AppRoutes.subscriptions, asset: 'assets/icons/tiles/expenses.png'),
    const _Feature(Icons.collections_rounded,      'Galeri',      [Color(0xFFEC4899), Color(0xFFDB2777)], Color(0xFF831843), AppRoutes.gallery, asset: 'assets/icons/tiles/gallery.png'),
    const _Feature(Icons.school_rounded,           'Eğitim',      [Color(0xFF8B5CF6), Color(0xFF7C3AED)], Color(0xFF4C1D95), AppRoutes.education, asset: 'assets/icons/tiles/education.png'),
    const _Feature(Icons.auto_awesome_rounded,     'AI',          [Color(0xFF4776E6), Color(0xFF2D3A8C)], Color(0xFF1E1B4B), AppRoutes.aiAssistant, asset: 'assets/icons/tiles/ai.png'),
  ];

  @override
  void initState() {
    super.initState();
    LocationTrackingService.startTracking();

    // İlk açılışta bir kez bildirim izni promptunu göster.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) NotificationPrompt.maybeShow(context);
    });

    _tickerFade = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
      value: 1.0,
    );

    _tickerTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!_notifExpanded) _cycleNotif();
    });
  }

  Future<void> _cycleNotif() async {
    await _tickerFade.reverse();
    if (!mounted) return;
    setState(() => _notifIdx = (_notifIdx + 1) % _liveNotifs.length);
    await _tickerFade.forward();
  }

  @override
  void dispose() {
    _tickerTimer.cancel();
    _tickerFade.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    ref.invalidate(todaySummaryProvider);
    ref.invalidate(upcomingEventsProvider);
    ref.invalidate(myTasksProvider);
    ref.invalidate(familyMoodsProvider);
    ref.invalidate(weatherProvider);
    await Future.delayed(const Duration(milliseconds: 500));
  }

  // Ana Ekran Özelleştir'de kaydedilen kutucuk sırasını uygular.
  List<_Feature> _applyOrder(List<_Feature> features) {
    final raw = HiveService.getSetting('hub_tile_order');
    if (raw == null || raw.isEmpty) return features;
    final order = raw.split('|');
    final ranked = [...features];
    ranked.sort((a, b) {
      final ia = order.indexOf(a.route);
      final ib = order.indexOf(b.route);
      return (ia < 0 ? 9999 : ia).compareTo(ib < 0 ? 9999 : ib);
    });
    return ranked;
  }

  /// Returns the subset of features visible to the given role.
  List<_Feature> _featuresForRole(MemberRole role) {
    switch (role) {
      case MemberRole.child:
      case MemberRole.baby:
        // Kids see only tasks, education, and chat
        return _features.where((f) =>
          f.route == AppRoutes.childManagement ||
          f.route == AppRoutes.childDevelopment ||
          f.route == AppRoutes.education,
        ).toList();
      case MemberRole.elder:
        // Elders: health-first ordering, no child management
        final priority = [
          AppRoutes.familyHealth,
          AppRoutes.emergency,
          AppRoutes.shopping,
          AppRoutes.budget,
          AppRoutes.gallery,
          AppRoutes.aiAssistant,
        ];
        return [
          ..._features.where((f) => priority.contains(f.route)),
          ..._features.where((f) => !priority.contains(f.route) &&
              f.route != AppRoutes.childManagement &&
              f.route != AppRoutes.childDevelopment),
        ];
      case MemberRole.guest:
        // Guests: shared shopping and gallery only
        return _features.where((f) =>
          f.route == AppRoutes.shopping ||
          f.route == AppRoutes.gallery,
        ).toList();
      case MemberRole.teen:
        // Teens: everything except child management tools
        return _features.where((f) =>
          f.route != AppRoutes.childManagement,
        ).toList();
      case MemberRole.admin:
      case MemberRole.parent:
        return _features;
    }
  }

  // Gerçek verilerden (yaklaşan etkinlikler + görevler) bildirim şeridi üretir.
  // Veri yoksa dostça bir varsayılan gösterir.
  List<_HubNotif> _buildLiveNotifs() {
    final events = ref.watch(upcomingEventsProvider).valueOrNull ?? [];
    final tasks = ref.watch(myTasksProvider).valueOrNull ?? [];
    String hhmm(DateTime d) =>
        '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
    String rel(DateTime d) {
      final diff = d.difference(DateTime.now());
      if (diff.isNegative) return 'geçti';
      if (diff.inMinutes < 60) return '${diff.inMinutes} dk sonra';
      if (diff.inHours < 24) return '${diff.inHours} saat sonra';
      return '${diff.inDays} gün sonra';
    }

    final list = <_HubNotif>[];
    for (final e in events.take(4)) {
      list.add(_HubNotif(
        icon: Icons.calendar_today_outlined,
        color: const Color(0xFF6366F1),
        title: e.title,
        source: 'Takvim · ${rel(e.start)}',
        time: hhmm(e.start),
      ));
    }
    for (final t in tasks.take(4)) {
      list.add(_HubNotif(
        icon: Icons.check_circle_outline,
        color: const Color(0xFF10B981),
        title: t.title,
        source: t.dueDate != null ? 'Görev · ${rel(t.dueDate!)}' : 'Görev',
        time: t.dueDate != null ? hhmm(t.dueDate!) : '',
      ));
    }
    if (list.isEmpty) {
      list.add(const _HubNotif(
        icon: Icons.notifications_none_rounded,
        color: Color(0xFF6B7280),
        title: 'Şimdilik yeni bildirim yok',
        source: 'Her şey güncel',
        time: '',
      ));
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final members = ref.watch(familyMembersProvider);
    final role = ref.watch(currentMemberRoleProvider);
    final visibleFeatures = _applyOrder(_featuresForRole(role));
    // Hub realtime senkronu canlı tutulsun (events/moods/tasks → anlık tazeleme).
    ref.watch(hubRealtimeSyncProvider);
    _liveNotifs = _buildLiveNotifs();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: const Color(0xFF07060D),
        body: Stack(
          children: [
            // ── Family Mode arka planı: sıcak + soğuk dengeli derinlik ──
            const Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0xFF2A1830), // üst: sıcak mor-bordo
                      Color(0xFF1A1230),
                      Color(0xFF0E0B18),
                      Color(0xFF0A0810), // alt: sıcak-koyu
                    ],
                    stops: [0.0, 0.32, 0.68, 1.0],
                  ),
                ),
              ),
            ),
            // ── Sıcak parıltı (mercan/şeftali) — aile sıcaklığı ──
            Positioned(
              top: -150,
              right: -90,
              child: Container(
                width: 360,
                height: 360,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFFFF6B8B).withAlpha(70), // sıcak pembe-mercan
                      const Color(0xFFFF6B8B).withAlpha(0),
                    ],
                  ),
                ),
              ),
            ),
            // ── Soğuk parıltı (indigo/teal) — denge ──
            Positioned(
              top: -70,
              left: -120,
              child: Container(
                width: 320,
                height: 320,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFF5B8DEF).withAlpha(64), // soğuk mavi
                      const Color(0xFF5B8DEF).withAlpha(0),
                    ],
                  ),
                ),
              ),
            ),
            // ── Alt sıcak amber tabanı (yuva hissi) ──
            Positioned(
              bottom: -160,
              right: -60,
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFFFFB27A).withAlpha(38), // sıcak amber
                      const Color(0xFFFFB27A).withAlpha(0),
                    ],
                  ),
                ),
              ),
            ),
            SafeArea(
              bottom: false,
              child: RefreshIndicator(
          onRefresh: _refresh,
          color: const Color(0xFF6366F1),
          backgroundColor: const Color(0xFF1A1A2E),
          child: CustomScrollView(
            slivers: [
              // ── Çevrimdışı rozeti ────────────────────────────────────────
              if (ref.watch(connectivityProvider).valueOrNull == false)
                const SliverToBoxAdapter(child: _OfflineBanner()),

              // ── Ticker notification bar ──────────────────────────────────
              SliverToBoxAdapter(child: _NotifTicker(
                notifs: _liveNotifs,
                currentIdx: _notifIdx.clamp(0, _liveNotifs.length - 1),
                expanded: _notifExpanded,
                fade: _tickerFade,
                onTap: () => setState(() => _notifExpanded = !_notifExpanded),
                onDismiss: (i) => setState(() {}),
              )),

              // ── Cover + profiles ─────────────────────────────────────────
              SliverToBoxAdapter(child: _CoverSection(members: members)),

              // ── Günlük Zeka Özeti (hub'ın beyni) ─────────────────────────
              const SliverToBoxAdapter(child: DailyBriefingCard()),

              // ── Akıllı Uyarılar (gerçek veriden içgörüler) ───────────────
              const SliverToBoxAdapter(child: SmartInsightsCard()),

              // ── Günlük Öneriler (eski Keşfet'in yerinde, collapse) ────────
              if (HiveService.getBoolSetting('hub_show_smart_card',
                  defaultValue: true))
                const SliverToBoxAdapter(child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: AISuggestionsWidget(),
                )),

              // ── Ailenin ruh hali (mood_entries — gerçek, realtime) ──────
              const SliverToBoxAdapter(child: FamilyMoodStrip()),

              // ── Yasal Haklar & Avantajlar (ülkeye göre, AI/realtime) ─────
              const SliverToBoxAdapter(child: LegalBenefitsCard()),

              // ── Quick access grid (butonlar hemen gorunsun) ──────────────
              SliverToBoxAdapter(child: _QuickGrid(features: visibleFeatures)),

              // ── Hub gömülü mini AI sohbet paneli ──────────────────────────
              const SliverToBoxAdapter(child: HubAiPanel()),

              // ── Stat strip ───────────────────────────────────────────────
              const SliverToBoxAdapter(child: _StatStrip()),

              const SliverToBoxAdapter(child: SizedBox(height: 32)),
            ],
          ),
        ),
        ),
          ],
        ),
      ),
    );
  }
}

// ─── Notification Ticker ──────────────────────────────────────────────────────
class _NotifTicker extends StatelessWidget {
  final List<_HubNotif> notifs;
  final int currentIdx;
  final bool expanded;
  final AnimationController fade;
  final VoidCallback onTap;
  final ValueChanged<int> onDismiss;

  const _NotifTicker({
    required this.notifs,
    required this.currentIdx,
    required this.expanded,
    required this.fade,
    required this.onTap,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final notif = notifs[currentIdx];
    return Column(
      children: [
        // ticker bar
        GestureDetector(
          onTap: onTap,
          child: Container(
            color: Colors.transparent,
            padding: const EdgeInsets.fromLTRB(14, 8, 14, 6),
            child: Row(
              children: [
                // colored icon
                Container(
                  width: 22, height: 22,
                  decoration: BoxDecoration(
                    color: notif.color,
                    borderRadius: BorderRadius.circular(7),
                  ),
                  child: Icon(notif.icon, size: 13, color: Colors.white),
                ),
                const SizedBox(width: 8),
                // fading text
                Expanded(
                  child: FadeTransition(
                    opacity: fade,
                    child: Text(
                      notif.title,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFFD1D5DB),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // dots
                Row(
                  children: List.generate(notifs.length, (i) => Container(
                    width: i == currentIdx ? 14 : 4,
                    height: 4,
                    margin: const EdgeInsets.only(right: 3),
                    decoration: BoxDecoration(
                      color: i == currentIdx
                          ? const Color(0xFF6366F1)
                          : Colors.white.withAlpha(40),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  )),
                ),
                const SizedBox(width: 6),
                // count badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6366F1).withAlpha(50),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${notifs.length} yeni',
                    style: const TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFFA5B4FC),
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                AnimatedRotation(
                  turns: expanded ? 0.5 : 0,
                  duration: const Duration(milliseconds: 250),
                  child: const Icon(Icons.keyboard_arrow_down,
                      size: 16, color: Color(0xFF6B7280)),
                ),
              ],
            ),
          ),
        ),

        // expanded cards
        AnimatedSize(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          child: expanded
              ? Padding(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                  child: Column(
                    children: List.generate(notifs.length, (i) {
                      final n = notifs[i];
                      return Dismissible(
                        key: ValueKey(i),
                        onDismissed: (_) => onDismiss(i),
                        background: Container(
                          margin: const EdgeInsets.only(bottom: 6),
                          decoration: BoxDecoration(
                            color: Colors.red.withAlpha(40),
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 6),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            color: n.color.withAlpha(15),
                            borderRadius: BorderRadius.circular(14),
                            border: Border(
                              left: BorderSide(color: n.color, width: 3),
                              top: BorderSide(
                                  color: n.color.withAlpha(40), width: 0.5),
                              right: BorderSide(
                                  color: n.color.withAlpha(40), width: 0.5),
                              bottom: BorderSide(
                                  color: n.color.withAlpha(40), width: 0.5),
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 30, height: 30,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [n.color, n.color.withAlpha(180)],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(n.icon, size: 15, color: Colors.white),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(n.title,
                                        style: const TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w700,
                                            color: Color(0xFFE5E7EB))),
                                    const SizedBox(height: 2),
                                    Text(n.source,
                                        style: const TextStyle(
                                            fontSize: 9,
                                            color: Color(0xFF6B7280))),
                                  ],
                                ),
                              ),
                              Text(n.time,
                                  style: const TextStyle(
                                      fontSize: 9,
                                      color: Color(0xFF6B7280),
                                      fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                      );
                    }),
                  ),
                )
              : const SizedBox.shrink(),
        ),

        // divider
        Container(height: 0.5, color: Colors.white.withAlpha(15)),
      ],
    );
  }
}

// ─── Cover Section ────────────────────────────────────────────────────────────
/// Aile kapak fotoğrafı: yerel dosya yolu veya uzak URL. Yerel kopya
/// öncelikli — Supabase yüklemesi başarısız olsa (403) bile fotoğraf görünür.
final coverPhotoProvider = StateProvider<String?>((ref) =>
    HiveService.getSetting('cover_photo_local') ??
    HiveService.getSetting('cover_photo_url'));

class _CoverSection extends ConsumerWidget {
  final List<FamilyMember> members;
  const _CoverSection({required this.members});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final weatherAsync = ref.watch(weatherProvider);
    final familyName = HiveService.getSetting('family_name') ?? 'Ailem';
    final coverPhoto = ref.watch(coverPhotoProvider);

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 10, 12, 0),
      height: 210,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6366F1).withAlpha(40),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // cover photo (yerel dosya veya URL) ya da gradyan
            if (coverPhoto == null)
              _CoverGradient()
            else if (coverPhoto.startsWith('http'))
              CachedNetworkImage(
                imageUrl: coverPhoto,
                fit: BoxFit.cover,
                placeholder: (_, _) => _CoverGradient(),
                errorWidget: (_, _, _) => _CoverGradient(),
              )
            else
              Image.file(
                File(coverPhoto),
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => _CoverGradient(),
              ),

            // gradient overlay
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withAlpha(120),
                    Colors.black.withAlpha(210),
                  ],
                  stops: const [0.0, 0.5, 1.0],
                ),
              ),
            ),

            // top row: logo + weather + edit
            Positioned(
              top: 12, left: 12, right: 12,
              child: Row(
                children: [
                  // logo
                  Container(
                    width: 30, height: 30,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(9),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(40),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(9),
                      child: Image.asset(
                        'assets/images/logo_icon.png',
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'FamilyHub',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  const Spacer(),
                  // weather
                  weatherAsync.when(
                    data: (w) => _WeatherPill(
                        temp: w.temperature.round()),
                    loading: () => const SizedBox.shrink(),
                    error: (_, _) => const SizedBox.shrink(),
                  ),
                  const SizedBox(width: 6),
                  // edit cover
                  GestureDetector(
                    onTap: () => _pickCoverPhoto(context, ref),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.black.withAlpha(80),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: Colors.white.withAlpha(40), width: 0.5),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.camera_alt_outlined,
                              size: 11, color: Color(0xFF9CA3AF)),
                          SizedBox(width: 3),
                          Text('Fotoğraf',
                              style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF9CA3AF))),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // bottom: family name + location + member profiles
            Positioned(
              bottom: 12, left: 12, right: 12,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$familyName Ailesi',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 3),
                  _LocationRow(),
                  const SizedBox(height: 10),
                  _MemberProfiles(members: members),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickCoverPhoto(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    final picker = ImagePicker();
    final picked =
        await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (picked == null) return;

    // 1) Önce yerel kopyayı kaydet → fotoğraf anında görünür (403 olsa bile).
    String? localPath;
    try {
      final dir = await getApplicationDocumentsDirectory();
      final ext = picked.path.split('.').last;
      final dest = File('${dir.path}/cover_photo.$ext');
      await dest.writeAsBytes(await File(picked.path).readAsBytes());
      localPath = dest.path;
      await HiveService.setSetting('cover_photo_local', localPath);
      ref.read(coverPhotoProvider.notifier).state = localPath;
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Kapak fotoğrafı güncellendi'),
          backgroundColor: Color(0xFF6366F1),
        ),
      );
    } catch (_) {
      // Yerel kopya bile başarısızsa devam etme.
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Fotoğraf kaydedilemedi'),
          backgroundColor: Color(0xFFEF4444),
        ),
      );
      return;
    }

    // 2) Buluta yükle (opsiyonel senkron). Başarısız olursa yerel görsel kalır.
    try {
      final client = SupabaseConfig.safeClient;
      final userId = client?.auth.currentUser?.id;
      if (client == null || userId == null) return;

      final bytes = await File(picked.path).readAsBytes();
      final ext = picked.path.split('.').last;
      final path = 'cover_photos/$userId/cover.$ext';
      await client.storage.from('family-assets').uploadBinary(
            path,
            bytes,
            fileOptions: FileOptions(contentType: 'image/$ext', upsert: true),
          );
      final url = client.storage.from('family-assets').getPublicUrl(path);
      await client
          .from('profiles')
          .update({'cover_photo_url': url}).eq('id', userId);
      await HiveService.setSetting('cover_photo_url', url);
    } catch (_) {
      // Bulut senkronu başarısız (ör. 403 / bucket yok) — yerel görsel geçerli.
    }
  }
}

class _CoverGradient extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0D0D1A), Color(0xFF1E1035), Color(0xFF0F0820)],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
      ),
      child: CustomPaint(painter: _OrbPainter()),
    );
  }
}

class _OrbPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..maskFilter = const MaskFilter.blur(BlurStyle.normal, 40);
    p.color = const Color(0xFF6366F1).withAlpha(120);
    canvas.drawCircle(Offset(size.width * 0.8, size.height * 0.1), 80, p);
    p.color = const Color(0xFFEC4899).withAlpha(80);
    canvas.drawCircle(Offset(size.width * 0.15, size.height * 0.8), 60, p);
    p.color = const Color(0xFF06B6D4).withAlpha(60);
    canvas.drawCircle(Offset(size.width * 0.5, size.height * 0.5), 40, p);
  }
  @override
  bool shouldRepaint(_) => false;
}

class _WeatherPill extends StatelessWidget {
  final int temp;
  const _WeatherPill({required this.temp});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withAlpha(70),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withAlpha(30), width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.wb_sunny_outlined, size: 12, color: Color(0xFFFBBF24)),
          const SizedBox(width: 4),
          Text('$temp°',
              style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: Colors.white)),
        ],
      ),
    );
  }
}

class _OfflineBanner extends StatelessWidget {
  const _OfflineBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: const Color(0xFFF59E0B).withAlpha(38),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.cloud_off_rounded, size: 15, color: Color(0xFFF59E0B)),
          SizedBox(width: 8),
          Text(
            'Çevrimdışısın — değişiklikler bağlanınca senkronlanacak',
            style: TextStyle(
                color: Color(0xFFF59E0B),
                fontSize: 12,
                fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _LocationRow extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Provider konumu GPS'ten çözüp Hive'a önbellekler; beklerken cache'i göster.
    final resolved = ref.watch(currentLocationProvider).valueOrNull;
    final locationModel = resolved ?? HiveService.getLocation();
    final city = locationModel != null && locationModel.city.isNotEmpty
        ? locationModel.city
        : 'Konum alınıyor…';
    final country = locationModel?.country ?? '';
    return Row(
      children: [
        const Icon(Icons.location_on_outlined,
            size: 11, color: Color(0xFF818CF8)),
        const SizedBox(width: 3),
        Text(
          country.isNotEmpty ? '$city, $country' : city,
          style: const TextStyle(fontSize: 10, color: Color(0xFFD1D5DB)),
        ),
      ],
    );
  }
}

// ─── Member profile circles ───────────────────────────────────────────────────
class _MemberProfiles extends StatelessWidget {
  final List<FamilyMember> members;
  const _MemberProfiles({required this.members});

  @override
  Widget build(BuildContext context) {
    final show = members.isEmpty
        ? <FamilyMember>[]
        : members.take(5).toList();

    return Row(
      children: [
        ...show.map((m) => _ProfileAvatar(member: m)),
        // add button
        GestureDetector(
          onTap: () => context.push(AppRoutes.family),
          child: Container(
            width: 44,
            height: 44,
            margin: const EdgeInsets.only(left: 6),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                  color: Colors.white.withAlpha(40), width: 1.5,
                  strokeAlign: BorderSide.strokeAlignInside),
              color: Colors.white.withAlpha(15),
            ),
            child: const Icon(Icons.add,
                size: 18, color: Color(0xFF6B7280)),
          ),
        ),
      ],
    );
  }
}

class _ProfileAvatar extends StatelessWidget {
  final FamilyMember member;
  const _ProfileAvatar({required this.member});

  static const _gradients = [
    [Color(0xFFEC4899), Color(0xFFF43F5E)],
    [Color(0xFF6366F1), Color(0xFF3B82F6)],
    [Color(0xFF10B981), Color(0xFF06B6D4)],
    [Color(0xFFF59E0B), Color(0xFFF43F5E)],
    [Color(0xFF8B5CF6), Color(0xFF6366F1)],
  ];

  @override
  Widget build(BuildContext context) {
    final idx = member.name.codeUnits.fold(0, (a, b) => a + b) % _gradients.length;
    final colors = _gradients[idx];
    final initial = member.name.isNotEmpty
        ? member.name[0].toUpperCase()
        : '?';

    return GestureDetector(
      onTap: () => context.push(AppRoutes.family),
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        child: Stack(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: colors,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border.all(
                  color: member.isOnline
                      ? const Color(0xFF22C55E)
                      : Colors.white.withAlpha(50),
                  width: 2,
                ),
                boxShadow: member.isOnline
                    ? [BoxShadow(
                        color: const Color(0xFF22C55E).withAlpha(80),
                        blurRadius: 8,
                      )]
                    : null,
              ),
              child: member.avatarUrl != null && member.avatarUrl!.isNotEmpty
                  ? ClipOval(
                      child: CachedNetworkImage(
                        imageUrl: member.avatarUrl!,
                        fit: BoxFit.cover,
                        errorWidget: (_, _, _) => Center(
                          child: Text(initial,
                              style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white)),
                        ),
                      ),
                    )
                  : Center(
                      child: Text(initial,
                          style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: Colors.white)),
                    ),
            ),
            // online/offline dot
            Positioned(
              right: 0, bottom: 0,
              child: Container(
                width: 12, height: 12,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: member.isOnline
                      ? const Color(0xFF22C55E)
                      : const Color(0xFF4B5563),
                  border: Border.all(
                      color: const Color(0xFF0A0A0F), width: 2),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── 3×4 Quick Access Grid ───────────────────────────────────────────────────
class _QuickGrid extends StatelessWidget {
  final List<_Feature> features;
  const _QuickGrid({required this.features});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 10, 12, 0),
      padding: const EdgeInsets.fromLTRB(12, 14, 12, 16),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(10),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withAlpha(18), width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 6, height: 6,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [Color(0xFF6366F1), Color(0xFFEC4899)],
                  ),
                ),
              ),
              const SizedBox(width: 6),
              const Text(
                'HIZLI ERİŞİM',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF6B7280),
                  letterSpacing: 1.0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: features.length, // 12 özellik → 3x4, "more" kaldırıldı
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 10,
              crossAxisSpacing: 8,
              // Daha büyük butonlar için artırılmış hücre yüksekliği.
              mainAxisExtent: 138,
            ),
            itemBuilder: (context, i) {
              final f = features[i];
              return _FeatureTile(feature: f);
            },
          ),
        ],
      ),
    );
  }
}

class _FeatureTile extends StatefulWidget {
  final _Feature feature;
  const _FeatureTile({required this.feature});
  @override
  State<_FeatureTile> createState() => _FeatureTileState();
}

class _FeatureTileState extends State<_FeatureTile> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final f = widget.feature;
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        context.push(f.route);
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.92 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (f.asset != null)
              // Premium PNG tile — kendi renkli zemini + parıltısı ile.
              SizedBox(
                width: 92,
                height: 92,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    boxShadow: [
                      BoxShadow(
                        color: f.shadow.withAlpha(_pressed ? 50 : 90),
                        blurRadius: _pressed ? 8 : 18,
                        offset: Offset(0, _pressed ? 2 : 6),
                      ),
                    ],
                  ),
                  child: Image.asset(f.asset!, fit: BoxFit.contain),
                ),
              )
            else
            Container(
              width: 92, height: 92,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: f.gradient,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: f.shadow.withAlpha(_pressed ? 60 : 100),
                    blurRadius: _pressed ? 6 : 14,
                    offset: Offset(0, _pressed ? 2 : 5),
                  ),
                  BoxShadow(
                    color: f.gradient[0].withAlpha(_pressed ? 30 : 60),
                    blurRadius: 0,
                    offset: Offset(0, _pressed ? 1 : 4),
                  ),
                ],
                border: Border(
                  bottom: BorderSide(
                      color: Colors.black.withAlpha(60), width: 2),
                ),
              ),
              child: Stack(
                children: [
                  // gloss
                  Positioned(
                    top: 0, left: 0, right: 0,
                    height: 38,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(22)),
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.white.withAlpha(45),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                  Center(
                    child: Icon(f.icon, size: 42, color: Colors.white,
                        shadows: [
                          Shadow(
                            color: Colors.black.withAlpha(100),
                            blurRadius: 6,
                          ),
                        ]),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              f.label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Color(0xFFC7CBD4),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Stat Strip ───────────────────────────────────────────────────────────────
class _StatStrip extends ConsumerWidget {
  const _StatStrip();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasksAsync = ref.watch(myTasksProvider);
    final taskCount = tasksAsync.valueOrNull?.length ?? 0;

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
      child: Row(
        children: [
          _StatCard(value: '$taskCount', label: 'BUGÜN GÖREV'),
          const SizedBox(width: 8),
          const _StatCard(value: '🔥 7', label: 'GÜN SERİSİ'),
          const SizedBox(width: 8),
          const _StatCard(value: '3', label: 'ÇEVRİMİÇİ',
              accent: Color(0xFF22C55E)),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String value;
  final String label;
  final Color? accent;
  const _StatCard({required this.value, required this.label, this.accent});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withAlpha(10),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withAlpha(18), width: 0.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: accent ?? Colors.white,
                )),
            const SizedBox(height: 2),
            Text(label,
                style: const TextStyle(
                  fontSize: 8,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF6B7280),
                  letterSpacing: 0.4,
                )),
          ],
        ),
      ),
    );
  }
}
