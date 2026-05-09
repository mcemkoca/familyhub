import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/supabase_client.dart';
import '../../../config/constants.dart';
import '../../../services/safe_arrival_service.dart';
import '../../../services/child_auth_service.dart';
import 'package:familyhub/l10n/app_localizations.dart';

class SafeArrivalScreen extends StatefulWidget {
  const SafeArrivalScreen({super.key});

  @override
  State<SafeArrivalScreen> createState() => _SafeArrivalScreenState();
}

class _SafeArrivalScreenState extends State<SafeArrivalScreen> {
  List<ArrivalMonitor> _active = [];
  List<ArrivalMonitor> _history = [];
  List<Map<String, dynamic>> _familyMembers = [];
  StreamSubscription<dynamic>? _activeSub;
  StreamSubscription<dynamic>? _histSub;

  @override
  void initState() {
    super.initState();
    SafeArrivalService.startMonitoring();
    _activeSub = SafeArrivalService.activeStream.listen((data) {
      if (mounted) setState(() => _active = data);
    });
    _histSub = SafeArrivalService.historyStream.listen((data) {
      if (mounted) setState(() => _history = data);
    });
    _loadFamilyMembers();
  }

  Future<void> _loadFamilyMembers() async {
    try {
      final client = SupabaseConfig.client;
      String? familyId;
      final user = client.auth.currentUser;
      if (user != null) {
        final profile = await client
            .from('profiles')
            .select('family_id')
            .eq('id', user.id)
            .maybeSingle();
        familyId = profile?['family_id'] as String?;
      }
      familyId ??= ChildAuthService.currentFamilyId;
      if (familyId == null) return;

      final profiles = await client
          .from('profiles')
          .select('id, display_name')
          .eq('family_id', familyId);
      final children = await client
          .from('child_accounts')
          .select('id, name')
          .eq('family_id', familyId);

      final members = <Map<String, dynamic>>[];
      for (final p in profiles) {
        members.add({'id': p['id'], 'name': p['display_name'] ?? 'Üye'});
      }
      for (final c in children) {
        members.add({'id': c['id'], 'name': c['name'] ?? 'Çocuk'});
      }
      if (mounted) setState(() => _familyMembers = members);
    } catch (e) { debugPrint('Safe arrival error: $e'); }
  }

  @override
  void dispose() {
    _activeSub?.cancel();
    _histSub?.cancel();
    super.dispose();
  }

