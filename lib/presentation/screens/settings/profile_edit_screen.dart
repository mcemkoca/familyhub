import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../config/constants.dart';
import '../../../core/validation/input_validator.dart';
import '../../../services/auth_service.dart';
import '../../../core/supabase_client.dart';
import '../../widgets/settings/screen_header.dart';
import '../../widgets/settings/settings_section.dart';
import 'package:go_router/go_router.dart';
import 'package:familyhub/l10n/app_localizations.dart';

class ProfileEditScreen extends ConsumerStatefulWidget {
  const ProfileEditScreen({super.key});

  @override
  ConsumerState<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends ConsumerState<ProfileEditScreen> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  String? _avatarUrl;
  bool _saving = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final userId = AuthService.currentUserId;
      if (userId == null) {
        setState(() => _isLoading = false);
        return;
      }

      final client = SupabaseConfig.safeClient;
      if (client == null) {
        setState(() => _isLoading = false);
        return;
      }

      final response = await client
          .from('profiles')
          .select('*')
          .eq('id', userId)
          .maybeSingle();

      if (response != null) {
        _nameController.text = response['display_name']?.toString() ?? '';
        _phoneController.text = response['phone']?.toString() ?? '';
        _emailController.text =
            response['email']?.toString() ??
            AuthService.currentUser?.email ??
            '';
        _avatarUrl = response['avatar_url']?.toString();
      } else {
        _emailController.text = AuthService.currentUser?.email ?? '';
      }
    } catch (e) {
      debugPrint('Profile load error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _pickAvatar() async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
      );
      if (picked == null) return;

      setState(() => _saving = true);

      final file = File(picked.path);
      final userId = AuthService.currentUserId;
      if (userId == null) return;

      final client = SupabaseConfig.safeClient;
      if (client == null) return;

      final fileExt = picked.path.split('.').last;
      final fileName = '$userId.$fileExt';

      await client.storage
          .from('avatars')
          .upload(fileName, file, fileOptions: const FileOptions(upsert: true));

      final publicUrl = client.storage.from('avatars').getPublicUrl(fileName);
      setState(() => _avatarUrl = publicUrl);

      await AuthService.updateProfile(avatarUrl: publicUrl);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context).profilFotografiGuncellendi)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fotoğraf yüklenemedi: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      setState(() => _saving = false);
    }
  }

  Future<void> _save() async {
    HapticFeedback.mediumImpact();

    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();

    final nameError = InputValidator.validateName(name);
    if (nameError != null) {
      _showError(nameError);
      return;
    }

    if (phone.isNotEmpty) {
      final phoneError = InputValidator.validatePhone(phone);
      if (phoneError != null) {
        _showError(phoneError);
        return;
      }
    }

    final normalizedPhone = phone.isNotEmpty ? InputValidator.normalizePhone(phone) : null;

    setState(() => _saving = true);

    try {
      await AuthService.updateProfile(
        displayName: name,
        phone: normalizedPhone,
        avatarUrl: _avatarUrl,
      );

      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profil bilgileri kaydedildi')),
        );
        if (context.mounted) context.pop();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        _showError(e.toString().replaceAll('Exception: ', ''));
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.error),
    );
  }

  void _showChangeEmailDialog() {
    final controller = TextEditingController(text: _emailController.text);
    bool saving = false;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(AppLocalizations.of(context).epostaDegistir),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'E-posta değişikliği için onay bağlantısı gönderilecektir.',
                style: TextStyle(fontSize: 13),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Yeni E-posta',
                  prefixIcon: Icon(Icons.email_outlined),
                ),
              ),
            ],
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
                      final email = controller.text.trim();
                      final error = InputValidator.validateEmail(email);
                      if (error != null) {
                        ScaffoldMessenger.of(
                          context,
                        ).showSnackBar(SnackBar(content: Text(error)));
                        return;
                      }

                      setDialogState(() => saving = true);
                      try {
                        final supabase = SupabaseConfig.safeClient;
                        if (supabase == null) throw Exception('Bağlantı yok');
                        await supabase.auth.updateUser(
                          UserAttributes(email: email),
                        );
                        if (!dialogContext.mounted) return;
                        Navigator.pop(dialogContext);
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Onay bağlantısı yeni e-posta adresinize gönderildi',
                            ),
                          ),
                        );
                      } catch (e) {
                        setDialogState(() => saving = false);
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Hata: $e'),
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
                  : Text(AppLocalizations.of(context).send),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkBackground : AppColors.cloudWhite;

    if (_isLoading) {
      return Scaffold(
        backgroundColor: bg,
        appBar: ScreenHeader(
          title: 'Profili Düzenle',
          showBack: true,
          onBack: () => context.pop(),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: bg,
      appBar: ScreenHeader(
        title: 'Profili Düzenle',
        showBack: true,
        onBack: () => context.pop(),
        rightAction: TextButton(
          onPressed: _saving || _nameController.text.trim().isEmpty
              ? null
              : _save,
          child: _saving
              ? SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.cobalt,
                  ),
                )
              : Text(
                  'Kaydet',
                  style: TextStyle(
                    color: _nameController.text.trim().isEmpty
                        ? AppColors.lightGray
                        : AppColors.cobalt,
                    fontWeight: FontWeight.w600,
                  ),
                ),
        ),
      ),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: Column(
              children: [
                const SizedBox(height: 24),
                // Avatar
                Center(
                  child: GestureDetector(
                    onTap: _pickAvatar,
                    child: Stack(
                      children: [
                        Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            color: _avatarUrl == null ? AppColors.cobalt : null,
                            borderRadius: BorderRadius.circular(32),
                            border: Border.all(
                              color: isDark ? AppColors.darkCard : Colors.white,
                              width: 4,
                            ),
                            image: _avatarUrl != null
                                ? DecorationImage(
                                    image: NetworkImage(_avatarUrl!),
                                    fit: BoxFit.cover,
                                  )
                                : null,
                          ),
                          child: _avatarUrl == null
                              ? Center(
                                  child: Text(
                                    _nameController.text.isNotEmpty
                                        ? _nameController.text[0].toUpperCase()
                                        : 'U',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 36,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                )
                              : null,
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: AppColors.cobalt,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: isDark
                                    ? AppColors.darkCard
                                    : Colors.white,
                                width: 2,
                              ),
                            ),
                            child: const Icon(
                              Icons.camera_alt,
                              size: 16,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                // Form
                SettingsSection(
                  title: 'KİŞİSEL BİLGİLER',
                  icon: Icons.person_outline,
                  children: [
                    _buildInput(
                      label: 'Ad Soyad',
                      controller: _nameController,
                      hint: 'Adınızı girin',
                      icon: Icons.person_outline,
                      onChanged: () => setState(() {}),
                    ),
                    _buildInput(
                      label: 'Telefon',
                      controller: _phoneController,
                      hint: 'Telefon numarası',
                      icon: Icons.phone_outlined,
                      keyboardType: TextInputType.phone,
                    ),
                    _buildInput(
                      label: 'E-posta',
                      controller: _emailController,
                      icon: Icons.email_outlined,
                      enabled: false,
                      suffix: TextButton(
                        onPressed: _showChangeEmailDialog,
                        child: Text(AppLocalizations.of(context).degistir),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInput({
    required String label,
    TextEditingController? controller,
    String? hint,
    required IconData icon,
    TextInputType? keyboardType,
    bool enabled = true,
    Widget? suffix,
    VoidCallback? onChanged,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: isDark ? AppColors.darkTextSecondary : AppColors.slate,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: controller,
            keyboardType: keyboardType,
            enabled: enabled,
            onChanged: (_) => onChanged?.call(),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.lightGray,
              ),
              prefixIcon: Icon(
                icon,
                size: 20,
                color: isDark ? AppColors.darkTextSecondary : AppColors.slate,
              ),
              suffixIcon: suffix,
              filled: true,
              fillColor: isDark ? AppColors.darkCard : const Color(0xFFF8FAFC),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
            ),
            style: TextStyle(
              color: enabled
                  ? (isDark ? AppColors.darkTextPrimary : AppColors.dark)
                  : AppColors.lightGray,
            ),
          ),
        ],
      ),
    );
  }
}
