import 'dart:async';
import 'package:flutter/material.dart';
import 'package:familyhub/l10n/app_localizations.dart';
import 'package:flutter/services.dart';
import '../../../config/constants.dart';
import '../../../domain/models/safety_models.dart';
import '../../../services/safety_service.dart';

class FamilySafetyStatus extends StatefulWidget {
  const FamilySafetyStatus({super.key});

  @override
  State<FamilySafetyStatus> createState() => _FamilySafetyStatusState();
}

class _FamilySafetyStatusState extends State<FamilySafetyStatus> {
  bool get isDark => Theme.of(context).brightness == Brightness.dark;

  List<MemberSafetyStatus> _members = [];
  StreamSubscription<dynamic>? _sub;

  @override
  void initState() {
    super.initState();
    SafetyService.startMonitoring();
    _sub = SafetyService.statusStream.listen((data) {
      if (mounted) setState(() => _members = data);
    });
  }

  @override
  void dispose() {
    SafetyService.stopMonitoring();
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Padding(
                padding: EdgeInsets.fromLTRB(4, 8, 4, 8),
                child: Text(
                  'AİLE GÜVENLİK DURUMU',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF9CA3AF),
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
            if (_members.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(right: 4),
                child: Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: Color(0xFF10B981),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Text(
                      'Canlı',
                      style: TextStyle(
                        fontSize: 11,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF13131A),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(20),
                blurRadius: 12,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              for (var i = 0; i < _members.length; i++) ...[
                _MemberCard(member: _members[i]),
                if (i < _members.length - 1)
                  Divider(
                    height: 1,
                    indent: 68,
                    color: isDark
                        ? const Color(0x1EFFFFFF).withAlpha(80)
                        : const Color(0x1EFFFFFF).withAlpha(100),
                  ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _MemberCard extends StatelessWidget {
  final MemberSafetyStatus member;

  const _MemberCard({required this.member});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => _showMemberDetail(context, member),
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            // Avatar with online dot
            Stack(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: member.color,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      member.initial,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: member.statusColor,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFF13131A),
                        width: 2,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 14),
            // Info column
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    member.name,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFE5E7EB),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    member.statusText,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                  // Battery / Signal chips
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 6,
                    children: [
                      _buildChip(
                        icon: _batteryIcon(member.batteryPercent),
                        label: '%${member.batteryPercent}',
                        color: member.batteryPercent < 20
                            ? const Color(0xFFF59E0B)
                            : (const Color(0xFF6B7280)),
                      ),
                      _buildChip(
                        icon: Icons.signal_cellular_alt,
                        label: member.signalStrength,
                        color: member.signalStrength == 'Zayıf'
                            ? const Color(0xFFF59E0B)
                            : (const Color(0xFF6B7280)),
                      ),
                      if (member.eta != null)
                        _buildChip(
                          icon: Icons.timer,
                          label: AppLocalizations.of(context).fssEta(member.eta ?? ''),
                          color: const Color(0xFF6366F1),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            // Right side status dot
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: member.statusColor,
                shape: BoxShape.circle,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withAlpha(15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: color),
          const SizedBox(width: 3),
          Text(
            label,
            style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  IconData _batteryIcon(int percent) {
    if (percent <= 10) return Icons.battery_alert;
    if (percent <= 30) return Icons.battery_2_bar;
    if (percent <= 60) return Icons.battery_4_bar;
    if (percent <= 80) return Icons.battery_5_bar;
    return Icons.battery_full;
  }

  void _showMemberDetail(BuildContext context, MemberSafetyStatus member) {
    HapticFeedback.lightImpact();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.85,
        expand: false,
        builder: (ctx, scrollController) {
          final isDark = Theme.of(ctx).brightness == Brightness.dark;
          return Container(
            decoration: const BoxDecoration(
              color: Color(0xFF0A0A0F),
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(24),
              ),
            ),
            child: ListView(
              controller: scrollController,
              padding: const EdgeInsets.all(20),
              children: [
                // Handle
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0x1EFFFFFF),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Header
                Row(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: member.color,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Center(
                        child: Text(
                          member.initial,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 22,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            member.name,
                            style: Theme.of(ctx).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: member.statusColor,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                member.statusText,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Color(0xFF6B7280),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                // Stats grid
                _buildStatsGrid(context, member, isDark),
                const SizedBox(height: 24),
                // Safe zones
                if (member.safeZones.isNotEmpty) ...[
                  Text(
                    'Güvenli Bölgeler',
                    style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 12),
                  ...member.safeZones.map((zone) {
                    final isDanger = zone.isDangerZone;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDanger
                            ? AppColors.error.withAlpha(30)
                            : (isDark
                                ? const Color(0xFF13131A)
                                : const Color(0xFF13131A)),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isDanger
                              ? AppColors.error.withAlpha(60)
                              : (isDark
                                  ? const Color(0x1EFFFFFF)
                                  : const Color(0x1EFFFFFF)),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isDanger ? Icons.warning : Icons.location_on,
                            color: isDanger ? AppColors.error : const Color(0xFF6366F1),
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  zone.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                                if (zone.address != null)
                                  Text(
                                    zone.address!,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF6B7280),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          Text(
                            '${zone.radiusMeters.toInt()}m',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF6B7280),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                  const SizedBox(height: 24),
                ],
                // Actions
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(ctx);
                          HapticFeedback.mediumImpact();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('${member.name} aranıyor...'),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                        icon: const Icon(Icons.call, size: 18),
                        label: Text(AppLocalizations.of(context).fmCall),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pop(ctx);
                          HapticFeedback.mediumImpact();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('${member.name} konumu açılıyor...'),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                        icon: const Icon(Icons.location_on, size: 18),
                        label: Text(AppLocalizations.of(context).fssMap),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                if (!member.isOnline)
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(ctx);
                        SafetyService.sendCheckInReminder(member.memberId);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('${member.name} için hatırlatıcı gönderildi'),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                      icon: const Icon(Icons.notifications_active, size: 18),
                      label: Text(AppLocalizations.of(context).fssSendReminder),
                    ),
                  ),
                const SizedBox(height: 20),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatsGrid(BuildContext context, MemberSafetyStatus member, bool isDark) {
    final stats = <_StatItem>[];

    if (member.lastLocation != null) {
      stats.add(_StatItem(
        icon: Icons.speed,
        label: AppLocalizations.of(context).fssSpeed,
        value: '${member.lastLocation!.speedKmh.toStringAsFixed(0)} km/h',
      ));
    }

    stats.add(_StatItem(
      icon: Icons.battery_full,
      label: AppLocalizations.of(context).fssBattery,
      value: '%${member.batteryPercent}',
      valueColor: member.batteryPercent < 20 ? const Color(0xFFF59E0B) : null,
    ));

    stats.add(_StatItem(
      icon: Icons.signal_cellular_alt,
      label: AppLocalizations.of(context).fssSignal,
      value: member.signalStrength,
      valueColor: member.signalStrength == 'Zayıf' ? const Color(0xFFF59E0B) : null,
    ));

    if (member.currentPlace != null) {
      stats.add(_StatItem(
        icon: Icons.place,
        label: AppLocalizations.of(context).chatLocation,
        value: member.currentPlace!,
      ));
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 2.2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: stats.length,
      itemBuilder: (context, index) {
        final s = stats[index];
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF13131A),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                children: [
                  Icon(s.icon, size: 14, color: const Color(0xFF6366F1)),
                  const SizedBox(width: 6),
                  Text(
                    s.label,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                s.value,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: s.valueColor ??
                      (const Color(0xFFE5E7EB)),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _StatItem {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  _StatItem({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });
}
