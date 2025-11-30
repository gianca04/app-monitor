import 'package:flutter/material.dart';
import 'package:monitor/core/theme_config.dart'; // Ajusta tu import

class OfflineBanner extends StatelessWidget {
  const OfflineBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      width: double.infinity,
      color: AppTheme.warning.withOpacity(0.15),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          const Icon(Icons.wifi_off, color: AppTheme.warning, size: 16),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'MODO OFFLINE ACTIVADO',
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppTheme.warning,
                fontWeight: FontWeight.bold,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }
}