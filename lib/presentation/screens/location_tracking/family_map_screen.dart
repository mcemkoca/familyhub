import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:familyhub/l10n/app_localizations.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../config/constants.dart';
import '../../../config/routes.dart';
import '../../../domain/entities.dart';
import '../../../services/koca_seed.dart';
import '../../../services/location_service.dart';
import '../../providers/app_providers.dart';
import '../../widgets/location_permission_prompt.dart';
import '../call/call_contact_list_screen.dart';
import '../../../core/app_logger.dart';

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

  // Gerçek harita + GPS.
  final MapController _mapController = MapController();
  LatLng? _myLocation;
  Timer? _locTimer;
  bool _locating = false;
  // GPS alınamazsa varsayılan merkez: Brüksel (Belçika pazarı).
  static const LatLng _defaultCenter = LatLng(50.8503, 4.3517);

  // Gerçek aile üyeleri build'de familyMembersProvider'dan doldurulur;
  // üye yoksa aşağıdaki demo kullanılır.
  List<_FamilyMember> _members = const [];

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
    // İlk konumu al, sonra 10 dakikada bir güncelle.
    _updateLocation();
    _locTimer = Timer.periodic(
        const Duration(minutes: 10), (_) => _updateLocation());
  }

  @override
  void dispose() {
    _locTimer?.cancel();
    _pulseController.dispose();
    _refreshController.dispose();
    super.dispose();
  }

  Future<void> _updateLocation() async {
    if (_locating) return;
    _locating = true;
    try {
      final pos = await LocationService.getCurrentPosition();
      if (pos != null && mounted) {
        final ll = LatLng(pos.latitude, pos.longitude);
        setState(() => _myLocation = ll);
        try {
          _mapController.move(ll, 14);
        } catch (e) {
          // Best-effort: harita henüz hazır değilse move atar; konum yine setState
          // ile işaretlendi, sonraki frame'de doğru görünür.
          AppLogger.logBestEffort(e, module: 'map', operation: 'moveCamera');
        }
      }
    } catch (_) {
      // Konum alınamadı — varsayılan merkez kullanılır.
    } finally {
      _locating = false;
    }
  }

  void _refresh() {
    HapticFeedback.mediumImpact();
    _refreshController.forward(from: 0);
    _updateLocation();
  }

  /// Seçili üyenin konumuna harita/navigasyon açar.
  Future<void> _openDirectionsTo(_FamilyMember m) async {
    LatLng? dest = m.liveLoc;
    if (dest == null) {
      final idx = _members.indexOf(m);
      if (idx >= 0) dest = _memberLatLng(idx, _members.length);
    }
    dest ??= _myLocation ?? _defaultCenter;
    final uri = Uri.parse(
        'https://www.google.com/maps/dir/?api=1&destination=${dest.latitude},${dest.longitude}');
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  /// Üyeleri gerçek koordinatlara eşler. Mevcut cihaz gerçek GPS'te; diğer
  /// üyeler (canlı konum boru hattı bağlanana kadar) merkez çevresine
  /// dağıtılır.
  LatLng _memberLatLng(int index, int total) {
    // Gerçek canlı konum varsa onu kullan.
    if (index >= 0 && index < _members.length) {
      final live = _members[index].liveLoc;
      if (live != null) return live;
    }
    final base = _myLocation ?? _defaultCenter;
    if (index == 0) return base;
    // Merkez etrafında küçük, belirlenimci bir dağılım.
    final angle = (index / math.max(total, 1)) * 2 * math.pi;
    const r = 0.004; // ~400m
    return LatLng(
      base.latitude + r * math.cos(angle),
      base.longitude + r * math.sin(angle),
    );
  }

  // Gerçek aile üyelerini haritaya eşler (konum boru hattı bağlanana kadar
  // konum metni dürüst, konumlar dağıtılmış olarak gösterilir).
  List<_FamilyMember> _mapReal(List<FamilyMember> real,
      [Map<String, LivePosition> live = const {}]) {
    if (real.isEmpty) return _kocaOrDemo();
    const palette = [
      Color(0xFFEC4899), Color(0xFF3B82F6), Color(0xFF10B981),
      Color(0xFFF97316), Color(0xFF8B5CF6), Color(0xFF14B8A6),
    ];
    final n = real.length;
    return List.generate(n, (i) {
      final m = real[i];
      final lp = live[m.id];
      // Üyeleri merkez etrafında dairesel dağıt (canlı konum yoksa).
      final angle = (i / n) * 2 * math.pi;
      final x = (0.5 + 0.22 * math.cos(angle)).clamp(0.1, 0.9);
      final y = (0.45 + 0.18 * math.sin(angle)).clamp(0.1, 0.85);
      final hasLive = lp != null;
      return _FamilyMember(
        id: m.id,
        liveLoc: hasLive ? LatLng(lp.lat, lp.lng) : null,
        name: m.name,
        role: _roleLabel(m.role),
        avatar: m.initial.isNotEmpty
            ? m.initial
            : (m.name.isNotEmpty ? m.name.substring(0, 1).toUpperCase() : '?'),
        color: palette[i % palette.length],
        location: hasLive ? 'Canlı konum' : 'Konum paylaşımı bekleniyor',
        lastSeen: hasLive
            ? _relTime(lp.at)
            : (m.isOnline
                ? 'Çevrimiçi'
                : (m.lastSeen != null ? _relTime(m.lastSeen!) : 'Bilinmiyor')),
        battery: lp?.battery ?? 0,
        status: hasLive
            ? LocationStatus.transit
            : (m.isOnline ? LocationStatus.home : LocationStatus.unknown),
        x: x.toDouble(),
        y: y.toDouble(),
        speed: (lp?.speed ?? 0).round(),
        activity: hasLive
            ? 'Canlı'
            : (m.isOnline ? 'Çevrimiçi' : 'Çevrimdışı'),
      );
    });
  }

  // Supabase üyeleri yokken yerel Koca Ailesi verisini haritaya yansıtır.
  List<_FamilyMember> _kocaOrDemo() {
    final koca = KocaSeed.localMembers();
    if (koca.isEmpty) return const [];
    const palette = [
      Color(0xFF3B82F6), Color(0xFFEC4899), Color(0xFF10B981),
      Color(0xFFF97316), Color(0xFF8B5CF6),
    ];
    final n = koca.length;
    return List.generate(n, (i) {
      final m = koca[i];
      final name = (m['name'] ?? '').toString();
      final online = m['online'] == true;
      final angle = (i / n) * 2 * math.pi;
      final x = (0.5 + 0.22 * math.cos(angle)).clamp(0.1, 0.9);
      final y = (0.45 + 0.18 * math.sin(angle)).clamp(0.1, 0.85);
      return _FamilyMember(
        name: name,
        role: (m['role'] ?? '').toString(),
        avatar: name.isNotEmpty ? name.substring(0, 1).toUpperCase() : '?',
        color: palette[i % palette.length],
        location: 'Konum paylaşımı bekleniyor',
        lastSeen: online ? 'Çevrimiçi' : 'Çevrimdışı',
        battery: 0,
        status: online ? LocationStatus.home : LocationStatus.unknown,
        x: x.toDouble(),
        y: y.toDouble(),
        speed: 0,
        activity: online ? 'Çevrimiçi' : 'Çevrimdışı',
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
    final live =
        ref.watch(familyLiveLocationsProvider).valueOrNull ?? const {};
    _members = _mapReal(ref.watch(familyMembersProvider), live);
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
                Text(AppLocalizations.of(context).fmTitle,
                    style: const TextStyle(
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
    final center = _myLocation ?? _defaultCenter;
    final total = _members.length;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: SizedBox(
          height: 260,
          child: Stack(
            children: [
              FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: center,
                  initialZoom: 14,
                  interactionOptions: const InteractionOptions(
                    flags: InteractiveFlag.pinchZoom |
                        InteractiveFlag.drag |
                        InteractiveFlag.doubleTapZoom,
                  ),
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.miro.familyhub',
                    maxZoom: 19,
                  ),
                  MarkerLayer(
                    markers: [
                      for (var i = 0; i < total; i++)
                        Marker(
                          point: _memberLatLng(i, total),
                          width: 46,
                          height: 46,
                          child: GestureDetector(
                            onTap: () =>
                                setState(() => _selectedMemberIndex = i),
                            child: _mapPin(_members[i],
                                i == _selectedMemberIndex),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
              // OSM atıf (lisans gereği).
              Positioned(
                right: 6,
                bottom: 4,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  color: Colors.black.withAlpha(120),
                  child: const Text('© OpenStreetMap',
                      style: TextStyle(color: Colors.white70, fontSize: 9)),
                ),
              ),
              // Konumuma git.
              Positioned(
                right: 10,
                top: 10,
                child: GestureDetector(
                  onTap: () {
                    final loc = _myLocation;
                    if (loc != null) {
                      _mapController.move(loc, 15);
                    } else {
                      _updateLocation();
                    }
                  },
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFF13131A),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF262631)),
                    ),
                    child: Icon(
                        _locating
                            ? Icons.hourglass_bottom
                            : Icons.my_location,
                        color: const Color(0xFF10B981),
                        size: 20),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _mapPin(_FamilyMember m, bool selected) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: selected ? 40 : 34,
          height: selected ? 40 : 34,
          decoration: BoxDecoration(
            color: m.color,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2.5),
            boxShadow: [
              BoxShadow(color: m.color.withAlpha(140), blurRadius: 8),
            ],
          ),
          alignment: Alignment.center,
          child: Text(m.avatar,
              style: TextStyle(fontSize: selected ? 18 : 15)),
        ),
      ],
    );
  }

  Widget _buildMemberScroller(bool isDark) {
    return SizedBox(
      height: 98,
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
    if (_members.isEmpty) {
      return const Padding(
        padding: EdgeInsets.fromLTRB(16, 12, 16, 0),
        child: Text(
          'Henüz takip edilen aile üyesi yok. Aile üyelerini ekleyip konum '
          'paylaşımını açtığınızda burada görünecekler.',
          style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 13.5),
        ),
      );
    }
    final idx = _selectedMemberIndex.clamp(0, _members.length - 1);
    final m = _members[idx];
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
                      Text(AppLocalizations.of(context).fmKmh,
                          style: const TextStyle(
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
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(
                          builder: (_) => const CallContactListScreen()),
                    ),
                    icon: const Icon(Icons.call, size: 16),
                    label: Text(AppLocalizations.of(context).fmCall),
                    style: OutlinedButton.styleFrom(
                        foregroundColor: m.color,
                        side: BorderSide(color: m.color)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => context.push(AppRoutes.chat),
                    icon: const Icon(Icons.message, size: 16),
                    label: Text(AppLocalizations.of(context).fmMessage),
                    style: OutlinedButton.styleFrom(
                        foregroundColor: m.color,
                        side: BorderSide(color: m.color)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _openDirectionsTo(m),
                    icon: const Icon(Icons.navigation, size: 16),
                    label: Text(AppLocalizations.of(context).fmRoute),
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
              Text(AppLocalizations.of(context).guvenliBolgeler,
                  style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFFE5E7EB))),
              const Spacer(),
              TextButton.icon(
                onPressed: () => context.push(AppRoutes.safeZones),
                icon: const Icon(Icons.add, size: 14),
                label: Text(AppLocalizations.of(context).crashAdd, style: const TextStyle(fontSize: 12)),
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
    // Gerçek konum-olay akışı bağlanana kadar boş görünür (demo yok).
    final events = <_LocationEvent>[];

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(AppLocalizations.of(context).fmTodayActivities,
              style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFFE5E7EB))),
          const SizedBox(height: 10),
          if (events.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0x1AFFFFFF),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(AppLocalizations.of(context).fmNoActivity,
                  style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 13.5)),
            )
          else
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
  final String? id;
  final LatLng? liveLoc; // gerçek canlı konum (varsa)
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
    this.id,
    this.liveLoc,
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
