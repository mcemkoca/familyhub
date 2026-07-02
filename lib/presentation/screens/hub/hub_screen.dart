import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../config/routes.dart';
import '../../../repositories/hub_repository.dart';
import '../../providers/app_providers.dart';
import '../../../domain/entities.dart';
import '../../../services/weather_service.dart';
import '../../../services/hive_service.dart';
import '../../../components/hub/ai_suggestions_widget.dart';
import '../../../components/hub/content_widgets/content_highlights_widget.dart';
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
  const _Feature(this.icon, this.label, this.gradient, this.shadow, this.route);
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
  late Timer _tickerTimer;
  late AnimationController _tickerFade;

  // sample notifications (will come from Supabase / FCM in production)
  static const _notifs = [
    _HubNotif(
      icon: Icons.medication_outlined,
      color: Color(0xFFEF4444),
      title: "Elif'in vitamini alınmadı",
      source: 'Sağlık · hatırlatıcı',
      time: '09:41',
    ),
    _HubNotif(
      icon: Icons.calendar_today_outlined,
      color: Color(0xFF6366F1),
      title: 'Diş hekimi randevusu — 14:00',
      source: 'Takvim · 2 saat sonra',
      time: '09:38',
    ),
    _HubNotif(
      icon: Icons.location_on_outlined,
      color: Color(0xFF10B981),
      title: 'Kerem okula ulaştı',
      source: 'Konum · otomatik',
      time: '08:21',
    ),
    _HubNotif(
      icon: Icons.credit_card_outlined,
      color: Color(0xFFF59E0B),
      title: 'Netflix yenileniyor — 3 gün',
      source: 'Abonelik · hatırlatıcı',
      time: '08:00',
    ),
  ];

  static final _features = <_Feature>[
    _Feature(Icons.shopping_cart_outlined,   'Alışveriş',   [Color(0xFF10B981), Color(0xFF059669)], Color(0xFF064E3B), AppRoutes.shopping),
    _Feature(Icons.restaurant_outlined,      'Mutfak',      [Color(0xFFF59E0B), Color(0xFFD97706)], Color(0xFF78350F), AppRoutes.kitchen),
    _Feature(Icons.child_care_outlined,      'Çocuk',       [Color(0xFF06B6D4), Color(0xFF0891B2)], Color(0xFF164E63), AppRoutes.childManagement),
    _Feature(Icons.eco_outlined,             'Gelişim',     [Color(0xFFF43F5E), Color(0xFFE11D48)], Color(0xFF881337), AppRoutes.childDevelopment),
    _Feature(Icons.monitor_heart_outlined,   'Sağlık',      [Color(0xFF14B8A6), Color(0xFF0D9488)], Color(0xFF134E4A), AppRoutes.familyHealth),
    _Feature(Icons.map_outlined,             'Konum',       [Color(0xFF3B82F6), Color(0xFF2563EB)], Color(0xFF1E3A8A), AppRoutes.familyMap),
    _Feature(Icons.emergency_outlined,       'Acil',        [Color(0xFFEF4444), Color(0xFFDC2626)], Color(0xFF7F1D1D), AppRoutes.emergency),
    _Feature(Icons.account_balance_wallet_outlined, 'Bütçe',[Color(0xFFA855F7), Color(0xFF9333EA)], Color(0xFF581C87), AppRoutes.budget),
    _Feature(Icons.subscriptions_outlined,   'Abonelik',    [Color(0xFF6366F1), Color(0xFF4F46E5)], Color(0xFF312E81), AppRoutes.subscriptions),
    _Feature(Icons.photo_library_outlined,   'Galeri',      [Color(0xFFEC4899), Color(0xFFDB2777)], Color(0xFF831843), AppRoutes.gallery),
    _Feature(Icons.menu_book_outlined,       'Eğitim',      [Color(0xFF8B5CF6), Color(0xFF7C3AED)], Color(0xFF4C1D95), AppRoutes.education),
    _Feature(Icons.psychology_outlined,      'AI',          [Color(0xFF4776E6), Color(0xFF2D3A8C)], Color(0xFF1E1B4B), AppRoutes.aiAssistant),
  ];

  @override
  void initState() {
    super.initState();
    LocationTrackingService.startTracking();

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
    setState(() => _notifIdx = (_notifIdx + 1) % _notifs.length);
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

  @override
  Widget build(BuildContext context) {
    final members = ref.watch(familyMembersProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: const Color(0xFF0A0A0F),
        body: RefreshIndicator(
          onRefresh: _refresh,
          color: const Color(0xFF6366F1),
          backgroundColor: const Color(0xFF1A1A2E),
          child: CustomScrollView(
            slivers: [
              // ── Ticker notification bar ──────────────────────────────────
              SliverToBoxAdapter(child: _NotifTicker(
                notifs: _notifs,
                currentIdx: _notifIdx,
                expanded: _notifExpanded,
                fade: _tickerFade,
                onTap: () => setState(() => _notifExpanded = !_notifExpanded),
                onDismiss: (i) => setState(() {}),
              )),

              // ── Cover + profiles ─────────────────────────────────────────
              SliverToBoxAdapter(child: _CoverSection(members: members)),

              // ── 3×4 Quick access grid ────────────────────────────────────
              SliverToBoxAdapter(child: _QuickGrid(features: _features)),

              // ── Stat strip ───────────────────────────────────────────────
              const SliverToBoxAdapter(child: _StatStrip()),

              // ── AI Suggestions ───────────────────────────────────────────
              const SliverToBoxAdapter(child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: AISuggestionsWidget(),
              )),

              // ── Content highlights ───────────────────────────────────────
              const SliverToBoxAdapter(child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: ContentHighlightsWidget(),
              )),

              const SliverToBoxAdapter(child: SizedBox(height: 32)),
            ],
          ),
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
                                      color: Color(0xFF4B5563),
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
class _CoverSection extends ConsumerWidget {
  final List<FamilyMember> members;
  const _CoverSection({required this.members});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final weatherAsync = ref.watch(weatherProvider);
    final familyName = HiveService.getSetting('family_name') ?? 'Ailem';
    final coverPhotoUrl = HiveService.getSetting('cover_photo_url');

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
            // cover photo or gradient
            coverPhotoUrl != null
                ? CachedNetworkImage(
                    imageUrl: coverPhotoUrl,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => _CoverGradient(),
                    errorWidget: (_, __, ___) => _CoverGradient(),
                  )
                : _CoverGradient(),

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
                      gradient: const LinearGradient(
                        colors: [Color(0xFF6366F1), Color(0xFFEC4899)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(9),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF6366F1).withAlpha(120),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: const Icon(Icons.home_outlined,
                        size: 16, color: Colors.white),
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
                    error: (_, __) => const SizedBox.shrink(),
                  ),
                  const SizedBox(width: 6),
                  // edit cover
                  GestureDetector(
                    onTap: () => _pickCoverPhoto(context),
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

  void _pickCoverPhoto(BuildContext context) {
    // TODO: image_picker → upload to Supabase storage → save URL
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Kapak fotoğrafı seçimi yakında'),
        backgroundColor: Color(0xFF1F2937),
      ),
    );
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

class _LocationRow extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locationModel = HiveService.getLocation();
    final city = locationModel != null && locationModel.city.isNotEmpty
        ? locationModel.city
        : 'Konum ayarlanmadı';
    final country = locationModel?.country ?? '';
    return Row(
      children: [
        const Icon(Icons.location_on_outlined,
            size: 11, color: Color(0xFF818CF8)),
        const SizedBox(width: 3),
        Text(
          country.isNotEmpty ? '$city, $country' : city,
          style: const TextStyle(fontSize: 10, color: Color(0xFF6B7280)),
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
                        errorWidget: (_, __, ___) => Center(
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
                'QUICK ACCESS',
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
            itemCount: features.length + 1, // +1 for "more" slot
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 14,
              crossAxisSpacing: 8,
              childAspectRatio: 0.85,
            ),
            itemBuilder: (context, i) {
              if (i == features.length) {
                return _MoreSlot();
              }
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
            Container(
              width: 62, height: 62,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: f.gradient,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(18),
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
                    height: 31,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(18)),
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
                    child: Icon(f.icon, size: 28, color: Colors.white,
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
            const SizedBox(height: 6),
            Text(
              f.label,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: Color(0xFF9CA3AF),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _MoreSlot extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 62, height: 62,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
                color: Colors.white.withAlpha(30),
                width: 1.5,
                strokeAlign: BorderSide.strokeAlignInside),
            color: Colors.white.withAlpha(8),
          ),
          child: const Center(
            child: Icon(Icons.more_horiz,
                size: 22, color: Color(0xFF4B5563)),
          ),
        ),
        const SizedBox(height: 6),
        const Text('More',
            style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: Color(0xFF374151))),
      ],
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
          _StatCard(value: '$taskCount', label: 'TASKS TODAY'),
          const SizedBox(width: 8),
          _StatCard(value: '🔥 7', label: 'DAY STREAK'),
          const SizedBox(width: 8),
          _StatCard(value: '3', label: 'ONLINE NOW',
              accent: const Color(0xFF22C55E)),
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
                  color: Color(0xFF4B5563),
                  letterSpacing: 0.4,
                )),
          ],
        ),
      ),
    );
  }
}
