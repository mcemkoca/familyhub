import 'package:flutter/material.dart';
import 'package:familyhub/l10n/app_localizations.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../services/auth_service.dart';
import '../../../services/invite_service.dart';
import '../../widgets/settings/screen_header.dart';

/// Deep-link landing screen for `/join?code=XXXXXX`.
///
/// Opened automatically when the user taps an invite link like:
///   https://familyhub.app/join?code=XXXXXX
/// Can also be navigated to manually from the onboarding "Aileye Katıl" step.
class JoinFamilyScreen extends StatefulWidget {
  /// Pre-filled invite code from deep link query param (may be null).
  final String? initialCode;

  const JoinFamilyScreen({super.key, this.initialCode});

  @override
  State<JoinFamilyScreen> createState() => _JoinFamilyScreenState();
}

class _JoinFamilyScreenState extends State<JoinFamilyScreen> {
  late final TextEditingController _codeCtrl;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _codeCtrl = TextEditingController(text: widget.initialCode ?? '');
    // Auto-join if code was passed via deep link
    if ((widget.initialCode ?? '').isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _join());
    }
  }

  @override
  void dispose() {
    _codeCtrl.dispose();
    super.dispose();
  }

  Future<void> _join() async {
    final code = _codeCtrl.text.trim().toUpperCase();
    if (code.isEmpty) {
      setState(() => _error = 'Lütfen bir davet kodu girin.');
      return;
    }

    final userId = AuthService.currentUserId;
    if (userId == null) {
      setState(() => _error = 'Önce giriş yapmalısınız.');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final svc = InviteService.create();
      await svc.joinFamilyByCode(code, userId);
      if (!mounted) return;
      HapticFeedback.mediumImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Aileye başarıyla katıldınız!'),
          backgroundColor: Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
        ),
      );
      // Return to hub
      context.go('/hub');
    } on FormatException catch (e) {
      setState(() {
        _loading = false;
        _error = e.message;
      });
    } catch (e) {
      setState(() {
        _loading = false;
        _error = 'Beklenmeyen hata: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      appBar: ScreenHeader(title: AppLocalizations.of(context).aileyeKatil, showBack: true, onBack: () => context.pop()),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icon
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6366F1), Color(0xFFEC4899)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Icon(Icons.group_add_outlined, size: 40, color: Colors.white),
              ),
              const SizedBox(height: 24),
              const Text(
                'Davet Kodunuzu Girin',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFFE5E7EB)),
              ),
              const SizedBox(height: 8),
              const Text(
                'Aile üyenizin size gönderdiği 6-8 karakterli kodu girin.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Color(0xFF6B7280), height: 1.5),
              ),
              const SizedBox(height: 32),
              // Code input
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF13131A),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _error != null
                        ? const Color(0xFFEF4444)
                        : const Color(0x1EFFFFFF),
                    width: 1,
                  ),
                ),
                child: TextField(
                  controller: _codeCtrl,
                  textAlign: TextAlign.center,
                  textCapitalization: TextCapitalization.characters,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFE5E7EB),
                    letterSpacing: 8,
                  ),
                  decoration: const InputDecoration(
                    hintText: 'XXXXXX',
                    hintStyle: TextStyle(
                      fontSize: 28,
                      color: Color(0xFF374151),
                      letterSpacing: 8,
                    ),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 20),
                  ),
                  onSubmitted: (_) => _join(),
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.error_outline, size: 16, color: Color(0xFFEF4444)),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        _error!,
                        style: const TextStyle(fontSize: 13, color: Color(0xFFEF4444)),
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 24),
              // Join button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: _loading
                        ? null
                        : const LinearGradient(
                            colors: [Color(0xFF6366F1), Color(0xFFEC4899)],
                          ),
                    color: _loading ? const Color(0xFF374151) : null,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: TextButton(
                    onPressed: _loading ? null : _join,
                    child: _loading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation(Colors.white),
                            ),
                          )
                        : Text(AppLocalizations.of(context).aileyeKatil,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
