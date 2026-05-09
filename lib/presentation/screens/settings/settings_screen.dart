import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../config/constants.dart';
import '../../../config/routes.dart';
import '../../../core/supabase_client.dart';
import '../../../repositories/backup_repository.dart';
import '../../../services/auth_service.dart';
import '../../../services/hive_service.dart';
import '../../providers/app_providers.dart';
import '../../widgets/settings/profile_card.dart';
import '../../widgets/settings/premium_card.dart';
import '../../widgets/settings/settings_section.dart';
import '../../widgets/settings/settings_item.dart';
import '../../widgets/settings/settings_toggle.dart';
import 'package:familyhub/l10n/app_localizations.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  String _accentLabel = 'Kobalt Mavi';
  String _fontLabel = 'Orta';
  String _languageLabel = 'Türkçe';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadDynamicLabels());
  }

  void _loadDynamicLabels() {
    final accent = HiveService.getSetting('accentColor') ?? 'cobalt';
    _accentLabel = switch (accent) {
      'green' => 'Yeşil',
      'orange' => 'Turuncu',
      'purple' => 'Mor',
      'red' => 'Kırmızı',
      _ => 'Kobalt Mavi',
    };

    final fontScale = HiveService.getDoubleSetting('fontScale') ?? 1.0;
    _fontLabel = switch (fontScale) {
      0.875 => 'Küçük',
      1.125 => 'Büyük',
      1.25 => 'Çok Büyük',
      _ => 'Orta',
    };

    _languageLabel = HiveService.getSetting('language') ?? 'Türkçe';
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);
    final isDark = themeMode == ThemeMode.dark;
    final safeBottom = MediaQuery.of(context).viewPadding.bottom;
    final safeTop = MediaQuery.of(context).viewPadding.top;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.cloudWhite,
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: SizedBox(height: safeTop > 0 ? 8 : 16),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ayarlar',
                      style: Theme.of(context)
                          .textTheme
                          .displayLarge
                          ?.copyWith(fontSize: 32),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'FamilyHub\'ınızı yönetin',
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(
                            color: isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.slate,
                          ),
                    ),
                  ],
                ),
              ),
            ),
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: ProfileCard(),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
            // Görünüm
            SliverToBoxAdapter(
              child: SettingsSection(
                title: 'GÖRÜNÜM',
                icon: Icons.palette_outlined,
                children: [
                  SettingsToggle(
                    icon: Icons.dark_mode_outlined,
                    iconColor: const Color(0xFF6366F1),
                    label: 'Koyu Tema',
                    description: 'Gece modunda daha rahat kullanım',
                    value: isDark,
                    onToggle: (v) async {
                      await HiveService.setSetting('themeMode', v ? 'dark' : 'light');
                      ref.read(themeModeProvider.notifier).state = v ? ThemeMode.dark : ThemeMode.light;
                    },
                  ),
                  SettingsItem(
                    icon: Icons.color_lens_outlined,
                    iconColor: const Color(0xFFEC4899),
                    label: 'Aksan Rengi',
                    description: 'Uygulama vurgu rengini değiştir',
                    showValue: _accentLabel,
                    onTap: () => context.push(AppRoutes.appearanceSettings),
                  ),
                  SettingsItem(
                    icon: Icons.text_fields,
                    iconColor: const Color(0xFF8B5CF6),
                    label: 'Yazı Boyutu',
                    description: 'Metin boyutunu ayarla',
                    showValue: _fontLabel,
                    onTap: () => context.push(AppRoutes.appearanceSettings),
                    isLast: true,
                  ),
                ],
              ),
            ),
            // Bildirimler
            SliverToBoxAdapter(
              child: SettingsSection(
                title: 'BİLDİRİMLER',
                icon: Icons.notifications_outlined,
                children: [
                  SettingsItem(
                    icon: Icons.calendar_today,
                    iconColor: AppColors.cobalt,
                    label: 'Etkinlik Hatırlatmaları',
                    description: 'Yaklaşan etkinlikler için bildirimler',
                    showValue: HiveService.getSetting('notifyEvents') ?? 'Açık',
                    onTap: () => context.push(AppRoutes.notificationSettings),
                  ),
                  SettingsItem(
                    icon: Icons.check_circle_outline,
                    iconColor: AppColors.success,
                    label: 'Görev Bildirimleri',
                    description: 'Atanan ve yaklaşan görevler',
                    showValue: HiveService.getSetting('notifyTasks') ?? 'Açık',
                    onTap: () => context.push(AppRoutes.notificationSettings),
                  ),
                  SettingsItem(
                    icon: Icons.warning_amber_rounded,
                    iconColor: AppColors.error,
                    label: 'Acil Durum Uyarıları',
                    description: 'Panik butonu ve güvenlik bildirimleri',
                    showValue: HiveService.getSetting('notifyEmergency') ?? 'Yüksek Öncelik',
                    onTap: () => context.push(AppRoutes.notificationSettings),
                  ),
                  SettingsItem(
                    icon: Icons.chat_bubble_outline,
                    iconColor: const Color(0xFF8B5CF6),
                    label: 'Sohbet Bildirimleri',
                    description: 'Mesajlar, duyurular ve etiketlemeler',
                    showValue: HiveService.getSetting('notifyChat') ?? 'Açık',
                    onTap: () => context.push(AppRoutes.notificationSettings),
                  ),
                  SettingsItem(
                    icon: Icons.location_on_outlined,
                    iconColor: const Color(0xFFF59E0B),
                    label: 'Konum Bildirimleri',
                    description: 'Güvenli bölge giriş/çıkış uyarıları',
                    showValue: HiveService.getSetting('notifyLocation') ?? 'Açık',
                    onTap: () => context.push(AppRoutes.notificationSettings),
                    isLast: true,
                  ),
                ],
              ),
            ),
            // Aile
            SliverToBoxAdapter(
              child: SettingsSection(
                title: 'AİLE',
                icon: Icons.people_outline,
                children: [
                  SettingsItem(
                    icon: Icons.people_outline,
                    iconColor: AppColors.cobalt,
                    label: 'Aile Yönetimi',
                    description: 'Üyeleri görüntüle, rolleri düzenle',
                    showValueWidget: FutureBuilder<int>(
                      future: _getMemberCount(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) return const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2));
                        return Text('${snapshot.data} Üye');
                      },
                    ),
                    onTap: () => context.push(AppRoutes.familyManage),
                  ),
                  SettingsItem(
                    icon: Icons.person_add_alt,
                    iconColor: AppColors.success,
                    label: 'Davet Kodu Oluştur',
                    description: 'Yeni üyeleri aileye davet et',
                    onTap: () => context.push(AppRoutes.inviteCode),
                  ),
                  SettingsItem(
                    icon: Icons.admin_panel_settings_outlined,
                    iconColor: const Color(0xFFF59E0B),
                    label: 'İzinler ve Roller',
                    description: 'Her üye için yetki ayarları',
                    onTap: () => context.push(AppRoutes.familyPermissions),
                  ),
                  SettingsItem(
                    icon: Icons.child_care,
                    iconColor: Colors.orange,
                    label: 'Çocuk Hesapları',
                    description: 'PIN ile çocuk girişleri yönetin',
                    onTap: () => context.push(AppRoutes.childManagement),
                  ),
                  SettingsItem(
                    icon: Icons.timer_outlined,
                    iconColor: const Color(0xFFEC4899),
                    label: 'Ekran Süresi',
                    description: 'Çocuk üyeler için kullanım limitleri',
                    showValue: 'Aktif',
                    onTap: () => context.push(AppRoutes.screenTimeSettings),
                  ),
                  SettingsItem(
                    icon: Icons.exit_to_app,
                    iconColor: AppColors.error,
                    label: 'Aileden Ayrıl',
                    description: 'Bu aileden çıkış yap',
                    onTap: () => _showLeaveDialog(context),
                    isDanger: true,
                    isLast: true,
                  ),
                ],
              ),
            ),
            // Hesap
            SliverToBoxAdapter(
              child: SettingsSection(
                title: 'HESAP',
                icon: Icons.person_outline,
                children: [
                  SettingsItem(
                    icon: Icons.person_outline,
                    iconColor: AppColors.cobalt,
                    label: 'Profil Bilgileri',
                    description: 'Ad, fotoğraf, telefon numarası',
                    onTap: () => context.push(AppRoutes.profileEdit),
                  ),
                  SettingsItem(
                    icon: Icons.key_outlined,
                    iconColor: const Color(0xFFF59E0B),
                    label: 'Güvenlik',
                    description: 'Şifre, iki faktör, biyometrik giriş',
                    showValue: 'Güvenli',
                    onTap: () => context.push(AppRoutes.securitySettings),
                  ),
                  SettingsItem(
                    icon: Icons.lock_outline,
                    iconColor: AppColors.success,
                    label: 'Gizlilik',
                    description: 'Veri paylaşımı, konum izinleri',
                    onTap: () => context.push(AppRoutes.privacySettings),
                  ),
                  SettingsItem(
                    icon: Icons.language,
                    iconColor: const Color(0xFF8B5CF6),
                    label: 'Dil ve Bölge',
                    description: 'Uygulama dili ve tarih formatı',
                    showValue: _languageLabel,
                    onTap: () => context.push(AppRoutes.languageSettings),
                    isLast: true,
                  ),
                ],
              ),
            ),
            // Hava Durumu
            SliverToBoxAdapter(
              child: SettingsSection(
                title: 'HAVA DURUMU',
                icon: Icons.wb_sunny_outlined,
                children: [
                  SettingsItem(
                    icon: Icons.wb_sunny,
                    iconColor: const Color(0xFFF59E0B),
                    label: 'Hava Durumu Ayarları',
                    description: 'Şehir, birim ve konum tercihleri',
                    showValueWidget: FutureBuilder<String?>(
                      future: Future.value(HiveService.getSetting('weatherCity')),
                      builder: (context, snapshot) {
                        return Text(snapshot.data ?? 'İstanbul');
                      },
                    ),
                    onTap: () => context.push(AppRoutes.weatherSettings),
                    isLast: true,
                  ),
                ],
              ),
            ),
            // Veri ve Depolama
            SliverToBoxAdapter(
              child: SettingsSection(
                title: 'VERİ VE DEPOLAMA',
                icon: Icons.storage_outlined,
                children: [
                  SettingsItem(
                    icon: Icons.backup_outlined,
                    iconColor: AppColors.cobalt,
                    label: 'Yedekleme',
                    description: 'Verilerinizi buluta yedekleyin',
                    showValueWidget: FutureBuilder<String>(
                      future: _getLastBackupTime(),
                      builder: (context, snapshot) {
                        return Text(snapshot.data ?? '...');
                      },
                    ),
                    onTap: () => context.push(AppRoutes.backupSettings),
                  ),
                  SettingsItem(
                    icon: Icons.restore,
                    iconColor: AppColors.success,
                    label: 'Geri Yükle',
                    description: 'Önceki yedekten veri kurtarın',
                    onTap: () => context.push(AppRoutes.backupSettings),
                  ),
                  SettingsItem(
                    icon: Icons.delete_outline,
                    iconColor: AppColors.error,
                    label: 'Verileri Sil',
                    description: 'Tüm verilerinizi kalıcı olarak silin',
                    onTap: () => _showDeleteDataDialog(context),
                    isDanger: true,
                  ),
                  SettingsItem(
                    icon: Icons.cleaning_services_outlined,
                    iconColor: AppColors.gray,
                    label: 'Önbelleği Temizle',
                    description: 'Geçici dosyaları temizleyin',
                    showValueWidget: FutureBuilder<String>(
                      future: _getCacheSize(),
                      builder: (context, snapshot) {
                        return Text(snapshot.data ?? '...');
                      },
                    ),
                    onTap: () => _showClearCacheDialog(context),
                    isLast: true,
                  ),
                ],
              ),
            ),
            // Premium
            SliverToBoxAdapter(
              child: SettingsSection(
                title: 'PREMIUM',
                icon: Icons.star_outline,
                highlight: true,
                children: [
                  Consumer(
                    builder: (context, ref, child) {
                      final premiumAsync = ref.watch(isPremiumProvider);
                      return premiumAsync.when(
                        data: (isPremium) {
                          if (!isPremium) {
                            return Padding(
                              padding: const EdgeInsets.all(16),
                              child: PremiumCard(
                                tier: 'Ücretsiz',
                                expiry: null,
                                features: const [
                                  'Temel özellikler',
                                  '4 aile üyesi',
                                  '1 GB depolama',
                                ],
                                onManage: () => context.push(AppRoutes.premium),
                              ),
                            );
                          }
                          return Padding(
                            padding: const EdgeInsets.all(16),
                            child: PremiumCard(
                              tier: 'Premium',
                              expiry: 'Aktif',
                              features: const [
                                'Sınırsız fotoğraf depolama',
                                '8 aile üyesi',
                                'AI asistan',
                                'Gelişmiş güvenlik',
                              ],
                              onManage: () => context.push(AppRoutes.premium),
                            ),
                          );
                        },
                        loading: () => const Padding(
                          padding: EdgeInsets.all(16),
                          child: Center(child: CircularProgressIndicator()),
                        ),
                        error: (e, s) => const SizedBox.shrink(),
                      );
                    },
                  ),
                ],
              ),
            ),
            // Yardım
            SliverToBoxAdapter(
              child: SettingsSection(
                title: 'YARDIM VE DESTEK',
                icon: Icons.help_outline,
                children: [
                  SettingsItem(
                    icon: Icons.menu_book_outlined,
                    iconColor: AppColors.cobalt,
                    label: 'Kullanım Kılavuzu',
                    description: 'FamilyHub\'ı nasıl kullanacağınızı öğrenin',
                    onTap: () => context.push(AppRoutes.userGuide),
                  ),
                  SettingsItem(
                    icon: Icons.support_agent_outlined,
                    iconColor: AppColors.success,
                    label: 'Destek ile İletişim',
                    description: 'Sorularınızı ve önerilerinizi paylaşın',
                    onTap: () => _openSupport(context),
                  ),
                  SettingsItem(
                    icon: Icons.bug_report_outlined,
                    iconColor: const Color(0xFFF59E0B),
                    label: 'Hata Bildir',
                    description: 'Karşılaştığınız sorunu raporlayın',
                    onTap: () => _openBugReport(context),
                  ),
                  SettingsItem(
                    icon: Icons.star_outline,
                    iconColor: const Color(0xFFEC4899),
                    label: 'Bizi Değerlendirin',
                    description: 'App Store\'da puan verin',
                    onTap: () => _openAppStore(context),
                    isLast: true,
                  ),
                ],
              ),
            ),
            // Yasal
            SliverToBoxAdapter(
              child: SettingsSection(
                title: 'YASAL',
                icon: Icons.description_outlined,
                children: [
                  SettingsItem(
                    icon: Icons.privacy_tip_outlined,
                    iconColor: AppColors.gray,
                    label: 'Gizlilik Politikası',
                    description: 'Verileriniz nasıl korunuyor',
                    onTap: () => context.push(AppRoutes.privacyPolicy),
                  ),
                  SettingsItem(
                    icon: Icons.description_outlined,
                    iconColor: AppColors.gray,
                    label: 'Kullanım Koşulları',
                    description: 'Hizmet şartları ve sorumluluklar',
                    onTap: () => context.push(AppRoutes.termsOfService),
                  ),
                  SettingsItem(
                    icon: Icons.info_outline,
                    iconColor: AppColors.gray,
                    label: 'Hakkında',
                    description: 'Sürüm 2.1.0 · FamilyHub Inc.',
                    showValue: 'Güncel',
                    onTap: () => context.push(AppRoutes.aboutApp),
                    isLast: true,
                  ),
                ],
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 32)),
            // Sign Out
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: () async {
                          await AuthService.signOut();
                          if (context.mounted) context.go(AppRoutes.login);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              AppColors.error.withAlpha(isDark ? 25 : 15),
                          foregroundColor: AppColors.error,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Text(
                          'Çıkış Yap',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'FamilyHub v2.1.0 (Build 2100)',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.lightGray,
                      ),
                    ),
                    SizedBox(height: safeBottom + 120),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showLeaveDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(AppLocalizations.of(context).ailedenAyril),
        content: const Text(
          'Aileden ayrıldığınızda tüm verileriniz bu aileden silinecek. Bu işlem geri alınamaz.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(AppLocalizations.of(context).cancel),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(dialogContext).pop();
              await _leaveFamily();
            },
            child: const Text('Ayrıl', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }

  void _showDeleteDataDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Verileri Sil'),
        content: const Text(
          'Tüm verileriniz kalıcı olarak silinecek. Bu işlem geri alınamaz.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(AppLocalizations.of(context).cancel),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(dialogContext).pop();
              await _deleteAllData();
            },
            child: const Text('Sil', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }

  void _showClearCacheDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(AppLocalizations.of(context).onbellegiTemizle),
        content: Text(AppLocalizations.of(context).geciciDosyalarSilinecekUygulamaBirazDahaYavasBaslayabilir),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(AppLocalizations.of(context).cancel),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(dialogContext).pop();
              await _clearCache();
            },
            child: const Text('Temizle'),
          ),
        ],
      ),
    );
  }

  void _openSupport(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('destek@familyhub.app')),
    );
  }

  void _openBugReport(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('hata@familyhub.app')),
    );
  }

  void _openAppStore(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppLocalizations.of(context).degerlendirmeSayfasiAciliyor)),
    );
  }

  Future<int> _getMemberCount() async {
    final client = SupabaseConfig.safeClient;
    final userId = AuthService.currentUserId;
    if (client == null || userId == null) return 0;
    try {
      final fm = await client
          .from('family_members')
          .select('family_id')
          .eq('user_id', userId)
          .maybeSingle();
      final familyId = fm?['family_id'] as String?;
      if (familyId == null) return 0;
      final adultCount = await client
          .from('family_members')
          .select('id')
          .eq('family_id', familyId)
          .eq('is_active', true)
          .count(CountOption.exact);
      final childCount = await client
          .from('child_accounts')
          .select('id')
          .eq('family_id', familyId)
          .eq('is_active', true)
          .count(CountOption.exact);
      return adultCount.count + childCount.count;
    } catch (_) {
      return 0;
    }
  }

  Future<void> _leaveFamily() async {
    final client = SupabaseConfig.safeClient;
    final userId = AuthService.currentUserId;
    if (client == null || userId == null) return;
    try {
      await client.from('family_members').update({'is_active': false}).eq('user_id', userId);
      await AuthService.signOut();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context).ailedenAyrildiniz)),
        );
        await Future.delayed(const Duration(seconds: 1));
        if (mounted) context.go(AppRoutes.login);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ayrılma hatası: $e')),
        );
      }
    }
  }

  Future<void> _deleteAllData() async {
    try {
      await Hive.deleteFromDisk();
      final client = SupabaseConfig.safeClient;
      final userId = AuthService.currentUserId;
      if (client != null && userId != null) {
        await client.from('profiles').update({
          'is_deleted': true,
          'deleted_at': DateTime.now().toIso8601String(),
        }).eq('id', userId);
        await client.rpc('delete_user_account', params: {'user_id': userId});
        await AuthService.signOut();
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context).tumVerilerSilindi)),
        );
        await Future.delayed(const Duration(seconds: 1));
        if (mounted) context.go(AppRoutes.login);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Silme hatası: $e')),
        );
      }
    }
  }

  Future<void> _clearCache() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final hiveDir = Directory('${dir.path}/hive');
      if (hiveDir.existsSync()) {
        await hiveDir.delete(recursive: true);
      }
      final cacheDir = Directory('${dir.path}/cache');
      if (cacheDir.existsSync()) {
        await cacheDir.delete(recursive: true);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context).onbellekTemizlendi)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Temizleme hatası: $e')),
        );
      }
    }
  }

  Future<String> _getLastBackupTime() async {
    try {
      final backups = await BackupRepository().getBackups();
      if (backups.isEmpty) return 'Henüz yok';
      final last = DateTime.parse(backups.first['created_at'] as String);
      final diff = DateTime.now().difference(last);
      if (diff.inMinutes < 1) return 'Az önce';
      if (diff.inHours < 1) return '${diff.inMinutes} dk önce';
      if (diff.inDays < 1) return '${diff.inHours} sa önce';
      return '${diff.inDays} gün önce';
    } catch (_) {
      return 'Henüz yok';
    }
  }

  Future<String> _getCacheSize() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final hiveDir = Directory('${dir.path}/hive');
      if (!hiveDir.existsSync()) return '0 MB';
      int totalSize = 0;
      await for (final file in hiveDir.list()) {
        if (file is File) totalSize += await file.length();
      }
      if (totalSize < 1024 * 1024) return '${(totalSize / 1024).toStringAsFixed(0)} KB';
      return '${(totalSize / 1024 / 1024).toStringAsFixed(1)} MB';
    } catch (_) {
      return '0 MB';
    }
  }
}
