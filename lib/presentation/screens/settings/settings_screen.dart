import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../config/routes.dart';
import '../../../core/supabase_client.dart';
import '../../../repositories/backup_repository.dart';
import '../../../services/auth_service.dart';
import '../../../services/hive_service.dart';
import '../../providers/app_providers.dart' show localFamilyMembers;
import '../../widgets/settings/profile_card.dart';
import '../../widgets/settings/premium_card.dart';
import '../../widgets/settings/settings_section.dart';
import '../../widgets/settings/settings_item.dart';
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
  late final Future<int> _memberCountFuture;

  @override
  void initState() {
    super.initState();
    _memberCountFuture = _getMemberCount();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadDynamicLabels());
  }

  void _loadDynamicLabels() {
    final accent = HiveService.getSetting('accentColor') ?? 'cobalt';
    _accentLabel = switch (accent) {
      'green' => 'Yeşil',
      'orange' => 'Turuncu',
      'purple' => 'Mor',
      'red' => 'Kırmızı',
      _ => 'İndigo',
    };

    // Floating point comparison via string key instead of double equality
    final fontScaleStr = HiveService.getSetting('fontScale') ?? '1.0';
    _fontLabel = switch (fontScaleStr) {
      '0.875' => 'Küçük',
      '1.125' => 'Büyük',
      '1.25' => 'Çok Büyük',
      _ => 'Orta',
    };

    _languageLabel = HiveService.getSetting('language') ?? 'Türkçe';
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final safeBottom = MediaQuery.of(context).viewPadding.bottom;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // Başlık
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
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
                      style: TextStyle(
                        fontSize: 14,
                        color: Theme.of(context).colorScheme.onSurface.withAlpha(128),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Profil kartı
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: ProfileCard(),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 8)),

            // ── BİLDİRİMLER ─────────────────────────────────────────
            SliverToBoxAdapter(
              child: SettingsSection(
                title: AppLocalizations.of(context).bildirimler,
                icon: Icons.notifications_outlined,
                children: [
                  SettingsItem(
                    icon: Icons.notifications_active_outlined,
                    iconColor: const Color(0xFF6366F1),
                    label: AppLocalizations.of(context).bildirimAyarlari,
                    description:
                        'Etkinlik, görev, acil durum, sohbet ve konum bildirimleri',
                    onTap: () => context.push(AppRoutes.notificationSettings),
                    isLast: true,
                  ),
                ],
              ),
            ),

            // ── AİLE ────────────────────────────────────────────────
            SliverToBoxAdapter(
              child: SettingsSection(
                title: AppLocalizations.of(context).aile,
                icon: Icons.people_outline,
                children: [
                  SettingsItem(
                    icon: Icons.people_outline,
                    iconColor: const Color(0xFF6366F1),
                    label: AppLocalizations.of(context).aileYonetimi,
                    description: AppLocalizations.of(context).uyeleriGoruntuleRolleriDuzenle,
                    showValueWidget: FutureBuilder<int>(
                      future: _memberCountFuture,
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Color(0xFF6B7280),
                            ),
                          );
                        }
                        return Text('${snapshot.data} Üye');
                      },
                    ),
                    onTap: () => context.push(AppRoutes.familyManage),
                  ),
                  SettingsItem(
                    icon: Icons.person_add_alt,
                    iconColor: const Color(0xFF10B981),
                    label: AppLocalizations.of(context).davetKoduOlustur,
                    description: AppLocalizations.of(context).yeniUyeleriAileyeDavetEt,
                    onTap: () => context.push(AppRoutes.inviteCode),
                  ),
                  SettingsItem(
                    icon: Icons.admin_panel_settings_outlined,
                    iconColor: const Color(0xFFF59E0B),
                    label: AppLocalizations.of(context).izinlerVeRoller,
                    description: AppLocalizations.of(context).herUyeIcinYetkiAyarlari,
                    onTap: () => context.push(AppRoutes.familyPermissions),
                  ),
                  SettingsItem(
                    icon: Icons.child_care,
                    iconColor: const Color(0xFF06B6D4),
                    label: AppLocalizations.of(context).cocukHesaplari,
                    description: AppLocalizations.of(context).pinIleCocukGirisleriYonetin,
                    onTap: () => context.push(AppRoutes.childManagement),
                  ),
                  SettingsItem(
                    icon: Icons.timer_outlined,
                    iconColor: const Color(0xFFEC4899),
                    label: AppLocalizations.of(context).ekranSuresi,
                    description: AppLocalizations.of(context).cocukUyelerIcinKullanimLimitleri,
                    showValue: 'Aktif',
                    onTap: () => context.push(AppRoutes.screenTimeSettings),
                  ),
                  SettingsItem(
                    icon: Icons.exit_to_app,
                    iconColor: const Color(0xFFEF4444),
                    label: AppLocalizations.of(context).ailedenAyril,
                    description: AppLocalizations.of(context).buAiledenCikisYap,
                    onTap: () => _showLeaveDialog(context),
                    isDanger: true,
                    isLast: true,
                  ),
                ],
              ),
            ),

            // ── HESAP ───────────────────────────────────────────────
            SliverToBoxAdapter(
              child: SettingsSection(
                title: 'HESAP',
                icon: Icons.person_outline,
                children: [
                  SettingsItem(
                    icon: Icons.person_outline,
                    iconColor: const Color(0xFF6366F1),
                    label: 'Profil Bilgileri',
                    description: AppLocalizations.of(context).adFotografTelefonNumarasi,
                    onTap: () => context.push(AppRoutes.profileEdit),
                  ),
                  SettingsItem(
                    icon: Icons.key_outlined,
                    iconColor: const Color(0xFFF59E0B),
                    label: AppLocalizations.of(context).safety,
                    description: AppLocalizations.of(context).sifreIkiFaktorBiyometrikGiris,
                    showValue: 'Güvenli',
                    onTap: () => context.push(AppRoutes.securitySettings),
                  ),
                  SettingsItem(
                    icon: Icons.lock_outline,
                    iconColor: const Color(0xFF10B981),
                    label: 'Gizlilik',
                    description: AppLocalizations.of(context).veriPaylasimiKonumIzinleri,
                    onTap: () => context.push(AppRoutes.privacySettings),
                  ),
                  SettingsItem(
                    icon: Icons.language,
                    iconColor: const Color(0xFF8B5CF6),
                    label: AppLocalizations.of(context).dilVeBolge,
                    description: AppLocalizations.of(context).uygulamaDiliVeTarihFormati,
                    showValue: _languageLabel,
                    onTap: () => context.push(AppRoutes.languageSettings),
                    isLast: true,
                  ),
                ],
              ),
            ),

            // ── HAVA DURUMU ─────────────────────────────────────────
            SliverToBoxAdapter(
              child: SettingsSection(
                title: 'HAVA DURUMU',
                icon: Icons.wb_sunny_outlined,
                children: [
                  SettingsItem(
                    icon: Icons.wb_sunny,
                    iconColor: const Color(0xFFF59E0B),
                    label: AppLocalizations.of(context).havaDurumuAyarlari,
                    description: AppLocalizations.of(context).sehirBirimVeKonumTercihleri,
                    showValueWidget: FutureBuilder<String?>(
                      future: Future.value(HiveService.getSetting('weatherCity')),
                      builder: (context, snapshot) {
                        return Text(snapshot.data ?? 'Brüksel');
                      },
                    ),
                    onTap: () => context.push(AppRoutes.weatherSettings),
                    isLast: true,
                  ),
                ],
              ),
            ),

            // ── VERİ VE DEPOLAMA ─────────────────────────────────────
            SliverToBoxAdapter(
              child: SettingsSection(
                title: AppLocalizations.of(context).veriVeDepolama,
                icon: Icons.storage_outlined,
                children: [
                  SettingsItem(
                    icon: Icons.backup_outlined,
                    iconColor: const Color(0xFF6366F1),
                    label: 'Yedekleme ve Geri Yükleme',
                    description: 'Verilerinizi buluta yedekleyin veya kurtarın',
                    showValueWidget: FutureBuilder<String>(
                      future: _getLastBackupTime(),
                      builder: (context, snapshot) {
                        return Text(snapshot.data ?? '...');
                      },
                    ),
                    onTap: () => context.push(AppRoutes.backupSettings),
                  ),
                  SettingsItem(
                    icon: Icons.cleaning_services_outlined,
                    iconColor: const Color(0xFF6B7280),
                    label: AppLocalizations.of(context).onbellegiTemizle,
                    description: AppLocalizations.of(context).geciciDosyalariTemizleyin,
                    showValueWidget: FutureBuilder<String>(
                      future: _getCacheSize(),
                      builder: (context, snapshot) {
                        return Text(snapshot.data ?? '...');
                      },
                    ),
                    onTap: () => _showClearCacheDialog(context),
                  ),
                  SettingsItem(
                    icon: Icons.delete_outline,
                    iconColor: const Color(0xFFEF4444),
                    label: 'Verileri Sil',
                    description: AppLocalizations.of(context).tumVerileriniziKaliciOlarakSilin,
                    onTap: () => _showDeleteDataDialog(context),
                    isDanger: true,
                    isLast: true,
                  ),
                ],
              ),
            ),

            // ── PREMIUM ─────────────────────────────────────────────
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
                        data: (isPremium) => Padding(
                          padding: const EdgeInsets.all(16),
                          child: PremiumCard(
                            tier: isPremium ? 'Premium' : 'Ücretsiz',
                            expiry: isPremium ? 'Aktif' : null,
                            features: isPremium
                                ? const [
                                    'Sınırsız fotoğraf depolama',
                                    '8 aile üyesi',
                                    'AI asistan',
                                    'Gelişmiş güvenlik',
                                  ]
                                : const [
                                    'Temel özellikler',
                                    '4 aile üyesi',
                                    '1 GB depolama',
                                  ],
                            onManage: () => context.push(AppRoutes.premium),
                          ),
                        ),
                        loading: () => const Padding(
                          padding: EdgeInsets.all(24),
                          child: Center(
                            child: CircularProgressIndicator(
                              color: Color(0xFF6366F1),
                            ),
                          ),
                        ),
                        error: (e, s) => const SizedBox.shrink(),
                      );
                    },
                  ),
                ],
              ),
            ),

            // ── YARDIM ──────────────────────────────────────────────
            // Yalnızca Kullanım Kılavuzu. Destek/Hata Bildir/Değerlendir
            // kaldırıldı (iletişim minimal olarak Hakkında altında).
            SliverToBoxAdapter(
              child: SettingsSection(
                title: 'YARDIM',
                icon: Icons.help_outline,
                children: [
                  SettingsItem(
                    icon: Icons.menu_book_outlined,
                    iconColor: const Color(0xFF6366F1),
                    label: AppLocalizations.of(context).kullanimKilavuzu,
                    description: 'FamilyHub\'ı nasıl kullanacağınızı öğrenin',
                    onTap: () => context.push(AppRoutes.userGuide),
                    isLast: true,
                  ),
                ],
              ),
            ),

            // ── YASAL ───────────────────────────────────────────────
            SliverToBoxAdapter(
              child: SettingsSection(
                title: 'YASAL',
                icon: Icons.description_outlined,
                children: [
                  SettingsItem(
                    icon: Icons.privacy_tip_outlined,
                    iconColor: const Color(0xFF6B7280),
                    label: AppLocalizations.of(context).gizlilikPolitikasi,
                    description: AppLocalizations.of(context).verilerinizNasilKorunuyor,
                    onTap: () => context.push(AppRoutes.privacyPolicy),
                  ),
                  SettingsItem(
                    icon: Icons.description_outlined,
                    iconColor: const Color(0xFF6B7280),
                    label: AppLocalizations.of(context).kullanimKosullari,
                    description: AppLocalizations.of(context).hizmetSartlariVeSorumluluklar,
                    onTap: () => context.push(AppRoutes.termsOfService),
                  ),
                  SettingsItem(
                    icon: Icons.info_outline,
                    iconColor: const Color(0xFF6B7280),
                    label: AppLocalizations.of(context).hakkinda,
                    description: AppLocalizations.of(context).surum210FamilyhubInc,
                    showValue: 'Güncel',
                    onTap: () => context.push(AppRoutes.aboutApp),
                    isLast: true,
                  ),
                ],
              ),
            ),

            // ── GÖRÜNÜM ─────────────────────────────────────────────
            SliverToBoxAdapter(
              child: SettingsSection(
                title: AppLocalizations.of(context).gorunum1,
                icon: Icons.palette_outlined,
                children: [
                  SettingsItem(
                    icon: Icons.color_lens_outlined,
                    iconColor: const Color(0xFFEC4899),
                    label: 'Aksan Rengi',
                    description: AppLocalizations.of(context).uygulamaVurguRenginiDegistir,
                    showValue: _accentLabel,
                    onTap: () => context.push(AppRoutes.appearanceSettings),
                  ),
                  SettingsItem(
                    icon: Icons.text_fields,
                    iconColor: const Color(0xFF8B5CF6),
                    label: AppLocalizations.of(context).fontSize,
                    description: 'Metin boyutunu ayarla',
                    showValue: _fontLabel,
                    onTap: () => context.push(AppRoutes.appearanceSettings),
                  ),
                  SettingsItem(
                    icon: Icons.dashboard_customize_outlined,
                    iconColor: const Color(0xFF06B6D4),
                    label: 'Ana Ekranı Özelleştir',
                    description: 'Akıllı kart, ipuçları ve kutucuk sırası',
                    onTap: () => context.push(AppRoutes.hubCustomize),
                    isLast: true,
                  ),
                ],
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 32)),

            // ── ÇIKIŞ ──────────────────────────────────────────────
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
                          backgroundColor: const Color(0xFFEF4444).withAlpha(25),
                          foregroundColor: const Color(0xFFEF4444),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(
                              color: const Color(0xFFEF4444).withAlpha(60),
                              width: 0.5,
                            ),
                          ),
                        ),
                        child: Text(AppLocalizations.of(context).logout,
                          style: const TextStyle(
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
                        color: Theme.of(context).colorScheme.onSurface.withAlpha(100),
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

  // ── Dialoglar ────────────────────────────────────────────────────────────

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
            child: Text(AppLocalizations.of(context).ayril, style: const TextStyle(color: Color(0xFFEF4444))),
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
        content: Text(AppLocalizations.of(context).tumVerilerinizKaliciOlarakSilinecekBuIslemGeriAlinamaz,
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
            child: const Text('Sil', style: TextStyle(color: Color(0xFFEF4444))),
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
        content: Text(AppLocalizations.of(context).geciciDosyalarSilinecekUygulamaBirazDahaYavasBaslayabilir,
        ),
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
            child: const Text('Temizle', style: TextStyle(color: Color(0xFF6366F1))),
          ),
        ],
      ),
    );
  }

  // ── Async İşlemler ────────────────────────────────────────────────────────

  Future<int> _getMemberCount() async {
    final local = localFamilyMembers().length;
    final client = SupabaseConfig.safeClient;
    final userId = AuthService.currentUserId;
    if (client == null || userId == null) return local;
    try {
      final fm = await client
          .from('family_members')
          .select('family_id')
          .eq('user_id', userId)
          .maybeSingle();
      final familyId = fm?['family_id'] as String?;
      if (familyId == null) return local;
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
      final total = adultCount.count + childCount.count;
      return total > 0 ? total : local;
    } catch (_) {
      return local;
    }
  }

  Future<void> _leaveFamily() async {
    final client = SupabaseConfig.safeClient;
    final userId = AuthService.currentUserId;
    if (client == null || userId == null) return;
    try {
      await client
          .from('family_members')
          .update({'is_active': false})
          .eq('user_id', userId);
      await AuthService.signOut();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Aileden ayrıldınız.')),
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
      // Hive'ı kapattıktan sonra sil — açık box'ları kapatmadan silmek crash'e neden olur
      await Hive.close();
      await Hive.deleteFromDisk();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tüm veriler silindi.')),
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
      // Sadece uygulama cache dizinini temizle; Hive data'sına dokunma
      final cacheDir = await getTemporaryDirectory();
      if (cacheDir.existsSync()) {
        for (final entity in cacheDir.listSync()) {
          try {
            await entity.delete(recursive: true);
          } catch (_) {}
        }
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Önbellek temizlendi.')),
        );
        // Yeni boyutu yansıt
        setState(() {});
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
      final cacheDir = await getTemporaryDirectory();
      if (!cacheDir.existsSync()) return '0 KB';
      int totalSize = 0;
      await for (final entity in cacheDir.list(recursive: true)) {
        if (entity is File) totalSize += await entity.length();
      }
      if (totalSize < 1024) return '$totalSize B';
      if (totalSize < 1024 * 1024) return '${(totalSize / 1024).toStringAsFixed(0)} KB';
      return '${(totalSize / 1024 / 1024).toStringAsFixed(1)} MB';
    } catch (_) {
      return '0 KB';
    }
  }
}
