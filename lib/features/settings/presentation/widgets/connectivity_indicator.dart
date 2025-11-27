import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/connectivity_provider.dart';
import '../../providers/connectivity_preferences_provider.dart';
import '../../services/connectivity_service.dart';

/// Widget compacto que muestra el estado de conectividad en el navbar
///
/// Opciones de visualización:
/// - Icono solo (compacto)
/// - Icono + texto (detallado)
/// - Punto de color (minimalista)
class ConnectivityIndicator extends ConsumerWidget {
  final ConnectivityDisplayMode? mode;
  final bool? showWhenOnline;

  const ConnectivityIndicator({super.key, this.mode, this.showWhenOnline});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Usar StateNotifier en lugar de Stream para mejor rendimiento
    final preferences = ref.watch(connectivityPreferencesNotifierProvider);
    final connectionStatusAsync = ref.watch(connectionStatusProvider);

    // Si las preferencias están deshabilitadas, no mostrar nada
    if (!preferences.isEnabled) {
      return const SizedBox.shrink();
    }

    // Usar preferencias del usuario o valores proporcionados
    final displayMode = mode ?? _getModeFromPreference(preferences.displayMode);
    final showOnline = showWhenOnline ?? preferences.showWhenOnline;

    return connectionStatusAsync.when(
      data: (status) {
        // Ocultar si está online y showWhenOnline es false
        if (status == ConnectionStatus.online && !showOnline) {
          return const SizedBox.shrink();
        }

        return _buildIndicator(context, status, displayMode);
      },
      loading: () => const SizedBox.shrink(), // No mostrar nada mientras carga
      error: (_, __) => const SizedBox.shrink(), // Ocultar si hay error
    );
  }

  ConnectivityDisplayMode _getModeFromPreference(int modeValue) {
    switch (modeValue) {
      case 0:
        return ConnectivityDisplayMode.iconOnly;
      case 1:
        return ConnectivityDisplayMode.iconWithText;
      case 2:
        return ConnectivityDisplayMode.dotOnly;
      case 3:
        return ConnectivityDisplayMode.badge;
      default:
        return ConnectivityDisplayMode.iconOnly;
    }
  }

  Widget _buildIndicator(
    BuildContext context,
    ConnectionStatus status,
    ConnectivityDisplayMode displayMode,
  ) {
    switch (displayMode) {
      case ConnectivityDisplayMode.iconOnly:
        return _buildIconOnly(status);
      case ConnectivityDisplayMode.iconWithText:
        return _buildIconWithText(status);
      case ConnectivityDisplayMode.dotOnly:
        return _buildDotOnly(status);
      case ConnectivityDisplayMode.badge:
        return _buildBadge(status);
    }
  }

  Widget _buildIconOnly(ConnectionStatus status) {
    final (icon, color, tooltip) = _getStatusInfo(status);

    return Tooltip(
      message: tooltip,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        child: Icon(icon, color: color, size: 20),
      ),
    );
  }

  Widget _buildIconWithText(ConnectionStatus status) {
    final (icon, color, tooltip) = _getStatusInfo(status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      margin: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.5), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min, // Ajustar al contenido
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 6),
          Flexible(
            // Permitir que el texto se ajuste
            child: Text(
              _getStatusText(status),
              style: TextStyle(
                color: color,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis, // Evitar desbordamiento
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDotOnly(ConnectionStatus status) {
    final (_, color, tooltip) = _getStatusInfo(status);

    return Tooltip(
      message: tooltip,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8),
        width: 10,
        height: 10,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.5),
              blurRadius: 4,
              spreadRadius: 1,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBadge(ConnectionStatus status) {
    final (icon, color, tooltip) = _getStatusInfo(status);

    return Tooltip(
      message: tooltip,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        margin: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 14),
            const SizedBox(width: 4),
            Text(
              _getStatusText(status),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  (IconData, Color, String) _getStatusInfo(ConnectionStatus status) {
    switch (status) {
      case ConnectionStatus.online:
        return (Icons.wifi, Colors.green.shade600, 'Conectado a Internet');
      case ConnectionStatus.noInternet:
        return (
          Icons.wifi_off,
          Colors.orange.shade700,
          'Conectado pero sin Internet',
        );
      case ConnectionStatus.offline:
        return (Icons.signal_wifi_off, Colors.red.shade700, 'Sin conexión');
    }
  }

  String _getStatusText(ConnectionStatus status) {
    switch (status) {
      case ConnectionStatus.online:
        return 'Conectado';
      case ConnectionStatus.noInternet:
        return 'Sin Internet';
      case ConnectionStatus.offline:
        return 'Desconectado';
    }
  }
}

/// Modos de visualización para el indicador
enum ConnectivityDisplayMode {
  /// Solo icono (más compacto)
  iconOnly,

  /// Icono con texto (más informativo)
  iconWithText,

  /// Solo punto de color (minimalista)
  dotOnly,

  /// Badge con fondo de color (destacado)
  badge,
}

/// Widget para mostrar el estado detallado en configuración
/// Optimizado para carga rápida sin loading states
class ConnectivityDetailCard extends ConsumerWidget {
  const ConnectivityDetailCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connectionStatusAsync = ref.watch(connectionStatusProvider);

    // Mostrar el estado actual sin loading states
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: connectionStatusAsync.when(
          data: (status) => _buildDetailContent(context, status),
          loading: () => _buildDetailContent(context, ConnectionStatus.offline),
          error: (_, __) =>
              _buildDetailContent(context, ConnectionStatus.offline),
        ),
      ),
    );
  }

  Widget _buildDetailContent(BuildContext context, ConnectionStatus status) {
    final isOnline = status == ConnectionStatus.online;
    final hasNetwork = status != ConnectionStatus.offline;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              _getMainIcon(status),
              size: 32,
              color: _getStatusColor(status),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _getStatusTitle(status),
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _getStatusDescription(status),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const Divider(height: 32),
        _buildStatusRow(
          context,
          'Conexión de red',
          hasNetwork ? 'Conectado' : 'Desconectado',
          hasNetwork ? Icons.check_circle : Icons.cancel,
          hasNetwork ? Colors.green : Colors.red,
        ),
        const SizedBox(height: 12),
        _buildStatusRow(
          context,
          'Acceso a Internet',
          isOnline ? 'Disponible' : 'No disponible',
          isOnline ? Icons.check_circle : Icons.cancel,
          isOnline ? Colors.green : Colors.red,
        ),
        const SizedBox(height: 20),
        if (!isOnline)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orange.shade200),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: Colors.orange.shade700,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Algunas funciones pueden no estar disponibles sin conexión',
                    style: TextStyle(
                      color: Colors.orange.shade900,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildStatusRow(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Row(
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(width: 12),
        Expanded(
          child: Text(label, style: Theme.of(context).textTheme.bodyMedium),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }

  IconData _getMainIcon(ConnectionStatus status) {
    switch (status) {
      case ConnectionStatus.online:
        return Icons.wifi;
      case ConnectionStatus.noInternet:
        return Icons.wifi_off;
      case ConnectionStatus.offline:
        return Icons.signal_wifi_off;
    }
  }

  Color _getStatusColor(ConnectionStatus status) {
    switch (status) {
      case ConnectionStatus.online:
        return Colors.green.shade600;
      case ConnectionStatus.noInternet:
        return Colors.orange.shade700;
      case ConnectionStatus.offline:
        return Colors.red.shade700;
    }
  }

  String _getStatusTitle(ConnectionStatus status) {
    switch (status) {
      case ConnectionStatus.online:
        return 'Conectado a Internet';
      case ConnectionStatus.noInternet:
        return 'Red Local Únicamente';
      case ConnectionStatus.offline:
        return 'Sin Conexión';
    }
  }

  String _getStatusDescription(ConnectionStatus status) {
    switch (status) {
      case ConnectionStatus.online:
        return 'Todas las funciones están disponibles';
      case ConnectionStatus.noInternet:
        return 'Conectado a red pero sin acceso a Internet';
      case ConnectionStatus.offline:
        return 'No hay conexión de red disponible';
    }
  }
}