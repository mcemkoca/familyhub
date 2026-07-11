import 'package:flutter/material.dart';

import 'package:go_router/go_router.dart';
import 'package:local_auth/local_auth.dart';

import '../../../config/constants.dart';
import '../../../config/routes.dart';
import '../../../core/supabase_client.dart';
import '../../../core/validation/input_validator.dart';
import '../../../services/auth_service.dart';
import '../../../services/biometric_service.dart';
import '../../../services/hive_service.dart';
import '../../widgets/settings/screen_header.dart';
import '../../widgets/settings/settings_section.dart';
import 'package:familyhub/l10n/app_localizations.dart';

class SecuritySettingsScreen extends StatefulWidget {
  const SecuritySettingsScreen({super.key});

  @override
  State<SecuritySettingsScreen> createState() => _SecuritySettingsScreenState();
}

class _SecuritySettingsScreenState extends State<SecuritySettingsScreen> {
  bool _biometricEnabled = false;
  bool _biometricAvailable = false;
  bool _hasPin = false;
  final _localAuth = LocalAuthentication();

  @override
  void initState() {
    super.initState();
    _checkBiometric();
    _loadPinState();
  }

  Future<void> _loadPinState() async {
    final has = await BiometricService.hasPin();
    if (mounted) setState(() => _hasPin = has);
  }

