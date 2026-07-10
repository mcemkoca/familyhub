import 'package:flutter/material.dart';
import 'package:familyhub/l10n/app_localizations.dart';
import '../../../services/notification_service.dart';

/// İlaç Hatırlatma — tam ekran hatırlatma bildirimi.
class MedicineReminderScreen extends StatelessWidget {
  final String name;
  final String dose;
  final String time;

  const MedicineReminderScreen({
    super.key,
    this.name = 'Parol 500 mg',
    this.dose = '1 tablet',
    this.time = 'Bugün 16:00',
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
          child: Column(
            children: [
              const Spacer(),
              // Zil ikonu
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [Color(0xFF14B8A6), Color(0xFF0D9488)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF14B8A6).withAlpha(110),
                      blurRadius: 40,
                      spreadRadius: 4,
                    ),
                  ],
                ),
                child: const Icon(Icons.notifications_active_rounded,
                    color: Colors.white, size: 60),
              ),
              const SizedBox(height: 32),
              const Text('İlaç Zamanı',
                  style: TextStyle(
                      color: Color(0xFF9CA3AF),
                      fontSize: 16,
                      fontWeight: FontWeight.w600)),
              const SizedBox(height: 12),
              Text(name,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 30,
                      fontWeight: FontWeight.w900)),
              const SizedBox(height: 8),
              Text('$dose zamanı!',
                  style: const TextStyle(
                      color: Color(0xFF14B8A6),
                      fontSize: 18,
                      fontWeight: FontWeight.w700)),
              const SizedBox(height: 20),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFF13131A),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: const Color(0xFF262631)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.schedule_rounded,
                        color: Color(0xFF9CA3AF), size: 18),
                    const SizedBox(width: 8),
                    Text(time,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              const Spacer(),
              // Aldım
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('İlaç alındı olarak işaretlendi ✓')),
                    );
                    Navigator.pop(context);
                  },
                  icon: const Icon(Icons.check_circle_rounded,
                      color: Colors.white),
                  label: const Text('Aldım',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w800)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF22C55E),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // 15 dk sonra hatırlat
              SizedBox(
                width: double.infinity,
                height: 56,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    final messenger = ScaffoldMessenger.of(context);
                    final navigator = Navigator.of(context);
                    try {
                      await NotificationService.requestPermission();
                      await NotificationService.scheduleNotification(
                        id: DateTime.now().millisecondsSinceEpoch % 2147483647,
                        title: 'İlaç Zamanı 💊',
                        body: '$name · $dose zamanı!',
                        scheduledDate:
                            DateTime.now().add(const Duration(minutes: 15)),
                        payload: 'medicine_reminder',
                      );
                    } catch (_) {}
                    messenger.showSnackBar(
                      const SnackBar(
                          content: Text('15 dakika sonra tekrar hatırlatılacak.')),
                    );
                    navigator.pop();
                  },
                  icon: const Icon(Icons.snooze_rounded,
                      color: Color(0xFF14B8A6)),
                  label: const Text('15 dk. sonra hatırlat',
                      style: TextStyle(
                          color: Color(0xFF14B8A6),
                          fontSize: 16,
                          fontWeight: FontWeight.w700)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFF14B8A6)),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // İptal
              SizedBox(
                width: double.infinity,
                height: 52,
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(AppLocalizations.of(context).cancel,
                      style: const TextStyle(
                          color: Color(0xFF9CA3AF),
                          fontSize: 15,
                          fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
