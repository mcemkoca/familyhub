import 'package:flutter/material.dart';

/// Centralized messenger service to replace inline ScaffoldMessenger usage.
/// Reduces 128× repeated SnackBar patterns across 47 files.
class AppMessenger {
  AppMessenger._();

  static void showSuccess(BuildContext context, String message) {
    _show(context, message, backgroundColor: Colors.green);
  }

  static void showError(BuildContext context, String message) {
    _show(context, message, backgroundColor: Colors.red);
  }

  static void showWarning(BuildContext context, String message) {
    _show(context, message, backgroundColor: Colors.orange);
  }

  static void showInfo(BuildContext context, String message) {
    _show(context, message, backgroundColor: Colors.blue);
  }

  static void _show(
    BuildContext context,
    String message, {
    required Color backgroundColor,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }
}
