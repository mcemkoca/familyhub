// lib/presentation/screens/location_tracking/battery_analytics_screen.dart
// Battery & tracking analytics with AI suggestions

import 'package:flutter/material.dart';
import '../../../domain/models/location_tracking.dart';
import '../../../services/battery_aware_location_tracker.dart';
import 'package:familyhub/l10n/app_localizations.dart';

class BatteryAnalyticsScreen extends StatefulWidget {
  const BatteryAnalyticsScreen({super.key});

  @override
  State<BatteryAnalyticsScreen> createState() => _BatteryAnalyticsScreenState();
}

class _BatteryAnalyticsScreenState extends State<BatteryAnalyticsScreen> {
  final tracker = BatteryAwareLocationTracker();

  /// Güncel optimizasyon önerilerini gösterir (gerçek tracker verisi).
  void _showOptimizationSuggestions() {
    final suggestions = tracker.generateOptimizationSuggestions();
    final t = AppLocalizations.of(context);
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF13131A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(t.baOptimize,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700)),
              const SizedBox(height: 12),
              if (suggestions.isEmpty)
                Text(t.baNoSuggestions,
                    style: const TextStyle(color: Color(0xFF9CA3AF)))
              else
                ...suggestions.map(
                  (s) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.bolt,
                            size: 16, color: Color(0xFF10B981)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${s.description} — %${s.potentialSaving.toStringAsFixed(0)}',
                            style: const TextStyle(
                                color: Color(0xFFE5E7EB), fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final suggestions = tracker.generateOptimizationSuggestions();

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context).bataryaAnalitigi),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Battery consumption
          _section(
            AppLocalizations.of(context).battChartTitle,
            children: [
              Text(
                AppLocalizations.of(context).gunlukOrtalama18,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              _dayBar(AppLocalizations.of(context).dowMon, 0.16),
              _dayBar(
                AppLocalizations.of(context).dowTue,
                0.20,
                highlight: true,
              ),
              _dayBar(AppLocalizations.of(context).dowWed, 0.14),
              _dayBar(AppLocalizations.of(context).dowThu, 0.16),
              _dayBar(
                AppLocalizations.of(context).dowFri,
                0.22,
                highlight: true,
              ),
              _dayBar(AppLocalizations.of(context).dowSat, 0.12, good: true),
              _dayBar(AppLocalizations.of(context).dowSun, 0.14),
              const SizedBox(height: 8),
              Row(
                children: [
                  _legend(Colors.red, AppLocalizations.of(context).battHigh),
                  const SizedBox(width: 12),
                  _legend(Colors.green, AppLocalizations.of(context).battLow),
                ],
              ),
            ],
          ),

          // Profile usage
          _section(
            AppLocalizations.of(context).profilKullanimi,
            children: [
              _profileBar(
                AppLocalizations.of(context).battProfileStationary,
                0.45,
                Colors.grey,
              ),
              _profileBar(
                AppLocalizations.of(context).battProfileWalking,
                0.25,
                Colors.blue,
              ),
              _profileBar(
                AppLocalizations.of(context).battProfileDriving,
                0.15,
                Colors.orange,
              ),
              _profileBar(
                AppLocalizations.of(context).battProfileRunning,
                0.08,
                Colors.teal,
              ),
              _profileBar(
                AppLocalizations.of(context).battProfileEmergency,
                0.05,
                Colors.red,
              ),
              _profileBar(
                AppLocalizations.of(context).battProfileCycling,
                0.02,
                Colors.purple,
              ),
              const SizedBox(height: 8),
              ElevatedButton.icon(
                onPressed: _showOptimizationSuggestions,
                icon: const Icon(Icons.track_changes),
                label: Text(AppLocalizations.of(context).baOptimize),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade700,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),

          // Efficiency metrics
          _section(
            AppLocalizations.of(context).verimlilikMetrikleri,
            children: [
              _metricRow('Konum/Batarya', '2.5 nokta/%', target: '3.0+'),
              _metricRow(
                AppLocalizations.of(context).baAvgAccuracy,
                '35m',
                target: '<50m',
              ),
              _metricRow(
                AppLocalizations.of(context).baOptimalRatio,
                '%68',
                target: '%80+',
              ),
              _metricRow(
                AppLocalizations.of(context).baWrongSwitch,
                '12/gün',
                target: '<5/gün',
              ),
            ],
          ),

          // AI suggestions
          _section(
            AppLocalizations.of(context).aiOptimizasyonOnerileri,
            children: [...suggestions.map((s) => _suggestionCard(s))],
          ),

          const SizedBox(height: 16),
          // Not: "Rapor İndir" kaldırıldı — dosya üretimi/paylaşımı yok;
          // tıklanıp hiçbir şey yapmıyordu.
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              // Tahminleri güncel pil seviyesiyle yeniden hesaplar.
              onPressed: () => setState(() {}),
              icon: const Icon(Icons.calculate),
              label: Text(AppLocalizations.of(context).baRecalculate),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade700,
                foregroundColor: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _section(String title, {required List<Widget> children}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF16213E),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _dayBar(
    String day,
    double value, {
    bool highlight = false,
    bool good = false,
  }) {
    final color = highlight ? Colors.red : (good ? Colors.green : Colors.blue);
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              day,
              style: const TextStyle(color: Colors.white70, fontSize: 13),
            ),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: value,
                minHeight: 10,
                backgroundColor: const Color(0xFF374151),
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${(value * 100).toInt()}%',
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _legend(Color color, String label) {
    return Row(
      children: [
        CircleAvatar(radius: 6, backgroundColor: color),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
      ],
    );
  }

  Widget _profileBar(String label, double value, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: const TextStyle(color: Colors.white70, fontSize: 13),
            ),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: value,
                minHeight: 10,
                backgroundColor: const Color(0xFF374151),
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${(value * 100).toInt()}%',
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _metricRow(String label, String value, {String? target}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(color: Colors.white70)),
                if (target != null)
                  Text(
                    AppLocalizations.of(context).batteryTarget(target),
                    style: const TextStyle(
                      color: Color(0xFF6B7280),
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _suggestionCard(OptimizationSuggestion s) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.purple.shade800, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.lightbulb, color: Colors.yellow, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  s.description,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                'Tasarruf: %${s.potentialSaving.toStringAsFixed(0)}',
                style: TextStyle(color: Colors.green.shade400, fontSize: 12),
              ),
              // Not: "Uygula/Detay" butonları kaldırıldı — tracker'da bu
              // öneriyi tek tıkla uygulayacak bir API yok; tıklanıp hiçbir şey
              // yapmayan buton kullanıcıyı yanıltıyordu. Öneri metni zaten
              // uygulanabilir bilgi veriyor.
            ],
          ),
        ],
      ),
    );
  }
}
