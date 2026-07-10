import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../../config/constants.dart';
import '../../../domain/models/drive_backup_model.dart';
import '../../../services/google_drive_service.dart';
import '../../../services/hive_service.dart';
import '../../widgets/settings/screen_header.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:familyhub/l10n/app_localizations.dart';

class CloudBackupScreen extends StatefulWidget {
  const CloudBackupScreen({super.key});

  @override
  State<CloudBackupScreen> createState() => _CloudBackupScreenState();
}

class _CloudBackupScreenState extends State<CloudBackupScreen> {
  bool get isDark => Theme.of(context).brightness == Brightness.dark;

  bool _isSignedIn = false;
  bool _checkingAuth = true;
  bool _backingUp = false;
  bool _restoring = false;
  bool _loadingBackups = false;
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
      if (mounted) {
        setState(() {
          _isSignedIn = signedIn;
          _checkingAuth = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _checkingAuth = false);
    }
  }

  Future<void> _signIn() async {
    HapticFeedback.mediumImpact();
    setState(() => _checkingAuth = true);
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
          SnackBar(
            content: Text('Giriş hatası: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _checkingAuth = false);
    }
  }

  Future<void> _signOut() async {
    HapticFeedback.mediumImpact();
    try {
      await GoogleDriveService().signOut();
      if (mounted) {
        setState(() {
          _isSignedIn = false;
          _account = null;
          _backups = [];
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context).googleDriveBaglantisiKesildi)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Bağlantı kesme hatası: $e')),
        );
      }
    }
  }

  Future<void> _loadBackups() async {
    setState(() => _loadingBackups = true);
    try {
      final backups = await GoogleDriveService().listBackups();
      if (mounted) setState(() => _backups = backups);
    } catch (e) {
      debugPrint('Yedek listesi hatası: $e');
    } finally {
      if (mounted) setState(() => _loadingBackups = false);
    }
  }

  Future<void> _triggerBackup() async {
    HapticFeedback.mediumImpact();
    setState(() => _backingUp = true);
    try {
      final backup = await GoogleDriveService().uploadBackup();
      await _loadBackups();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Yedekleme tamamlandı: ${backup.formattedDate}'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Yedekleme hatası: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _backingUp = false);
    }
  }

