import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../../config/constants.dart';
import '../../../domain/models/drive_backup_model.dart';
import '../../../services/google_drive_service.dart';

import '../../widgets/settings/screen_header.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../widgets/settings/settings_section.dart';
import '../../widgets/settings/hive_settings_toggle.dart';
import 'package:go_router/go_router.dart';
import 'package:familyhub/l10n/app_localizations.dart';

class BackupSettingsScreen extends StatefulWidget {
  const BackupSettingsScreen({super.key});

  @override
  State<BackupSettingsScreen> createState() => _BackupSettingsScreenState();
}

class _BackupSettingsScreenState extends State<BackupSettingsScreen> {
  bool _backingUp = false;
  bool _restoring = false;

  bool _isSignedIn = false;
  GoogleSignInAccount? _account;
  List<DriveBackup> _backups = [];

  @override
  void initState() {
    super.initState();
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    try {
      final signedIn = await GoogleDriveService().isSignedIn();
      if (signedIn) {
        _account = GoogleDriveService().currentUser;
        await _loadBackups();
      }
      if (mounted) setState(() => _isSignedIn = signedIn);
    } catch (e) { debugPrint('Backup settings error: $e'); }
  }

  Future<void> _signIn() async {
    HapticFeedback.mediumImpact();
    try {
      final account = await GoogleDriveService().signIn();
      if (account != null && mounted) {
        setState(() {
          _isSignedIn = true;
          _account = account;
        });
        await _loadBackups();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Giriş hatası: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  Future<void> _signOut() async {
    try {
      await GoogleDriveService().signOut();
      if (mounted) {
        setState(() {
          _isSignedIn = false;
          _account = null;
          _backups = [];
        });
      }
    } catch (e) { debugPrint('Backup settings error: $e'); }
  }

  Future<void> _loadBackups() async {
    try {
      final backups = await GoogleDriveService().listBackups();
      if (mounted) setState(() => _backups = backups);
    } catch (e) { debugPrint('Backup settings error: $e'); }
  }

  Future<void> _triggerBackup() async {
    HapticFeedback.mediumImpact();
    setState(() => _backingUp = true);
    try {
      await GoogleDriveService().uploadBackup();
      await _loadBackups();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context).yedeklemeTamamlandi),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Yedekleme hatası: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _backingUp = false);
    }
  }

  Future<void> _triggerRestore(DriveBackup backup) async {
    HapticFeedback.mediumImpact();
    setState(() => _restoring = true);
    try {
      await GoogleDriveService().restoreBackup(backup.fileId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context).verilerGeriYuklendi),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Geri yükleme hatası: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _restoring = false);
    }
  }

  Future<void> _showRestoreDialog() async {
    if (!_isSignedIn) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).onceGoogleDriveHesabiniziBaglayin),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    await _loadBackups();
    if (!mounted) return;

    if (_backups.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).geriYuklenecekYedekBulunamadi)),
      );
      return;
    }

    await showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(AppLocalizations.of(context).geriYukle),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: _backups.length,
            itemBuilder: (context, index) {
              final b = _backups[index];
              return ListTile(
                title: Text(b.formattedDate),
                subtitle: Text(b.formattedSize),
                onTap: () {
                  Navigator.pop(dialogContext);
                  _triggerRestore(b);
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(AppLocalizations.of(context).close),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkBackground : AppColors.cloudWhite;

    return Scaffold(
      backgroundColor: bg,
      appBar: ScreenHeader(
        title: 'Yedekleme Ayarları',
        showBack: true,
        onBack: () => context.pop(),
      ),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // Google Account Card
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF4285F4),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white.withAlpha(20),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: SvgPicture.asset(
                            'assets/images/google_drive_logo.svg',
                            width: 32,
                            height: 32,
                            colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Google Drive',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _isSignedIn && _account != null
                                    ? _account!.email
                                    : 'Hesap Bağlı Değil',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (!_isSignedIn)
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton.icon(
                          onPressed: _signIn,
                          icon: const Icon(Icons.login, color: Color(0xFF4285F4)),
                          label: const Text(
                            'Google Hesabı Bağla',
                            style: TextStyle(color: Color(0xFF4285F4)),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      )
                    else
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: OutlinedButton.icon(
                          onPressed: _signOut,
                          icon: const Icon(Icons.logout, color: Colors.white),
                          label: const Text(
                            'Bağlantıyı Kes',
                            style: TextStyle(color: Colors.white),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.white70),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          const SliverToBoxAdapter(
            child: SettingsSection(
              title: 'AYARLAR',
              icon: Icons.settings_outlined,
              children: [
                HiveSettingsToggle(
                  settingsKey: 'auto_backup_enabled',
                  title: 'Otomatik Yedekleme',
                  subtitle: 'Her hafta otomatik yedekle',
                  defaultValue: false,
                ),
              ],
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: _backingUp || !_isSignedIn ? null : _triggerBackup,
                  icon: _backingUp
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: isDark ? AppColors.dark : Colors.white,
                          ),
                        )
                      : const Icon(Icons.cloud_upload),
                  label: Text(_backingUp ? 'Yedekleniyor...' : 'Şimdi Yedekle'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.cobalt,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: OutlinedButton.icon(
                  onPressed: _showRestoreDialog,
                  icon: _restoring
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.orange,
                          ),
                        )
                      : const Icon(Icons.restore, color: Colors.orange),
                  label: Text(
                    _restoring ? 'Yükleniyor...' : 'Geri Yükle',
                    style: const TextStyle(color: Colors.orange),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.orange),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 32)),
        ],
      ),
    );
  }
}
