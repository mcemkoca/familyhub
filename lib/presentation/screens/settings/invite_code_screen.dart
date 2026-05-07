import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import '../../../config/constants.dart';
import '../../../core/supabase_client.dart';
import '../../../services/auth_service.dart';
import '../../widgets/settings/screen_header.dart';
import 'package:go_router/go_router.dart';
import 'package:familyhub/l10n/app_localizations.dart';

class InviteCodeScreen extends StatefulWidget {
  const InviteCodeScreen({super.key});

  @override
  State<InviteCodeScreen> createState() => _InviteCodeScreenState();
}

class _InviteCodeScreenState extends State<InviteCodeScreen> {
  String? _code;
  bool _generating = false;
  String _role = 'parent'; // 'parent' or 'child'

  Future<void> _generateCode() async {
    HapticFeedback.mediumImpact();
    setState(() => _generating = true);
    try {
      final client = SupabaseConfig.safeClient;
      final userId = AuthService.currentUserId;
      if (client == null || userId == null) {
        throw Exception('Oturum açık değil');
      }

      final fm = await client
          .from('family_members')
          .select('family_id')
          .eq('user_id', userId)
          .maybeSingle();
      final familyId = fm?['family_id'] as String?;
      if (familyId == null) {
        throw Exception('Aile bulunamadı');
      }

      final code = await client.rpc(
        'generate_invite_code',
        params: {'family_id': familyId, 'role': _role},
      ) as String;

      if (mounted) {
        setState(() {
          _code = code;
          _generating = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _generating = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Davet kodu oluşturulamadı: $e'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _copyCode() {
    if (_code == null) return;
    Clipboard.setData(ClipboardData(text: _code!));
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppLocalizations.of(context).kodKopyalandi),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _shareCode() {
    if (_code == null) return;
    SharePlus.instance.share(
      ShareParams(
        text: 'FamilyHub\'a katıl! Davet kodun: $_code',
        subject: 'FamilyHub Davet Kodu',
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
        title: 'Davet Kodu',
        showBack: true,
        onBack: () => context.pop(),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppColors.success.withAlpha(isDark ? 30 : 20),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Icon(
                  Icons.person_add_alt,
                  size: 36,
                  color: AppColors.success,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Aileye Davet Et',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: isDark ? AppColors.darkTextPrimary : AppColors.dark,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Yeni üyeleri davet etmek için bir kod oluşturun. Kod 24 saat geçerlidir.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.slate,
                ),
              ),
              const SizedBox(height: 24),
              // Role selector
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkCard : const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _role = 'parent'),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: _role == 'parent'
                                ? (isDark ? AppColors.darkBackground : Colors.white)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: _role == 'parent'
                                ? [BoxShadow(color: Colors.black.withAlpha(10), blurRadius: 4, offset: const Offset(0, 2))]
                                : null,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.admin_panel_settings_outlined,
                                size: 18,
                                color: _role == 'parent' ? AppColors.cobalt : AppColors.gray,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Ebeveyn',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: _role == 'parent'
                                      ? AppColors.cobalt
                                      : (isDark ? AppColors.darkTextSecondary : AppColors.gray),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _role = 'child'),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: _role == 'child'
                                ? (isDark ? AppColors.darkBackground : Colors.white)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: _role == 'child'
                                ? [BoxShadow(color: Colors.black.withAlpha(10), blurRadius: 4, offset: const Offset(0, 2))]
                                : null,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.child_care_outlined,
                                size: 18,
                                color: _role == 'child' ? AppColors.pink : AppColors.gray,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Çocuk',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: _role == 'child'
                                      ? AppColors.pink
                                      : (isDark ? AppColors.darkTextSecondary : AppColors.gray),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              if (_code != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkCard : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark
                          ? AppColors.darkBorder
                          : AppColors.border,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _code!,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2,
                          color: isDark
                              ? AppColors.darkTextPrimary
                              : AppColors.dark,
                        ),
                      ),
                      const SizedBox(width: 16),
                      IconButton(
                        onPressed: _copyCode,
                        icon: const Icon(Icons.copy, color: AppColors.cobalt),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: _generating ? null : _generateCode,
                  icon: _generating
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: isDark ? AppColors.dark : Colors.white,
                          ),
                        )
                      : const Icon(Icons.refresh),
                  label: Text(_code == null ? 'Kod Oluştur' : 'Yeni Kod Oluştur'),
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
              if (_code != null) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: OutlinedButton.icon(
                    onPressed: _shareCode,
                    icon: const Icon(Icons.share),
                    label: Text(AppLocalizations.of(context).share),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.cobalt,
                      side: const BorderSide(color: AppColors.cobalt),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
