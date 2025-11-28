import 'package:flutter/material.dart';

// Constantes de diseño Industrial
const Color _kBackgroundColor = Color(0xFF1F1F1F); // Fondo oscuro
const Color _kBorderColor = Colors.white12; // Borde sutil
const Color _kAccentColor = Colors.amber; // Acento industrial
const double _kRadius = 4.0; // Radio casi recto

class BottomModal extends StatelessWidget {
  final Widget child;
  final bool isDismissible;
  final bool enableDrag;

  const BottomModal({
    super.key,
    required this.child,
    this.isDismissible = true,
    this.enableDrag = true,
  });

  @override
  Widget build(BuildContext context) {
    // 1. Calculamos límite de altura (85% de la pantalla)
    final double maxScreenHeight = MediaQuery.of(context).size.height * 0.85;
    // 2. Capturamos la altura del teclado
    final double keyboardHeight = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: keyboardHeight),
      child: Container(
        // 4. Constraints en lugar de height fijo
        constraints: BoxConstraints(
          maxHeight: maxScreenHeight,
        ),
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: _kBackgroundColor,
          border: Border.all(color: _kBorderColor),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(_kRadius),
            topRight: Radius.circular(_kRadius),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min, // Se adapta al contenido, no estira
          children: [
            // Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            // 5. Flexible + SingleChildScrollView
            // Esto permite que el contenido crezca hasta el límite y luego haga scroll
            Flexible(
              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(), // Scroll firme industrial
                child: Material(
                  color: Colors.transparent,
                  child: child, // Tu contenido arbitrario
                ),
              ),
            ),
            
            // Safe area inferior opcional por si el contenido no tiene padding final
            SizedBox(height: MediaQuery.of(context).padding.bottom > 0 ? 0 : 16),
          ],
        ),
      ),
    );
  }

  static Future<T?> show<T>(
    BuildContext context, {
    required Widget child,
    bool isDismissible = true,
    bool enableDrag = true,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isDismissible: isDismissible,
      enableDrag: enableDrag,
      // CRÍTICO: Permite que el modal supere el 50% de la pantalla
      isScrollControlled: true, 
      backgroundColor: Colors.transparent, // El Container maneja el color
      elevation: 0,
      builder: (context) => BottomModal(
        isDismissible: isDismissible,
        enableDrag: enableDrag,
        child: child,
      ),
    );
  }
}