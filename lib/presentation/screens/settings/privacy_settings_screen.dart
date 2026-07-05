import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';

import '../../../core/supabase_client.dart';
import '../../../services/auth_service.dart';
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
          text: 'FamilyHub Veri Dışa Aktarımı',
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
        title: const Text('Hesabı Sil', style: TextStyle(color: Color(0xFFEF4444))),
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
        title: 'Gizlilik',
        showBack: true,
        onBack: () => context.pop(),
      ),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: SettingsSection(
              title: 'VERİ PAYLAŞIMI',
              icon: Icons.share_outlined,
              children: [
                HiveSettingsToggle(
                  settingsKey: 'privacy_location_share',
                  title: 'Konum Paylaşımı',
                  subtitle: 'Aile üyeleri konumunuzu görebilsin',
                  defaultValue: true,
                  onSupabaseSync: (v) => _syncToSupabase('location_share', v),
                ),
                HiveSettingsToggle(
                  settingsKey: 'privacy_profile_visible',
                  title: 'Profil Görünürlüğü',
                  subtitle: 'Profiliniz diğer üyelere görünür',
                  defaultValue: true,
                  onSupabaseSync: (v) => _syncToSupabase('profile_visible', v),
                ),
                HiveSettingsToggle(
                  settingsKey: 'privacy_activity_status',
                  title: 'Aktivite Durumu',
                  subtitle: 'Çevrimiçi durumunuzu göster',
                  defaultValue: true,
                  onSupabaseSync: (v) => _syncToSupabase('activity_status', v),
                ),
              ],
            ),
          ),
          SliverToBoxAdapter(
            child: SettingsSection(
              title: 'ANALİTİK',
              icon: Icons.analytics_outlined,
              children: [
                HiveSettingsToggle(
                  settingsKey: 'privacy_analytics',
                  title: 'Kullanım Analitiği',
                  subtitle: 'Anonim kullanım verisi gönder',
                  defaultValue: false,
                  onSupabaseSync: (v) => _syncToSupabase('analytics', v),
                ),
              ],
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
                  title: const Text('Hesabımı Sil', style: TextStyle(color: Color(0xFFEF4444))),
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
