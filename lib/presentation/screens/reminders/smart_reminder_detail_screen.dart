import 'package:flutter/material.dart';
import '../../../domain/models/smart_reminder.dart';
import '../../../repositories/smart_reminder_repository.dart';
import 'package:familyhub/l10n/app_localizations.dart';
import '../../../core/app_logger.dart';

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
    } catch (e, st) {
      // Sessizce null bırakılırsa aşağıdaki `_reminder!` çöker; hatayı
      // görünür kıl ve kullanıcıya bilgi ver.
      AppLogger.logError(e,
          module: 'reminders', operation: 'loadReminder', stackTrace: st);
      _reminder = null;
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final textColor = const Color(0xFFE5E7EB);

    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // Yükleme başarısızsa `_reminder!` CRASH ederdi — güvenli hata ekranı.
    final loaded = _reminder;
    if (loaded == null) {
      return Scaffold(
        backgroundColor: const Color(0xFF0A0A0F),
        appBar: AppBar(
          backgroundColor: const Color(0xFF1A1A2E),
          foregroundColor: textColor,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline,
                    size: 40, color: Color(0xFF6B7280)),
                const SizedBox(height: 12),
                Text(AppLocalizations.of(context).srdLoadFailed,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Color(0xFF9CA3AF))),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: _loadReminder,
                  child: Text(AppLocalizations.of(context).retry),
                ),
              ],
            ),
          ),
        ),
      );
    }
    final r = loaded;

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
          // Not: hardcoded "AI öneri" kartı kaldırıldı — öneriler sabit
          // metindi ve "Uygula" hiçbir şey yapmadan "Uygulandı" diyordu.
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  /// İstatistikler GERÇEK hatırlatıcı durumundan okunur.
  ///
  /// Önceden hiç doldurulmayan `_analytics` map'inden okunuyordu → her metrik
  /// sıfır görünüyordu; "Ort. Cevap Süresi 3.2 dk" ise hardcoded'dı.
  Widget _buildStatsCard(bool isDark, Color textColor) {
    final st = _reminder?.status;
    final total = st?.triggerCount ?? 0;
    final rate = st?.completionRate ?? 0;
    // Tamamlanan sayısı orandan türetilir (ayrı sayaç modelde yok).
    final completions = (total * rate / 100).round();

    String fmt(DateTime? d) => d == null
        ? '—'
        : '${d.day.toString().padLeft(2, '0')}.'
            '${d.month.toString().padLeft(2, '0')} '
            '${d.hour.toString().padLeft(2, '0')}:'
            '${d.minute.toString().padLeft(2, '0')}';

    return _Card(
      isDark: isDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(AppLocalizations.of(context).basariMetrikleri,
              style: _sectionStyle(textColor)),
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
          const Divider(height: 32),
          _buildMetricRow(
            'Başarı Oranı',
            '%${rate.toStringAsFixed(1)}',
            Icons.trending_up,
            Colors.purple,
          ),
          _buildMetricRow(
            'Son Tetiklenme',
            fmt(st?.lastTriggered),
            Icons.history,
            Colors.teal,
          ),
          _buildMetricRow(
            'Sıradaki',
            fmt(st?.nextScheduled),
            Icons.schedule,
            Colors.blue,
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
          if (_timeDistribution.isEmpty)
            Text(AppLocalizations.of(context).srdNoDataYet,
                style: const TextStyle(color: Color(0xFF6B7280), fontSize: 12)),
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
          if (_locationDistribution.isEmpty)
            Text(AppLocalizations.of(context).srdNoDataYet,
                style: const TextStyle(color: Color(0xFF6B7280), fontSize: 12)),
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


  TextStyle _sectionStyle(Color textColor) {
    return TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.bold,
      color: textColor,
    );
  }
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
