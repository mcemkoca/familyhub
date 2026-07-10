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
  bool get isDark => Theme.of(context).brightness == Brightness.dark;

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
      // RLS politikası ilk klasörün kullanıcı id'sine eşit olmasını ister
      // (storage.foldername(name)[1] = auth.uid). Bu yüzden "<userId>/avatar.ext".
      final fileName = '$userId/avatar.$fileExt';

      await client.storage
          .from('avatars')
          .upload(fileName, file, fileOptions: const FileOptions(upsert: true));

      // Cache-bust için sürüm parametresi ekle (aynı yol upsert edildiğinden).
      final publicUrl =
          '${client.storage.from('avatars').getPublicUrl(fileName)}?v=${DateTime.now().millisecondsSinceEpoch}';
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
              Text(AppLocalizations.of(context).epostaDegisikligiIcinOnayBaglantisiGonderilecektir,
                style: const TextStyle(fontSize: 13),
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
                          SnackBar(
                            content: Text(AppLocalizations.of(context).onayBaglantisiYeniEpostaAdresinizeGonderildi,
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
    final bg = const Color(0xFF0A0A0F);

    if (_isLoading) {
      return Scaffold(
        backgroundColor: bg,
        appBar: ScreenHeader(
          title: AppLocalizations.of(context).profiliDuzenle,
          showBack: true,
          onBack: () => context.pop(),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: bg,
      appBar: ScreenHeader(
        title: AppLocalizations.of(context).profiliDuzenle,
        showBack: true,
        onBack: () => context.pop(),
        rightAction: TextButton(
          onPressed: _saving || _nameController.text.trim().isEmpty
              ? null
              : _save,
          child: _saving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Color(0xFF6366F1),
                  ),
                )
              : Text(
                  'Kaydet',
                  style: TextStyle(
                    color: _nameController.text.trim().isEmpty
                        ? const Color(0xFF9CA3AF)
                        : const Color(0xFF6366F1),
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
                            color: _avatarUrl == null ? const Color(0xFF6366F1) : null,
                            borderRadius: BorderRadius.circular(32),
                            border: Border.all(
                              color: const Color(0xFF13131A),
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
                              color: const Color(0xFF6366F1),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: const Color(0xFFE5E7EB),
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
                  title: AppLocalizations.of(context).kisiselBilgiler,
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
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Color(0xFF6B7280),
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
                    ? const Color(0xFF6B7280)
                    : const Color(0xFF9CA3AF),
              ),
              prefixIcon: Icon(
                icon,
                size: 20,
                color: const Color(0xFF6B7280),
              ),
              suffixIcon: suffix,
              filled: true,
              fillColor: const Color(0xFF13131A),
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
                  ? (const Color(0xFFE5E7EB))
                  : const Color(0xFF9CA3AF),
            ),
          ),
        ],
      ),
    );
  }
}
