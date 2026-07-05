import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../config/constants.dart';
import '../../../domain/entities.dart';
import '../../providers/app_providers.dart';
import '../../widgets/location_permission_prompt.dart';

class FamilyMapScreen extends ConsumerStatefulWidget {
  const FamilyMapScreen({super.key});

  @override
  ConsumerState<FamilyMapScreen> createState() => _FamilyMapScreenState();
}

class _FamilyMapScreenState extends ConsumerState<FamilyMapScreen>
    with TickerProviderStateMixin {
  bool get isDark => Theme.of(context).brightness == Brightness.dark;

  int _selectedMemberIndex = 0;
  late AnimationController _pulseController;
  late AnimationController _refreshController;

  // Gerçek aile üyeleri build'de familyMembersProvider'dan doldurulur;
  // üye yoksa aşağıdaki demo kullanılır.
  List<_FamilyMember> _members = _demoMembers;

  static const _demoMembers = <_FamilyMember>[
    _FamilyMember(
      name: 'Anne',
      role: 'Ebeveyn',
      avatar: '👩',
      color: Color(0xFFEC4899),
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
      color: Color(0xFF3B82F6),
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
      role: 'Çocuk ”¢ 12 yaş',
      avatar: '👧',
      color: Color(0xFF10B981),
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
      role: 'Çocuk ”¢ 8 yaş',
      avatar: '👦',
      color: Color(0xFFF97316),
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
    const _SafeZone(name: 'Ev', x: 0.48, y: 0.45, radius: 0.06,
        color: Color(0xFF10B981)),
    const _SafeZone(name: 'Okul', x: 0.62, y: 0.28, radius: 0.05,
        color: Color(0xFF3B82F6)),
    const _SafeZone(name: 'Park', x: 0.55, y: 0.6, radius: 0.04,
        color: Color(0xFFF97316)),
  ];

  @override
  void initState() {
    super.initState();
    // İlk kez aile haritasına girildiğinde konum izni promptunu göster.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) LocationPermissionPrompt.maybeShow(context);
    });
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

  // Gerçek aile üyelerini haritaya eşler (konum boru hattı bağlanana kadar
  // konum metni dürüst, konumlar dağıtılmış olarak gösterilir).
  List<_FamilyMember> _mapReal(List<FamilyMember> real) {
    if (real.isEmpty) return _demoMembers;
    const palette = [
      Color(0xFFEC4899), Color(0xFF3B82F6), Color(0xFF10B981),
      Color(0xFFF97316), Color(0xFF8B5CF6), Color(0xFF14B8A6),
    ];
    final n = real.length;
    return List.generate(n, (i) {
      final m = real[i];
      // Üyeleri merkez etrafında dairesel dağıt.
      final angle = (i / n) * 2 * math.pi;
      final x = (0.5 + 0.22 * math.cos(angle)).clamp(0.1, 0.9);
      final y = (0.45 + 0.18 * math.sin(angle)).clamp(0.1, 0.85);
      return _FamilyMember(
        name: m.name,
        role: _roleLabel(m.role),
        avatar: m.initial.isNotEmpty
            ? m.initial
            : (m.name.isNotEmpty ? m.name.substring(0, 1).toUpperCase() : '?'),
        color: palette[i % palette.length],
        location: 'Konum paylaşımı bekleniyor',
        lastSeen: m.isOnline
            ? 'Çevrimiçi'
            : (m.lastSeen != null ? _relTime(m.lastSeen!) : 'Bilinmiyor'),
        battery: 0,
        status: m.isOnline ? LocationStatus.home : LocationStatus.unknown,
        x: x.toDouble(),
        y: y.toDouble(),
        speed: 0,
        activity: m.isOnline ? 'Çevrimiçi' : 'Çevrimdışı',
      );
    });
  }

  String _roleLabel(MemberRole r) {
    switch (r) {
      case MemberRole.admin:
      case MemberRole.parent:
        return 'Ebeveyn';
      case MemberRole.teen:
        return 'Genç';
      case MemberRole.child:
        return 'Çocuk';
      case MemberRole.baby:
        return 'Bebek';
      case MemberRole.elder:
        return 'Büyük';
      case MemberRole.guest:
        return 'Misafir';
    }
  }

  String _relTime(DateTime t) {
    final d = DateTime.now().difference(t);
    if (d.inMinutes < 1) return 'Şimdi';
    if (d.inMinutes < 60) return '${d.inMinutes} dk önce';
    if (d.inHours < 24) return '${d.inHours} saat önce';
    return '${d.inDays} gün önce';
  }

  @override
  Widget build(BuildContext context) {
    _members = _mapReal(ref.watch(familyMembersProvider));
    if (_selectedMemberIndex >= _members.length) _selectedMemberIndex = 0;
    return Scaffold(
      backgroundColor:
          const Color(0xFF0A0A0F),
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
          colors: [Color(0xFF0A1F12), Color(0xFF0D2A1A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: const Color(0x1EFFFFFF), width: 0.5),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF10B981).withAlpha(40),
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
            child: const Center(child: Text('🗺️', style: TextStyle(fontSize: 26))),
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
                    '${_members.length} üye takipte Â· $homeCount evde',
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
                color: Colors.black.withAlpha(40),
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
            const Positioned(
              right: 12,
              top: 12,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _MapLegendItem('Ev', Color(0xFF10B981)),
                  _MapLegendItem('Okul', Color(0xFF3B82F6)),
                  _MapLegendItem('Park', Color(0xFFF97316)),
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
                    : const Color(0x1AFFFFFF),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                    color: selected ? m.color : const Color(0x1EFFFFFF),
                    width: selected ? 2 : 0.5),
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
                                  : const Color(0xFFE5E7EB))),
                      Text(m.lastSeen,
                          style: const TextStyle(
                              fontSize: 11, color: Color(0xFF6B7280))),
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
                              style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFFE5E7EB))),
                          const SizedBox(width: 8),
                          _StatusBadge(m.status),
                        ],
                      ),
                      Text(m.role,
                          style: const TextStyle(
                              fontSize: 12, color: Color(0xFF6B7280))),
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
                              fontSize: 10, color: Color(0xFF6B7280))),
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
              const Text('Güvenli Bölgeler',
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFFE5E7EB))),
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
                      color: const Color(0x1AFFFFFF),
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
                            style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFFE5E7EB))),
                        Text('$insideCount içeride',
                            style: const TextStyle(
                                fontSize: 10, color: Color(0xFF6B7280))),
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
      const _LocationEvent('Anne', '👩', Color(0xFFEC4899),
          'Eve geldi', '14:32', Icons.home),
      const _LocationEvent('Baba', '👨', Color(0xFF3B82F6),
          'Evden çıktı', '08:15', Icons.directions_car),
      const _LocationEvent('Elif', '👧', Color(0xFF10B981),
          'Okula ulaştı', '08:42', Icons.school),
      const _LocationEvent('Can', '👦', Color(0xFFF97316),
          'Güvenli bölgeye girdi', '15:10', Icons.check_circle),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Bugünkü Aktiviteler',
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFFE5E7EB))),
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(
              color: const Color(0x1AFFFFFF),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                    color:
                        Colors.black.withAlpha(20),
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
                                style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFFE5E7EB),
                                    fontSize: 13)),
                            TextSpan(
                                text: ' ${ev.action}',
                                style: const TextStyle(
                                    color: Color(0xFF6B7280),
                                    fontSize: 13)),
                          ],
                        ),
                      ),
                      trailing: Text(ev.time,
                          style: const TextStyle(
                              fontSize: 11, color: Color(0xFF6B7280))),
                      dense: true,
                    ),
                    if (!isLast)
                      Divider(
                          height: 1,
                          indent: 16,
                          endIndent: 16,
                          color: isDark
                              ? const Color(0x1EFFFFFF)
                              : const Color(0x1EFFFFFF)),
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

// â”€â”€â”€ Data models â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

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

// â”€â”€â”€ Small widgets â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

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
      LocationStatus.unknown => ('Bilinmiyor', const Color(0xFF6B7280)),
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
    return Expanded(
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF0A0A0F),
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
                      style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFFE5E7EB))),
                  Text(label,
                      style: const TextStyle(
                          fontSize: 10, color: Color(0xFF6B7280))),
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
            ? const Color(0xFFF59E0B)
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