  /// PIN belirleme/değiştirme diyaloğu — salt'lı hash olarak saklanır.
  void _showSetPinDialog() {
    final pinController = TextEditingController();
    final confirmController = TextEditingController();
    bool saving = false;
    final t = AppLocalizations.of(context);

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(_hasPin ? t.pinChange : t.pinSet),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: pinController,
                obscureText: true,
                keyboardType: TextInputType.number,
                maxLength: 6,
                decoration: InputDecoration(
                  labelText: t.pinLabel,
                  prefixIcon: const Icon(Icons.pin_outlined),
                  counterText: '',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: confirmController,
                obscureText: true,
                keyboardType: TextInputType.number,
                maxLength: 6,
                decoration: InputDecoration(
                  labelText: t.pinConfirmLabel,
                  prefixIcon: const Icon(Icons.pin_outlined),
                  counterText: '',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: saving ? null : () => Navigator.pop(dialogContext),
              child: Text(t.cancel),
            ),
            TextButton(
              onPressed: saving
                  ? null
                  : () async {
                      final pin = pinController.text.trim();
                      final confirm = confirmController.text.trim();
                      if (pin.length < 4) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(t.pinTooShort)),
                        );
                        return;
                      }
                      if (pin != confirm) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(t.pinMismatch)),
                        );
                        return;
                      }
                      setDialogState(() => saving = true);
                      final messenger = ScaffoldMessenger.of(context);
                      await BiometricService.registerPin(pin);
                      if (!dialogContext.mounted) return;
                      Navigator.pop(dialogContext);
                      await _loadPinState();
                      messenger.showSnackBar(
                        SnackBar(content: Text(t.pinSaved)),
                      );
                    },
              child: Text(t.save),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _removePin() async {
    final t = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(t.pinRemove),
        content: Text(t.pinRemoveConfirm),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(t.cancel)),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(t.pinRemove,
                  style: const TextStyle(color: AppColors.error))),
        ],
      ),
    );
    if (confirmed != true) return;
    await BiometricService.clearPin();
    await _loadPinState();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).pinRemoved)),
      );
    }
  }

  Future<void> _checkBiometric() async {
    try {
      final available = await _localAuth.canCheckBiometrics &&
          await _localAuth.isDeviceSupported();
      setState(() {
        _biometricAvailable = available;
        _biometricEnabled =
            HiveService.getBoolSetting('biometric_enabled', defaultValue: false);
      });
    } catch (e) { debugPrint('Security settings error: $e'); }
  }

  Future<void> _toggleBiometric(bool enabled) async {
    if (!_biometricAvailable) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).buCihazBiyometrikKimlikDogrulamayiDesteklemiyor)),
      );
      return;
    }

    if (enabled) {
      try {
        final didAuthenticate = await _localAuth.authenticate(
          localizedReason: 'FamilyHub\'a giriş yapmak için kimliğinizi doğrulayın',
        );
        if (!didAuthenticate) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(AppLocalizations.of(context).kimlikDogrulamaBasarisiz)),
            );
          }
          return;
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Biyometrik hata: $e')),
          );
        }
        return;
      }
    }

    setState(() => _biometricEnabled = enabled);
    await HiveService.setBoolSetting('biometric_enabled', enabled);

    final client = SupabaseConfig.safeClient;
    final userId = AuthService.currentUserId;
    if (client != null && userId != null) {
      try {
        await client.from('settings').upsert({
          'user_id': userId,
          'security': {'biometric_enabled': enabled},
        }, onConflict: 'user_id');
      } catch (e) {
        debugPrint('Supabase sync hatası: $e');
      }
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            enabled
                ? 'Biyometrik giriş etkinleştirildi'
                : 'Biyometrik giriş devre dışı bırakıldı',
          ),
        ),
      );
    }
  }

  void _showChangePasswordDialog() {
    final currentController = TextEditingController();
    final newController = TextEditingController();
    final confirmController = TextEditingController();
    bool saving = false;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(AppLocalizations.of(context).sifreDegistir),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: currentController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(context).mevcutSifre,
                    prefixIcon: const Icon(Icons.lock_outline),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: newController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(context).yeniSifre,
                    prefixIcon: const Icon(Icons.lock_outline),
                    helperText: AppLocalizations.of(context).enAz8KarakterBuyukkucukHarfRakamVeOzelKarakter,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: confirmController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Yeni Şifre (Tekrar)',
                    prefixIcon: Icon(Icons.lock_outline),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: saving ? null : () => Navigator.pop(dialogContext),
              child: Text(AppLocalizations.of(context).cancel),
            ),
            TextButton(
              onPressed: saving
                  ? null
                  : () async {
                      final current = currentController.text;
                      final newPass = newController.text;
                      final confirm = confirmController.text;

                      if (current.isEmpty ||
                          newPass.isEmpty ||
                          confirm.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(AppLocalizations.of(context).tumAlanlariDoldurun),
                          ),
                        );
                        return;
                      }

                      final validation = InputValidator.validatePassword(
                        newPass,
                      );
                      if (validation != null) {
                        ScaffoldMessenger.of(
                          context,
                        ).showSnackBar(SnackBar(content: Text(validation)));
                        return;
                      }

                      if (newPass != confirm) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(AppLocalizations.of(context).sifrelerEslesmiyor)),
                        );
                        return;
                      }

                      setDialogState(() => saving = true);
                      try {
                        await AuthService.updatePassword(current, newPass);
                        if (!dialogContext.mounted) return;
                        Navigator.pop(dialogContext);
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(AppLocalizations.of(context).sifrenizguncellendi1),
                          ),
                        );
                      } catch (e) {
                        setDialogState(() => saving = false);
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Hata: ${e.toString().replaceAll('Exception: ', '')}',
                            ),
                            backgroundColor: AppColors.error,
                          ),
                        );
                      }
                    },
              child: saving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(AppLocalizations.of(context).save),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showDeleteAccountDialog() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(AppLocalizations.of(context).hesabiSil,
          style: const TextStyle(color: AppColors.error),
        ),
        content: Text(AppLocalizations.of(context).hesabiniziSilmekGeriAlinamazTumVerilerinizKaliciOlarakSilinecek,
        ),
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
        context.go(AppRoutes.login);
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

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      appBar: ScreenHeader(
        title: AppLocalizations.of(context).safety,
        showBack: true,
        onBack: () => context.pop(),
      ),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: SettingsSection(
              title: AppLocalizations.of(context).sifreYonetimi,
              icon: Icons.password_outlined,
              children: [
                ListTile(
                  leading: const Icon(
                    Icons.lock_reset,
                    color: Color(0xFF6366F1),
                  ),
                  title: Text(AppLocalizations.of(context).sifreDegistir),
                  subtitle: Text(AppLocalizations.of(context).mevcutSifreniziGuncelleyin),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: _showChangePasswordDialog,
                ),
                ListTile(
                  leading: const Icon(
                    Icons.help_outline,
                    color: Color(0xFF10B981),
                  ),
                  title: Text(AppLocalizations.of(context).guvenlikSorulari),
                  subtitle: Text(AppLocalizations.of(context).sifreUnutmaDurumundaKullanilacak2Soru,
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push(AppRoutes.securityQuestionsSetup),
                ),
              ],
            ),
          ),
          SliverToBoxAdapter(
            child: SettingsSection(
              title: AppLocalizations.of(context).pinSection,
              icon: Icons.pin_outlined,
              children: [
                ListTile(
                  leading: const Icon(Icons.pin_outlined,
                      color: Color(0xFF6366F1)),
                  title: Text(_hasPin
                      ? AppLocalizations.of(context).pinChange
                      : AppLocalizations.of(context).pinSet),
                  subtitle:
                      Text(AppLocalizations.of(context).pinSubtitle),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: _showSetPinDialog,
                ),
                if (_hasPin)
                  ListTile(
                    leading: const Icon(Icons.lock_open_outlined,
                        color: AppColors.error),
                    title: Text(AppLocalizations.of(context).pinRemove,
                        style: const TextStyle(color: AppColors.error)),
                    onTap: _removePin,
                  ),
              ],
            ),
          ),
          SliverToBoxAdapter(
            child: SettingsSection(
              title: AppLocalizations.of(context).girisSecenekleri,
              icon: Icons.fingerprint,
              children: [
                SwitchListTile(
                  secondary: const Icon(
                    Icons.fingerprint,
                    color: Color(0xFF10B981),
                  ),
                  title: Text(AppLocalizations.of(context).biyometrikGiris),
                  subtitle: Text(
                    _biometricAvailable
                        ? 'Parmak izi veya yüz tanıma ile giriş'
                        : 'Cihazınız biyometriği desteklemiyor',
                  ),
                  value: _biometricEnabled,
                  activeThumbColor: const Color(0xFF6366F1),
                  onChanged: _biometricAvailable ? _toggleBiometric : null,
                ),
              ],
            ),
          ),
          SliverToBoxAdapter(
            child: SettingsSection(
              title: AppLocalizations.of(context).tehlikeBolgesi,
              icon: Icons.warning_amber_rounded,
              children: [
                ListTile(
                  leading: const Icon(
                    Icons.delete_forever,
                    color: AppColors.error,
                  ),
                  title: Text(AppLocalizations.of(context).hesabiSil,
                    style: const TextStyle(color: AppColors.error),
                  ),
                  subtitle: Text(AppLocalizations.of(context).tumVerilerinizKaliciOlarakSilinecek,
                  ),
                  onTap: _showDeleteAccountDialog,
                ),
              ],
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 32)),
        ],
      ),
    );
  }
}
