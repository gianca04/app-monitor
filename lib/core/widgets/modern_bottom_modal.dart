import 'package:flutter/material.dart';

// Constantes de diseño Industrial
const Color _kBackgroundColor = Color.fromARGB(255, 0, 0, 0);
const Color _kBorderColor = Colors.white12;
const double _kRadius = 4.0;

class ModernBottomModal extends StatelessWidget {
  final String? title;
  final Widget content;
  final List<Widget>? actions;

  const ModernBottomModal({
    super.key,
    this.title,
    required this.content,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    // Calculamos la altura disponible para no tapar la status bar
    final double maxScreenHeight = MediaQuery.of(context).size.height * 0.85;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        // Restricción: El modal se adapta al contenido, pero nunca pasa del 85% de la pantalla
        constraints: BoxConstraints(
          maxHeight: maxScreenHeight,
        ),
        decoration: BoxDecoration(
          color: _kBackgroundColor,
          border: Border.all(color: _kBorderColor),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(_kRadius),
            topRight: Radius.circular(_kRadius),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min, // Se encoge al tamaño mínimo del contenido
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // --- HEADER FIJO ---
            const SizedBox(height: 12),
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

            if (title != null) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Text(
                  title!.toUpperCase(),
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.0,
                      ),
                ),
              ),
              const SizedBox(height: 8),
            ],

            // --- CONTENIDO SCROLLABLE ---
            // Flexible permite que esta parte se encoja si sale el teclado
            // o crezca hasta el límite del constraint.
            Flexible(
              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(), // Scroll "sólido" estilo industrial
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Material(
                    color: Colors.transparent,
                    child: content,
                  ),
                ),
              ),
            ),

            // --- ACCIONES FIJAS AL PIE ---
            if (actions != null && actions!.isNotEmpty) ...[
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                // SafeArea inferior para proteger en iPhones sin botón home
                child: SafeArea(
                  top: false,
                  child: Column(
                    children: [
                      ...actions!,
                      SizedBox(height: MediaQuery.of(context).padding.bottom),
                    ],
                  ),
                ),
              ),
            ] else
              // Si no hay acciones, añadimos un safe area padding al final del contenido
              SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
          ],
        ),
      ),
    );
  }

  static Future<T?> show<T>(
    BuildContext context, {
    String? title,
    required Widget content,
    List<Widget>? actions,
    bool isDismissible = true,
    bool enableDrag = true,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      backgroundColor: _kBackgroundColor,
      shape: const RoundedRectangleBorder(
        side: BorderSide(color: _kBorderColor),
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(_kRadius),
        ),
      ),
      isDismissible: isDismissible,
      enableDrag: enableDrag,
      // CLAVE: isScrollControlled permite que el modal crezca según su contenido
      // y no se limite al 50% de la pantalla por defecto.
      isScrollControlled: true,
      elevation: 0,
      builder: (context) => ModernBottomModal(
        title: title,
        content: content,
        actions: actions,
      ),
    );
  }
}