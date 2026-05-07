import 'package:flutter/material.dart';

import '../../../config/constants.dart';
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
      });
    } catch (e) {
      debugPrint('Supabase sync hatası: $e');
    }
  }

  Future<void> _exportUserData() async {
    // TODO: GDPR veri indirme implementasyonu
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppLocalizations.of(context).veriIndirmeHazirlaniyor)),
    );
  }

  Future<void> _showDeleteAccountDialog() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Hesabı Sil', style: TextStyle(color: AppColors.error)),
        content: Text(AppLocalizations.of(context).hesabiniziSilmekGeriAlinamazTumVerilerinizKaliciOlarakSilinecek),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(AppLocalizations.of(context).cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Sil', style: TextStyle(color: AppColors.error)),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkBackground : AppColors.cloudWhite;

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
                  leading: const Icon(Icons.download, color: AppColors.cobalt),
                  title: Text(AppLocalizations.of(context).verilerimiIndir),
                  subtitle: Text(AppLocalizations.of(context).gdprKapsamindaTumVerileriniz),
                  onTap: _exportUserData,
                ),
                ListTile(
                  leading: const Icon(Icons.delete_forever, color: AppColors.error),
                  title: const Text('Hesabımı Sil', style: TextStyle(color: AppColors.error)),
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
