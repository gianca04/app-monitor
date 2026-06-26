import 'package:flutter/material.dart';
import 'package:monitor/core/theme_config.dart';

class IndustrialFeedback {
  static void showSuccess(
    BuildContext context, {
    required String message,
    VoidCallback? onDismiss,
    String? actionLabel,
    VoidCallback? onAction,
    Duration duration = const Duration(seconds: 4),
  }) {
    _showSnackBar(
      context,
      message: message,
      icon: Icons.check_circle_outline,
      iconColor: AppTheme.success,
      actionLabel: actionLabel,
      onAction: onAction,
      duration: duration,
    );
  }

  static void showError(
    BuildContext context, {
    required String message,
    VoidCallback? onDismiss,
    String? actionLabel,
    VoidCallback? onAction,
    Duration duration = const Duration(seconds: 5),
  }) {
    _showSnackBar(
      context,
      message: message,
      icon: Icons.error_outline,
      iconColor: AppTheme.error,
      actionLabel: actionLabel,
      onAction: onAction,
      duration: duration,
    );
  }

  static void showWarning(
    BuildContext context, {
    required String message,
    VoidCallback? onDismiss,
    String? actionLabel,
    VoidCallback? onAction,
    Duration duration = const Duration(seconds: 4),
  }) {
    _showSnackBar(
      context,
      message: message,
      icon: Icons.warning_amber_outlined,
      iconColor: AppTheme.warning,
      actionLabel: actionLabel,
      onAction: onAction,
      duration: duration,
    );
  }

  static void showInfo(
    BuildContext context, {
    required String message,
    VoidCallback? onDismiss,
    String? actionLabel,
    VoidCallback? onAction,
    Duration duration = const Duration(seconds: 4),
  }) {
    _showSnackBar(
      context,
      message: message,
      icon: Icons.info_outline,
      iconColor: AppTheme.primaryAccent,
      actionLabel: actionLabel,
      onAction: onAction,
      duration: duration,
    );
  }

  static void _showSnackBar(
    BuildContext context, {
    required String message,
    required IconData icon,
    required Color iconColor,
    String? actionLabel,
    VoidCallback? onAction,
    required Duration duration,
  }) {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    scaffoldMessenger.removeCurrentSnackBar();
    scaffoldMessenger.showSnackBar(
      SnackBar(
        backgroundColor: AppTheme.inputFill,
        behavior: SnackBarBehavior.floating,
        duration: duration,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.kRadius),
          side: const BorderSide(color: AppTheme.border),
        ),
        content: Row(
          children: [
            Icon(
              icon,
              color: iconColor,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message.toUpperCase(),
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
        ),
        action: actionLabel != null && onAction != null
            ? SnackBarAction(
                label: actionLabel,
                textColor: AppTheme.primaryAccent,
                onPressed: onAction,
              )
            : null,
      ),
    );
  }
}
