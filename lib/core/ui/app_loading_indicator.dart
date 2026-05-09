import 'package:flutter/material.dart';

/// Centralized loading indicator to replace 75× CircularProgressIndicator usage.
/// Supports size variants and optional label.
class AppLoadingIndicator extends StatelessWidget {
  const AppLoadingIndicator({
    super.key,
    this.size = AppLoadingSize.medium,
    this.label,
    this.color,
  });

  final AppLoadingSize size;
  final String? label;
  final Color? color;

  double get _dimension => switch (size) {
    AppLoadingSize.small => 16,
    AppLoadingSize.medium => 32,
    AppLoadingSize.large => 48,
  };

  double get _strokeWidth => switch (size) {
    AppLoadingSize.small => 2,
    AppLoadingSize.medium => 3,
    AppLoadingSize.large => 4,
  };

  @override
  Widget build(BuildContext context) {
    final indicator = SizedBox(
      width: _dimension,
      height: _dimension,
      child: CircularProgressIndicator(
        strokeWidth: _strokeWidth,
        valueColor: color != null
            ? AlwaysStoppedAnimation<Color>(color!)
            : null,
      ),
    );

    if (label == null) return indicator;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        indicator,
        const SizedBox(height: 8),
        Text(
          label!,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}

enum AppLoadingSize { small, medium, large }
