import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/connectivity_provider.dart';
import '../../providers/connectivity_preferences_provider.dart';
import '../../services/connectivity_service.dart';
import '../../../../core/theme_config.dart';

/// Widget compacto que muestra el estado de conectividad en el navbar
///
/// Opciones de visualización:
/// - Icono solo (compacto)
/// - Icono + texto (detallado)
/// - Punto de color (minimalista)
class ConnectivityIndicator extends ConsumerWidget {
  // ... (Mismo constructor y lógica de build que tu código original) ...
  final ConnectivityDisplayMode? mode;
  final bool? showWhenOnline;

  const ConnectivityIndicator({super.key, this.mode, this.showWhenOnline});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // ... (Mantén tu lógica de Riverpod intacta aquí) ...
    // Solo cambiaremos los métodos _build... de abajo
    final preferences = ref.watch(connectivityPreferencesNotifierProvider);
    final connectionStatusAsync = ref.watch(connectionStatusProvider);

    if (!preferences.isEnabled) return const SizedBox.shrink();

    final displayMode = mode ?? _getModeFromPreference(preferences.displayMode);
    final showOnline = showWhenOnline ?? preferences.showWhenOnline;

    return connectionStatusAsync.when(
      data: (status) {
        if (status == ConnectionStatus.online && !showOnline) {
          return const SizedBox.shrink();
        }
        return _buildIndicator(context, status, displayMode);
      },
      loading: () => _buildIndicator(context, ConnectionStatus.offline, displayMode),
      error: (_, __) => _buildIndicator(context, ConnectionStatus.offline, displayMode),
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
    // Redirigimos al método correcto
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
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          border: Border.all(color: color), // Borde cuadrado
          borderRadius: BorderRadius.circular(4), // Regla Radius 4
        ),
        child: Icon(icon, color: color, size: 20),
      ),
    );
  }

  Widget _buildIconWithText(ConnectionStatus status) {
    final (icon, color, tooltip) = _getStatusInfo(status);
    return Tooltip(
      message: tooltip,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.transparent, // Sin fondo solido
          borderRadius: BorderRadius.circular(4), // Regla Radius 4
          border: Border.all(color: color, width: 1), // Borde definido
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 14),
            const SizedBox(width: 8),
            Text(
              _getStatusText(status),
              style: TextStyle(
                color: color,
                fontSize: 12, // Un poco más grande para legibilidad
                fontWeight: FontWeight.bold,
                letterSpacing: 1.0, // Espaciado técnico
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDotOnly(ConnectionStatus status) {
    final (_, color, tooltip) = _getStatusInfo(status);
    return Tooltip(
      message: tooltip,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8),
        width: 12,
        height: 12,
        decoration: BoxDecoration(
          color: color, // El punto sí puede ser sólido
          shape: BoxShape.rectangle, // Cambiado de círculo a cuadrado
          borderRadius: BorderRadius.circular(2), // Ligeramente redondeado
          // Eliminada la sombra (BoxShadow) según reglas
        ),
      ),
    );
  }

  Widget _buildBadge(ConnectionStatus status) {
    // Para el estilo industrial, Badge e IconWithText son muy similares,
    // pero Badge puede tener un fondo semitransparente muy sutil.
    final (icon, color, tooltip) = _getStatusInfo(status);
    return Tooltip(
      message: tooltip,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1), // Fondo muy sutil
          borderRadius: BorderRadius.circular(4), // Regla Radius 4
          border: Border.all(color: color),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 14),
            const SizedBox(width: 4),
            Text(
              _getStatusText(status),
              style: TextStyle(
                color: color,
                fontSize: 10,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
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
        return (
          Icons.wifi,
          AppTheme.success,
          'Conectado a Internet',
        );
      case ConnectionStatus.noInternet:
        return (Icons.wifi_off, AppTheme.warning, 'Sin Internet');
      case ConnectionStatus.offline:
        return (Icons.signal_wifi_off, AppTheme.error, 'Offline');
    }
  }

  String _getStatusText(ConnectionStatus status) {
    switch (status) {
      case ConnectionStatus.online:
        return 'ONLINE'; // Mayúsculas técnica
      case ConnectionStatus.noInternet:
        return 'LOCAL';
      case ConnectionStatus.offline:
        return 'OFFLINE';
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
    
    // REGLA: Color de fondo técnico y Borde Gris Suave
    final borderColor = AppTheme.border;
    final cardBgColor = AppTheme.surface; 

    // REGLA: Reemplazar Card con Container + Decoration
    return Container(
      decoration: BoxDecoration(
        color: cardBgColor,
        border: Border.all(color: borderColor),
        borderRadius: BorderRadius.circular(4), // REGLA: Radio casi recto
      ),
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

    // Colores de texto para alto contraste en fondo oscuro
    final titleStyle = Theme.of(context).textTheme.titleLarge?.copyWith(
      fontWeight: FontWeight.bold,
      color: Colors.white, // Blanco puro para títulos
      letterSpacing: 0.5,
    );
    
    final subtitleStyle = Theme.of(context).textTheme.bodyMedium?.copyWith(
      color: Colors.grey.shade400, // Gris claro para subtítulos
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min, // Ajuste al contenido
      children: [
        // CABECERA
        Row(
          children: [
            // Icono en un contenedor cuadrado sutil (opcional, pero se ve más técnico)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _getStatusColor(status).withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: _getStatusColor(status).withOpacity(0.3)),
              ),
              child: Icon(
                _getMainIcon(status),
                size: 28, // Un poco más pequeño para balancear
                color: _getStatusColor(status),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _getStatusTitle(status).toUpperCase(), // Estilo técnico
                    style: titleStyle?.copyWith(fontSize: 16),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _getStatusDescription(status),
                    style: subtitleStyle,
                  ),
                ],
              ),
            ),
          ],
        ),

        // REGLA: Separador Divider blanco suave
        const Divider(height: 32, color: Colors.white10),

        // ESTADOS INDIVIDUALES
        _buildStatusRow(
          context,
          'Conexión de red',
          hasNetwork ? 'CONECTADO' : 'DESCONECTADO', // Mayúsculas
          hasNetwork ? Icons.check_circle_outline : Icons.highlight_off, // Iconos outline son más limpios
          hasNetwork ? Colors.greenAccent : Colors.redAccent, // Accents brillan mejor en oscuro
        ),
        const SizedBox(height: 16), // Más espacio para respirar
        _buildStatusRow(
          context,
          'Acceso a Internet',
          isOnline ? 'DISPONIBLE' : 'NO DISPONIBLE',
          isOnline ? Icons.check_circle_outline : Icons.highlight_off,
          isOnline ? Colors.greenAccent : Colors.redAccent,
        ),

        // CAJA DE ADVERTENCIA (Solo si no hay internet)
        if (!isOnline) ...[
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              // REGLA: Fondo transparente con tinte y borde definido
              color: Colors.orangeAccent.withOpacity(0.05),
              border: Border.all(color: Colors.orangeAccent.withOpacity(0.5)),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start, // Alinear arriba por si el texto es largo
              children: [
                const Icon(
                  Icons.warning_amber_rounded, // Icono más técnico
                  color: Colors.orangeAccent,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Funciones limitadas. Los datos se guardarán localmente.',
                    style: TextStyle(
                      color: Colors.orangeAccent.shade100,
                      fontSize: 13,
                      height: 1.4, // Mejor lectura
                    ),
                  ),
                ),
              ],
            ),
          ),
        ]
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
        return AppTheme.success;
      case ConnectionStatus.noInternet:
        return AppTheme.warning;
      case ConnectionStatus.offline:
        return AppTheme.error;
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
