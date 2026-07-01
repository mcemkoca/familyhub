import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../config/constants.dart';

class FamilyMapScreen extends StatefulWidget {
  const FamilyMapScreen({super.key});

  @override
  State<FamilyMapScreen> createState() => _FamilyMapScreenState();
}

class _FamilyMapScreenState extends State<FamilyMapScreen>
    with TickerProviderStateMixin {
  int _selectedMemberIndex = 0;
  late AnimationController _pulseController;
  late AnimationController _refreshController;

  // Demo aile üyeleri — gerçek implementasyonda Supabase'den gelir
  final _members = [
    _FamilyMember(
      name: 'Anne',
      role: 'Ebeveyn',
      avatar: '👩',
      color: const Color(0xFFEC4899),
      location: 'Kadıköy, İstanbul',
      lastSeen: 'Şimdi',
      battery: 72,
      status: LocationStatus.home,
      x: 0.48,
      y: 0.45,
      speed: 0,
      activity: 'Evde',
    ),
    _FamilyMember(
      name: 'Baba',
      role: 'Ebeveyn',
      avatar: '👨',
      color: const Color(0xFF3B82F6),
      location: 'Şişli, İstanbul',
      lastSeen: '3 dk önce',
      battery: 45,
      status: LocationStatus.transit,
      x: 0.3,
      y: 0.3,
      speed: 42,
      activity: 'Araçta gidiyor',
    ),
    _FamilyMember(
      name: 'Elif',
      role: 'Çocuk • 12 yaş',
      avatar: '👧',
      color: const Color(0xFF10B981),
      location: 'Beşiktaş İlkokulu',
      lastSeen: '1 dk önce',
      battery: 88,
      status: LocationStatus.school,
      x: 0.62,
      y: 0.28,
      speed: 0,
      activity: 'Okulda',
    ),
    _FamilyMember(
      name: 'Can',
      role: 'Çocuk • 8 yaş',
      avatar: '👦',
      color: const Color(0xFFF97316),
      location: 'Güvenli Bölge',
      lastSeen: '5 dk önce',
      battery: 30,
      status: LocationStatus.safeZone,
      x: 0.55,
      y: 0.6,
      speed: 3,
      activity: 'Parkta yürüyor',
    ),
  ];

  final _safeZones = [
    _SafeZone(name: 'Ev', x: 0.48, y: 0.45, radius: 0.06,
        color: const Color(0xFF10B981)),
    _SafeZone(name: 'Okul', x: 0.62, y: 0.28, radius: 0.05,
        color: const Color(0xFF3B82F6)),
    _SafeZone(name: 'Park', x: 0.55, y: 0.6, radius: 0.04,
        color: const Color(0xFFF97316)),
  ];

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
    _refreshController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _refreshController.dispose();
    super.dispose();
  }

  void _refresh() {
    HapticFeedback.mediumImpact();
    _refreshController.forward(from: 0);
    // In real app: trigger location update
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor:
          isDark ? AppColors.darkBackground : AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(isDark),
            Expanded(
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(child: _buildMap(isDark)),
                  SliverToBoxAdapter(
                      child: _buildMemberScroller(isDark)),
                  SliverToBoxAdapter(
                      child: _buildSelectedDetail(isDark)),
                  SliverToBoxAdapter(
                      child: _buildSafeZonesList(isDark)),
                  SliverToBoxAdapter(
                      child: _buildActivityFeed(isDark)),
                  const SliverToBoxAdapter(
                      child: SizedBox(height: 24)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    final homeCount = _members.where((m) => m.status == LocationStatus.home).length;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.fromLTRB(18, 14, 14, 18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF43E97B), Color(0xFF38F9D7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF43E97B).withAlpha(100),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(40),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withAlpha(60)),
            ),
            child: const Center(child: Text('🗺️', style: TextStyle(fontSize: 26))),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Aile Haritası',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 20,
                      color: Colors.white,
                      letterSpacing: -0.5,
                    )),
                Text(
                    '${_members.length} üye takipte · $homeCount evde',
                    style: const TextStyle(
                        fontSize: 12,
                        color: Colors.white70,
                        fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          RotationTransition(
            turns: _refreshController,
            child: GestureDetector(
              onTap: _refresh,
              child: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(40),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withAlpha(60)),
                ),
                child: const Icon(Icons.refresh, color: Colors.white, size: 20),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMap(bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Container(
        height: 260,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            colors: isDark
                ? [const Color(0xFF0F2027), const Color(0xFF203A43)]
                : [const Color(0xFFB7E8D0), const Color(0xFFD1EAF7)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withAlpha(isDark ? 40 : 10),
                blurRadius: 16,
                offset: const Offset(0, 4))
          ],
        ),
        child: Stack(
          children: [
            // Grid lines (map feel)
            CustomPaint(
              size: const Size(double.infinity, 260),
              painter: _MapGridPainter(isDark: isDark),
            ),
            // Safe zones
            ..._safeZones.map((z) => _buildSafeZoneCircle(z)),
            // Member markers
            ..._members.asMap().entries.map((e) =>
                _buildMemberMarker(e.value, e.key == _selectedMemberIndex)),
            // Map legend
            Positioned(
              right: 12,
              top: 12,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _MapLegendItem('Ev', const Color(0xFF10B981)),
                  _MapLegendItem('Okul', const Color(0xFF3B82F6)),
                  _MapLegendItem('Park', const Color(0xFFF97316)),
                ],
              ),
            ),
            // Scale indicator
            Positioned(
              left: 12,
              bottom: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withAlpha(100),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text('İstanbul',
                    style: TextStyle(
                        color: Colors.white70, fontSize: 11)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSafeZoneCircle(_SafeZone zone) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final h = 260.0;
        return Positioned(
          left: zone.x * w - zone.radius * w,
          top: zone.y * h - zone.radius * w,
          child: Container(
            width: zone.radius * w * 2,
            height: zone.radius * w * 2,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: zone.color.withAlpha(30),
              border: Border.all(
                  color: zone.color.withAlpha(120), width: 1.5),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMemberMarker(_FamilyMember member, bool selected) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final h = 260.0;
        return Positioned(
          left: member.x * w - 18,
          top: member.y * h - 18,
          child: GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() => _selectedMemberIndex =
                  _members.indexOf(member));
            },
            child: AnimatedBuilder(
              animation: _pulseController,
              builder: (_, child) {
                final pulse = selected
                    ? math.sin(_pulseController.value * math.pi * 2) *
                            0.3 +
                        0.7
                    : 1.0;
                return Transform.scale(
                  scale: selected ? (1.0 + pulse * 0.15) : 1.0,
                  child: child,
                );
              },
              child: Stack(
                alignment: Alignment.center,
                children: [
                  if (selected)
                    AnimatedBuilder(
                      animation: _pulseController,
                      builder: (_, _) {
                        final r =
                            _pulseController.value * 24 + 18;
                        return Container(
                          width: r,
                          height: r,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: member.color.withAlpha(
                                (60 * (1 - _pulseController.value))
                                    .toInt()),
                          ),
                        );
                      },
                    ),
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: member.color,
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: Colors.white,
                          width: selected ? 3 : 2),
                      boxShadow: [
                        BoxShadow(
                            color: member.color.withAlpha(100),
                            blurRadius: selected ? 12 : 4)
                      ],
                    ),
                    child: Center(
                      child: Text(member.avatar,
                          style: const TextStyle(fontSize: 16)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMemberScroller(bool isDark) {
    return SizedBox(
      height: 90,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
        itemCount: _members.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (_, i) {
          final m = _members[i];
          final selected = i == _selectedMemberIndex;
          return GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() => _selectedMemberIndex = i);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: selected
                    ? m.color.withAlpha(30)
                    : (isDark ? AppColors.darkCard : Colors.white),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                    color: selected ? m.color : AppColors.border,
                    width: selected ? 2 : 1),
              ),
              child: Row(
                children: [
                  Text(m.avatar,
                      style: const TextStyle(fontSize: 22)),
                  const SizedBox(width: 8),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(m.name,
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: selected
                                  ? m.color
                                  : (isDark
                                      ? AppColors.darkTextPrimary
                                      : AppColors.dark))),
                      Text(m.lastSeen,
                          style: const TextStyle(
                              fontSize: 11, color: AppColors.slate)),
                      const SizedBox(height: 3),
                      _BatteryBar(battery: m.battery, color: m.color),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSelectedDetail(bool isDark) {
    final m = _members[_selectedMemberIndex];
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
              colors: [m.color.withAlpha(30), m.color.withAlpha(10)]),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: m.color.withAlpha(60)),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Text(m.avatar, style: const TextStyle(fontSize: 30)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(m.name,
                              style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: isDark
                                      ? AppColors.darkTextPrimary
                                      : AppColors.dark)),
                          const SizedBox(width: 8),
                          _StatusBadge(m.status),
                        ],
                      ),
                      Text(m.role,
                          style: const TextStyle(
                              fontSize: 12, color: AppColors.slate)),
                    ],
                  ),
                ),
                if (m.speed > 0)
                  Column(
                    children: [
                      Text('${m.speed}',
                          style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: m.color)),
                      const Text('km/h',
                          style: TextStyle(
                              fontSize: 10, color: AppColors.slate)),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                _DetailTile(
                    Icons.location_on, m.location, 'Konum', m.color),
                const SizedBox(width: 8),
                _DetailTile(Icons.directions_run, m.activity,
                    'Aktivite', m.color),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _DetailTile(Icons.battery_charging_full,
                    '${m.battery}%', 'Batarya', m.color),
                const SizedBox(width: 8),
                _DetailTile(Icons.access_time, m.lastSeen,
                    'Son Güncelleme', m.color),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.call, size: 16),
                    label: const Text('Ara'),
                    style: OutlinedButton.styleFrom(
                        foregroundColor: m.color,
                        side: BorderSide(color: m.color)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.message, size: 16),
                    label: const Text('Mesaj'),
                    style: OutlinedButton.styleFrom(
                        foregroundColor: m.color,
                        side: BorderSide(color: m.color)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.navigation, size: 16),
                    label: const Text('Yol'),
                    style: OutlinedButton.styleFrom(
                        foregroundColor: m.color,
                        side: BorderSide(color: m.color)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSafeZonesList(bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Güvenli Bölgeler',
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: isDark
                          ? AppColors.darkTextPrimary
                          : AppColors.dark)),
              const Spacer(),
              TextButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.add, size: 14),
                label: const Text('Ekle', style: TextStyle(fontSize: 12)),
                style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF10B981)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: _safeZones.map((z) {
              final insideCount = _members
                  .where((m) => _isInsideZone(m, z))
                  .length;
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                      right: z == _safeZones.last ? 0 : 8),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkCard : Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                          color: z.color.withAlpha(60)),
                    ),
                    child: Column(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                              color: z.color.withAlpha(25),
                              shape: BoxShape.circle),
                          child: Icon(
                              z.name == 'Ev'
                                  ? Icons.home
                                  : z.name == 'Okul'
                                      ? Icons.school
                                      : Icons.park,
                              color: z.color,
                              size: 18),
                        ),
                        const SizedBox(height: 6),
                        Text(z.name,
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: isDark
                                    ? AppColors.darkTextPrimary
                                    : AppColors.dark)),
                        Text('$insideCount içeride',
                            style: const TextStyle(
                                fontSize: 10, color: AppColors.slate)),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  bool _isInsideZone(_FamilyMember m, _SafeZone z) {
    final dx = m.x - z.x;
    final dy = m.y - z.y;
    return math.sqrt(dx * dx + dy * dy) < z.radius;
  }

  Widget _buildActivityFeed(bool isDark) {
    final events = [
      _LocationEvent('Anne', '👩', const Color(0xFFEC4899),
          'Eve geldi', '14:32', Icons.home),
      _LocationEvent('Baba', '👨', const Color(0xFF3B82F6),
          'Evden çıktı', '08:15', Icons.directions_car),
      _LocationEvent('Elif', '👧', const Color(0xFF10B981),
          'Okula ulaştı', '08:42', Icons.school),
      _LocationEvent('Can', '👦', const Color(0xFFF97316),
          'Güvenli bölgeye girdi', '15:10', Icons.check_circle),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Bugünkü Aktiviteler',
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: isDark
                      ? AppColors.darkTextPrimary
                      : AppColors.dark)),
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCard : Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                    color:
                        Colors.black.withAlpha(isDark ? 20 : 6),
                    blurRadius: 8,
                    offset: const Offset(0, 2))
              ],
            ),
            child: Column(
              children: events.asMap().entries.map((e) {
                final ev = e.value;
                final isLast = e.key == events.length - 1;
                return Column(
                  children: [
                    ListTile(
                      leading: Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: ev.color.withAlpha(25),
                          shape: BoxShape.circle,
                        ),
                        child:
                            Icon(ev.icon, color: ev.color, size: 18),
                      ),
                      title: RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                                text: ev.memberName,
                                style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: isDark
                                        ? AppColors.darkTextPrimary
                                        : AppColors.dark,
                                    fontSize: 13)),
                            TextSpan(
                                text: ' ${ev.action}',
                                style: TextStyle(
                                    color: isDark
                                        ? AppColors.darkTextSecondary
                                        : AppColors.slate,
                                    fontSize: 13)),
                          ],
                        ),
                      ),
                      trailing: Text(ev.time,
                          style: const TextStyle(
                              fontSize: 11, color: AppColors.slate)),
                      dense: true,
                    ),
                    if (!isLast)
                      Divider(
                          height: 1,
                          indent: 16,
                          endIndent: 16,
                          color: isDark
                              ? AppColors.darkBorder
                              : AppColors.border),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Data models ─────────────────────────────────────────────────────────────

