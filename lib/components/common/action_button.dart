import 'package:flutter/material.dart';
import '../../config/constants.dart';
import '../../core/navigation/action_registry.dart';

/// Universal action button that wraps [ActionRegistry.execute] with
/// built-in loading states, success/error feedback, and auto-retry.
///
/// Usage:
/// ```dart
/// ActionButton(
///   action: 'login',
///   params: {'email': 'a@b.com', 'password': '...'},
///   label: 'Giriş Yap',
///   icon: Icons.login,
/// )
/// ```
class ActionButton extends StatefulWidget {
  final String action;
  final Map<String, dynamic>? params;
  final String label;
  final IconData? icon;
  final ButtonStyle? style;
  final VoidCallback? onSuccess;
  final void Function(String error)? onError;
  final bool showLoading;
  final bool showFeedback;

  const ActionButton({
    super.key,
    required this.action,
    this.params,
    required this.label,
    this.icon,
    this.style,
    this.onSuccess,
    this.onError,
    this.showLoading = true,
    this.showFeedback = true,
  });

  @override
  State<ActionButton> createState() => _ActionButtonState();
}

class _ActionButtonState extends State<ActionButton> {
  bool _isLoading = false;

  Future<void> _handlePress() async {
    if (_isLoading) return;

    final scaffold = ScaffoldMessenger.of(context);
    SnackBar? loadingSnack;

    if (widget.showLoading) {
      setState(() => _isLoading = true);
      loadingSnack = SnackBar(
        content: Row(
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(width: 12),
            const Text('İşleniyor...'),
          ],
        ),
        duration: const Duration(days: 1),
        behavior: SnackBarBehavior.floating,
      );
      scaffold.showSnackBar(loadingSnack);
    }

    try {
      await ActionRegistry.execute(widget.action, widget.params);

      if (mounted) {
        scaffold.hideCurrentSnackBar();

        if (widget.showFeedback) {
          scaffold.showSnackBar(
            SnackBar(
              content: const Text('✅ İşlem başarılı'),
              backgroundColor: AppColors.success,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 2),
            ),
          );
        }

        widget.onSuccess?.call();
      }
    } catch (e) {
      if (mounted) {
        scaffold.hideCurrentSnackBar();

        final errorMsg = _formatError(e);

        if (widget.showFeedback) {
          scaffold.showSnackBar(
            SnackBar(
              content: Text('❌ $errorMsg'),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
              action: SnackBarAction(
                label: 'Tekrar Dene',
                textColor: Colors.white,
                onPressed: _handlePress,
              ),
              duration: const Duration(seconds: 6),
            ),
          );
        }

        widget.onError?.call(errorMsg);
      }
    } finally {
      if (mounted && widget.showLoading) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _formatError(Object error) {
    final msg = error.toString().toLowerCase();
    if (msg.contains('network') || msg.contains('socket') || msg.contains('connection')) {
      return 'İnternet bağlantısı yok';
    }
    if (msg.contains('timeout')) {
      return 'Bağlantı zaman aşımına uğradı';
    }
    if (msg.contains('auth') || msg.contains('giriş') || msg.contains('şifre') || msg.contains('e-posta')) {
      return error.toString().replaceAll('Exception: ', '');
    }
    if (msg.contains('validation') || msg.contains('geçersiz')) {
      return error.toString().replaceAll('Exception: ', '');
    }
    return 'Bir hata oluştu';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (widget.icon != null) {
      return ElevatedButton.icon(
        onPressed: _isLoading ? null : _handlePress,
        icon: _isLoading
            ? SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: isDark ? Colors.white70 : Colors.white,
                ),
              )
            : Icon(widget.icon),
        label: Text(widget.label),
        style: widget.style,
      );
    }

    return ElevatedButton(
      onPressed: _isLoading ? null : _handlePress,
      style: widget.style,
      child: _isLoading
          ? SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: isDark ? Colors.white70 : Colors.white,
              ),
            )
          : Text(widget.label),
    );
  }
}
