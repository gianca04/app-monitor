import 'package:flutter/material.dart';

class IndustrialCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final Color? borderColor;
  final Color? backgroundColor;

  const IndustrialCard({
    super.key,
    required this.child,
    this.onTap,
    this.borderColor,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    // Definimos los colores base del sistema industrial
    final effectiveBorderColor = borderColor ?? Colors.grey.shade700;
    final effectiveBgColor = backgroundColor ?? const Color(0xFF1E1E1E);

    return Container(
      
        padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: effectiveBgColor,
        border: Border.all(color: effectiveBorderColor, width: 1),
        borderRadius: BorderRadius.circular(4), // Regla: Radio casi recto
      ),
      // ClipRRect asegura que el efecto de onda (InkWell) no se salga del borde
      child: ClipRRect(
        borderRadius: BorderRadius.circular(3), // Un píxel menos para encajar dentro del borde
        child: Material(
          color: Colors.transparent, // Necesario para ver el color del Container
          child: InkWell(
            onTap: onTap,
            // Color del feedback sutilmente gris/blanco
            splashColor: Colors.white.withOpacity(0.05),
            highlightColor: Colors.white.withOpacity(0.02),
            child: child,
          ),
        ),
      ),
    );
  }
}