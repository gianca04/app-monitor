import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:fleather/fleather.dart';
import '../theme_config.dart';
import 'industrial_quill_editor.dart';

/// Widget reutilizable para entrada de evidencia fotográfica con estilo industrial.
/// 
/// Proporciona dos secciones de foto (antes/después del trabajo) con editores
/// de descripción Quill integrados.
/// 
/// Ejemplo de uso:
/// ```dart
/// IndustrialPhotoEntry(
///   index: 0,
///   data: _photos[0],
///   onPickAfterPhoto: () => _pickPhoto(0, true),
///   onPickBeforePhoto: () => _pickPhoto(0, false),
///   onRemove: () => _removePhoto(0),
///   onAfterDescChanged: (value) => _photos[0]['descripcion'] = value,
///   onBeforeDescChanged: (value) => _photos[0]['before_work_descripcion'] = value,
/// )
/// ```
class IndustrialPhotoEntry extends StatefulWidget {
  /// Índice de la foto (usado para mostrar el número)
  final int index;

  /// Datos de la foto. Debe contener:
  /// - 'descripcion': String (Delta JSON o texto plano)
  /// - 'before_work_descripcion': String (Delta JSON o texto plano)
  /// - 'photo_bytes': Uint8List? (bytes de la foto después)
  /// - 'before_work_photo_bytes': Uint8List? (bytes de la foto antes)
  /// - 'photo_path': String? (ruta local de la foto después)
  /// - 'before_work_photo_path': String? (ruta local de la foto antes)
  final Map<String, dynamic> data;

  /// URL de la foto después del trabajo (para fotos de servidor)
  final String? afterPhotoUrl;

  /// URL de la foto antes del trabajo (para fotos de servidor)
  final String? beforePhotoUrl;

  /// Callback cuando se quiere seleccionar la foto "después"
  final VoidCallback onPickAfterPhoto;

  /// Callback cuando se quiere seleccionar la foto "antes"
  final VoidCallback onPickBeforePhoto;

  /// Callback para eliminar esta entrada de foto
  final VoidCallback onRemove;

  /// Callback cuando cambia la descripción de "después"
  final ValueChanged<String> onAfterDescChanged;

  /// Callback cuando cambia la descripción de "antes"
  final ValueChanged<String> onBeforeDescChanged;

  /// Widget personalizado para mostrar imágenes de URL (ej: ImageViewer)
  final Widget Function(String url)? urlImageBuilder;

  /// Si se debe mostrar el editor de texto rico (Fleather)
  /// Si es false, se usa TextFormField simple
  final bool useRichEditor;

  /// Etiqueta para la sección "después"
  final String afterLabel;

  /// Etiqueta para la sección "antes"
  final String beforeLabel;

  /// Altura del área de foto
  final double photoHeight;

  /// Altura del editor de descripción
  final double editorHeight;

  const IndustrialPhotoEntry({
    super.key,
    required this.index,
    required this.data,
    this.afterPhotoUrl,
    this.beforePhotoUrl,
    required this.onPickAfterPhoto,
    required this.onPickBeforePhoto,
    required this.onRemove,
    required this.onAfterDescChanged,
    required this.onBeforeDescChanged,
    this.urlImageBuilder,
    this.useRichEditor = true,
    this.afterLabel = 'DESPUÉS DEL TRABAJO',
    this.beforeLabel = 'ANTES DEL TRABAJO',
    this.photoHeight = 180,
    this.editorHeight = 120,
  });

  @override
  State<IndustrialPhotoEntry> createState() => _IndustrialPhotoEntryState();
}

