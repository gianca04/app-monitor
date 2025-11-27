import 'package:flutter/material.dart';

// Constantes de diseño Industrial
const Color _kBackgroundColor = Color(0xFF1F1F1F); // Fondo oscuro
const Color _kBorderColor = Colors.white12; // Borde sutil
const Color _kAccentColor = Colors.amber; // Acento industrial
const double _kRadius = 4.0; // Radio casi recto

class BottomModal extends StatelessWidget {
  final Widget child;
  final double? height;
  final bool isDismissible;
  final bool enableDrag;

  const BottomModal({
    super.key,
    required this.child,
    this.height,
    this.isDismissible = true,
    this.enableDrag = true,
  });

  @override
  Widget build(BuildContext context) {
    // Inyectamos el Theme para que los inputs y dividers dentro del "child"
    // hereden automáticamente el estilo industrial sin modificar la lógica interna.
    return Theme(
      data: Theme.of(context).copyWith(
        brightness: Brightness.dark,
        dividerColor: Colors.white10, // Regla: Separadores sutiles
        inputDecorationTheme: const InputDecorationTheme(
          filled: true,
          fillColor: Colors.black12,
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          // Regla: Inputs OutlineInputBorder con borde gris suave
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(_kRadius)),
            borderSide: BorderSide(color: Colors.grey),
          ),
          // Regla: Al enfocar, borde Ámbar
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(_kRadius)),
            borderSide: BorderSide(color: _kAccentColor, width: 2),
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(_kRadius)),
          ),
        ),
      ),
      child: Container(
        height: height,
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: _kBackgroundColor,
          // Regla: Siempre con Border.all
          border: Border.all(color: _kBorderColor),
          // Regla: Bordes Rectos o casi rectos (Radius.circular(4))
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(_kRadius),
            topRight: Radius.circular(_kRadius),
          ),
          // Regla: Sombras Eliminadas
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle (Estilo oscuro)
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24, // Gris industrial
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              // Material transparente para que los InkWell funcionen visualmente sobre el fondo oscuro
              child: Material(
                color: Colors.transparent,
                child: child,
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Future<T?> show<T>(
    BuildContext context, {
    required Widget child,
    double? height,
    bool isDismissible = true,
    bool enableDrag = true,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isDismissible: isDismissible,
      enableDrag: enableDrag,
      backgroundColor: _kBackgroundColor, // Fondo oscuro
      elevation: 0, // Regla: Sin sombra
      // Shape ajustado al borde y radio definidos
      shape: const RoundedRectangleBorder(
        side: BorderSide(color: _kBorderColor),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(_kRadius),
          topRight: Radius.circular(_kRadius),
        ),
      ),
      builder: (context) => BottomModal(
        child: child,
        height: height,
        isDismissible: isDismissible,
        enableDrag: enableDrag,
      ),
    );
  }
}