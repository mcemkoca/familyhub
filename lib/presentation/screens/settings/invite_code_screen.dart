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
  bool get isDark => Theme.of(context).brightness == Brightness.dark;

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
        // Davet kodu gerçek cross-device özelliği — hesap + bulut aile gerekir.
        throw Exception(
            'Davet kodu için önce hesabınızla giriş yapıp bir aile oluşturun. '
            '(Çevrimdışı modda davet kodu paylaşılamaz.)');
      }

      final fm = await client
          .from('family_members')
          .select('family_id')
          .eq('user_id', userId)
          .maybeSingle();
      final familyId = fm?['family_id'] as String?;
      if (familyId == null) {
        throw Exception(
            'Aile bulunamadı. Ayarlar > Aile Yönetimi\'nden bir aile '
            'oluşturduktan sonra davet kodu üretebilirsiniz.');
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
            content: Text(AppLocalizations.of(context).icCreateFailed('$e')),
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
    const baseUrl = 'https://familyhub.app/join';
    final deepLink = '$baseUrl?code=$_code';
    SharePlus.instance.share(
      ShareParams(
        text: 'FamilyHub\'a katılmak için bağlantıya tıkla:\n$deepLink\n\nYa da kodu manuel gir: $_code',
        subject: 'FamilyHub Aile Daveti',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bg = const Color(0xFF0A0A0F);

    return Scaffold(
      backgroundColor: bg,
      appBar: ScreenHeader(
        title: AppLocalizations.of(context).icTitle,
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
                  color: const Color(0xFF10B981).withAlpha(30),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Icon(
                  Icons.person_add_alt,
                  size: 36,
                  color: Color(0xFF10B981),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Aileye Davet Et',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFE5E7EB),
                ),
              ),
              const SizedBox(height: 8),
              Text(AppLocalizations.of(context).yeniUyeleriDavetEtmekIcinBirKodOlusturunKod24SaatGecerlidir,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF6B7280),
                ),
              ),
              const SizedBox(height: 24),
              // Role selector
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: const Color(0xFF13131A),
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
                                ? (const Color(0xFF0A0A0F))
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
                                color: _role == 'parent' ? const Color(0xFF6366F1) : const Color(0xFF6B7280),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Ebeveyn',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: _role == 'parent'
                                      ? const Color(0xFF6366F1)
                                      : (const Color(0xFF6B7280)),
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
                                ? (const Color(0xFF0A0A0F))
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
                                color: _role == 'child' ? const Color(0xFFEC4899) : const Color(0xFF6B7280),
                              ),
                              const SizedBox(width: 6),
                              Text(AppLocalizations.of(context).child,
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: _role == 'child'
                                      ? const Color(0xFFEC4899)
                                      : (const Color(0xFF6B7280)),
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
                    color: const Color(0xFF13131A),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark
                          ? const Color(0x1EFFFFFF)
                          : const Color(0x1EFFFFFF),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _code!,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2,
                          color: Color(0xFFE5E7EB),
                        ),
                      ),
                      const SizedBox(width: 16),
                      IconButton(
                        onPressed: _copyCode,
                        icon: const Icon(Icons.copy, color: Color(0xFF6366F1)),
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
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Color(0xFFE5E7EB),
                          ),
                        )
                      : const Icon(Icons.refresh),
                  label: Text(_code == null ? 'Kod Oluştur' : 'Yeni Kod Oluştur'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6366F1),
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
                      foregroundColor: const Color(0xFF6366F1),
                      side: const BorderSide(color: Color(0xFF6366F1)),
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
