import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/theme_config.dart';
import '../../../../features/photos/presentation/widgets/image_viewer.dart';
import '../../../../features/photos/presentation/widgets/image_preview_modal.dart';
import '../../../../core/widgets/modern_bottom_modal.dart';
import '../../data/models/work_report.dart';

// Constantes de diseño (reutilizadas para consistencia)
const Color kIndBg = AppTheme.background;
const Color kIndSurface = AppTheme.surface;
const Color kIndBorder = AppTheme.border;
const Color kIndAccent = AppTheme.primaryAccent;
const double kIndRadius = 4.0;

class IndustrialPhotoEntry extends StatefulWidget {
  final int index;
  final Map<String, dynamic> data;
  final WorkReport? report;
  // Updated callbacks to pass full data
  final Function(XFile? file, Uint8List? bytes, String description)
  onUpdateAfter;
  final Function(XFile? file, Uint8List? bytes, String description)
  onUpdateBefore;
  final VoidCallback onRemove;
  final VoidCallback? onSave;
  final bool isEditMode;

  const IndustrialPhotoEntry({
    super.key,
    required this.index,
    required this.data,
    this.report,
    required this.onUpdateAfter,
    required this.onUpdateBefore,
    required this.onRemove,
    this.onSave,
    this.isEditMode = true,
  });

  @override
  State<IndustrialPhotoEntry> createState() => _IndustrialPhotoEntryState();
}

class _IndustrialPhotoEntryState extends State<IndustrialPhotoEntry> {
  // We don't need text controllers here anymore since editing is in the modal.
  // We just display the text.

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    String? existingAfterUrl;
    String? existingBeforeUrl;

    if (widget.data['id'] != null &&
        widget.report != null &&
        widget.report!.photos != null) {
      final originalPhoto = widget.report!.photos!.firstWhere(
        (p) => p.id == widget.data['id'],
        orElse: () => widget.report!.photos![0],
      );
      if (originalPhoto.id == widget.data['id']) {
        existingAfterUrl = originalPhoto.afterWork.photoPath;
        existingBeforeUrl = originalPhoto.beforeWork.photoPath;
      }
    }

