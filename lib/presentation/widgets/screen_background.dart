import 'package:flutter/material.dart';

/// Bir ekranın arkasına tam-kaplayan görsel yerleştirir; görsel yoksa (henüz
/// eklenmemişse) sessizce düz koyu renge düşer — asla çökmez.
///
/// Kullanım: Scaffold(backgroundColor: Colors.transparent, body: ScreenBackground(
///   asset: 'assets/images/backgrounds/shopping_bg.png', child: ...));
class ScreenBackground extends StatelessWidget {
  final String asset;
  final Widget child;

  /// Görsel yüklenene/eklenene kadar gösterilecek düz renk.
  final Color fallback;

  /// Görselin üzerine hafif karartma (içerik okunabilirliği için).
  final double overlayOpacity;

  const ScreenBackground({
    super.key,
    required this.asset,
    required this.child,
    this.fallback = const Color(0xFF0A0A0F),
    this.overlayOpacity = 0.35,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        ColoredBox(color: fallback),
        Image.asset(
          asset,
          fit: BoxFit.cover,
          // Asset henüz eklenmemişse çökme — düz renk arkada zaten var.
          errorBuilder: (_, _, _) => const SizedBox.shrink(),
        ),
        if (overlayOpacity > 0)
          ColoredBox(color: Colors.black.withValues(alpha: overlayOpacity)),
        child,
      ],
    );
  }
}
