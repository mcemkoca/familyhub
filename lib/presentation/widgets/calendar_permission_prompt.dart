import 'package:flutter/material.dart';
import '../../services/hive_service.dart';
import '../../services/calendar_sync_service.dart';

/// Takvim erişim izni ön-açıklama promptu (FamilyWall tarzı).
/// Cihaz takvimini aile takvimiyle eşleştirmek için izin ister.
/// İlk kez takvim ekranına girildiğinde bir kez gösterilir.
class CalendarPermissionPrompt {
  static const String _shownKey = 'calendar_prompt_shown';

  /// Daha önce gösterilmediyse ve izin henüz yoksa promptu gösterir.
  static Future<void> maybeShow(BuildContext context) async {
    if (HiveService.getSetting(_shownKey) == 'true') return;
    final already = await CalendarSyncService.hasPermission();
    if (already) {
      await HiveService.setSetting(_shownKey, 'true');
      return;
    }
    await HiveService.setSetting(_shownKey, 'true');
    if (!context.mounted) return;
    await show(context);
  }

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _CalendarPromptSheet(),
    );
  }
}

class _CalendarPromptSheet extends StatelessWidget {
  const _CalendarPromptSheet();

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
              Container(
                width: 84,
                height: 84,
                decoration: BoxDecoration(
                  color: const Color(0xFF8B5CF6).withAlpha(28),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.calendar_month_rounded,
                    color: Color(0xFFA78BFA), size: 42),
              ),
              const SizedBox(height: 24),
              const Text(
                'Takviminizi Eşleştirin',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              const Text(
                'FamilyHub\'ın cihaz takviminize erişmesine izin verin; '
                'aile etkinlikleriniz ve randevularınız tek yerde toplansın. '
                'Her aile üyesi kendi takvimini bağlayabilir.',
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
                        await CalendarSyncService.requestPermission();
                    if (!context.mounted) return;
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(granted
                            ? 'Takvim erişimi verildi — eşleştirmeye hazır'
                            : 'İzin verilmedi — ayarlardan açabilirsiniz'),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF8B5CF6),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(27),
                    ),
                  ),
                  child: const Text(
                    'İzin Ver',
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
                    'Şimdi Değil',
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
