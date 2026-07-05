import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../config/constants.dart';
import '../../../services/auth_service.dart';
import '../../../core/supabase_client.dart';
import '../../../repositories/child_account_repository.dart';
import '../../widgets/settings/screen_header.dart';
import '../../widgets/settings/settings_section.dart';
import 'package:go_router/go_router.dart';
import 'package:familyhub/l10n/app_localizations.dart';

class ScreenTimeSettingsScreen extends ConsumerStatefulWidget {
  const ScreenTimeSettingsScreen({super.key});

  @override
  ConsumerState<ScreenTimeSettingsScreen> createState() =>
      _ScreenTimeSettingsScreenState();
}

class _ScreenTimeSettingsScreenState
    extends ConsumerState<ScreenTimeSettingsScreen> {
  List<Map<String, dynamic>> _children = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadChildren();
  }

  Future<void> _loadChildren() async {
    try {
      final userId = AuthService.currentUserId;
      if (userId == null) return;

      final client = SupabaseConfig.safeClient;
      if (client == null) return;

      // Get family_id from profile
      final profile = await client
          .from('profiles')
          .select('family_id')
          .eq('id', userId)
          .maybeSingle();

      final familyId = profile?['family_id'] as String?;
      if (familyId == null) {
        setState(() => _isLoading = false);
        return;
      }

      final response = await client
          .from('child_accounts')
          .select('*')
          .eq('family_id', familyId)
          .order('name');

      setState(() {
        _children = (response as List).cast<Map<String, dynamic>>();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updateScreenTime(String childId, int? minutes) async {
    try {
      final client = SupabaseConfig.safeClient;
      if (client == null) return;

      await client
          .from('child_accounts')
          .update({'daily_screen_time_minutes': minutes})
          .eq('id', childId);

      setState(() {
        final index = _children.indexWhere((c) => c['id'] == childId);
        if (index != -1) {
          _children[index] = {
            ..._children[index],
            'daily_screen_time_minutes': minutes,
          };
        }
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context).ekranSuresiGuncellendi)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  Future<void> _lockChild(String childId, String childName, int lockMinutes, String reason) async {
    try {
      final repo = ChildAccountRepository();
      await repo.updateRemoteLock(
        childId,
        enabled: true,
        lockUntil: DateTime.now().add(Duration(minutes: lockMinutes)),
        reason: reason.isNotEmpty ? reason : 'Ebeveyn tarafından uzaktan kilitlendi',
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$childName $lockMinutes dk boyunca kilitlendi'),
            backgroundColor: const Color(0xFF6366F1),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Kilitleme başarısız: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  void _showLockDialog(String childId, String childName) {
    final reasonController = TextEditingController();
    int selectedMinutes = 30;
    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.lock_clock, color: AppColors.error),
              const SizedBox(width: 8),
              Expanded(child: Text('$childName Kilitle')),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(AppLocalizations.of(context).buCihaziHemenKilitleyinCocukGirisYapamayacak),
                const SizedBox(height: 16),
                Text('Süre: ${selectedMinutes ~/ 60}s ${selectedMinutes % 60}d',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Slider(
                  value: selectedMinutes.toDouble(),
                  min: 5,
                  max: 240,
                  divisions: 47,
                  label: '${selectedMinutes ~/ 60}s ${selectedMinutes % 60}d',
                  onChanged: (v) => setDialogState(() => selectedMinutes = v.round()),
                ),
                TextField(
                  controller: reasonController,
                  decoration: const InputDecoration(
                    labelText: 'Neden (isteğe bağlı)',
                    hintText: 'Örn: Ödev zamanı',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(AppLocalizations.of(context).cancel),
            ),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(dialogContext);
                _lockChild(childId, childName, selectedMinutes, reasonController.text);
              },
              icon: const Icon(Icons.lock),
              label: const Text('Kilitle'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showTimePicker(String childId, int currentMinutes) {
    int selectedMinutes = currentMinutes;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context).gunlukEkranSuresi),
        content: StatefulBuilder(
          builder: (context, setDialogState) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${selectedMinutes ~/ 60}s ${selectedMinutes % 60}d',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Slider(
                value: selectedMinutes.toDouble(),
                min: 15,
                max: 300,
                divisions: 19,
                label: '${selectedMinutes ~/ 60}s ${selectedMinutes % 60}d',
                onChanged: (v) =>
                    setDialogState(() => selectedMinutes = v.round()),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context).cancel),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _updateScreenTime(childId, selectedMinutes);
            },
            child: Text(AppLocalizations.of(context).save),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      appBar: ScreenHeader(
        title: 'Ekran Süresi',
        showBack: true,
        onBack: () => context.pop(),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      'Çocuk üyeler için günlük ekran süresi limitleri belirleyin.',
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                  ),
                ),
                if (_children.isEmpty)
                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: Center(
                        child: Text(
                          'Henüz çocuk hesabı eklenmemiş.\nÇocuk Hesapları bölümünden ekleyebilirsiniz.',
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  )
                else
                  SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final child = _children[index];
                      final minutes =
                          child['daily_screen_time_minutes'] as int? ?? 120;
                      final isEnabled = minutes > 0;

                      return SettingsSection(
                        title: (child['name'] ?? 'Çocuk')
                            .toString()
                            .toUpperCase(),
                        icon: Icons.child_care,
                        children: [
                          SwitchListTile(
                            title: Text(AppLocalizations.of(context).ekranSuresiLimiti),
                            subtitle: Text(
                              isEnabled
                                  ? 'Günlük ${minutes ~/ 60} saat ${minutes % 60} dakika'
                                  : 'Limit yok',
                            ),
                            value: isEnabled,
                            activeThumbColor: const Color(0xFF6366F1),
                            onChanged: (v) {
                              _updateScreenTime(
                                child['id'] as String,
                                v ? 120 : 0,
                              );
                            },
                          ),
                          if (isEnabled)
                            ListTile(
                              title: Text(AppLocalizations.of(context).sureyiAyarla),
                              trailing: const Icon(Icons.chevron_right),
                              onTap: () => _showTimePicker(
                                child['id'] as String,
                                minutes,
                              ),
                            ),
                          ListTile(
                            leading: const Icon(Icons.lock_clock, color: AppColors.error),
                            title: const Text(
                              'Hemen Kilitle',
                              style: TextStyle(color: AppColors.error, fontWeight: FontWeight.w600),
                            ),
                            subtitle: Text(AppLocalizations.of(context).cihaziUzaktanKilitle),
                            trailing: const Icon(Icons.chevron_right, color: AppColors.error),
                            onTap: () => _showLockDialog(
                              child['id'] as String,
                              (child['name'] ?? 'Çocuk') as String,
                            ),
                          ),
                        ],
                      );
                    }, childCount: _children.length),
                  ),
              ],
            ),
    );
  }
}
