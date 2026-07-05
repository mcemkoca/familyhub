import 'package:flutter/material.dart';
import '../../services/hive_service.dart';
import '../../services/notification_service.dart';

/// "Güncel Kal" bildirim izni promptu (FamilyWall tarzı).
/// İlk çalışmada bir kez gösterilir; kullanıcı "Aç" derse izin istenir,
/// "Sonra" derse ertelenir. Hive flag ile tekrar gösterilmez.
class NotificationPrompt {
  static const String _shownKey = 'notif_prompt_shown';

  /// Daha önce gösterilmediyse promptu gösterir. Genelde Hub açılışında çağrılır.
  static Future<void> maybeShow(BuildContext context) async {
    final shown = HiveService.getSetting(_shownKey) == 'true';
    if (shown) return;
    await HiveService.setSetting(_shownKey, 'true');
    if (!context.mounted) return;
    await show(context);
  }

  /// Promptu her koşulda gösterir (ör. ayarlardan).
  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _NotificationPromptSheet(),
    );
  }
}

class _NotificationPromptSheet extends StatelessWidget {
  const _NotificationPromptSheet();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF13131A),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(40),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 28),
              // Çan ikonu + kırmızı rozet
              SizedBox(
                width: 84,
                height: 84,
                child: Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 84,
                      height: 84,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF59E0B).withAlpha(28),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.notifications_rounded,
                          color: Color(0xFFFBBF24), size: 44),
                    ),
                    Positioned(
                      top: 4,
                      right: 8,
                      child: Container(
                        width: 22,
                        height: 22,
                        decoration: const BoxDecoration(
                          color: Color(0xFFEF4444),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.priority_high_rounded,
                            color: Colors.white, size: 14),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Güncel Kal',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Bildirimleri açın; önemli hatırlatmaları ve yeni mesajları '
                'asla kaçırmayın. Bunu istediğiniz zaman değiştirebilirsiniz.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFF9CA3AF),
                  fontSize: 14,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: () async {
                    final granted =
                        await NotificationService.requestPermission();
                    if (!context.mounted) return;
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(granted
                            ? 'Bildirimler açıldı'
                            : 'Bildirim izni verilmedi — ayarlardan açabilirsiniz'),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4F7DF3),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(27),
                    ),
                  ),
                  child: const Text(
                    'Bildirimleri Aç',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  style: TextButton.styleFrom(
                    backgroundColor: const Color(0xFF1F2430),
                    foregroundColor: const Color(0xFFD1D5DB),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(27),
                    ),
                  ),
                  child: const Text(
                    'Sonra',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
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
