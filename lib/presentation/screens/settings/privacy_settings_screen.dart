import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';

import '../../../core/supabase_client.dart';
import '../../../services/auth_service.dart';
import '../../../features/privacy/domain/privacy_preferences.dart';
import '../../../features/privacy/data/privacy_repository.dart';
import '../../widgets/settings/hive_settings_toggle.dart';
import '../../widgets/settings/screen_header.dart';
import '../../widgets/settings/settings_section.dart';
import 'package:go_router/go_router.dart';
import 'package:familyhub/l10n/app_localizations.dart';

class PrivacySettingsScreen extends StatefulWidget {
  const PrivacySettingsScreen({super.key});

  @override
  State<PrivacySettingsScreen> createState() => _PrivacySettingsScreenState();
}

class _PrivacySettingsScreenState extends State<PrivacySettingsScreen> {
  Future<void> _syncToSupabase(String settingKey, bool value) async {
    final client = SupabaseConfig.safeClient;
    final userId = AuthService.currentUserId;
    if (client == null || userId == null) return;

    try {
      await client.from('settings').upsert({
        'user_id': userId,
        'privacy': {
          settingKey: value,
          'updated_at': DateTime.now().toIso8601String(),
        },
      }, onConflict: 'user_id');
    } catch (e) {
      debugPrint('Supabase sync hatası: $e');
    }
  }

