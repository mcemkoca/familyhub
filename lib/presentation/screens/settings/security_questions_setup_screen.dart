import 'package:flutter/material.dart';
import 'package:familyhub/l10n/app_localizations.dart';
import 'package:flutter/services.dart';
import '../../../config/constants.dart';
import '../../../services/auth_service.dart';
import '../../widgets/settings/screen_header.dart';
import 'package:go_router/go_router.dart';

class SecurityQuestionsSetupScreen extends StatefulWidget {
  const SecurityQuestionsSetupScreen({super.key});

  @override
  State<SecurityQuestionsSetupScreen> createState() => _SecurityQuestionsSetupScreenState();
}

class _SecurityQuestionsSetupScreenState extends State<SecurityQuestionsSetupScreen> {
  bool get isDark => Theme.of(context).brightness == Brightness.dark;

  bool _isLoading = false;
  bool _hasExisting = false;

  String? _selectedQuestion1;
  String? _selectedQuestion2;
  final _answer1Controller = TextEditingController();
  final _answer2Controller = TextEditingController();
  final _customQuestion1Controller = TextEditingController();
  final _customQuestion2Controller = TextEditingController();

  static const List<String> _presetQuestions = [
    'İlk evcil hayvanınızın adı nedir?',
    'Anne kızlık soyadı nedir?',
    'En sevdiğiniz çocukluk arkadaşınızın adı nedir?',
    'İlkokul öğretmeninizin adı nedir?',
    'En sevdiğiniz kitabın adı nedir?',
    'Doğduğunuz şehir nedir?',
    'En sevdiğiniz yemek nedir?',
    'Babanızın orta adı nedir?',
  ];

  @override
  void initState() {
    super.initState();
    _loadExisting();
  }

