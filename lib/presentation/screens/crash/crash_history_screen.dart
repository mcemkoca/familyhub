// lib/presentation/screens/crash/crash_history_screen.dart
// Crash event history and statistics

import 'package:flutter/material.dart';
import '../../../core/supabase_client.dart';
import '../../../domain/models/crash_event.dart';
import '../../../repositories/crash_event_repository.dart';
import '../../../services/auth_service.dart';
import 'package:familyhub/l10n/app_localizations.dart';

class CrashHistoryScreen extends StatelessWidget {
  const CrashHistoryScreen({super.key});

  Future<String?> _getFamilyId() async {
    final userId = AuthService.currentUserId;
    if (userId == null) return null;
    final profile = await SupabaseConfig.client
        .from('profiles')
        .select('family_id')
        .eq('id', userId)
        .maybeSingle();
    return profile?['family_id'] as String?;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context).kazaGecmisi)),
      body: FutureBuilder<String?>(
        future: _getFamilyId(),
        builder: (context, familySnapshot) {
          if (!familySnapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final familyId = familySnapshot.data;
          if (familyId == null) {
            return Center(
              child: Text(AppLocalizations.of(context).aileBilgisiBulunamadi),
            );
          }
          return StreamBuilder<List<CrashEvent>>(
            // Realtime: aile kaza olayları anında yansır.
            stream: CrashEventRepository().watchFamilyEvents(familyId),
            builder: (context, snapshot) {
              // Hata durumunda sonsuz spinner yerine boş listeyle devam et.
              if (snapshot.hasError) {
                return Center(
                  child: Text(
                    AppLocalizations.of(context).aileBilgisiBulunamadi,
                  ),
                );
              }
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final events = snapshot.data!;
              final total = events.length;
              final falseAlarms = events.where((e) => e.isFalsePositive).length;
              final realCrashes = events
                  .where(
                    (e) =>
                        !e.isFalsePositive &&
                        e.response.status == CrashResponseStatus.autoSos,
                  )
                  .length;

              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Summary card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF16213E),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'TOPLAM OLAYLAR',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _statRow('Tespit edilen', '$total'),
                        _statRow(
                          'Yanlış alarm',
                          '$falseAlarms (%${total > 0 ? (falseAlarms / total * 100).round() : 0})',
                        ),
                        _statRow('Gerçek kaza', '$realCrashes'),
                        const Divider(color: Colors.white24, height: 20),
                        Text(
                          AppLocalizations.of(context).son30Gun0Olay,
                          style: const TextStyle(color: Colors.white70),
                        ),
                        const SizedBox(height: 8),
                        ElevatedButton.icon(
                          onPressed: () {},
                          icon: const Icon(Icons.bar_chart),
                          label: Text(
                            AppLocalizations.of(context).detayliIstatistik,
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue.shade800,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  Text(
                    AppLocalizations.of(context).olayListesi,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),

                  ...events.map((e) => _buildEventCard(context, e)),

                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.download),
                    label: Text(AppLocalizations.of(context).tumRaporlariIndir),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6B7280),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _statRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white70)),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventCard(BuildContext context, CrashEvent event) {
    final isFalseAlarm = event.isFalsePositive;
    final isRealCrash =
        !isFalseAlarm && event.response.status == CrashResponseStatus.autoSos;
    final color = isFalseAlarm
        ? Colors.green
        : (isRealCrash ? Colors.red : Colors.orange);
    final icon = isFalseAlarm
        ? Icons.check_circle
        : (isRealCrash ? Icons.emergency : Icons.warning);
    final label = isFalseAlarm
        ? 'Yanlış alarm'
        : (isRealCrash ? 'GERÇEK KAZA' : 'Bekleyen');

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF16213E),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withAlpha(102), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  '${_fmtDate(event.detection.timestamp)} - $label',
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${event.sensorData.accelerometer.peakG.toStringAsFixed(1)}G | ${event.context.transportMode.name}',
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
          const SizedBox(height: 8),
          if (isRealCrash)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _responseRow(Icons.emergency, 'SOS tetiklendi'),
                _responseRow(Icons.check_circle, 'Aile bilgilendirildi'),
                if (event.outcome?.emergencyServicesCalled ?? false)
                  _responseRow(Icons.phone, '112 arandı')
                else
                  _responseRow(
                    Icons.cancel,
                    '112 aranmadı (kullanıcı iptal etti)',
                    ok: false,
                  ),
              ],
            ),
          if (isFalseAlarm)
            _responseRow(Icons.check_circle, 'Kullanıcı "İyiyim" dedi'),
          const SizedBox(height: 10),
          Row(
            children: [
              TextButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.article, size: 18),
                label: Text(AppLocalizations.of(context).commonDetail),
              ),
              if (isRealCrash)
                TextButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.download, size: 18),
                  label: Text(AppLocalizations.of(context).raporIndir),
                ),
              const Spacer(),
              IconButton(
                onPressed: () {},
                icon: const Icon(
                  Icons.delete,
                  color: Colors.redAccent,
                  size: 20,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _responseRow(IconData icon, String text, {bool ok = true}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(icon, color: ok ? Colors.green : Colors.orange, size: 16),
          const SizedBox(width: 8),
          Text(
            text,
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ],
      ),
    );
  }

  String _fmtDate(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')}.${dt.year} ${_fmtTime(dt)}';
  }

  String _fmtTime(DateTime dt) =>
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
}
