import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
import 'package:fleather/fleather.dart';
import 'dart:convert';
import '../providers/photos_provider.dart';
import '../../data/models/photo.dart';
import '../../../../core/services/quill_converter_providers.dart';

// --- Constantes de Diseño Industrial ---
const Color kIndBg = Color(0xFF1F1F1F);
const Color kIndSurface = Color(0xFF121212); // Fondo de inputs
const Color kIndBorder = Colors.white24;
const Color kIndAccent = Colors.amber;
const double kIndRadius = 4.0;

class PhotoForm extends ConsumerStatefulWidget {
  final Photo? photo;

  const PhotoForm({super.key, this.photo});

  @override
  ConsumerState<PhotoForm> createState() => _PhotoFormState();
}

class _PhotoFormState extends ConsumerState<PhotoForm> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _workReportIdController;

  // Fleather Controllers
  late FleatherController _afterWorkDescriptionController;
  late FleatherController _beforeWorkDescriptionController;
  final GlobalKey<EditorState> _afterEditorKey = GlobalKey();
  final GlobalKey<EditorState> _beforeEditorKey = GlobalKey();

  MultipartFile? _afterWorkPhoto;
  MultipartFile? _beforeWorkPhoto;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _workReportIdController = TextEditingController(
      text: widget.photo?.workReportId.toString() ?? '',
    );

    // Initialize Fleather controllers
    _initAfterWorkController();
    _initBeforeWorkController();
  }

  Future<void> _initAfterWorkController() async {
    final text = widget.photo?.afterWork.description ?? '';
    _afterWorkDescriptionController = await _initFleatherController(text);
    if (mounted) setState(() {});
  }

  Future<void> _initBeforeWorkController() async {
    final text = widget.photo?.beforeWork.description ?? '';
    _beforeWorkDescriptionController = await _initFleatherController(text);
    if (mounted) setState(() {});
  }

  Future<FleatherController> _initFleatherController(String text) async {
    if (text.isEmpty) return FleatherController();

    try {
      // 1. Try converting HTML to Quill
      final convertHtmlToQuill = ref.read(convertHtmlToQuillProvider);
      final result = await convertHtmlToQuill(text);

      return result.fold(
        (failure) {
          // 2. If HTML conversion fails, try JSON parsing
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
            throw const FormatException('Invalid JSON');
          } catch (_) {
            // 3. Fallback: Treat as plain text
            return FleatherController(
              document: ParchmentDocument.fromDelta(Delta()..insert(text)),
            );
          }
        },
        (conversionResult) {
          // Successfully converted HTML
          try {
            final delta = jsonDecode(conversionResult.content);
            if (delta is Map && delta['ops'] != null) {
              return FleatherController(
                document: ParchmentDocument.fromJson(delta['ops']),
              );
            }
            throw const FormatException('Invalid Converted JSON');
          } catch (e) {
            return FleatherController(
              document: ParchmentDocument.fromDelta(Delta()..insert(text)),
            );
          }
        },
      );
    } catch (e) {
      return FleatherController(
        document: ParchmentDocument.fromDelta(Delta()..insert(text)),
      );
    }
  }

  @override
  void dispose() {
    _workReportIdController.dispose();
    _afterWorkDescriptionController.dispose();
    _beforeWorkDescriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(bool isAfterWork) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes();
      final multipartFile = MultipartFile.fromBytes(
        bytes,
        filename: pickedFile.name,
      );

      setState(() {
        if (isAfterWork) {
          _afterWorkPhoto = multipartFile;
        } else {
          _beforeWorkPhoto = multipartFile;
        }
      });
    }
  }

  Future<String?> _getHtmlContent(FleatherController controller) async {
    if (controller.document.toPlainText().trim().isEmpty) return null;

    final deltaJson = jsonEncode({
      'ops': controller.document.toDelta().toJson(),
    });
    final convertQuillToHtml = ref.read(convertQuillToHtmlProvider);
    final result = await convertQuillToHtml(deltaJson);

    return result.fold(
      (failure) => null, // Or handle error?
      (success) => success.content,
    );
  }

  @override
  Widget build(BuildContext context) {
    // Usamos Theme local para inyectar estilos a los inputs automáticamente
    return Theme(
      data: Theme.of(context).copyWith(
        brightness: Brightness.dark,
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: kIndSurface,
          labelStyle: const TextStyle(color: Colors.grey),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(kIndRadius),
            borderSide: const BorderSide(color: Colors.white24),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(kIndRadius),
            borderSide: const BorderSide(color: kIndAccent, width: 1.5),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(kIndRadius),
            borderSide: const BorderSide(color: Colors.redAccent),
          ),
        ),
      ),
      child: Container(
        color: kIndBg, // Fondo general
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildSectionTitle('IDENTIFICACIÓN DEL REPORTE'),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _workReportIdController,
                  decoration: const InputDecoration(
                    labelText: 'ID DE REPORTE',
                    prefixIcon: Icon(Icons.numbers, color: Colors.grey),
                  ),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                  keyboardType: TextInputType.number,
                  validator: (value) =>
                      value?.isEmpty ?? true ? 'Campo requerido' : null,
                ),

                const SizedBox(height: 24),
                const Divider(color: Colors.white10),
                const SizedBox(height: 24),

                // --- SECCIÓN AFTER WORK (REQUERIDO) ---
                _buildSectionTitle('EVIDENCIA FINAL (AFTER WORK)'),
                const SizedBox(height: 12),

                // Widget visual personalizado para el Picker
                _IndustrialImagePicker(
                  label: 'FOTO FINAL',
                  isFileSelected: _afterWorkPhoto != null,
                  onTap: () => _pickImage(true),
                  isRequired: true,
                ),

                const SizedBox(height: 12),
                _buildFleatherEditor(
                  label: 'DESCRIPCIÓN DE LA EVIDENCIA',
                  controller: _afterWorkDescriptionController,
                  editorKey: _afterEditorKey,
                ),

                const SizedBox(height: 24),
                const Divider(color: Colors.white10),
                const SizedBox(height: 24),

                // --- SECCIÓN BEFORE WORK (OPCIONAL) ---
                _buildSectionTitle('EVIDENCIA INICIAL (BEFORE WORK)'),
                const SizedBox(height: 12),

                _IndustrialImagePicker(
                  label: 'FOTO INICIAL (OPCIONAL)',
                  isFileSelected: _beforeWorkPhoto != null,
                  onTap: () => _pickImage(false),
                  isRequired: false,
                ),

                const SizedBox(height: 12),
                _buildFleatherEditor(
                  label: 'DESCRIPCIÓN INICIAL',
                  controller: _beforeWorkDescriptionController,
                  editorKey: _beforeEditorKey,
                ),

                const SizedBox(height: 32),

                // --- BOTÓN DE ACCIÓN ---
                SizedBox(
                  height: 54,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kIndAccent,
                      foregroundColor: Colors
                          .black, // Texto negro sobre ámbar para alto contraste
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(kIndRadius),
                      ),
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.black)
                        : Text(
                            widget.photo == null
                                ? 'REGISTRAR EVIDENCIA'
                                : 'ACTUALIZAR EVIDENCIA',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.0,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFleatherEditor({
    required String label,
    required FleatherController controller,
    required GlobalKey<EditorState> editorKey,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: kIndSurface,
        border: Border.all(color: kIndBorder),
        borderRadius: BorderRadius.circular(kIndRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                const Icon(Icons.description, color: Colors.grey, size: 16),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: kIndBorder),
          FleatherToolbar.basic(controller: controller, editorKey: editorKey),
          Container(
            height: 150,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: FleatherEditor(
              controller: controller,
              focusNode: FocusNode(),
              editorKey: editorKey,
              padding: const EdgeInsets.all(8),
            ),
          ),
        ],
      ),
    );
  }

  // Helper para títulos de sección estilo técnico
  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: Colors.white54,
        fontSize: 12,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.2,
      ),
    );
  }

  Future<void> _submit() async {
    if (_formKey.currentState?.validate() ?? false) {
      if (_afterWorkPhoto == null && widget.photo == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('⚠️ La foto final es obligatoria'),
            backgroundColor: Colors.redAccent.shade700,
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }

      setState(() => _isLoading = true);

      try {
        final afterHtml = await _getHtmlContent(
          _afterWorkDescriptionController,
        );
        final beforeHtml = await _getHtmlContent(
          _beforeWorkDescriptionController,
        );

        if (afterHtml == null && widget.photo == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('⚠️ La descripción final es obligatoria'),
            ),
          );
          setState(() => _isLoading = false);
          return;
        }

        if (widget.photo == null) {
          await ref
              .read(photosProvider.notifier)
              .createPhoto(
                int.parse(_workReportIdController.text),
                _afterWorkPhoto!,
                afterHtml ?? '',
                _beforeWorkPhoto,
                beforeHtml,
              );
        } else {
          await ref
              .read(photosProvider.notifier)
              .updatePhoto(
                widget.photo!.id!,
                _afterWorkPhoto,
                afterHtml ?? '',
                _beforeWorkPhoto,
                beforeHtml,
              );
        }

        if (mounted) Navigator.of(context).pop();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error: $e')));
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }
}

