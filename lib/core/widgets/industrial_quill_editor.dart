import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:fleather/fleather.dart';
import '../theme_config.dart';

/// Widget reutilizable de editor Quill con estilo industrial.
/// 
/// Proporciona un editor de texto rico (Fleather) con toolbar integrada,
/// siguiendo el diseño industrial de la aplicación.
/// 
/// Ejemplo de uso:
/// ```dart
/// FleatherController _controller = FleatherController();
/// 
/// IndustrialQuillEditor(
///   controller: _controller,
///   label: 'DESCRIPCIÓN',
///   icon: Icons.description,
///   height: 200,
/// )
/// ```
class IndustrialQuillEditor extends StatelessWidget {
  /// Controlador del editor Fleather.
  /// Si es null, mostrará un indicador de carga.
  final FleatherController? controller;

  /// Etiqueta que se muestra en el encabezado del editor.
  final String label;

  /// Icono que se muestra junto a la etiqueta.
  final IconData icon;

  /// Altura del área de edición (no incluye la toolbar).
  final double height;

  /// Key global para el estado del editor.
  /// Si no se proporciona, se genera una automáticamente.
  final GlobalKey<EditorState>? editorKey;

  /// Placeholder que se muestra cuando el editor está vacío.
  final String? placeholder;

  /// Si el editor es de solo lectura.
  final bool readOnly;

  /// FocusNode personalizado para el editor.
  final FocusNode? focusNode;

  /// Callback cuando el contenido cambia.
  final VoidCallback? onChanged;

  const IndustrialQuillEditor({
    super.key,
    required this.controller,
    required this.label,
    required this.icon,
    this.height = 200,
    this.editorKey,
    this.placeholder,
    this.readOnly = false,
    this.focusNode,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveEditorKey = editorKey ?? GlobalKey<EditorState>();
    final effectiveFocusNode = focusNode ?? FocusNode();

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        border: Border.all(color: AppTheme.border),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(AppTheme.kRadius),
          topRight: Radius.circular(AppTheme.kRadius),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header con icono y etiqueta
          Padding(
            padding: const EdgeInsets.only(left: 16, top: 8),
            child: Row(
              children: [
                Icon(icon, color: Colors.grey, size: 18),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          // Contenido del editor
          if (controller == null)
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                height: height,
                child: const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                      AppTheme.primaryAccent,
                    ),
                  ),
                ),
              ),
            )
          else ...[
            // Toolbar del editor
            if (!readOnly)
              FleatherToolbar.basic(
                controller: controller!,
                editorKey: effectiveEditorKey,
              ),
            // Área de edición
            Container(
              height: height,
              decoration: BoxDecoration(
                border: Border.all(color: AppTheme.border),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(AppTheme.kRadius),
                  bottomRight: Radius.circular(AppTheme.kRadius),
                ),
              ),
              child: FleatherEditor(
                controller: controller!,
                padding: const EdgeInsets.all(16),
                focusNode: effectiveFocusNode,
                editorKey: effectiveEditorKey,
                readOnly: readOnly,
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Obtiene el contenido del editor como JSON Delta.
  /// Útil para guardar el contenido.
  static String getContentAsJson(FleatherController controller) {
    return jsonEncode(controller.document.toDelta().toJson());
  }

  /// Crea un FleatherController con texto plano.
  static FleatherController createWithText(String text) {
    if (text.isEmpty) {
      return FleatherController();
    }
    return FleatherController(
      document: ParchmentDocument.fromDelta(Delta()..insert('$text\n')),
    );
  }

  /// Crea un FleatherController desde JSON Delta.
  static FleatherController? createFromJson(String jsonContent) {
    if (jsonContent.isEmpty) {
      return FleatherController();
    }
    try {
      final delta = jsonDecode(jsonContent);
      if (delta is List) {
        return FleatherController(
          document: ParchmentDocument.fromJson(delta),
        );
      } else if (delta is Map && delta['ops'] != null) {
        return FleatherController(
          document: ParchmentDocument.fromJson(delta['ops']),
        );
      }
      return FleatherController(
        document: ParchmentDocument.fromDelta(Delta()..insert('$jsonContent\n')),
      );
    } catch (_) {
      return FleatherController(
        document: ParchmentDocument.fromDelta(Delta()..insert('$jsonContent\n')),
      );
    }
  }

  /// Verifica si el editor está vacío.
  static bool isEmpty(FleatherController controller) {
    final text = controller.document.toPlainText().trim();
    return text.isEmpty;
  }

  /// Obtiene el texto plano del editor.
  static String getPlainText(FleatherController controller) {
    return controller.document.toPlainText().trim();
  }
}

/// Widget simplificado de editor Quill sin toolbar.
/// Útil para áreas de texto más pequeñas como descripciones de fotos.
class IndustrialQuillEditorCompact extends StatelessWidget {
  final FleatherController? controller;
  final String? placeholder;
  final double height;
  final GlobalKey<EditorState>? editorKey;
  final bool readOnly;
  final FocusNode? focusNode;

  const IndustrialQuillEditorCompact({
    super.key,
    required this.controller,
    this.placeholder,
    this.height = 100,
    this.editorKey,
    this.readOnly = false,
    this.focusNode,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveEditorKey = editorKey ?? GlobalKey<EditorState>();
    final effectiveFocusNode = focusNode ?? FocusNode();

    if (controller == null) {
      return Container(
        height: height,
        decoration: BoxDecoration(
          color: AppTheme.surface,
          border: Border.all(color: AppTheme.border),
          borderRadius: BorderRadius.circular(AppTheme.kRadius),
        ),
        child: const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryAccent),
          ),
        ),
      );
    }

    return Container(
      height: height,
      decoration: BoxDecoration(
        color: AppTheme.surface,
        border: Border.all(color: AppTheme.border),
        borderRadius: BorderRadius.circular(AppTheme.kRadius),
      ),
      child: FleatherEditor(
        controller: controller!,
        padding: const EdgeInsets.all(12),
        focusNode: effectiveFocusNode,
        editorKey: effectiveEditorKey,
        readOnly: readOnly,
      ),
    );
  }
}