    final afterBytes = widget.data['photo_bytes'] as Uint8List?;
    final beforeBytes = widget.data['before_work_photo_bytes'] as Uint8List?;
    final afterDesc = widget.data['descripcion']?.toString() ?? '';
    final beforeDesc = widget.data['before_work_descripcion']?.toString() ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: kIndSurface,
        border: Border.all(color: kIndBorder),
        borderRadius: BorderRadius.circular(kIndRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header ID
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: kIndBorder)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'EVIDENCIA #${widget.index + 1}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: kIndAccent,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.0,
                  ),
                ),
                if (widget.data['id'] != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black26,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'ID: ${widget.data['id']}',
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 10,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // BEFORE COLUMN
                Expanded(
                  child: _buildPhotoColumn(
                    context,
                    title: 'ANTES',
                    imageBytes: beforeBytes,
                    imageUrl: existingBeforeUrl,
                    description: beforeDesc,
                    onUpdate: widget.onUpdateBefore,
                    isEditMode: widget.isEditMode,
                  ),
                ),

                const SizedBox(width: 12),

                // AFTER COLUMN
                Expanded(
                  child: _buildPhotoColumn(
                    context,
                    title: 'DESPUES',
                    imageBytes: afterBytes,
                    imageUrl: existingAfterUrl,
                    description: afterDesc,
                    onUpdate: widget.onUpdateAfter,
                    isEditMode: widget.isEditMode,
                  ),
                ),
              ],
            ),
          ),

          // Actions Footer
          if (widget.isEditMode)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: kIndBorder)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: widget.onRemove,
                    icon: Icon(
                      Icons.delete_outline,
                      size: 16,
                      color: theme.colorScheme.error,
                    ),
                    label: Text(
                      'ELIMINAR',
                      style: TextStyle(
                        color: theme.colorScheme.error,
                        fontSize: 12,
                      ),
                    ),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                  ),
                  if (widget.onSave != null) ...[
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: widget.onSave,
                      icon: const Icon(Icons.save_outlined, size: 16),
                      label: const Text(
                        'GUARDAR',
                        style: TextStyle(fontSize: 12),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kIndAccent,
                        foregroundColor: Colors.black,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(kIndRadius),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPhotoColumn(
    BuildContext context, {
    required String title,
    Uint8List? imageBytes,
    String? imageUrl,
    required String description,
    required Function(XFile?, Uint8List?, String) onUpdate,
    bool isEditMode = true,
  }) {
    final theme = Theme.of(context);
    final hasImage =
        imageBytes != null || (imageUrl != null && imageUrl.isNotEmpty);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Title
        Text(
          title,
          style: theme.textTheme.bodySmall?.copyWith(
            color: kIndAccent,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),

        // Image Area
        GestureDetector(
          onTap: () async {
            if (hasImage) {
              // Open Viewer/Preview
              // Wait, if it's Edit Mode, tapping usually opens the Edit Modal?
              // Or tapping opens viewer, and Edit button opens Edit Modal?
              // "al presionar el icono de editar abreiremos un modal..."
              // "manten la funcionalidad original de que al presionar la imagen se abra el viewer"
              if (imageBytes != null) {
                // Custom bytes viewer
                await _showBytesViewer(context, imageBytes, title);
              } else {
                ImagePreviewModal.show(
                  context,
                  url: imageUrl ?? '',
                  title: title,
                );
              }
            } else if (isEditMode) {
              // If empty, open Picker directly (simplest flow)
              // Or open Edit Modal in 'empty' state?
              // Let's open Edit Modal directly for consistency, it handles picking.
              await _showEditModal(
                context,
                title,
                imageBytes,
                imageUrl,
                description,
                onUpdate,
              );
            }
          },
          child: Container(
            height: 160,
            decoration: BoxDecoration(
              color: Colors.black26,
              border: Border.all(color: Colors.white10),
              borderRadius: BorderRadius.circular(kIndRadius),
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (imageBytes != null)
                  Image.memory(imageBytes, fit: BoxFit.cover)
                else if (imageUrl != null && imageUrl.isNotEmpty)
                  ImageViewer(url: imageUrl, fit: BoxFit.cover)
                else
                  _buildPlaceholder(() async {
                    // Placeholder click triggers Edit Modal
                    await _showEditModal(
                      context,
                      title,
                      imageBytes,
                      imageUrl, // might be null
                      description,
                      onUpdate,
                      startWithPicker: true,
                    );
                  }),

                // Edit Overlay Button (only if image exists and is edit mode)
                if (hasImage && isEditMode)
                  Positioned(
                    top: 4,
                    right: 4,
                    child: Material(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(20),
                      child: InkWell(
                        onTap: () => _showEditModal(
                          context,
                          title,
                          imageBytes,
                          imageUrl,
                          description,
                          onUpdate,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        child: const Padding(
                          padding: EdgeInsets.all(6),
                          child: Icon(
                            Icons.edit,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 8),

        // Description (Read Only / Display)
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.black12,
            borderRadius: BorderRadius.circular(kIndRadius),
          ),
          child: Text(
            description.isEmpty ? 'Sin descripción' : description,
            style: TextStyle(
              color: description.isEmpty ? Colors.white24 : Colors.white70,
              fontSize: 12,
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildPlaceholder(VoidCallback onTap) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.add_a_photo_outlined, color: Colors.white24, size: 32),
        const SizedBox(height: 8),
        const Text(
          'Sin Evidencia',
          style: TextStyle(color: Colors.white24, fontSize: 10),
        ),
        const SizedBox(height: 8),
        // Mini buttons
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            InkWell(
              onTap: onTap,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.white24),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'SELECCIONAR',
                  style: TextStyle(color: Colors.white54, fontSize: 10),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _showBytesViewer(
    BuildContext context,
    Uint8List bytes,
    String title,
  ) {
    return showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          fit: StackFit.expand,
          children: [
            InteractiveViewer(child: Image.memory(bytes, fit: BoxFit.contain)),
            Positioned(
              top: 40,
              right: 20,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 30),
                onPressed: () => Navigator.pop(ctx),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showEditModal(
    BuildContext context,
    String title,
    Uint8List? initialBytes,
    String? initialUrl,
    String initialDescription,
    Function(XFile?, Uint8List?, String) onUpdate, {
    bool startWithPicker = false,
  }) async {
    final result = await ModernBottomModal.show<_PhotoEditResult>(
      context,
      title: 'EDITAR $title',
      content: _PhotoEditModalContent(
        initialBytes: initialBytes,
        initialUrl: initialUrl,
        initialDescription: initialDescription,
        startWithPicker: startWithPicker,
      ),
    );

    if (result != null) {
      onUpdate(result.file, result.bytes, result.description);
    }
  }
}

class _PhotoEditResult {
  final XFile? file;
  final Uint8List? bytes;
  final String description;

  _PhotoEditResult({this.file, this.bytes, required this.description});
}

class _PhotoEditModalContent extends StatefulWidget {
  final Uint8List? initialBytes;
  final String? initialUrl;
  final String initialDescription;
  final bool startWithPicker;

  const _PhotoEditModalContent({
    required this.initialBytes,
    required this.initialUrl,
    required this.initialDescription,
    this.startWithPicker = false,
  });

  @override
  State<_PhotoEditModalContent> createState() => _PhotoEditModalContentState();
}

class _PhotoEditModalContentState extends State<_PhotoEditModalContent> {
  late TextEditingController _textController;
  Uint8List? _currentBytes;
  XFile? _currentFile;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(text: widget.initialDescription);
    _currentBytes = widget.initialBytes;

    if (widget.startWithPicker) {
      // Defer picker open until build is done to avoid errors
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _pickImage();
      });
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    // Show Sheet for Camera/Gallery
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors
          .transparent, // Use ModernBottomModal style manually or just basic sheet
      builder: (ctx) => Container(
        color: kIndSurface,
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Colors.white),
              title: const Text(
                'Tomar Foto',
                style: TextStyle(color: Colors.white),
              ),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: Colors.white),
              title: const Text(
                'Galería',
                style: TextStyle(color: Colors.white),
              ),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );

    if (source != null) {
      final picker = ImagePicker();
      final picked = await picker.pickImage(source: source);
      if (picked != null) {
        final bytes = await picked.readAsBytes();
        setState(() {
          _currentFile = picked;
          _currentBytes = bytes;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Large Image Preview Area
        Container(
          height: 300,
          decoration: BoxDecoration(
            color: Colors.black38,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.white12),
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (_currentBytes != null)
                Image.memory(_currentBytes!, fit: BoxFit.contain)
              else if (widget.initialUrl != null &&
                  widget.initialUrl!.isNotEmpty)
                ImageViewer(url: widget.initialUrl!, fit: BoxFit.contain)
              else
                const Center(
                  child: Text(
                    'Sin imagen',
                    style: TextStyle(color: Colors.white24),
                  ),
                ),

              // Overlay Change Button
              Center(
                child: Material(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(30),
                  child: InkWell(
                    onTap: _pickImage,
                    borderRadius: BorderRadius.circular(30),
                    child: const Padding(
                      padding: EdgeInsets.all(12),
                      child: Icon(
                        Icons.cameraswitch,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Description Field
        TextField(
          controller: _textController,
          maxLines: 5,
          maxLength: 500,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            labelText: 'DESCRIPCIÓN',
            alignLabelWithHint: true,
            hintText: 'Ingrese detalles de la evidencia...',
            filled: true,
            fillColor: Colors.black12,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.white24),
            ),
          ),
        ),

        const SizedBox(height: 24),

        // Save / Cancel
        Row(
          children: [
            Expanded(
              child: TextButton(
                onPressed: () =>
                    Navigator.pop(context), // Cancel -> returns null
                child: const Text(
                  'CANCELAR',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(
                    context,
                    _PhotoEditResult(
                      file:
                          _currentFile, // New file (null if not changed, but wait, if changed)
                      bytes:
                          _currentBytes, // New bytes (or initial if not changed? Wait.)
                      // Logic: If _currentFile is null, we didn't change photo.
                      // But _currentBytes might be initialBytes.
                      // We should pass back what we have.
                      // IMPORTANT: Parent logic needs to know if we CHANGED the file.
                      // If we pass _currentFile (wrapper), it's enough.
                      // But if we passed initialBytes and return same bytes, parent might not know if it's new.
                      description: _textController.text,
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: kIndAccent,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('GUARDAR CAMBIOS'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}
