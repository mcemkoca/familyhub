import 'dart:math';
import 'package:flutter/material.dart';

/// İlerlemeye (0.0–1.0) göre büyüyen ağaç görselleştirmesi.
/// Gövde → dallar → yapraklar → meyveler kademeli olarak belirir.
/// Gelişim ve Eğitim ilerleme bölümlerinde kullanılır.
class GrowingTree extends StatelessWidget {
  final double progress; // 0.0 - 1.0
  final double size;
  final String? label;

  const GrowingTree({
    super.key,
    required this.progress,
    this.size = 220,
    this.label,
  });

  String get _stageLabel => stageLabelFor(progress);

  /// İlerlemeye göre aşama etiketi (0.0–1.0). Aralık dışı değerler kırpılır.
  static String stageLabelFor(double progress) {
    final p = progress.clamp(0.0, 1.0);
    if (p >= 0.95) return 'Meyve verdi! 🎉';
    if (p >= 0.7) return 'Çiçek açıyor 🌸';
    if (p >= 0.45) return 'Yapraklandı 🌿';
    if (p >= 0.2) return 'Filizlendi 🌱';
    return 'Tohum ekildi 🌰';
  }

  @override
  Widget build(BuildContext context) {
    final p = progress.clamp(0.0, 1.0);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: size,
          height: size,
          child: CustomPaint(painter: _TreePainter(p)),
        ),
        const SizedBox(height: 8),
        Text(
          label ?? _stageLabel,
          style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 2),
        Text(
          '%${(p * 100).round()} büyüme',
          style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 12),
        ),
      ],
    );
  }
}

class _TreePainter extends CustomPainter {
  final double p;
  _TreePainter(this.p);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final groundY = h * 0.9;

    // Toprak
    final ground = Paint()..color = const Color(0xFF3B2A1A);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromLTWH(0, groundY, w, h - groundY), const Radius.circular(6)),
      ground,
    );
    // Çim
    final grass = Paint()..color = const Color(0xFF2E7D32);
    canvas.drawRect(Rect.fromLTWH(0, groundY, w, 5), grass);

    final cx = w / 2;
    // Gövde yüksekliği ilerlemeyle artar
    final trunkTop = groundY - (h * 0.5) * (0.25 + 0.75 * p);
    final trunkPaint = Paint()
      ..color = const Color(0xFF6D4C2B)
      ..strokeWidth = 6 + 6 * p
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(cx, groundY), Offset(cx, trunkTop), trunkPaint);

    // Dallar (progress > 0.2)
    if (p > 0.2) {
      final branchPaint = Paint()
        ..color = const Color(0xFF6D4C2B)
        ..strokeWidth = 3 + 3 * p
        ..strokeCap = StrokeCap.round;
      final bp = ((p - 0.2) / 0.8).clamp(0.0, 1.0);
      final trunkLen = groundY - trunkTop;
      // simetrik dal çiftleri
      final branches = [
        [0.55, -1, 0.30],
        [0.55, 1, 0.30],
        [0.75, -1, 0.24],
        [0.75, 1, 0.24],
        [0.9, -1, 0.18],
        [0.9, 1, 0.18],
      ];
      for (final b in branches) {
        final atFrac = b[0] as double;
        final dir = (b[1]).toDouble();
        final lenFrac = b[2] as double;
        final startY = groundY - trunkLen * atFrac;
        final len = trunkLen * lenFrac * bp;
        final end = Offset(cx + dir * len, startY - len * 0.7);
        canvas.drawLine(Offset(cx, startY), end, branchPaint);
      }
    }

    // Yaprak tacı (progress > 0.35) — büyüdükçe genişler
    if (p > 0.35) {
      final lp = ((p - 0.35) / 0.65).clamp(0.0, 1.0);
      final crownR = (w * 0.28) * lp + w * 0.06;
      final crownCenter = Offset(cx, trunkTop - crownR * 0.4);
      final leafColors = [
        const Color(0xFF388E3C),
        const Color(0xFF43A047),
        const Color(0xFF66BB6A),
      ];
      // birkaç örtüşen daire ile taç
      final blobs = [
        Offset(crownCenter.dx, crownCenter.dy),
        Offset(crownCenter.dx - crownR * 0.6, crownCenter.dy + crownR * 0.2),
        Offset(crownCenter.dx + crownR * 0.6, crownCenter.dy + crownR * 0.2),
        Offset(crownCenter.dx, crownCenter.dy - crownR * 0.5),
      ];
      for (int i = 0; i < blobs.length; i++) {
        final paint = Paint()..color = leafColors[i % leafColors.length];
        canvas.drawCircle(blobs[i], crownR * (0.7 + 0.05 * i), paint);
      }

      // Çiçekler (progress > 0.7)
      if (p > 0.7) {
        final flowerPaint = Paint()..color = const Color(0xFFF8BBD0);
        final rnd = Random(42);
        final n = (10 * ((p - 0.7) / 0.3)).round();
        for (int i = 0; i < n; i++) {
          final a = rnd.nextDouble() * 2 * pi;
          final r = crownR * (0.3 + rnd.nextDouble() * 0.6);
          final fx = crownCenter.dx + cos(a) * r;
          final fy = crownCenter.dy + sin(a) * r * 0.8;
          canvas.drawCircle(Offset(fx, fy), 3.2, flowerPaint);
        }
      }

      // Meyveler (progress > 0.9)
      if (p > 0.9) {
        final fruitPaint = Paint()..color = const Color(0xFFE53935);
        final rnd = Random(7);
        final n = (8 * ((p - 0.9) / 0.1)).round();
        for (int i = 0; i < n; i++) {
          final a = rnd.nextDouble() * 2 * pi;
          final r = crownR * (0.35 + rnd.nextDouble() * 0.55);
          final fx = crownCenter.dx + cos(a) * r;
          final fy = crownCenter.dy + sin(a) * r * 0.85;
          canvas.drawCircle(Offset(fx, fy), 4.5, fruitPaint);
          canvas.drawCircle(
              Offset(fx - 1.3, fy - 1.3), 1.3, Paint()..color = Colors.white24);
        }
      }
    } else if (p > 0.05) {
      // Filiz (küçük yeşil uç)
      final sprout = Paint()..color = const Color(0xFF66BB6A);
      canvas.drawCircle(Offset(cx, trunkTop), 6 + 8 * p, sprout);
    }
  }

  @override
  bool shouldRepaint(covariant _TreePainter old) => old.p != p;
}
