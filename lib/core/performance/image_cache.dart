import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

/// Optimized image widgets using cached_network_image.
class OptimizedImage {
  static Widget network({
    required String url,
    double? width,
    double? height,
    BoxFit fit = BoxFit.cover,
    Widget? placeholder,
    Widget? errorWidget,
  }) {
    return CachedNetworkImage(
      imageUrl: url,
      width: width,
      height: height,
      fit: fit,
      memCacheWidth: width?.toInt(),
      memCacheHeight: height?.toInt(),
      maxWidthDiskCache: 1080,
      maxHeightDiskCache: 1080,
      placeholder: (context, url) => placeholder ?? _defaultPlaceholder(),
      errorWidget: (context, url, error) => errorWidget ?? _defaultError(),
      fadeInDuration: const Duration(milliseconds: 150),
      fadeOutDuration: const Duration(milliseconds: 150),
    );
  }

  static Widget avatar({
    required String? url,
    required String fallbackText,
    double size = 48,
    Color? backgroundColor,
  }) {
    if (url == null || url.isEmpty) {
      return _fallbackAvatar(fallbackText, size, backgroundColor);
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(size / 4),
      child: CachedNetworkImage(
        imageUrl: url,
        width: size,
        height: size,
        fit: BoxFit.cover,
        memCacheWidth: size.toInt() * 2, // Retina
        placeholder: (_, _) =>
            _fallbackAvatar(fallbackText, size, backgroundColor),
        errorWidget: (_, _, _) =>
            _fallbackAvatar(fallbackText, size, backgroundColor),
      ),
    );
  }

  static Widget _defaultPlaceholder() {
    return Container(
      color: const Color(0xFF1E293B),
      child: const Center(
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation(Color(0xFF3B82F6)),
        ),
      ),
    );
  }

  static Widget _defaultError() {
    return Container(
      color: const Color(0xFF1E293B),
      child: const Icon(Icons.broken_image, color: Color(0xFF64748B)),
    );
  }

  static Widget _fallbackAvatar(String text, double size, Color? bgColor) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: bgColor ?? const Color(0xFF3B82F6),
        borderRadius: BorderRadius.circular(size / 4),
      ),
      child: Center(
        child: Text(
          text.isNotEmpty ? text[0].toUpperCase() : '?',
          style: TextStyle(
            color: Colors.white,
            fontSize: size * 0.4,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