  Future<void> _loadExisting() async {
    setState(() => _isLoading = true);
    try {
      final data = await AuthService.getMySecurityQuestions();
      if (data != null) {
        setState(() {
          _hasExisting = true;
          _selectedQuestion1 = data['security_question_1'] as String?;
          _selectedQuestion2 = data['security_question_2'] as String?;
          if (_selectedQuestion1 != null && !_presetQuestions.contains(_selectedQuestion1)) {
            _customQuestion1Controller.text = _selectedQuestion1!;
            _selectedQuestion1 = 'Özel soru...';
          }
          if (_selectedQuestion2 != null && !_presetQuestions.contains(_selectedQuestion2)) {
            _customQuestion2Controller.text = _selectedQuestion2!;
            _selectedQuestion2 = 'Özel soru...';
          }
        });
      }
    } catch (e) {
      debugPrint('Load security questions failed: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _save() async {
    HapticFeedback.mediumImpact();

    final q1 = _selectedQuestion1 == 'Özel soru...'
        ? _customQuestion1Controller.text.trim()
        : _selectedQuestion1;
    final q2 = _selectedQuestion2 == 'Özel soru...'
        ? _customQuestion2Controller.text.trim()
        : _selectedQuestion2;
    final a1 = _answer1Controller.text.trim();
    final a2 = _answer2Controller.text.trim();

    if (q1 == null || q1.isEmpty || q2 == null || q2.isEmpty) {
      _showError('Lütfen her iki güvenlik sorusunu da seçin');
      return;
    }
    if (q1 == q2) {
      _showError('İki güvenlik sorusu farklı olmalıdır');
      return;
    }
    if (a1.isEmpty || a2.isEmpty) {
      _showError('Lütfen her iki cevabı da girin');
      return;
    }
    if (a1.length < 2 || a2.length < 2) {
      _showError('Cevaplar en az 2 karakter olmalıdır');
      return;
    }

    setState(() => _isLoading = true);
    try {
      await AuthService.updateSecurityQuestions(
        question1: q1,
        answer1: a1,
        question2: q2,
        answer2: a2,
      );
      if (mounted) {
        _showSuccess('Güvenlik sorularınız kaydedildi');
        setState(() => _hasExisting = true);
      }
    } catch (e) {
      _showError(e.toString().replaceAll('Exception: ', ''));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  void dispose() {
    _answer1Controller.dispose();
    _answer2Controller.dispose();
    _customQuestion1Controller.dispose();
    _customQuestion2Controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accentColor = Theme.of(context).colorScheme.primary;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      appBar: ScreenHeader(
        title: AppLocalizations.of(context).guvenlikSorulari,
        showBack: true,
        onBack: () => context.pop(),
      ),
      body: _isLoading && !_hasExisting
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (_hasExisting) ...[
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFF10B981).withAlpha(20),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: const Color(0xFF10B981).withAlpha(60),
                                ),
                              ),
                              child: const Row(
                                children: [
                                  Icon(Icons.verified, color: Color(0xFF10B981), size: 20),
                                  SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Güvenlik sorularınız ayarlı. Şifrenizi unuttuğunuzda bu sorularla hesabınızı doğrulayabilirsiniz.',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.white70,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),
                          ],
                          const Text(
                            'Soru 1',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF6B7280),
                            ),
                          ),
                          const SizedBox(height: 8),
                          _buildQuestionDropdown(
                            value: _selectedQuestion1,
                            onChanged: (v) => setState(() => _selectedQuestion1 = v),
                            customController: _customQuestion1Controller,
                            isDark: isDark,
                            accentColor: accentColor,
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _answer1Controller,
                            decoration: InputDecoration(
                              labelText: 'Cevap 1',
                              hintText: AppLocalizations.of(context).guvenlikSorusununCevabi,
                              filled: true,
                              fillColor: const Color(0x1AFFFFFF),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: Color(0x1EFFFFFF),
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: accentColor, width: 1.5),
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          const Text(
                            'Soru 2',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF6B7280),
                            ),
                          ),
                          const SizedBox(height: 8),
                          _buildQuestionDropdown(
                            value: _selectedQuestion2,
                            onChanged: (v) => setState(() => _selectedQuestion2 = v),
                            customController: _customQuestion2Controller,
                            isDark: isDark,
                            accentColor: accentColor,
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _answer2Controller,
                            decoration: InputDecoration(
                              labelText: 'Cevap 2',
                              hintText: AppLocalizations.of(context).guvenlikSorusununCevabi,
                              filled: true,
                              fillColor: const Color(0x1AFFFFFF),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: Color(0x1EFFFFFF),
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: accentColor, width: 1.5),
                              ),
                            ),
                          ),
                          const SizedBox(height: 32),
                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _save,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: accentColor,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(AppRadius.medium),
                                ),
                              ),
                              child: _isLoading
                                  ? const SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Text(
                                      'Kaydet',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Center(
                            child: Text(
                              'Bu sorular şifrenizi unuttuğunuzda hesabınızı kurtarmanızı sağlar. Cevaplarınızı güvenli bir yerde saklayın.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 12,
                                color: Color(0xFF6B7280),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildQuestionDropdown({
    required String? value,
    required ValueChanged<String?> onChanged,
    required TextEditingController customController,
    required bool isDark,
    required Color accentColor,
  }) {
    final items = [..._presetQuestions, 'Özel soru...'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: const Color(0x1AFFFFFF),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color(0x1EFFFFFF),
            ),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              isExpanded: true,
              value: value != null && items.contains(value) ? value : null,
              hint: Text(AppLocalizations.of(context).birSoruSecin,
                style: TextStyle(
                  color: Color(0xFF6B7280),
                ),
              ),
              dropdownColor: const Color(0xFF13131A),
              style: const TextStyle(
                color: Color(0xFFE5E7EB),
                fontSize: 14,
              ),
              icon: Icon(Icons.arrow_drop_down, color: accentColor),
              items: items.map((q) {
                return DropdownMenuItem<String>(
                  value: q,
                  child: Text(q, overflow: TextOverflow.ellipsis),
                );
              }).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
        if (value == 'Özel soru...') ...[
          const SizedBox(height: 8),
          TextField(
            controller: customController,
            decoration: InputDecoration(
              hintText: AppLocalizations.of(context).kendiSorunuzuYazin,
              filled: true,
              fillColor: const Color(0x1AFFFFFF),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: Color(0x1EFFFFFF),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: accentColor, width: 1.5),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
