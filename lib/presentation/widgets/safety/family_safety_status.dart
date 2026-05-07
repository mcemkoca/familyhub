import 'dart:async';
import 'package:flutter/material.dart';
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
  List<MemberSafetyStatus> _members = [];
  StreamSubscription? _sub;

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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(4, 8, 4, 8),
                child: Text(
                  'AİLE GÜVENLİK DURUMU',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: isDark ? AppColors.slateLight : AppColors.slate,
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
                        color: AppColors.success,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Canlı',
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.slate,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
        Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCard : Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: isDark
                    ? Colors.black.withAlpha(20)
                    : Colors.black.withAlpha(5),
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
                        ? AppColors.darkBorder.withAlpha(80)
                        : AppColors.border.withAlpha(100),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
                        color: isDark ? AppColors.darkCard : Colors.white,
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
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? AppColors.darkTextPrimary
                          : AppColors.dark,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    member.statusText,
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.slate,
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
                            ? AppColors.warning
                            : (isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.slate),
                      ),
                      _buildChip(
                        icon: Icons.signal_cellular_alt,
                        label: member.signalStrength,
                        color: member.signalStrength == 'Zayıf'
                            ? AppColors.warning
                            : (isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.slate),
                      ),
                      if (member.eta != null)
                        _buildChip(
                          icon: Icons.timer,
                          label: 'ETA: ${member.eta}',
                          color: AppColors.cobalt,
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
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
          return Container(
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkBackground : AppColors.background,
              borderRadius: const BorderRadius.vertical(
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
                      color: isDark ? AppColors.darkBorder : AppColors.border,
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
                                style: TextStyle(
                                  fontSize: 14,
                                  color: isDark
                                      ? AppColors.darkTextSecondary
                                      : AppColors.slate,
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
                _buildStatsGrid(member, isDark),
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
                            ? AppColors.error.withAlpha(isDark ? 30 : 15)
                            : (isDark
                                ? AppColors.darkCard
                                : AppColors.card),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isDanger
                              ? AppColors.error.withAlpha(60)
                              : (isDark
                                  ? AppColors.darkBorder
                                  : AppColors.border),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isDanger ? Icons.warning : Icons.location_on,
                            color: isDanger ? AppColors.error : AppColors.cobalt,
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
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isDark
                                          ? AppColors.darkTextSecondary
                                          : AppColors.slate,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          Text(
                            '${zone.radiusMeters.toInt()}m',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark
                                  ? AppColors.darkTextSecondary
                                  : AppColors.gray,
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
                        label: const Text('Ara'),
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
                        label: const Text('Harita'),
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
                      label: const Text('Hatırlatıcı Gönder'),
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

  Widget _buildStatsGrid(MemberSafetyStatus member, bool isDark) {
    final stats = <_StatItem>[];

    if (member.lastLocation != null) {
      stats.add(_StatItem(
        icon: Icons.speed,
        label: 'Hız',
        value: '${member.lastLocation!.speedKmh.toStringAsFixed(0)} km/h',
      ));
    }

    stats.add(_StatItem(
      icon: Icons.battery_full,
      label: 'Batarya',
      value: '%${member.batteryPercent}',
      valueColor: member.batteryPercent < 20 ? AppColors.warning : null,
    ));

    stats.add(_StatItem(
      icon: Icons.signal_cellular_alt,
      label: 'Sinyal',
      value: member.signalStrength,
      valueColor: member.signalStrength == 'Zayıf' ? AppColors.warning : null,
    ));

    if (member.currentPlace != null) {
      stats.add(_StatItem(
        icon: Icons.place,
        label: 'Konum',
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
            color: isDark ? AppColors.darkCard : AppColors.card,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                children: [
                  Icon(s.icon, size: 14, color: AppColors.cobalt),
                  const SizedBox(width: 6),
                  Text(
                    s.label,
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.slate,
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
                      (isDark
                          ? AppColors.darkTextPrimary
                          : AppColors.dark),
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