  Future<void> _triggerRestore(DriveBackup backup) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(AppLocalizations.of(context).geriYukle),
        content: Text(
          '${backup.formattedDate} tarihli yedeği geri yüklemek istiyor musunuz?\n\nMevcut verileriniz üzerine yazılacak.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: Text(AppLocalizations.of(context).cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(c, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: Text(AppLocalizations.of(context).geriYukle),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

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

  Future<void> _deleteBackup(DriveBackup backup) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(AppLocalizations.of(context).yedegiSil),
        content: Text('${backup.formattedDate} tarihli yedeği Google Drive\'dan silmek istiyor musunuz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: Text(AppLocalizations.of(context).cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(c, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: Text(AppLocalizations.of(context).delete),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await GoogleDriveService().deleteBackup(backup.fileId);
      await _loadBackups();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Yedek silindi')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Silme hatası: $e')),
        );
      }
    }
  }

  Widget _buildSignedOutState(BuildContext context, bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: const Color(0xFF4285F4).withAlpha(30),
              borderRadius: BorderRadius.circular(24),
            ),
            child: SvgPicture.asset(
              'assets/images/google_drive_logo.svg',
              width: 48,
              height: 48,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Google Drive Yedekleme',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Color(0xFFE5E7EB),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Verilerinizi güvenle Google Drive hesabınıza yedekleyin. Aileden ayrılsanız bile verilerinize erişebilirsiniz.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF6B7280),
            ),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton.icon(
              onPressed: _checkingAuth ? null : _signIn,
              icon: _checkingAuth
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.login),
              label: Text(AppLocalizations.of(context).googleHesabiBagla,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4285F4),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Yedekleme işlemi sadece sizin erişebileceğiniz Google Drive hesabınıza yapılır. FamilyHub sunucularında tutulmaz.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: Color(0xFF6B7280),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSignedInState(BuildContext context, bool isDark) {
    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        // Google Account Card
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF13131A),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: const Color(0x1EFFFFFF),
                ),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundImage: _account?.photoUrl != null
                            ? NetworkImage(_account!.photoUrl!)
                            : null,
                        backgroundColor: const Color(0xFF4285F4).withAlpha(20),
                        child: _account?.photoUrl == null
                            ? const Icon(Icons.person, color: Color(0xFF4285F4))
                            : null,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _account?.displayName ?? 'Kullanıcı',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFFE5E7EB),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _account?.email ?? '',
                              style: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFF10B981),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.verified, color: Color(0xFF10B981), size: 20),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextButton.icon(
                    onPressed: _signOut,
                    icon: const Icon(Icons.logout, size: 18),
                    label: Text(AppLocalizations.of(context).baglantiyiKes),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.error,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        // Actions
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _backingUp ? null : _triggerBackup,
                    icon: _backingUp
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.backup),
                    label: Text(_backingUp ? 'Yedekleniyor...' : 'Şimdi Yedekle'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4285F4),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 14),
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
        const SliverToBoxAdapter(child: SizedBox(height: 24)),
        // Auto backup toggle
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF13131A),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0x1EFFFFFF),
                ),
              ),
              child: Row(
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Otomatik Yedekleme',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFFE5E7EB),
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Her hafta otomatik olarak Google Drive\'a yedekle',
                          style: TextStyle(
                            fontSize: 13,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: HiveService.getBoolSetting('gdrive_auto_backup', defaultValue: false),
                    onChanged: (v) async {
                      await HiveService.setBoolSetting('gdrive_auto_backup', v);
                      setState(() {});
                    },
                    activeTrackColor: const Color(0xFF6366F1),
                    activeThumbColor: Colors.white,
                  ),
                ],
              ),
            ),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 24)),
        // Backup history
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text(AppLocalizations.of(context).yedeklemeGecmisi,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Color(0xFF6B7280),
                letterSpacing: 0.5,
              ),
            ),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 12)),
        if (_loadingBackups)
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: Center(child: CircularProgressIndicator()),
            ),
          )
        else if (_backups.isEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.cloud_off, size: 48, color: Colors.grey),
                    SizedBox(height: 12),
                    Text(AppLocalizations.of(context).henuzYedeklemeYok,
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                    SizedBox(height: 8),
                    Text(AppLocalizations.of(context).simdiYedekleButonunaBasarakBaslayabilirsiniz,
                      style: TextStyle(fontSize: 13, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),
          )
        else
          SliverList.builder(
            itemCount: _backups.length,
            itemBuilder: (context, index) {
              final b = _backups[index];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF13131A),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0x1EFFFFFF),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: const Color(0xFF4285F4).withAlpha(15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.cloud_done,
                          color: Color(0xFF4285F4),
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              b.formattedDate,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFFE5E7EB),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${b.formattedSize} · Google Drive',
                              style: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFF6B7280),
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.delete_outline,
                          color: Colors.red,
                          size: 20,
                        ),
                        onPressed: () => _deleteBackup(b),
                      ),
                      TextButton(
                        onPressed: _restoring ? null : () => _triggerRestore(b),
                        child: _restoring
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : Text(AppLocalizations.of(context).geriYukle),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        const SliverToBoxAdapter(child: SizedBox(height: 32)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      appBar: ScreenHeader(
        title: 'Google Drive Yedekleme',
        showBack: true,
        onBack: () => context.pop(),
      ),
      body: _checkingAuth
          ? const Center(child: CircularProgressIndicator())
          : _isSignedIn
              ? _buildSignedInState(context, isDark)
              : _buildSignedOutState(context, isDark),
    );
  }
}
