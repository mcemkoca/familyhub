import 'package:flutter/material.dart';

/// Centralized messenger service to replace inline ScaffoldMessenger usage.
/// Reduces 128× repeated SnackBar patterns across 47 files.
class AppMessenger {
  AppMessenger._();

  static void showSuccess(BuildContext context, String message) {
    _show(context, message, backgroundColor: Colors.green, label: 'Success');
  }

  static void showError(BuildContext context, String message) {
    _show(context, message, backgroundColor: Colors.red, label: 'Error');
  }

  static void showWarning(BuildContext context, String message) {
    _show(context, message, backgroundColor: Colors.orange, label: 'Warning');
  }

  static void showInfo(BuildContext context, String message) {
    _show(context, message, backgroundColor: Colors.blue, label: 'Info');
  }

  static void _show(
    BuildContext context,
    String message, {
    required Color backgroundColor,
    required String label,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Semantics(
          label: label,
          child: Text(message),
        ),
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