class _IndustrialPhotoEntryState extends State<IndustrialPhotoEntry> {
  FleatherController? _afterController;
  FleatherController? _beforeController;
  final GlobalKey<EditorState> _afterEditorKey = GlobalKey();
  final GlobalKey<EditorState> _beforeEditorKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    if (widget.useRichEditor) {
      _initControllers();
    }
  }

  void _initControllers() {
    // Inicializar controlador "después"
    _afterController = IndustrialQuillEditor.createFromJson(
      widget.data['descripcion'] ?? '',
    );
    _afterController?.addListener(_onAfterChanged);

    // Inicializar controlador "antes"
    _beforeController = IndustrialQuillEditor.createFromJson(
      widget.data['before_work_descripcion'] ?? '',
    );
    _beforeController?.addListener(_onBeforeChanged);
  }

  void _onAfterChanged() {
    if (_afterController != null) {
      widget.onAfterDescChanged(
        IndustrialQuillEditor.getContentAsJson(_afterController!),
      );
    }
  }

  void _onBeforeChanged() {
    if (_beforeController != null) {
      widget.onBeforeDescChanged(
        IndustrialQuillEditor.getContentAsJson(_beforeController!),
      );
    }
  }

  @override
  void dispose() {
    _afterController?.removeListener(_onAfterChanged);
    _beforeController?.removeListener(_onBeforeChanged);
    _afterController?.dispose();
    _beforeController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        border: Border.all(color: AppTheme.border),
        borderRadius: BorderRadius.circular(AppTheme.kRadius),
      ),
      child: Column(
        children: [
          // Header
          _buildHeader(),

          // Content
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                // AFTER WORK BLOCK
                _buildPhotoBlock(
                  title: widget.afterLabel,
                  buttonLabel: 'AGREGAR FOTO',
                  bytes: widget.data['photo_bytes'],
                  localPath: widget.data['photo_path'],
                  url: widget.afterPhotoUrl,
                  controller: _afterController,
                  editorKey: _afterEditorKey,
                  onPick: widget.onPickAfterPhoto,
                  onDescChanged: widget.onAfterDescChanged,
                  initialDesc: widget.data['descripcion'] ?? '',
                ),

                const Divider(color: Colors.white10, height: 24),

                // BEFORE WORK BLOCK
                _buildPhotoBlock(
                  title: widget.beforeLabel,
                  buttonLabel: 'AGREGAR FOTO',
                  bytes: widget.data['before_work_photo_bytes'],
                  localPath: widget.data['before_work_photo_path'],
                  url: widget.beforePhotoUrl,
                  controller: _beforeController,
                  editorKey: _beforeEditorKey,
                  onPick: widget.onPickBeforePhoto,
                  onDescChanged: widget.onBeforeDescChanged,
                  initialDesc: widget.data['before_work_descripcion'] ?? '',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppTheme.border)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'EVIDENCIA #${widget.index + 1}',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryAccent,
              fontSize: 12,
              letterSpacing: 1.2,
            ),
          ),
          InkWell(
            onTap: widget.onRemove,
            borderRadius: BorderRadius.circular(4),
            child: const Padding(
              padding: EdgeInsets.all(4),
              child: Icon(
                Icons.close,
                color: Colors.redAccent,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoBlock({
    required String title,
    required String buttonLabel,
    required Uint8List? bytes,
    required String? localPath,
    required String? url,
    required FleatherController? controller,
    required GlobalKey<EditorState> editorKey,
    required VoidCallback onPick,
    required ValueChanged<String> onDescChanged,
    required String initialDesc,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Título de la sección
        Text(
          title,
          style: const TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 11,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: 8),

        // Área de la foto
        InkWell(
          onTap: onPick,
          borderRadius: BorderRadius.circular(AppTheme.kRadius),
          child: Container(
            width: double.infinity,
            height: widget.photoHeight,
            decoration: BoxDecoration(
              color: AppTheme.background,
              border: Border.all(color: AppTheme.border),
              borderRadius: BorderRadius.circular(AppTheme.kRadius),
            ),
            child: _buildPhotoContent(bytes, localPath, url, buttonLabel),
          ),
        ),
        const SizedBox(height: 12),

        // Editor de descripción
        if (widget.useRichEditor && controller != null)
          IndustrialQuillEditor(
            controller: controller,
            label: 'DESCRIPCIÓN',
            icon: Icons.description,
            height: widget.editorHeight,
            editorKey: editorKey,
          )
        else
          _buildSimpleDescriptionField(initialDesc, onDescChanged),
      ],
    );
  }

  Widget _buildPhotoContent(
    Uint8List? bytes,
    String? localPath,
    String? url,
    String buttonLabel,
  ) {
    // Prioridad: bytes > localPath > url > placeholder
    if (bytes != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(AppTheme.kRadius - 1),
        child: Image.memory(bytes, fit: BoxFit.cover, width: double.infinity),
      );
    }

    if (localPath != null && localPath.isNotEmpty) {
      final file = File(localPath);
      if (file.existsSync()) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(AppTheme.kRadius - 1),
          child: Image.file(file, fit: BoxFit.cover, width: double.infinity),
        );
      }
    }

    if (url != null && url.isNotEmpty) {
      if (widget.urlImageBuilder != null) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(AppTheme.kRadius - 1),
          child: widget.urlImageBuilder!(url),
        );
      }
      return ClipRRect(
        borderRadius: BorderRadius.circular(AppTheme.kRadius - 1),
        child: Image.network(
          url,
          fit: BoxFit.cover,
          width: double.infinity,
          errorBuilder: (_, __, ___) => _buildPlaceholder(buttonLabel),
        ),
      );
    }

    return _buildPlaceholder(buttonLabel);
  }

  Widget _buildPlaceholder(String buttonLabel) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(
          Icons.camera_alt,
          color: Colors.grey,
          size: 36,
        ),
        const SizedBox(height: 8),
        Text(
          buttonLabel,
          style: const TextStyle(
            color: Colors.grey,
            fontSize: 11,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildSimpleDescriptionField(
    String initialValue,
    ValueChanged<String> onChanged,
  ) {
    return TextFormField(
      initialValue: initialValue,
      decoration: InputDecoration(
        labelText: 'Descripción',
        prefixIcon: const Icon(
          Icons.description,
          color: AppTheme.textSecondary,
          size: 20,
        ),
        filled: true,
        fillColor: AppTheme.surface,
        labelStyle: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.kRadius),
          borderSide: const BorderSide(color: AppTheme.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.kRadius),
          borderSide: const BorderSide(color: AppTheme.primaryAccent, width: 1.5),
        ),
      ),
      maxLines: 2,
      onChanged: onChanged,
    );
  }
}

