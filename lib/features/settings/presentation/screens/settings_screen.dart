import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vibration/vibration.dart';
// Asegúrate de que estas importaciones apunten a tus archivos correctos
import '../widgets/connectivity_indicator.dart';
import 'package:monitor/features/settings/providers/connectivity_preferences_provider.dart';

// Constantes del sistema de diseño Industrial
const kIndustrialBg = Color(0xFF121212);
const kIndustrialSurface = Color(0xFF1E1E1E);
const kIndustrialBorder = Colors.white24;
const kIndustrialAccent = Colors.amber;
const kIndustrialRadius = 4.0;

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final preferences = ref.watch(connectivityPreferencesNotifierProvider);

    return Scaffold(
      backgroundColor: kIndustrialBg, // Fondo Oscuro Industrial
      appBar: AppBar(
        title: const Text(
          'SETTINGS',
          style: TextStyle(
            letterSpacing: 1.0,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: kIndustrialSurface,
        elevation: 0, // Sin sombras
        centerTitle: true,
        shape: const Border(
          bottom: BorderSide(color: kIndustrialBorder),
        ), // Borde inferior
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const SizedBox(height: 16),
          _buildSectionHeader(context, 'CONFIGURACIÓN GENERAL'),
          const SizedBox(height: 8),
          Text(
            'Gestiona los parámetros operativos del sistema.',
            style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
          ),
          const SizedBox(height: 24),

          // Sección de Conectividad
          _buildSectionHeader(context, 'ESTADO DE CONEXIÓN'),
          const SizedBox(height: 12),
          // Asumo que este widget también debería seguir el estilo,
          // pero como es importado, lo envuelvo en un contenedor industrial por si acaso
          Container(child: const ConnectivityDetailCard()),

          const SizedBox(height: 24),

          // Configuración del Indicador
          _buildSectionHeader(context, 'PREFERENCIAS DE INDICADOR'),
          const SizedBox(height: 12),

          _buildConnectivitySettings(context, ref, preferences),

          const SizedBox(height: 32),

          // Sección de General
          _buildSectionHeader(context, 'SISTEMA'),
          const SizedBox(height: 12),

          _IndustrialCardContainer(
            children: [
              _buildIndustrialTile(
                icon: Icons.notifications_outlined,
                title: 'Notificaciones',
                subtitle: 'Alertas del sistema',
                trailing: CupertinoSwitch(
                  activeColor: kIndustrialAccent,
                  value: true,
                  onChanged: (value) {},
                ),
              ),
              const Divider(height: 1, color: Colors.white10),
              //_buildIndustrialTile(
              //  icon: Icons.language,
              //  title: 'Idioma',
              //  subtitle: 'Español (ES)',
              //  trailing: const Icon(Icons.chevron_right, color: Colors.grey),
              //  onTap: () {},
              //),
              const Divider(height: 1, color: Colors.white10),
              _buildIndustrialTile(
                icon: Icons.dark_mode_outlined,
                title: 'Tema oscuro',
                subtitle: 'Forzado por sistema',
                trailing: CupertinoSwitch(
                  activeColor: kIndustrialAccent, // Ámbar
                  value: true,
                  onChanged: (value) {},
                ),
              ),
            ],
          ),

          const SizedBox(height: 32),

          // Sección de Información
          _buildSectionHeader(context, 'ACERCA DE'),
          const SizedBox(height: 12),
          _IndustrialCardContainer(
            children: [
              _buildIndustrialTile(
                icon: Icons.info_outline,
                title: 'Versión del Cliente',
                subtitle: 'v0.1.1 (Build 2024)',
              ),
              const Divider(height: 1, color: Colors.white10),
              _buildIndustrialTile(
                icon: Icons.description_outlined,
                title: 'Términos de Servicio',
                trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                onTap: () {},
              ),
              const Divider(height: 1, color: Colors.white10),
              _buildIndustrialTile(
                icon: Icons.privacy_tip_outlined,
                title: 'Política de Privacidad',
                trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                onTap: () {},
              ),
            ],
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  // Helper para títulos de sección (Mayúsculas, estilo técnico)
  Widget _buildSectionHeader(BuildContext context, String text) {
    return Text(
      text,
      style: const TextStyle(
        color: kIndustrialAccent,
        fontWeight: FontWeight.bold,
        letterSpacing: 0.5,
        fontSize: 12,
      ),
    );
  }

  Widget _buildConnectivitySettings(
    BuildContext context,
    WidgetRef ref,
    ConnectivityPreferences preferences,
  ) {
    final notifier = ref.read(connectivityPreferencesNotifierProvider.notifier);

    return _IndustrialCardContainer(
      children: [
        // Habilitar/Deshabilitar indicador
        _buildIndustrialTile(
          icon: Icons.visibility,
          title: 'Mostrar indicador',
          subtitle: 'Visualizar estado en navbar',
          trailing: CupertinoSwitch(
            activeColor: kIndustrialAccent,
            trackColor: Colors.grey[800],
            value: preferences.isEnabled,
            onChanged: (value) async {
              await notifier.updatePreference(isEnabled: value);
            },
          ),
        ),

        const Divider(height: 1, color: Colors.white10),

        // Selector de modo de visualización
        _buildIndustrialTile(
          icon: Icons.palette_outlined,
          title: 'Estilo visual',
          subtitle: preferences.displayModeName,
          enabled: preferences.isEnabled,
          trailing: const Icon(Icons.chevron_right, color: Colors.grey),
          onTap: preferences.isEnabled
              ? () {
                  _showDisplayModeDialog(context, ref, preferences, notifier);
                }
              : null,
        ),

        const Divider(height: 1, color: Colors.white10),

        // Mostrar cuando está online
        _buildIndustrialTile(
          icon: Icons.wifi,
          title: 'Mostrar conectado',
          subtitle: 'Visible incluso con señal estable',
          enabled: preferences.isEnabled,
          trailing: CupertinoSwitch(
            activeColor: kIndustrialAccent,
            trackColor: Colors.grey[800],
            value: preferences.showWhenOnline,
            onChanged: preferences.isEnabled
                ? (value) async {
                    await notifier.updatePreference(showWhenOnline: value);
                  }
                : null,
          ),
        ),

        const Divider(height: 1, color: Colors.white10),

        // Notificaciones
        _buildIndustrialTile(
          icon: Icons.notifications_outlined,
          title: 'Alertas de estado',
          subtitle: 'Notificar cambios de red',
          enabled: preferences.isEnabled,
          trailing: CupertinoSwitch(
            activeColor: kIndustrialAccent,
            trackColor: Colors.grey[800],
            value: preferences.showNotifications,
            onChanged: preferences.isEnabled
                ? (value) async {
                    await notifier.updatePreference(showNotifications: value);
                  }
                : null,
          ),
        ),

        const Divider(height: 1, color: Colors.white10),

        // Vibración
        _buildIndustrialTile(
          icon: Icons.vibration,
          title: 'Feedback Háptico',
          subtitle: 'Vibrar al perder conexión',
          enabled: preferences.isEnabled,
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (preferences.isEnabled && preferences.vibrateOnDisconnect)
                IconButton(
                  icon: const Icon(
                    Icons.play_arrow,
                    size: 20,
                    color: kIndustrialAccent,
                  ),
                  onPressed: () => _testVibration(context),
                ),
              CupertinoSwitch(
                activeColor: kIndustrialAccent,
                trackColor: Colors.grey[800],
                value: preferences.vibrateOnDisconnect,
                onChanged: preferences.isEnabled
                    ? (value) async {
                        await notifier.updatePreference(
                          vibrateOnDisconnect: value,
                        );
                      }
                    : null,
              ),
            ],
          ),
        ),

        const Divider(height: 1, color: Colors.white10),

        // Sonido
        _buildIndustrialTile(
          icon: Icons.volume_up_outlined,
          title: 'Sonido de alerta',
          subtitle: 'Audio al cambiar estado',
          enabled: preferences.isEnabled,
          trailing: CupertinoSwitch(
            activeColor: kIndustrialAccent,
            trackColor: Colors.grey[800],
            value: preferences.playSoundOnChange,
            onChanged: preferences.isEnabled
                ? (value) async {
                    await notifier.updatePreference(playSoundOnChange: value);
                  }
                : null,
          ),
        ),

        const Divider(height: 1, color: Colors.white10),

        // Botón de resetear
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () async {
              // Lógica original mantenida
              final confirmed = await showCupertinoDialog<bool>(
                context: context,
                builder: (context) => CupertinoAlertDialog(
                  // Nota: CupertinoAlertDialog no se estiliza fácilmente, se deja nativo o se hace custom
                  title: const Text('Restablecer configuración'),
                  content: const Text('¿Restablecer valores predeterminados?'),
                  actions: [
                    CupertinoDialogAction(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancelar'),
                    ),
                    CupertinoDialogAction(
                      isDestructiveAction: true,
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Restablecer'),
                    ),
                  ],
                ),
              );

              if (confirmed == true) {
                await notifier.resetToDefaults();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text(
                        'Configuración restablecida',
                        style: TextStyle(color: Colors.black),
                      ),
                      backgroundColor:
                          kIndustrialAccent, // Ámbar para éxito/info
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  );
                }
              }
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Row(
                children: [
                  const Icon(Icons.restore, color: Colors.deepOrangeAccent),
                  const SizedBox(width: 16),
                  Text(
                    'RESTABLECER VALORES',
                    style: TextStyle(
                      color: Colors.deepOrangeAccent.shade100,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ==========================================
  // WIDGETS DE AYUDA (Estilo Industrial)
  // ==========================================

  // Contenedor "Card" con bordes rectos y sin sombra
  Widget _IndustrialCardContainer({required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: kIndustrialSurface,
        borderRadius: BorderRadius.circular(kIndustrialRadius),
        border: Border.all(color: kIndustrialBorder),
      ),
      clipBehavior: Clip.antiAlias, // Asegura que el InkWell no se salga
      child: Column(children: children),
    );
  }

  // Tile personalizado para reemplazar ListTile y controlar colores/bordes
  Widget _buildIndustrialTile({
    required IconData icon,
    required String title,
    String? subtitle,
    Widget? trailing,
    VoidCallback? onTap,
    bool enabled = true,
  }) {
    final Color textColor = enabled ? Colors.white : Colors.grey.shade700;
    final Color iconColor = enabled ? Colors.grey : Colors.grey.shade800;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: enabled ? onTap : null,
        splashColor: kIndustrialAccent.withOpacity(0.1), // Feedback Ámbar
        highlightColor: Colors.white10,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Icon(icon, color: iconColor, size: 24),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: textColor,
                        fontWeight: FontWeight.w500,
                        fontSize: 15,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: enabled
                              ? Colors.grey.shade500
                              : Colors.grey.shade800,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (trailing != null) trailing,
            ],
          ),
        ),
      ),
    );
  }

  // ... (Lógica de vibración _testVibration se mantiene igual, solo ajustando colores de snackbar)
  void _testVibration(BuildContext context) async {
    // ... tu logica original ...
    // Solo asegúrate de cambiar los colors de SnackBar a estilos planos
    // Ejemplo: backgroundColor: kIndustrialSurface, content style white...
    // Para no alargar demasiado el código, asumo que mantienes tu lógica
    // pero te recomiendo usar kIndustrialAccent para éxito y redAccent para error.
    try {
      final hasVibrator = await Vibration.hasVibrator();
      if (hasVibrator == true) {
        await Vibration.vibrate(duration: 300);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Vibración OK',
                style: TextStyle(color: Colors.black),
              ),
              backgroundColor: kIndustrialAccent,
            ),
          );
        }
      } else {
        HapticFeedback.heavyImpact();
      }
    } catch (e) {
      // Error handling
    }
  }

  // ==========================================
  // BOTTOM SHEET INDUSTRIAL
  // ==========================================

  void _showDisplayModeDialog(
    BuildContext context,
    WidgetRef ref,
    ConnectivityPreferences preferences,
    ConnectivityPreferencesNotifier notifier,
  ) {
    final modes = [
      {'value': 0, 'name': 'Solo icono', 'icon': Icons.circle},
      {'value': 1, 'name': 'Icono con texto', 'icon': Icons.label},
      {'value': 2, 'name': 'Punto de color', 'icon': Icons.fiber_manual_record},
      {'value': 3, 'name': 'Badge numérico', 'icon': Icons.badge},
    ];

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: kIndustrialSurface, // Fondo oscuro
      shape: const RoundedRectangleBorder(
        // Borde superior recto/casi recto con línea blanca sutil
        side: BorderSide(color: kIndustrialBorder),
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(kIndustrialRadius),
        ),
      ),
      isScrollControlled: true,
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle bar sutil
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white10,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              Text(
                'VISUALIZACIÓN',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Selecciona el formato del indicador:',
                style: TextStyle(color: Colors.grey.shade500),
              ),
              const SizedBox(height: 24),

              // Options
              ...modes.map((mode) {
                final isSelected = preferences.displayMode == mode['value'];
                // Estilo Industrial: Borde Ambar si seleccionado, Gris si no
                final borderColor = isSelected
                    ? kIndustrialAccent
                    : kIndustrialBorder;
                final textColor = isSelected
                    ? kIndustrialAccent
                    : Colors.white70;

                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: Material(
                    color: Colors
                        .transparent, // Transparente para ver el fondo del modal
                    child: InkWell(
                      onTap: () async {
                        await notifier.updatePreference(
                          displayMode: mode['value'] as int,
                        );
                        if (context.mounted) Navigator.pop(context);
                      },
                      borderRadius: BorderRadius.circular(kIndustrialRadius),
                      splashColor: kIndustrialAccent.withOpacity(0.1),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          vertical: 16,
                          horizontal: 16,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: borderColor,
                            width: isSelected
                                ? 1.5
                                : 1, // Borde fino siempre visible
                          ),
                          borderRadius: BorderRadius.circular(
                            kIndustrialRadius,
                          ),
                          // Fondo sutil si está seleccionado
                          color: isSelected
                              ? kIndustrialAccent.withOpacity(0.05)
                              : Colors.transparent,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              mode['icon'] as IconData,
                              size: 20,
                              color: textColor,
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Text(
                                (mode['name'] as String)
                                    .toUpperCase(), // Texto en mayúsculas estilo técnico
                                style: TextStyle(
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                  color: textColor,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                            if (isSelected)
                              const Icon(
                                Icons.check,
                                color: kIndustrialAccent,
                                size: 20,
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),

              const SizedBox(height: 16),

              // Cancel button estilo Outline
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: const BorderSide(
                      color: Colors.grey,
                    ), // Borde gris neutro
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(kIndustrialRadius),
                    ),
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('CANCELAR'),
                ),
              ),

              SizedBox(height: MediaQuery.of(context).padding.bottom),
            ],
          ),
        );
      },
    );
  }
}
