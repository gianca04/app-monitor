import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/work_report.dart';
import '../../../photos/presentation/widgets/photo_action_viewer.dart';
import '../../../../core/theme_config.dart';

// --- CONSTANTES DE DISEÑO INDUSTRIAL ---
const Color kIndBg = AppTheme.background;
const Color kIndSurface = AppTheme.surface;
const Color kIndBorder = AppTheme.border;
const Color kIndAccent = AppTheme.primaryAccent;
const double kIndRadius = 4.0;

class IndustrialPhotoEntry extends ConsumerStatefulWidget {
  final int index;
  final Map<String, dynamic> data;
  final WorkReport? report;
  final VoidCallback onPickAfter;
  final VoidCallback onPickBefore;
  final VoidCallback onRemove;
  final VoidCallback? onSave;
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
    this.onSave,
    required this.onAfterDescChanged,
    required this.onBeforeDescChanged,
    this.isEditMode = false,
  });

  @override
  ConsumerState<IndustrialPhotoEntry> createState() =>
      _IndustrialPhotoEntryState();
}

class _IndustrialPhotoEntryState extends ConsumerState<IndustrialPhotoEntry> {
  late TextEditingController _afterController;
  late TextEditingController _beforeController;

  String _stripHtmlTags(String htmlString) {
    return htmlString.replaceAll(RegExp(r'<[^>]*>'), '');
  }

  @override
  void initState() {
    super.initState();
    _afterController = TextEditingController();
    _beforeController = TextEditingController();

    _initControllers();
  }

  void _initControllers() {
    // === AFTER WORK DESCRIPTION ===
    final afterText = _stripHtmlTags(widget.data['descripcion'] ?? '');
    _afterController.text = afterText;

    // === BEFORE WORK DESCRIPTION ===
    final beforeText = _stripHtmlTags(widget.data['before_work_descripcion'] ?? '');
    _beforeController.text = beforeText;

    // Listeners for changes
    _afterController.addListener(() {
      widget.onAfterDescChanged(_afterController.text);
    });

    _beforeController.addListener(() {
      widget.onBeforeDescChanged(_beforeController.text);
    });
  }

  @override
  void dispose() {
    _afterController.dispose();
    _beforeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: kIndSurface,
        border: Border.all(color: kIndBorder),
        borderRadius: BorderRadius.circular(kIndRadius),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: kIndBorder)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'EVIDENCIA #${widget.index + 1}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white70,
                  ),
                ),
                Row(
                  children: [
                    if (widget.isEditMode && widget.onSave != null)
                      IconButton(
                        icon: const Icon(
                          Icons.save,
                          color: kIndAccent,
                          size: 20,
                        ),
                        onPressed: widget.onSave,
                        tooltip: 'Guardar',
                      ),
                    IconButton(
                      icon: const Icon(
                        Icons.close,
                        color: Colors.redAccent,
                        size: 20,
                      ),
                      onPressed: widget.onRemove,
                      tooltip: 'Eliminar',
                    ),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                _buildPhotoBlock(
                  context,
                  widget.isEditMode ? '' : 'DESPUÉS DEL TRABAJO',
                  'FOTO FINAL',
                  widget.data['photo_bytes'],
                  widget.data['id'] != null
                      ? widget.report?.photos
                            ?.firstWhere((p) => p.id == widget.data['id'])
                            .afterWork
                            .photoPath
                      : null,
                  widget.onPickAfter,
                  _afterController,
                ),
                const Divider(color: Colors.white10, height: 24),
                _buildPhotoBlock(
                  context,
                  widget.isEditMode ? 'ANTES DEL TRABAJO' : 'ANTES DEL TRABAJO',
                  'FOTO INICIAL',
                  widget.data['before_work_photo_bytes'],
                  widget.data['id'] != null
                      ? widget.report?.photos
                            ?.firstWhere((p) => p.id == widget.data['id'])
                            .beforeWork
                            .photoPath
                      : null,
                  widget.onPickBefore,
                  _beforeController,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoBlock(
    BuildContext context,
    String title,
    String btnLabel,
    Uint8List? bytes,
    String? url,
    VoidCallback onPick,
    TextEditingController controller,
  ) {
    final hasPhoto = bytes != null || url != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: kIndAccent,
              ),
            ),
            if (hasPhoto)
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onPick,
                  borderRadius: BorderRadius.circular(kIndRadius),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.blueAccent, width: 0.5),
                      borderRadius: BorderRadius.circular(kIndRadius),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.refresh,
                          size: 14,
                          color: Colors.blueAccent,
                        ),
                        const SizedBox(width: 4),
                        const Text(
                          'CAMBIAR FOTO',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.blueAccent,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        PhotoActionViewer(
          title: title,
          url: url,
          bytes: bytes,
          placeholderLabel: 'Tocar para agregar foto',
          onPlaceholderTap: onPick,
          borderRadius: kIndRadius,
          borderColor: kIndBorder,
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: kIndSurface,
            border: Border.all(color: kIndBorder),
            borderRadius: BorderRadius.circular(kIndRadius),
          ),
          child: TextField(
            controller: controller,
            maxLines: null,
            minLines: 5,
            decoration: const InputDecoration(
              border: InputBorder.none,
              contentPadding: EdgeInsets.all(12),
            ),
            style: const TextStyle(color: Colors.white),
          ),
        ),
      ],
    );
  }
}