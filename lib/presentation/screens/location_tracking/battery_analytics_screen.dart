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
          _section('BATARYA TÜKETİMİ (7 Gün)', children: [
            Text(AppLocalizations.of(context).gunlukOrtalama18, style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            _dayBar('Pazartesi', 0.16),
            _dayBar('Salı', 0.20, highlight: true),
            _dayBar('Çarşamba', 0.14),
            _dayBar('Perşembe', 0.16),
            _dayBar('Cuma', 0.22, highlight: true),
            _dayBar('Cumartesi', 0.12, good: true),
            _dayBar('Pazar', 0.14),
            const SizedBox(height: 8),
            Row(
              children: [
                _legend(Colors.red, 'Yüksek'),
                const SizedBox(width: 12),
                _legend(Colors.green, 'Düşük'),
              ],
            ),
          ]),

          // Profile usage
          _section('PROFİL KULLANIMI', children: [
            _profileBar('Durağan', 0.45, Colors.grey),
            _profileBar('Yürüyüş', 0.25, Colors.blue),
            _profileBar('Araç', 0.15, Colors.orange),
            _profileBar('Koşu', 0.08, Colors.teal),
            _profileBar('Acil', 0.05, Colors.red),
            _profileBar('Bisiklet', 0.02, Colors.purple),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.track_changes),
              label: const Text('Optimize Et'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade700,
                foregroundColor: Colors.white,
              ),
            ),
          ]),

          // Efficiency metrics
          _section('VERİMLİLİK METRİKLERİ', children: [
            _metricRow('Konum/Batarya', '2.5 nokta/%', target: '3.0+'),
            _metricRow('Ortalama hassasiyet', '35m', target: '<50m'),
            _metricRow('Optimal profil oranı', '%68', target: '%80+'),
            _metricRow('Yanlış profil geçişi', '12/gün', target: '<5/gün'),
          ]),

          // AI suggestions
          _section('🤖 AI OPTİMİZASYON ÖNERİLERİ', children: [
            ...suggestions.map((s) => _suggestionCard(s)),
          ]),

          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.download),
                  label: Text(AppLocalizations.of(context).raporIndir),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6B7280),
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.calculate),
                  label: const Text('Yeniden Hesapla'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade700,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
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
          Text(title, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _dayBar(String day, double value, {bool highlight = false, bool good = false}) {
    final color = highlight ? Colors.red : (good ? Colors.green : Colors.blue);
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          SizedBox(width: 80, child: Text(day, style: const TextStyle(color: Colors.white70, fontSize: 13))),
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
          Text('${(value * 100).toInt()}%', style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _legend(Color color, String label) {
    return Row(
      children: [
        CircleAvatar(radius: 6, backgroundColor: color),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
      ],
    );
  }

  Widget _profileBar(String label, double value, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          SizedBox(width: 80, child: Text(label, style: const TextStyle(color: Colors.white70, fontSize: 13))),
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
          Text('${(value * 100).toInt()}%', style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
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
                  Text('Hedef: $target', style: const TextStyle(color: Color(0xFF6B7280), fontSize: 12)),
              ],
            ),
          ),
          Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
                  style: const TextStyle(color: Colors.white, fontSize: 13, height: 1.4),
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
              const Spacer(),
              TextButton(
                onPressed: () {},
                child: const Text('Uygula'),
              ),
              TextButton(
                onPressed: () {},
                child: const Text('Detay'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