enum LocationStatus { home, school, transit, safeZone, unknown }

class _FamilyMember {
  final String name, role, avatar, location, lastSeen, activity;
  final Color color;
  final int battery, speed;
  final LocationStatus status;
  final double x, y;
  const _FamilyMember({
    required this.name,
    required this.role,
    required this.avatar,
    required this.color,
    required this.location,
    required this.lastSeen,
    required this.battery,
    required this.status,
    required this.x,
    required this.y,
    required this.speed,
    required this.activity,
  });
}

class _SafeZone {
  final String name;
  final double x, y, radius;
  final Color color;
  const _SafeZone(
      {required this.name,
      required this.x,
      required this.y,
      required this.radius,
      required this.color});
}

class _LocationEvent {
  final String memberName, avatar, action, time;
  final Color color;
  final IconData icon;
  const _LocationEvent(this.memberName, this.avatar, this.color,
      this.action, this.time, this.icon);
}

// ─── Small widgets ────────────────────────────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  final LocationStatus status;
  const _StatusBadge(this.status);

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      LocationStatus.home => ('Evde', const Color(0xFF10B981)),
      LocationStatus.school => ('Okulda', const Color(0xFF3B82F6)),
      LocationStatus.transit => ('Yolda', const Color(0xFFF97316)),
      LocationStatus.safeZone => ('Güvenli', const Color(0xFF10B981)),
      LocationStatus.unknown => ('Bilinmiyor', AppColors.slate),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
          color: color.withAlpha(25),
          borderRadius: BorderRadius.circular(6)),
      child: Text(label,
          style: TextStyle(
              fontSize: 10, fontWeight: FontWeight.w700, color: color)),
    );
  }
}