// --- WIDGET AUXILIAR PARA EL PICKER (DISEÑO INDUSTRIAL) ---
class _IndustrialImagePicker extends StatelessWidget {
  final String label;
  final bool isFileSelected;
  final VoidCallback onTap;
  final bool isRequired;

  const _IndustrialImagePicker({
    required this.label,
    required this.isFileSelected,
    required this.onTap,
    required this.isRequired,
  });

  @override
  Widget build(BuildContext context) {
    // Si hay archivo, borde Ámbar sólido. Si no, borde gris discontinuo (simulado con opacidad)
    final borderColor = isFileSelected ? kIndAccent : kIndBorder;
    final bgColor = isFileSelected
        ? kIndAccent.withOpacity(0.1)
        : Colors.transparent;
    final iconColor = isFileSelected ? kIndAccent : Colors.grey;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(kIndRadius),
      child: Container(
        height: 80, // Altura fija para consistencia
        decoration: BoxDecoration(
          color: bgColor,
          border: Border.all(
            color: borderColor,
            width: isFileSelected ? 1.5 : 1,
          ),
          borderRadius: BorderRadius.circular(kIndRadius),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isFileSelected ? Icons.check_circle : Icons.camera_alt_outlined,
              color: iconColor,
              size: 28,
            ),
            const SizedBox(width: 12),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isFileSelected ? 'IMAGEN CARGADA' : 'SUBIR FOTO',
                  style: TextStyle(
                    color: isFileSelected ? kIndAccent : Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                Text(
                  label,
                  style: TextStyle(
                    color: isFileSelected
                        ? kIndAccent.withOpacity(0.8)
                        : Colors.grey,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
            if (isFileSelected) ...[
              const SizedBox(width: 16),
              const Text(
                'CAMBIAR',
                style: TextStyle(color: Colors.white38, fontSize: 10),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