  void _showNewMonitorDialog() {
    if (_familyMembers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).aileUyeleriYukleniyorLutfenBekleyin),
        ),
      );
      return;
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    String selectedMemberId = _familyMembers.first['id'] as String;
    String selectedMemberName = _familyMembers.first['name'] as String;
    final destCtrl = TextEditingController(text: 'İş');
    int duration = 30;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSt) => AlertDialog(
          backgroundColor: isDark ? AppColors.darkCard : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(AppLocalizations.of(context).yeniVarisPlanla),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Üye seçimi
              DropdownButtonFormField<String>(
                initialValue: selectedMemberId,
                decoration: const InputDecoration(labelText: 'Üye'),
                items: _familyMembers.map((m) {
                  return DropdownMenuItem(
                    value: m['id'] as String,
                    child: Text(m['name'] as String),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) {
                    final member = _familyMembers.firstWhere(
                      (m) => m['id'] == val,
                    );
                    setSt(() {
                      selectedMemberId = val;
                      selectedMemberName = member['name'] as String;
                    });
                  }
                },
              ),
              const SizedBox(height: 12),
              TextField(
                controller: destCtrl,
                decoration: const InputDecoration(labelText: 'Hedef'),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Text(AppLocalizations.of(context).sure),
                  Expanded(
                    child: Slider(
                      value: duration.toDouble(),
                      min: 5,
                      max: 120,
                      divisions: 23,
                      label: '$duration dk',
                      onChanged: (v) => setSt(() => duration = v.round()),
                    ),
                  ),
                  Text('$duration dk'),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(AppLocalizations.of(context).cancel),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(ctx);
                await SafeArrivalService.startMonitor(
                  memberId: selectedMemberId,
                  memberName: selectedMemberName,
                  destination: destCtrl.text.isEmpty ? 'İş' : destCtrl.text,
                  durationMinutes: duration,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.cobalt,
                foregroundColor: Colors.white,
              ),
              child: Text(AppLocalizations.of(context).baslat),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.cloudWhite,
      appBar: AppBar(
        title: Text(AppLocalizations.of(context).guvenliVaris),
        centerTitle: true,
        backgroundColor: isDark
            ? AppColors.darkBackground
            : AppColors.cloudWhite,
        foregroundColor: isDark ? AppColors.darkTextPrimary : AppColors.dark,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => SafeArrivalService.startMonitoring(),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          if (_active.isNotEmpty) ...[
            Text(
              'AKTİF MONİTÖRLER',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: isDark ? AppColors.slateLight : AppColors.slate,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 12),
            ..._active.map((m) {
              final etaLeft =
                  m.durationMinutes -
                  DateTime.now().difference(m.startedAt).inMinutes;
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.timer, color: AppColors.cobalt),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            '${m.memberName} → ${m.destination}',
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
                          ),
                        ),
                        Text(
                          m.status == 'delayed' ? 'Gecikme!' : 'Aktif',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: m.status == 'delayed'
                                ? AppColors.error
                                : AppColors.success,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    LinearProgressIndicator(
                      value: m.progress.clamp(0.0, 1.0),
                      backgroundColor: isDark
                          ? AppColors.darkBorder
                          : AppColors.border,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        m.status == 'delayed'
                            ? AppColors.error
                            : AppColors.cobalt,
                      ),
                      borderRadius: BorderRadius.circular(4),
                      minHeight: 8,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('%${(m.progress * 100).round()} tamamlandı'),
                        Text(
                          m.status == 'delayed'
                              ? '${m.delayMinutes} dk gecikme'
                              : '${etaLeft.clamp(0, 999)} dk kaldı',
                          style: TextStyle(
                            color: m.status == 'delayed'
                                ? AppColors.error
                                : AppColors.cobalt,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        TextButton.icon(
                          onPressed: () =>
                              SafeArrivalService.cancelMonitor(m.id),
                          icon: const Icon(Icons.cancel, size: 16),
                          label: Text(AppLocalizations.of(context).cancel),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 20),
          ],
          if (_history.isNotEmpty) ...[
            Text(
              'GEÇMİŞ',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: isDark ? AppColors.slateLight : AppColors.slate,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 12),
            ..._history
                .take(5)
                .map(
                  (m) => ListTile(
                    leading: Icon(
                      m.status == 'arrived' ? Icons.check_circle : Icons.cancel,
                      color: m.status == 'arrived'
                          ? AppColors.success
                          : AppColors.error,
                    ),
                    title: Text('${m.memberName} → ${m.destination}'),
                    subtitle: Text(
                      '${m.startedAt.day}/${m.startedAt.month} ${m.startedAt.hour.toString().padLeft(2, '0')}:${m.startedAt.minute.toString().padLeft(2, '0')}',
                    ),
                    trailing: Text(
                      m.status == 'arrived' ? 'Vardı' : 'İptal',
                      style: TextStyle(
                        color: m.status == 'arrived'
                            ? AppColors.success
                            : AppColors.error,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
            const SizedBox(height: 20),
          ],
          if (_active.isEmpty && _history.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 60),
                child: Column(
                  children: [
                    Icon(Icons.timer_outlined, size: 64, color: Colors.grey),
                    SizedBox(height: 16),
                    Text(
                      'Henüz varış planı yok',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Yeni bir varış planlamak için butona bas',
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),
          ElevatedButton.icon(
            onPressed: () {
              HapticFeedback.mediumImpact();
              _showNewMonitorDialog();
            },
            icon: const Icon(Icons.add),
            label: Text(AppLocalizations.of(context).yeniVarisPlanla),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.cobalt,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
