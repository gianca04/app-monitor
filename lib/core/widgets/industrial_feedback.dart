import 'package:flutter/material.dart';
import 'package:monitor/core/theme_config.dart';

class IndustrialFeedback {
  // Dentro de class IndustrialFeedback ...

  static SnackBar buildSuccess({
    required String message,
    required VoidCallback onDismiss,
  }) {
    // Color verde industrial (tipo fósforo o terminal antigua)
    const color = Color(0xFF00C853); // O usa AppTheme.success si lo tienes

    return SnackBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      behavior: SnackBarBehavior.floating,
      padding: EdgeInsets.zero,
      margin: const EdgeInsets.only(bottom: 20, left: 16, right: 16),
      content: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: color.withOpacity(0.1), // Fondo muy sutil
          border: Border.all(color: color, width: 1.5), // Borde sólido
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // HEADER "ACCESS GRANTED"
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              color: color,
              child: Row(
                children: [
                  const Icon(
                    Icons.check_box_sharp,
                    color: Colors.black,
                    size: 16,
                  ), // Icono negro para contraste con verde
                  const SizedBox(width: 8),
                  Text(
                    "// OPERACION EXITOSA",
                    style: TextStyle(
                      color: Colors.black, // Texto negro sobre verde neón
                      fontFamily: 'monospace',
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const Spacer(),
                  InkWell(
                    onTap: onDismiss,
                    child: const Text(
                      "[OK]",
                      style: TextStyle(
                        color: Colors.black,
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // MENSAJE
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Text(
                message.toUpperCase(),
                style: TextStyle(
                  color: color,
                  fontFamily: 'monospace',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static SnackBar buildError({
    required String message,
    required VoidCallback onDismiss,
  }) {
    // Definimos los colores aquí o usamos tu AppTheme
    final color = AppTheme.error;

    return SnackBar(
      // 1. ELIMINAR ESTILOS NATIVOS
      backgroundColor: Colors.transparent,
      elevation: 0,
      behavior: SnackBarBehavior.floating, // Flotante para poder darle márgenes
      padding: EdgeInsets.zero, // Quitamos padding nativo para control total
      margin: const EdgeInsets.only(bottom: 20, left: 16, right: 16),

      // 2. CONTENIDO PERSONALIZADO (Tu diseño industrial)
      content: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: color.withOpacity(0.05), // Fondo sutil
          border: Border.all(color: color.withOpacity(0.5), width: 1.5),
        ),
        child: Column(
          mainAxisSize:
              MainAxisSize.min, // Importante para que no ocupe toda la pantalla
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // --- HEADER INDUSTRIAL ---
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              color: color, // Header sólido
              child: Row(
                children: [
                  const Icon(
                    Icons.warning_amber_sharp,
                    color: Colors.white,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    "// ERROR",
                    style: TextStyle(
                      color: Colors.white,
                      fontFamily: 'monospace',
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const Spacer(),
                  // Botón de cerrar estilo "consola"
                  InkWell(
                    onTap: onDismiss,
                    child: const Text(
                      "[X]",
                      style: TextStyle(
                        color: Colors.white,
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // --- CUERPO DEL MENSAJE ---
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Pequeña decoración visual lateral
                  Container(
                    width: 2,
                    height: 24,
                    color: color.withOpacity(0.5),
                    margin: const EdgeInsets.only(top: 2, right: 12),
                  ),
                  Expanded(
                    child: Text(
                      message.toUpperCase(),
                      style: TextStyle(
                        color: color,
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
      ),
    );
  }
}
