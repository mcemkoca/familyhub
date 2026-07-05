import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../config/routes.dart';
import '../../../services/auth_service.dart';
import '../../../core/supabase_client.dart';
import 'steps/account_step.dart';
import 'steps/profile_step.dart';
import 'steps/parent_role_step.dart';
import 'steps/safe_zones_step.dart';
import 'steps/children_step.dart';
import 'steps/health_step.dart';
import 'package:familyhub/l10n/app_localizations.dart';

class RegistrationWizardScreen extends ConsumerStatefulWidget {
  const RegistrationWizardScreen({super.key});

  @override
  ConsumerState<RegistrationWizardScreen> createState() => _RegistrationWizardScreenState();
}

class _RegistrationWizardScreenState extends ConsumerState<RegistrationWizardScreen> {
  final _pageController = PageController();
  int _currentStep = 0;
  bool _isLoading = false;

  // Wizard state
  String? _userId;
  String? _familyId;
  String _name = '';

  final _profileData = <String, dynamic>{};
  final _parentRoleData = <String, dynamic>{};
  final _safeZones = <Map<String, dynamic>>[];
  final _children = <Map<String, dynamic>>[];
  final _healthData = <String, dynamic>{};

  void _nextPage() {
    if (_currentStep < 5) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _prevPage() {
    if (_currentStep > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _finishWizard() async {
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(milliseconds: 500));
    if (mounted) {
      context.go(AppRoutes.hub);
    }
  }

  Future<void> _skipToEnd() async {
    if (_currentStep == 0) {
      // Can't skip account creation
      return;
    }
    _pageController.animateToPage(
      5,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: _currentStep > 0
            ? IconButton(
                onPressed: _prevPage,
                icon: const Icon(Icons.arrow_back),
              )
            : null,
        title: Text(
          'Kayıt (${_currentStep + 1}/6)',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        actions: [
          if (_currentStep > 0 && _currentStep < 5)
            TextButton(
              onPressed: _skipToEnd,
              child: Text(AppLocalizations.of(context).simdiGec),
            ),
        ],
      ),
      body: Column(
        children: [
          // Progress bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: (_currentStep + 1) / 6,
                minHeight: 6,
                backgroundColor: const Color(0x1EFFFFFF),
                valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF6366F1)),
              ),
            ),
          ),
          // Page view
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              onPageChanged: (index) => setState(() => _currentStep = index),
              children: [
                AccountStep(
                  onAccountCreated: (name, email, password, familyId, userId) {
                    setState(() {
                      _name = name;
                      _familyId = familyId;
                      _userId = userId;
                    });
                    _nextPage();
                  },
                ),
                ProfileStep(
                  onSaved: (data) {
                    setState(() => _profileData.addAll(data));
                    _saveProfileData();
                    _nextPage();
                  },
                ),
                ParentRoleStep(
                  onSaved: (data) {
                    setState(() => _parentRoleData.addAll(data));
                    _saveParentRoleData();
                    _nextPage();
                  },
                ),
                SafeZonesStep(
                  familyId: _familyId,
                  onSaved: (zones) {
                    setState(() => _safeZones.addAll(zones));
                    _nextPage();
                  },
                ),
                ChildrenStep(
                  familyId: _familyId,
                  onSaved: (children) {
                    setState(() => _children.addAll(children));
                    _nextPage();
                  },
                ),
                HealthStep(
                  onSaved: (data) {
                    setState(() => _healthData.addAll(data));
                    _saveHealthData();
                    _finishWizard();
                  },
                  isLoading: _isLoading,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _saveProfileData() async {
    try {
      await AuthService.updateProfile(
        displayName: _name,
        phone: _profileData['phone']?.toString(),
        dateOfBirth: _profileData['date_of_birth']?.toString(),
        preferredLanguage: _profileData['preferred_language']?.toString(),
        themePreference: _profileData['theme_preference']?.toString(),
      );
    } catch (e) {
      debugPrint('Profile save error: $e');
    }
  }

  Future<void> _saveParentRoleData() async {
    try {
      final client = SupabaseConfig.safeClient;
      if (client == null || _userId == null || _familyId == null) return;

      await client.from('family_members').update({
        'role': _parentRoleData['role']?.toString() ?? 'admin',
        'display_name': _parentRoleData['display_name']?.toString() ?? _name,
        'color': _parentRoleData['color']?.toString(),
      }).eq('family_id', _familyId!).eq('user_id', _userId!);
    } catch (e) {
      debugPrint('Parent role save error: $e');
    }
  }

  Future<void> _saveHealthData() async {
    try {
      await AuthService.updateProfile(
        bloodType: _healthData['blood_type']?.toString(),
        allergies: (_healthData['allergies'] as List?)?.cast<String>(),
        chronicConditions: (_healthData['chronic_conditions'] as List?)?.cast<String>(),
        emergencyContact: _healthData['emergency_contact'] as Map<String, dynamic>?,
      );
    } catch (e) {
      debugPrint('Health save error: $e');
    }
  }
}
