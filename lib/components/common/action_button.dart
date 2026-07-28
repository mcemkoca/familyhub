import 'package:flutter/material.dart';
import 'package:familyhub/l10n/app_localizations.dart';
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
///   label: AppLocalizations.of(context).login,
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
            Text(AppLocalizations.of(context).abProcessing),
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
            const SnackBar(
              content: Text('✅ İşlem başarılı'),
              backgroundColor: Color(0xFF10B981),
              behavior: SnackBarBehavior.floating,
              duration: Duration(seconds: 2),
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
                label: AppLocalizations.of(context).cdRetry,
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

    if (widget.icon != null) {
      return ElevatedButton.icon(
        onPressed: _isLoading ? null : _handlePress,
        icon: _isLoading
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white70,
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
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white70,
              ),
            )
          : Text(widget.label),
    );
  }
}
