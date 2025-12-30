import 'dart:typed_data';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fleather/fleather.dart';
import '../../data/models/work_report.dart';
import '../../../photos/presentation/widgets/photo_action_viewer.dart';
import '../../../../core/theme_config.dart';
import '../../../../core/services/quill_converter_providers.dart';

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
  late FleatherController _afterController;
  late FleatherController _beforeController;
  final GlobalKey<EditorState> _afterEditorKey = GlobalKey();
  final GlobalKey<EditorState> _beforeEditorKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    // Initialize with empty controllers first to avoid late initialization error
    _afterController = FleatherController();
    _beforeController = FleatherController();

    // Then load the actual content asynchronously
    _initControllers();
  }

  Future<void> _initControllers() async {
    // === AFTER WORK DESCRIPTION ===
    try {
      final text = widget.data['descripcion'] ?? '';
      if (text.isNotEmpty) {
        _afterController = await _initFleatherController(text);
        if (mounted) setState(() {});
      }
    } catch (e) {
      print('❌ [PHOTO ENTRY] Error initializing after controller: $e');
    }

    // === BEFORE WORK DESCRIPTION ===
    try {
      final text = widget.data['before_work_descripcion'] ?? '';
      if (text.isNotEmpty) {
        _beforeController = await _initFleatherController(text);
        if (mounted) setState(() {});
      }
    } catch (e) {
      print('❌ [PHOTO ENTRY] Error initializing before controller: $e');
    }

    // Listeners for changes
    _afterController.addListener(() {
      try {
        final delta = _afterController.document.toDelta().toJson();
        widget.onAfterDescChanged(jsonEncode({'ops': delta}));
      } catch (e) {
        // Handle potential encoding errors
      }
    });

    _beforeController.addListener(() {
      try {
        final delta = _beforeController.document.toDelta().toJson();
        widget.onBeforeDescChanged(jsonEncode({'ops': delta}));
      } catch (e) {
        // Handle potential encoding errors
      }
    });
  }

  Future<FleatherController> _initFleatherController(String text) async {
    if (text.isEmpty) return FleatherController();

    try {
      // 1. Try converting HTML to Quill using the provider
      final convertHtmlToQuill = ref.read(convertHtmlToQuillProvider);
      final result = await convertHtmlToQuill(text);

      return result.fold(
        (failure) {
          // 2. If HTML conversion fails, try robust JSON parsing or plain text
          try {
            final delta = jsonDecode(text);
            if (delta is Map && delta['ops'] != null) {
              return FleatherController(
                document: ParchmentDocument.fromJson(delta['ops']),
              );
            } else if (delta is List) {
              return FleatherController(
                document: ParchmentDocument.fromJson(delta),
              );
            }
            throw const FormatException('Invalid JSON for Delta');
          } catch (_) {
            // 3. Fallback: Treat as plain text
            return FleatherController(
              document: ParchmentDocument.fromDelta(Delta()..insert(text)),
            );
          }
        },
        (conversionResult) {
          // Successfully converted HTML to Delta JSON string
          // The converter usually returns a JSON string representing the Delta
          try {
            final delta = jsonDecode(conversionResult.content);
            // Verify structure returned by converter (usually {ops: [...]} )
            if (delta is Map && delta['ops'] != null) {
              return FleatherController(
                document: ParchmentDocument.fromJson(delta['ops']),
              );
            } else if (delta is List) {
              return FleatherController(
                document: ParchmentDocument.fromJson(delta),
              );
            }
            throw const FormatException('Invalid Converted JSON');
          } catch (e) {
            print('⚠️ [PHOTO ENTRY] Converted HTML JSON invalid: $e');
            // If conversion result isn't valid JSON, fallback to text
            return FleatherController(
              document: ParchmentDocument.fromDelta(Delta()..insert(text)),
            );
          }
        },
      );
    } catch (e) {
      print('⚠️ [PHOTO ENTRY] General error parsing text: $e');
      return FleatherController(
        document: ParchmentDocument.fromDelta(Delta()..insert(text)),
      );
    }
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
                  _afterEditorKey,
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
                  _beforeEditorKey,
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
    FleatherController controller,
    GlobalKey<EditorState> editorKey,
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
          child: Column(
            children: [
              FleatherToolbar.basic(
                controller: controller,
                editorKey: editorKey,
              ),
              Container(
                height: 150,
                decoration: const BoxDecoration(
                  border: Border(top: BorderSide(color: kIndBorder)),
                ),
                child: FleatherEditor(
                  controller: controller,
                  padding: const EdgeInsets.all(12),
                  focusNode: FocusNode(),
                  editorKey: editorKey,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}