  Future<void> _exportUserData() async {
    final shareText = AppLocalizations.of(context).privExportShareText;
    final client = SupabaseConfig.safeClient;
    final userId = AuthService.currentUserId;
    if (client == null || userId == null) return;

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppLocalizations.of(context).veriIndirmeHazirlaniyor)),
    );

    try {
      final profile = await client.from('profiles').select().eq('id', userId).maybeSingle();
      final settings = await client.from('settings').select().eq('user_id', userId).maybeSingle();
      final export = {
        'export_date': DateTime.now().toIso8601String(),
        'user_id': userId,
        'profile': profile,
        'settings': settings,
      };

      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/familyhub_data_export.json');
      await file.writeAsString(const JsonEncoder.withIndent('  ').convert(export));

      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path)],
          text: shareText,
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Veri dışa aktarma başarısız: $e')),
        );
      }
    }
  }

  Future<void> _showDeleteAccountDialog() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(AppLocalizations.of(context).hesabiSil, style: const TextStyle(color: Color(0xFFEF4444))),
        content: Text(AppLocalizations.of(context).hesabiniziSilmekGeriAlinamazTumVerilerinizKaliciOlarakSilinecek),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(AppLocalizations.of(context).cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Sil', style: TextStyle(color: Color(0xFFEF4444))),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final client = SupabaseConfig.safeClient;
    final userId = AuthService.currentUserId;
    if (client == null || userId == null) return;

    try {
      await client.from('profiles').update({
        'is_deleted': true,
        'deleted_at': DateTime.now().toIso8601String(),
      }).eq('id', userId);

      await client.rpc('delete_user_account', params: {'user_id': userId});

      await AuthService.signOut();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context).hesabinizSilindiUygulamaKapatilacak)),
        );
        await Future.delayed(const Duration(seconds: 2));
        if (mounted) context.go('/login');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hesap silme hatası: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bg = const Color(0xFF0A0A0F);

    return Scaffold(
      backgroundColor: bg,
      appBar: ScreenHeader(
        title: AppLocalizations.of(context).setPrivacy,
        showBack: true,
        onBack: () => context.pop(),
      ),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: SettingsSection(
              title: AppLocalizations.of(context).veriPaylasimi,
              icon: Icons.share_outlined,
              children: [
                HiveSettingsToggle(
                  settingsKey: 'privacy_location_share',
                  title: AppLocalizations.of(context).konumPaylasimi1,
                  subtitle: AppLocalizations.of(context).aileUyeleriKonumunuzuGorebilsin,
                  defaultValue: true,
                  onSupabaseSync: (v) => _syncToSupabase('location_share', v),
                ),
                HiveSettingsToggle(
                  settingsKey: 'privacy_profile_visible',
                  title: AppLocalizations.of(context).profilGorunurlugu,
                  subtitle: AppLocalizations.of(context).profilinizDigerUyelereGorunur,
                  defaultValue: true,
                  onSupabaseSync: (v) => _syncToSupabase('profile_visible', v),
                ),
                HiveSettingsToggle(
                  settingsKey: 'privacy_activity_status',
                  title: AppLocalizations.of(context).privActivityStatus,
                  subtitle: AppLocalizations.of(context).cevrimiciDurumunuzuGoster,
                  defaultValue: true,
                  onSupabaseSync: (v) => _syncToSupabase('activity_status', v),
                ),
              ],
            ),
          ),
          SliverToBoxAdapter(
            child: SettingsSection(
              title: AppLocalizations.of(context).analitik,
              icon: Icons.analytics_outlined,
              children: [
                HiveSettingsToggle(
                  settingsKey: 'privacy_analytics',
                  title: AppLocalizations.of(context).kullanimAnalitigi,
                  subtitle: AppLocalizations.of(context).anonimKullanimVerisiGonder,
                  defaultValue: false,
                  onSupabaseSync: (v) => _syncToSupabase('analytics', v),
                ),
              ],
            ),
          ),
          // ── AI VERİ İZİNLERİ (PrivacyPreferences modeline bağlı) ──
          SliverToBoxAdapter(
            child: SettingsSection(
              title: AppLocalizations.of(context).privacyAiSection,
              icon: Icons.smart_toy_outlined,
              children: [_AiPermissions()],
            ),
          ),
          SliverToBoxAdapter(
            child: SettingsSection(
              title: 'GDPR',
              icon: Icons.verified_user_outlined,
              children: [
                ListTile(
                  leading: const Icon(Icons.download, color: Color(0xFF6366F1)),
                  title: Text(AppLocalizations.of(context).verilerimiIndir),
                  subtitle: Text(AppLocalizations.of(context).gdprKapsamindaTumVerileriniz),
                  onTap: _exportUserData,
                ),
                ListTile(
                  leading: const Icon(Icons.delete_forever, color: Color(0xFFEF4444)),
                  title: Text(AppLocalizations.of(context).hesabimiSil, style: const TextStyle(color: Color(0xFFEF4444))),
                  subtitle: Text(AppLocalizations.of(context).tumVerilerinizKaliciOlarakSilinecek),
                  onTap: _showDeleteAccountDialog,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// AI veri izinleri — PrivacyPreferences modeline bağlı, modül bazlı switch.
/// Hassas modüller (sağlık/finans/çocuk/konum) varsayılan kapalı + rozet.
class _AiPermissions extends StatefulWidget {
  @override
  State<_AiPermissions> createState() => _AiPermissionsState();
}

class _AiPermissionsState extends State<_AiPermissions> {
  final _repo = PrivacyRepository.instance;
  late PrivacyPreferences _prefs = _repo.load();

  static const _order = [
    PrivacyModule.calendar,
    PrivacyModule.tasks,
    PrivacyModule.shopping,
    PrivacyModule.kitchen,
    PrivacyModule.health,
    PrivacyModule.finance,
    PrivacyModule.child,
    PrivacyModule.location,
  ];

  String _label(AppLocalizations t, PrivacyModule m) => switch (m) {
        PrivacyModule.calendar => t.privacyModCalendar,
        PrivacyModule.tasks => t.privacyModTasks,
        PrivacyModule.shopping => t.privacyModShopping,
        PrivacyModule.kitchen => t.privacyModKitchen,
        PrivacyModule.health => t.privacyModHealth,
        PrivacyModule.finance => t.privacyModFinance,
        PrivacyModule.child => t.privacyModChild,
        PrivacyModule.location => t.privacyModLocation,
      };

  Future<void> _toggle(PrivacyModule m, bool v) async {
    final next = _prefs.toggleModule(m, v);
    await _repo.save(next);
    if (mounted) setState(() => _prefs = next);
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
          child: Text(t.privacyAiDesc,
              style: const TextStyle(color: Color(0xFF6B7280), fontSize: 12)),
        ),
        for (final m in _order)
          SwitchListTile(
            value: _prefs.aiAllows(m),
            activeTrackColor: const Color(0xFF6366F1),
            onChanged: (v) => _toggle(m, v),
            title: Row(children: [
              Text(_label(t, m),
                  style: const TextStyle(color: Color(0xFFE5E7EB), fontSize: 15)),
              if (PrivacyPreferences.isSensitive(m)) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0x33F59E0B),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(t.privacySensitive,
                      style: const TextStyle(
                          color: Color(0xFFF59E0B),
                          fontSize: 10,
                          fontWeight: FontWeight.w700)),
                ),
              ],
            ]),
          ),
      ],
    );
  }
}
