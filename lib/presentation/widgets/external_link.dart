import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// Dış bağlantıyı (YouTube, web) açmadan önce kullanıcıyı uyarır.
/// Kullanıcı onaylarsa tarayıcıda/uygulamada açar.
Future<void> openExternalLink(BuildContext context, String url,
    {String? label}) async {
  final uri = Uri.tryParse(url);
  if (uri == null) return;
  final isYoutube = url.contains('youtube') || url.contains('youtu.be');
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: const Color(0xFF13131A),
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          Icon(isYoutube ? Icons.smart_display : Icons.open_in_new,
              color: const Color(0xFF6366F1), size: 22),
          const SizedBox(width: 10),
          const Expanded(
            child: Text('Uygulamadan Ayrılıyorsunuz',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w800)),
          ),
        ],
      ),
      content: Text(
        isYoutube
            ? 'Bu bağlantı YouTube\'da açılacak. Devam etmek istiyor musunuz?'
            : 'Bu bağlantı tarayıcıda açılacak. Devam etmek istiyor musunuz?',
        style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 14, height: 1.4),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Vazgeç',
              style: TextStyle(color: Color(0xFF9CA3AF))),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(ctx, true),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF6366F1),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
          ),
          child: const Text('Devam Et'),
        ),
      ],
    ),
  );
  if (ok == true) {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}