class _DetailTile extends StatelessWidget {
  final IconData icon;
  final String value, label;
  final Color color;
  const _DetailTile(this.icon, this.value, this.label, this.color);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Expanded(
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkBackground : Colors.white,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 6),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: isDark
                              ? AppColors.darkTextPrimary
                              : AppColors.dark)),
                  Text(label,
                      style: const TextStyle(
                          fontSize: 10, color: AppColors.slate)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BatteryBar extends StatelessWidget {
  final int battery;
  final Color color;
  const _BatteryBar({required this.battery, required this.color});

  @override
  Widget build(BuildContext context) {
    final barColor = battery < 20
        ? AppColors.error
        : battery < 40
            ? AppColors.warning
            : color;
    return SizedBox(
      width: 60,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: battery / 100,
              backgroundColor: barColor.withAlpha(30),
              valueColor: AlwaysStoppedAnimation(barColor),
              minHeight: 5,
            ),
          ),
          const SizedBox(height: 1),
          Text('$battery%',
              style: TextStyle(
                  fontSize: 9,
                  color: barColor,
                  fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _MapLegendItem extends StatelessWidget {
  final String label;
  final Color color;
  const _MapLegendItem(this.label, this.color);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
                width: 8,
                height: 8,
                decoration:
                    BoxDecoration(color: color, shape: BoxShape.circle)),
            const SizedBox(width: 4),
            Text(label,
                style: const TextStyle(
                    color: Colors.white70, fontSize: 10)),
          ],
        ),
      );
}

class _MapGridPainter extends CustomPainter {
  final bool isDark;
  const _MapGridPainter({required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = isDark
          ? Colors.white.withAlpha(8)
          : Colors.black.withAlpha(8)
      ..strokeWidth = 1;

    for (double x = 0; x < size.width; x += size.width / 8) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += size.height / 5) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }

    // Draw some "road" lines
    final roadPaint = Paint()
      ..color = isDark
          ? Colors.white.withAlpha(20)
          : Colors.black.withAlpha(12)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(
        Offset(0, size.height * 0.4),
        Offset(size.width, size.height * 0.4),
        roadPaint);
    canvas.drawLine(
        Offset(size.width * 0.5, 0),
        Offset(size.width * 0.45, size.height),
        roadPaint);
    canvas.drawLine(
        Offset(size.width * 0.2, 0),
        Offset(size.width * 0.25, size.height),
        roadPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
