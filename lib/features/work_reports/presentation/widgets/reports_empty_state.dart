import 'package:flutter/material.dart';

class ReportsEmptyState extends StatelessWidget {
  final bool isOffline;
  final String? error;

  const ReportsEmptyState({
    super.key,
    required this.isOffline,
    this.error,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isOffline ? Icons.wifi_off : Icons.description_outlined,
            size: 64,
            color: colorScheme.onSurface.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            error != null
                ? 'ERROR AL CARGAR REPORTES'
                : isOffline
                    ? 'SIN CONEXIÓN'
                    : 'NO HAY REPORTES',
            style: theme.textTheme.headlineSmall?.copyWith(
              color: colorScheme.onSurface.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            error ?? (isOffline
                ? 'Verifica tu conexión a internet para cargar reportes desde la nube.'
                : 'Crea tu primer reporte usando el botón +'),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurface.withOpacity(0.6),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}