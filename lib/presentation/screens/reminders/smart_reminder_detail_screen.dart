import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../domain/models/smart_reminder.dart';
import '../../../repositories/smart_reminder_repository.dart';
import 'package:familyhub/l10n/app_localizations.dart';

class SmartReminderDetailScreen extends StatefulWidget {
  final String reminderId;
  const SmartReminderDetailScreen({super.key, required this.reminderId});

  @override
  State<SmartReminderDetailScreen> createState() =>
      _SmartReminderDetailScreenState();
}

class _SmartReminderDetailScreenState extends State<SmartReminderDetailScreen> {
  bool get isDark => Theme.of(context).brightness == Brightness.dark;

  SmartReminder? _reminder;
  bool _loading = true;

  final Map<String, dynamic> _analytics = {};
  final Map<String, int> _timeDistribution = {};
  final Map<String, int> _locationDistribution = {};

  @override
  void initState() {
    super.initState();
    _loadReminder();
  }

  Future<void> _loadReminder() async {
    setState(() => _loading = true);
    try {
      _reminder = await SmartReminderRepository().getById(widget.reminderId);
    } catch (e) {
      _reminder = null;
    }
    setState(() => _loading = false);
  }

  void _applyOptimization(String suggestion) {
    HapticFeedback.mediumImpact();
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context).srdApplied(suggestion))));
  }

  @override
  Widget build(BuildContext context) {
    final textColor = const Color(0xFFE5E7EB);

    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final r = _reminder!;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      appBar: AppBar(
        title: Text(r.title),
        backgroundColor: isDark
            ? const Color(0xFF1A1A2E)
            : const Color(0xFFF8F9FA),
        foregroundColor: textColor,
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: _buildStatsCard(isDark, textColor),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _buildTimeDistributionCard(isDark, textColor),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 16)),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _buildLocationDistributionCard(isDark, textColor),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 16)),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _buildAiSuggestionsCard(isDark, textColor),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  Widget _buildStatsCard(bool isDark, Color textColor) {
    final total = _analytics['total_triggers'] as int? ?? 0;
    final completions = _analytics['completions'] as int? ?? 0;
    final snoozes = _analytics['snoozes'] as int? ?? 0;
    final dismisses = _analytics['dismisses'] as int? ?? 0;
    final rate = _analytics['completion_rate'] as double? ?? 0;

    return _Card(
      isDark: isDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(AppLocalizations.of(context).basariMetrikleri, style: _sectionStyle(textColor)),
          const SizedBox(height: 16),
          _buildMetricRow(
            'Tetiklenme',
            '$total kez',
            Icons.flash_on,
            Colors.orange,
          ),
          _buildMetricRow(
            'Tamamlanma',
            '$completions kez',
            Icons.check_circle,
            Colors.green,
          ),
          _buildMetricRow(
            'Erteleme',
            '$snoozes kez',
            Icons.snooze,
            Colors.blue,
          ),
          _buildMetricRow(
            'Yoksayma',
            '$dismisses kez',
            Icons.cancel,
            Colors.grey,
          ),
          const Divider(height: 32),
          _buildMetricRow(
            'Başarı Oranı',
            '%${rate.toStringAsFixed(1)}',
            Icons.trending_up,
            Colors.purple,
          ),
          _buildMetricRow(
            'Ort. Cevap Süresi',
            '3.2 dk',
            Icons.timer,
            Colors.teal,
          ),
        ],
      ),
    );
  }

  Widget _buildMetricRow(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(child: Text(label)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildTimeDistributionCard(bool isDark, Color textColor) {
    // Boş map'te reduce StateError atar → güvenli varsayılan.
    final maxVal = _timeDistribution.isEmpty
        ? 1
        : _timeDistribution.values.reduce((a, b) => a > b ? a : b);

    return _Card(
      isDark: isDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(AppLocalizations.of(context).zamanDagilimi, style: _sectionStyle(textColor)),
          const SizedBox(height: 16),
          ..._timeDistribution.entries.map((e) {
            final pct = e.value / maxVal;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  SizedBox(width: 50, child: Text(e.key)),
                  Expanded(
                    child: Stack(
                      children: [
                        Container(
                          height: 20,
                          decoration: BoxDecoration(
                            color: Colors.grey.withAlpha(26),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        FractionallySizedBox(
                          widthFactor: pct,
                          child: Container(
                            height: 20,
                            decoration: BoxDecoration(
                              color: const Color(0xFF6366F1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 40,
                    child: Text('${e.value}', textAlign: TextAlign.right),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildLocationDistributionCard(bool isDark, Color textColor) {
    // Boş map'te reduce StateError atar → güvenli varsayılan.
    final maxVal = _locationDistribution.isEmpty
        ? 1
        : _locationDistribution.values.reduce((a, b) => a > b ? a : b);

    return _Card(
      isDark: isDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(AppLocalizations.of(context).lokasyonDagilimi, style: _sectionStyle(textColor)),
          const SizedBox(height: 16),
          ..._locationDistribution.entries.map((e) {
            final pct = e.value / maxVal;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  SizedBox(
                    width: 100,
                    child: Text(e.key, overflow: TextOverflow.ellipsis),
                  ),
                  Expanded(
                    child: Stack(
                      children: [
                        Container(
                          height: 20,
                          decoration: BoxDecoration(
                            color: Colors.grey.withAlpha(26),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        FractionallySizedBox(
                          widthFactor: pct,
                          child: Container(
                            height: 20,
                            decoration: BoxDecoration(
                              color: Colors.orange,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 40,
                    child: Text('${e.value}', textAlign: TextAlign.right),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildAiSuggestionsCard(bool isDark, Color textColor) {
    final suggestions = [
      _AiOptSuggestion(
        text: '17:00-19:00 arası başarı %95, akıllı pencereyi daralt',
        icon: Icons.schedule,
      ),
      _AiOptSuggestion(
        text: 'A101 dışında başarı düşük, sadece A101\'e odaklan',
        icon: Icons.location_on,
      ),
      _AiOptSuggestion(
        text: 'Erteleme oranı yüksek, nazik ton deneyin',
        icon: Icons.mood,
      ),
    ];

    return _Card(
      isDark: isDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(AppLocalizations.of(context).aiOgrenmeOnerileri, style: _sectionStyle(textColor)),
          const SizedBox(height: 16),
          ...suggestions.map(
            (s) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Icon(s.icon, color: Colors.purple[400]),
                  const SizedBox(width: 12),
                  Expanded(child: Text(s.text)),
                  TextButton(
                    onPressed: () => _applyOptimization(s.text),
                    child: Text(AppLocalizations.of(context).rtApply),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.refresh),
              label: Text(AppLocalizations.of(context).modeliYenidenEgit),
            ),
          ),
        ],
      ),
    );
  }

  TextStyle _sectionStyle(Color textColor) {
    return TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.bold,
      color: textColor,
    );
  }
}

class _AiOptSuggestion {
  final String text;
  final IconData icon;
  _AiOptSuggestion({required this.text, required this.icon});
}

class _Card extends StatelessWidget {
  final bool isDark;
  final Widget child;
  const _Card({required this.isDark, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFE5E7EB),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}
