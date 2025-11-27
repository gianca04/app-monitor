import 'package:flutter/material.dart';

// Constantes de diseño Industrial
const Color _kBackgroundColor = Color(0xFF1F1F1F); // Fondo oscuro industrial
const Color _kBorderColor = Colors.white12; // Borde sutil
const Color _kAccentColor = Colors.amber; // Acento industrial
const double _kRadius = 4.0; // Radio casi recto

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
    // Envolvemos el contenido en un Theme local para forzar el estilo de Inputs y Dividers
    // sin que el desarrollador tenga que estilar cada widget manualmente.
    return Theme(
      data: Theme.of(context).copyWith(
        brightness: Brightness.dark,
        dividerColor: Colors.white10, // Regla: Separadores Colors.white10
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
          // Regla: Sombras Eliminadas (Container no tiene boxShadow por defecto aquí)
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Handle for dragging (Estilizado oscuro)
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24, // Gris industrial para el handle
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (title != null) ...[
              Text(
                title!,
                textAlign: TextAlign.start,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.white, // Texto claro sobre fondo oscuro
                      fontSize: 18,
                    ),
              ),
              const SizedBox(height: 8),
              // Regla: Usar Divider(color: Colors.white10) para separar secciones
              const Divider(color: Colors.white10, height: 24),
            ],
            Flexible(
              child: SingleChildScrollView(
                // Ink para asegurar que los efectos InkWell se vean bien sobre el fondo oscuro
                child: Material(
                  color: Colors.transparent,
                  child: content,
                ),
              ),
            ),
            if (actions != null && actions!.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Divider(color: Colors.white10),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: actions!,
              ),
            ],
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
      isDismissible: isDismissible,
      enableDrag: enableDrag,
      backgroundColor: _kBackgroundColor, // Fondo del modal
      elevation: 0, // Regla: Sombras eliminadas
      // Ajustamos el shape del BottomSheet nativo para que coincida con el borde
      shape: const RoundedRectangleBorder(
        side: BorderSide(color: _kBorderColor),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(_kRadius),
          topRight: Radius.circular(_kRadius),
        ),
      ),
      builder: (context) => ModernBottomModal(
        title: title,
        content: content,
        actions: actions,
      ),
    );
  }
}