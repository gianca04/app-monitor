import 'package:flutter/material.dart';
import 'package:monitor/core/theme_config.dart';
import 'package:monitor/core/router/root_navigator_key.dart';

class IndustrialFeedback {
  static OverlayEntry? _activeEntry;

  static void showSuccess({
    required String message,
    required VoidCallback onDismiss,
  }) {
    _showOverlay(
      content: _buildSuccessCard(
        message: message,
        onDismiss: onDismiss,
      ),
    );
  }

  static void showError({
    required String message,
    required VoidCallback onDismiss,
  }) {
    _showOverlay(
      content: _buildErrorCard(
        message: message,
        onDismiss: onDismiss,
      ),
    );
  }

  static void _showOverlay({required Widget content}) {
    final overlay = rootNavigatorKey.currentState?.overlay;
    if (overlay == null) return;

    _activeEntry?.remove();

    late final OverlayEntry entry;

    entry = OverlayEntry(
      builder: (context) => Positioned.fill(
        child: SafeArea(
          child: Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Material(
                color: Colors.transparent,
                child: content,
              ),
            ),
          ),
        ),
      ),
    );

    _activeEntry = entry;
    overlay.insert(entry);

    Future.delayed(const Duration(seconds: 4), () {
      if (_activeEntry == entry) {
        entry.remove();
        _activeEntry = null;
      }
    });
  }

  static Widget _buildSuccessCard({
    required String message,
    required VoidCallback onDismiss,
  }) {
    const color = Color(0xFF00C853);

    return _IndustrialFeedbackCard(
      borderColor: color,
      headerColor: color,
      headerIcon: Icons.check_box_sharp,
      headerText: 'OPERACION EXITOSA',
      headerTextColor: Colors.black,
      actionText: '[OK]',
      actionTextColor: Colors.black,
      message: message,
      messageColor: color,
      onDismiss: onDismiss,
      showAccentBar: false,
    );
  }

  static Widget _buildErrorCard({
    required String message,
    required VoidCallback onDismiss,
  }) {
    final color = AppTheme.error;

    return _IndustrialFeedbackCard(
      borderColor: color.withOpacity(0.5),
      headerColor: color,
      headerIcon: Icons.warning_amber_sharp,
      headerText: 'ERROR',
      headerTextColor: Colors.white,
      actionText: '[X]',
      actionTextColor: Colors.white,
      message: message,
      messageColor: color,
      onDismiss: onDismiss,
      showAccentBar: true,
    );
  }
}

class _IndustrialFeedbackCard extends StatelessWidget {
  const _IndustrialFeedbackCard({
    required this.borderColor,
    required this.headerColor,
    required this.headerIcon,
    required this.headerText,
    required this.headerTextColor,
    required this.actionText,
    required this.actionTextColor,
    required this.message,
    required this.messageColor,
    required this.onDismiss,
    required this.showAccentBar,
  });

  final Color borderColor;
  final Color headerColor;
  final IconData headerIcon;
  final String headerText;
  final Color headerTextColor;
  final String actionText;
  final Color actionTextColor;
  final String message;
  final Color messageColor;
  final VoidCallback onDismiss;
  final bool showAccentBar;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: borderColor.withOpacity(showAccentBar ? 0.05 : 0.1),
        border: Border.all(color: borderColor, width: 1.5),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            color: headerColor,
            child: Row(
              children: [
                Icon(
                  headerIcon,
                  color: headerTextColor,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Text(
                  headerText,
                  style: TextStyle(
                    color: headerTextColor,
                    fontFamily: 'monospace',
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                  ),
                ),
                const Spacer(),
                InkWell(
                  onTap: onDismiss,
                  child: Text(
                    actionText,
                    style: TextStyle(
                      color: actionTextColor,
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (showAccentBar) ...[
                  Container(
                    width: 2,
                    height: 24,
                    color: messageColor.withOpacity(0.5),
                    margin: const EdgeInsets.only(top: 2, right: 12),
                  ),
                ],
                Expanded(
                  child: Text(
                    message.toUpperCase(),
                    style: TextStyle(
                      color: messageColor,
                      fontFamily: 'monospace',
                      fontSize: 12,
                      height: 1.4,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
