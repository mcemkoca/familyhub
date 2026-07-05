import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../services/hive_service.dart';
import '../../../config/constants.dart';
import '../../providers/app_providers.dart';
import '../../widgets/settings/screen_header.dart';
import 'package:go_router/go_router.dart';
import 'package:familyhub/l10n/app_localizations.dart';

class AppearanceSettingsScreen extends ConsumerStatefulWidget {
  const AppearanceSettingsScreen({super.key});

  @override
  ConsumerState<AppearanceSettingsScreen> createState() => _AppearanceSettingsScreenState();
}

class _AppearanceSettingsScreenState extends ConsumerState<AppearanceSettingsScreen> {
  late Color _selectedAccent;
  late String _selectedAccentKey;
  bool _hasChanges = false;

  late final Color _originalAccent;

  @override
  void initState() {
    super.initState();
    _selectedAccent = ref.read(accentColorProvider);

    _originalAccent = _selectedAccent;

    final savedAccent = HiveService.getSetting('accentColor') ?? 'cobalt';
    _selectedAccentKey = savedAccent;
  }

  void _markChanged() {
    setState(() {
      _hasChanges = _selectedAccent != _originalAccent;
    });
  }

  Future<void> _save() async {
    HapticFeedback.mediumImpact();

    await HiveService.setSetting('accentColor', _selectedAccentKey);

    ref.read(accentColorProvider.notifier).state = _selectedAccent;

    setState(() => _hasChanges = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).gorunumAyarlariKaydedildi)),
      );
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {

    final accentOptions = [
      {'color': const Color(0xFF6366F1), 'label': 'Kobalt', 'key': 'cobalt'},
      {'color': AppColors.green, 'label': 'Yeşil', 'key': 'green'},
      {'color': AppColors.orange, 'label': 'Turuncu', 'key': 'orange'},
      {'color': const Color(0xFF8B5CF6), 'label': 'Mor', 'key': 'purple'},
      {'color': AppColors.red, 'label': 'Kırmızı', 'key': 'red'},
    ];

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      appBar: ScreenHeader(
        title: 'Görünüm',
        showBack: true,
        onBack: () => context.pop(),
      ),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Aksan Rengi',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Color(0xFF6B7280),
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF13131A),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color(0x1EFFFFFF),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: accentOptions.map((opt) {
                final selected = _selectedAccent == opt['color'];
                return GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() {
                      _selectedAccent = opt['color'] as Color;
                      _selectedAccentKey = opt['key'] as String;
                    });
                    ref.read(accentColorProvider.notifier).state = opt['color'] as Color;
                    _markChanged();
                  },
                  child: Column(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: opt['color'] as Color,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: selected ? Colors.white : Colors.transparent,
                            width: 3,
                          ),
                          boxShadow: selected
                              ? [BoxShadow(color: (opt['color'] as Color).withAlpha(80), blurRadius: 12)]
                              : null,
                        ),
                        child: selected
                            ? const Icon(Icons.check, color: Colors.white, size: 20)
                            : null,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        opt['label'] as String,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                          color: const Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _hasChanges ? _save : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: _selectedAccent,
                foregroundColor: Colors.white,
                elevation: 0,
                disabledBackgroundColor: const Color(0x1EFFFFFF),
                disabledForegroundColor: const Color(0xFF6B7280),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text(
                'Kaydet',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}
