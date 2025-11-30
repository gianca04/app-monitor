import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:monitor/core/theme_config.dart';
import '../../../settings/providers/connectivity_provider.dart';
import '../../../settings/services/connectivity_service.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connectivityAsync = ref.watch(connectionStatusProvider);
    final isOnline = connectivityAsync.maybeWhen(
      data: (status) => status == ConnectionStatus.online,
      orElse: () => false,
    );

    final Color borderColor = AppTheme.border; // Borde suave
    return Scaffold(
      backgroundColor: AppTheme.background, // Fondo principal muy oscuro
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // SECCIÓN 1: ESTADO DE REGISTROS (Resumen Operativo)
            const SectionTitle(title: "ESTADO DE SINCRONIZACIÓN"),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TechCard(
                    title: "Por Sincronizar",
                    value: "12", // Dato dinámico
                    icon: Icons.cloud_upload_outlined,
                    accentColor: Colors.orangeAccent,
                    borderColor: borderColor,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TechCard(
                    title: "Guardados Local",
                    value: "45", // Dato dinámico
                    icon: Icons.save_alt,
                    accentColor: Colors.blueAccent,
                    borderColor: borderColor,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // SECCIÓN 2: DATOS MAESTROS (Proyectos y Colaboradores)
            const SectionTitle(title: "DATOS MAESTROS"),
            const SizedBox(height: 10),
            
            
            
            // Tarjeta de Proyectos
            SyncStatusCard(
              title: "Proyectos",
              subtitle: "Asignados: 3",
              lastSync: "12/10/2023 09:15",
              borderColor: borderColor,
            ),

            const SizedBox(height: 32),

            // SECCIÓN 3: ACCIONES RÁPIDAS
            // Botón 1: Nuevo Reporte (Online/Estándar)
            ActionButton(
              label: "NUEVO REPORTE",
              icon: Icons.add_circle_outline,
              isPrimary: true,
              enabled: isOnline,
              onTap: () async {
                final connectivity = ref.read(connectionStatusProvider);
                final isCurrentlyOnline = connectivity.maybeWhen(
                  data: (status) => status == ConnectionStatus.online,
                  orElse: () => false,
                );
                if (isCurrentlyOnline) {
                  context.go('/work-reports/create');
                }
              },
            ),
            
            const SizedBox(height: 16),
            
            // Botón 2: Reporte Offline
            ActionButton(
              label: "NUEVO REPORTE SIN CONEXIÓN",
              icon: Icons.wifi_off,
              isPrimary: false, // Estilo secundario pero con borde
              onTap: () {},
            ),
          ],
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// WIDGETS REUTILIZABLES (Cumpliendo tus Reglas de Diseño)
// -----------------------------------------------------------------------------

class TechCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color accentColor;
  final Color borderColor;

  const TechCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.accentColor,
    required this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    // Regla: Bordes rectos (Radius 4), Border.all, Sin sombras
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {}, // Regla: Feedback InkWell
        borderRadius: BorderRadius.circular(4),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(color: borderColor),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: accentColor, size: 28),
              const SizedBox(height: 12),
              Text(
                value,
                style: TextStyle(
                  fontSize: 28, 
                  fontWeight: FontWeight.bold, 
                  color: AppTheme.textPrimary
                ),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SyncStatusCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String lastSync;
  final Color borderColor;

  const SyncStatusCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.lastSync,
    required this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {},
        borderRadius: BorderRadius.circular(4),
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: borderColor),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: 16, 
                            fontWeight: FontWeight.w600, 
                            color: AppTheme.textPrimary
                          ),
                        ),
                        Text(
                          subtitle,
                          style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                        ),
                      ],
                    ),
                    const Icon(Icons.sync, color: AppTheme.textSecondary),
                  ],
                ),
              ),
              // Regla: Separador Divider blanco suave
              const Divider(height: 1, color: Colors.white10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    const Icon(Icons.access_time, size: 14, color: AppTheme.textSecondary),
                    const SizedBox(width: 8),
                    Text(
                      "Última sinc.: $lastSync",
                      style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isPrimary;
  final bool enabled;
  final VoidCallback? onTap;

  const ActionButton({
    super.key,
    required this.label,
    required this.icon,
    required this.isPrimary,
    this.enabled = true,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Si es primario borde ámbar, si no gris
    final color = (isPrimary && enabled) ? AppTheme.primaryAccent : AppTheme.textSecondary; 
    
    final buttonWidget = Material(
      color: Colors.transparent, // Fondo transparente para ver el borde limpio
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(4),
        splashColor: enabled ? color.withOpacity(0.1) : null, // Feedback de color acorde al borde
        child: Container(
          height: 56,
          decoration: BoxDecoration(
            border: Border.all(color: color, width: isPrimary ? 2 : 1), // Más grueso si es primario
            borderRadius: BorderRadius.circular(4),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color),
              const SizedBox(width: 12),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (!enabled) {
      return Tooltip(
        message: "Requiere conexión a internet",
        child: buttonWidget,
      );
    }

    return buttonWidget;
  }
}

class SectionTitle extends StatelessWidget {
  final String title;
  const SectionTitle({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.bold,
        color: AppTheme.textSecondary,
        letterSpacing: 1.2,
      ),
    );
  }
}