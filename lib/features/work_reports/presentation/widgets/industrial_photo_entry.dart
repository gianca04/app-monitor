import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/theme_config.dart';
import '../../../../photos/presentation/widgets/image_viewer.dart';
import '../../../../photos/presentation/widgets/image_preview_modal.dart';
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
  final VoidCallback onPickAfter;
  final VoidCallback onPickBefore;
  final VoidCallback onRemove;
  final VoidCallback onSave;
  final ValueChanged<String> onAfterDescChanged;
  final ValueChanged<String> onBeforeDescChanged;
  final bool isEditMode;

  const IndustrialPhotoEntry({
    super.key,
    required this.index,
    required this.data,
    this.report,
    required this.onPickAfter,
    required this.onPickBefore,
    required this.onRemove,
    required this.onSave,
    required this.onAfterDescChanged,
    required this.onBeforeDescChanged,
    this.isEditMode = true,
  });

  @override
  State<IndustrialPhotoEntry> createState() => _IndustrialPhotoEntryState();
}

class _IndustrialPhotoEntryState extends State<IndustrialPhotoEntry> {
  late TextEditingController _afterController;
  late TextEditingController _beforeController;

  @override
  void initState() {
    super.initState();
    // Initialize controllers with JSON string data (handling potential Delta/JSON structure simply as text for now
    // or assuming it might come as plain text if already converted.
    // Given the previous context, we want simple TextFields.
    // If the data comes as '{"ops":...}', we might want to just show it or clean it.
    // optimizing for 'user sends plain text' flow as requested in "Replace Quill with TextField".
    _afterController = TextEditingController(
      text: _extractText(widget.data['descripcion']),
    );
    _beforeController = TextEditingController(
      text: _extractText(widget.data['before_work_descripcion']),
    );
  }

  String _extractText(dynamic content) {
    if (content == null) return '';
    // If it looks like JSON/Delta, you might want to parse it,
    // but for now let's treat it as string to avoid complex parsing logic here
    // unless necessary. If the user just wants "Text", we assume clean text or raw string.
    return content.toString();
  }

  @override
  void dispose() {
    _afterController.dispose();
    _beforeController.dispose();
    super.dispose();
  }

  void _showFullScreen(
    BuildContext context,
    dynamic imageSource,
    String title,
  ) {
    // Handle different image sources (Url string, Bytes, File path) for the preview
    // For now, ImagePreviewModal expects a URL string.
    // If we have bytes, we might need a different viewer or temporary handling.
    // ImageViewer handles URLs and Files.

    if (imageSource is String) {
      ImagePreviewModal.show(context, url: imageSource, title: title);
    } else if (imageSource is Uint8List) {
      // Custom preview for bytes if needed, strictly requested "image viewer"
      // We can use a simple Dialog with memory image if ImagePreviewModal doesn't support bytes directly yet.
      showDialog(
        context: context,
        builder: (ctx) => Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: EdgeInsets.zero,
          child: Stack(
            fit: StackFit.expand,
            children: [
              InteractiveViewer(
                child: Image.memory(imageSource, fit: BoxFit.contain),
              ),
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
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Determine image sources
    // 'photo' usually holds the MultipartFile for upload
    // 'photo_bytes' holds Uint8List for preview of new selection
    // 'photo_path' or url might be in data if it's an existing photo (from API)

    // Existing URLs (if available in a typed object inside data or data itself)
    // The data map structure seems to be:
    // { 'id', 'descripcion', 'before_work_descripcion', 'photo', 'before_work_photo', 'photo_bytes', 'before_work_photo_bytes', ... }
    // If editing an existing report, we might need to look at widget.report?.photos[index] ???
    // OR the data map is populated from the report in `_WorkReportEditFormState.initState`.

    // Let's rely on what's passed in `data`.
    // We need to know if there's an existing URL if no new bytes are present.
    // The previous implementation in `work_report_edit_form.dart` loop:
    // `_photos.add({ ..., 'photo': null, ... })`.
    // Wait, `WorkReportEditForm` init logic:
    // `for (var photo in widget.report.photos!) { _photos.add({ 'id': photo.id, ..., 'photo_url': photo.afterWork.photoPath ... }) }` ??
    // Checking `WorkReportEditForm` again...

    // In `WorkReportEditForm`:
    // _photos.add({
    //   'id': photo.id,
    //   'descripcion': ...,
    //   ...
    //   'photo': null,
    //   'photo_bytes': null
    // })
    // It DOES NOT store the existing URL in the map!
    // But we have `widget.report`.
    // If `data['id']` is not null, we can find the original URL from `widget.report`.

    String? existingAfterUrl;
    String? existingBeforeUrl;

    if (widget.data['id'] != null &&
        widget.report != null &&
        widget.report!.photos != null) {
      final originalPhoto = widget.report!.photos!.firstWhere(
        (p) => p.id == widget.data['id'],
        orElse: () => widget
            .report!
            .photos![0], // Fallback/Unsafe? Should be safe if ID exists
      );
      // Check if IDs match to be sure
      if (originalPhoto.id == widget.data['id']) {
        existingAfterUrl = originalPhoto.afterWork.photoPath;
        existingBeforeUrl = originalPhoto.beforeWork.photoPath;
      }
    }

    final afterBytes = widget.data['photo_bytes'] as Uint8List?;
    final beforeBytes = widget.data['before_work_photo_bytes'] as Uint8List?;

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
                    controller: _beforeController,
                    onPick: widget.onPickBefore,
                    onTextChanged: widget.onBeforeDescChanged,
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
                    controller: _afterController,
                    onPick: widget.onPickAfter,
                    onTextChanged: widget.onAfterDescChanged,
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
    required TextEditingController controller,
    required VoidCallback onPick,
    required ValueChanged<String> onTextChanged,
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
          onTap: () {
            if (hasImage) {
              _showFullScreen(
                context,
                imageBytes ?? imageUrl,
                '$title - Vista Previa',
              );
            } else if (isEditMode) {
              onPick();
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
                  _buildPlaceholder(onPick),

                // Edit Overlay Button (only if image exists)
                if (hasImage && isEditMode)
                  Positioned(
                    top: 4,
                    right: 4,
                    child: Material(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(20),
                      child: InkWell(
                        onTap: onPick,
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

        // Description Input
        TextField(
          controller: controller,
          onChanged: onTextChanged,
          readOnly: !isEditMode,
          style: const TextStyle(fontSize: 12),
          maxLines: 3,
          minLines: 1,
          decoration: InputDecoration(
            hintText: 'Descripción...',
            hintStyle: TextStyle(color: Colors.white24, fontSize: 12),
            filled: true,
            fillColor: Colors.black12,
            contentPadding: const EdgeInsets.all(8),
            isDense: true,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(kIndRadius),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPlaceholder(VoidCallback onPick) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.add_a_photo_outlined, color: Colors.white24, size: 32),
        const SizedBox(height: 8),
        Text(
          'Sin Evidencia',
          style: TextStyle(color: Colors.white24, fontSize: 10),
        ),
        const SizedBox(height: 8),
        // Mini buttons
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            InkWell(
              onTap: onPick,
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
}