/// Widget simplificado para una sola foto con descripción.
/// Útil cuando solo se necesita una foto (sin antes/después).
class IndustrialSinglePhotoEntry extends StatelessWidget {
  final int index;
  final Uint8List? photoBytes;
  final String? photoPath;
  final String? photoUrl;
  final String description;
  final VoidCallback onPickPhoto;
  final VoidCallback onRemove;
  final ValueChanged<String> onDescChanged;
  final Widget Function(String url)? urlImageBuilder;
  final String title;
  final double photoHeight;

  const IndustrialSinglePhotoEntry({
    super.key,
    required this.index,
    this.photoBytes,
    this.photoPath,
    this.photoUrl,
    required this.description,
    required this.onPickPhoto,
    required this.onRemove,
    required this.onDescChanged,
    this.urlImageBuilder,
    this.title = 'FOTO',
    this.photoHeight = 180,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        border: Border.all(color: AppTheme.border),
        borderRadius: BorderRadius.circular(AppTheme.kRadius),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: AppTheme.border)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '$title #${index + 1}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryAccent,
                    fontSize: 12,
                    letterSpacing: 1.2,
                  ),
                ),
                InkWell(
                  onTap: onRemove,
                  borderRadius: BorderRadius.circular(4),
                  child: const Padding(
                    padding: EdgeInsets.all(4),
                    child: Icon(
                      Icons.close,
                      color: Colors.redAccent,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Content
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Foto
                InkWell(
                  onTap: onPickPhoto,
                  borderRadius: BorderRadius.circular(AppTheme.kRadius),
                  child: Container(
                    width: double.infinity,
                    height: photoHeight,
                    decoration: BoxDecoration(
                      color: AppTheme.background,
                      border: Border.all(color: AppTheme.border),
                      borderRadius: BorderRadius.circular(AppTheme.kRadius),
                    ),
                    child: _buildPhotoContent(),
                  ),
                ),
                const SizedBox(height: 12),

                // Descripción simple
                TextFormField(
                  initialValue: description,
                  decoration: InputDecoration(
                    labelText: 'Descripción',
                    prefixIcon: const Icon(
                      Icons.description,
                      color: AppTheme.textSecondary,
                      size: 20,
                    ),
                    filled: true,
                    fillColor: AppTheme.surface,
                    labelStyle: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 13,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppTheme.kRadius),
                      borderSide: const BorderSide(color: AppTheme.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppTheme.kRadius),
                      borderSide: const BorderSide(
                        color: AppTheme.primaryAccent,
                        width: 1.5,
                      ),
                    ),
                  ),
                  maxLines: 2,
                  onChanged: onDescChanged,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoContent() {
    if (photoBytes != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(AppTheme.kRadius - 1),
        child: Image.memory(
          photoBytes!,
          fit: BoxFit.cover,
          width: double.infinity,
        ),
      );
    }

    if (photoPath != null && photoPath!.isNotEmpty) {
      final file = File(photoPath!);
      if (file.existsSync()) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(AppTheme.kRadius - 1),
          child: Image.file(file, fit: BoxFit.cover, width: double.infinity),
        );
      }
    }

    if (photoUrl != null && photoUrl!.isNotEmpty) {
      if (urlImageBuilder != null) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(AppTheme.kRadius - 1),
          child: urlImageBuilder!(photoUrl!),
        );
      }
      return ClipRRect(
        borderRadius: BorderRadius.circular(AppTheme.kRadius - 1),
        child: Image.network(
          photoUrl!,
          fit: BoxFit.cover,
          width: double.infinity,
          errorBuilder: (_, __, ___) => _buildPlaceholder(),
        ),
      );
    }

    return _buildPlaceholder();
  }

  Widget _buildPlaceholder() {
    return const Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.camera_alt, color: Colors.grey, size: 36),
        SizedBox(height: 8),
        Text(
          'AGREGAR FOTO',
          style: TextStyle(
            color: Colors.grey,
            fontSize: 11,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
}
