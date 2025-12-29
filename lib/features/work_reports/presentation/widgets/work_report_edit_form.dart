import 'dart:typed_data';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
import 'package:go_router/go_router.dart';
import 'package:fleather/fleather.dart';
import '../../data/models/work_report.dart';
import '../providers/work_reports_provider.dart';
import '../../../photos/presentation/widgets/image_viewer.dart';
import '../../../../core/widgets/modern_bottom_modal.dart';
import '../../../employees/presentation/widgets/quick_search_modal.dart';
import '../../../employees/data/models/quick_search_response.dart';
import '../../../projects/presentation/widgets/quick_search_modal.dart'
    as projects_modal;
import '../../../projects/data/models/quick_search_response.dart';
import '../../../photos/domain/usecases/create_photo_usecase.dart';
import '../../../photos/domain/usecases/update_photo_usecase.dart';
import '../../../photos/domain/usecases/delete_photo_usecase.dart';
import 'industrial_selector.dart';
import '../../../../core/widgets/industrial_signature.dart';
import '../../../../core/theme_config.dart';
import '../../../../core/services/quill_converter_providers.dart';

// --- CONSTANTES DE DISEÑO INDUSTRIAL ---
const Color kIndBg = AppTheme.background;
const Color kIndSurface = AppTheme.surface;
const Color kIndBorder = AppTheme.border;
const Color kIndAccent = AppTheme.primaryAccent;
const double kIndRadius = 4.0;

class WorkReportEditForm extends ConsumerStatefulWidget {
  final WorkReport report;

  const WorkReportEditForm({super.key, required this.report});

  @override
  ConsumerState<WorkReportEditForm> createState() => _WorkReportEditFormState();
}

class _WorkReportEditFormState extends ConsumerState<WorkReportEditForm> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  FleatherController? _descriptionController;
  late TextEditingController _reportDateController;
  late TextEditingController _startTimeController;
  late TextEditingController _endTimeController;
  FleatherController? _toolsController;
  FleatherController? _personnelController;
  FleatherController? _materialsController;
  FleatherController? _suggestionsController;
  late TextEditingController _employeeIdController;
  late TextEditingController _projectIdController;

  final GlobalKey<EditorState> _editorKey = GlobalKey();
  final GlobalKey<EditorState> _descriptionEditorKey = GlobalKey();
  final GlobalKey<EditorState> _personnelEditorKey = GlobalKey();
  final GlobalKey<EditorState> _materialsEditorKey = GlobalKey();
  final GlobalKey<EditorState> _suggestionsEditorKey = GlobalKey();

  EmployeeQuick? _selectedEmployee;
  ProjectQuick? _selectedProject;

  String? _supervisorSignature;
  String? _managerSignature;
  String? _supervisorSignatureBytes;
  String? _managerSignatureBytes;

  List<Map<String, dynamic>> _photos = [];

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.report.name ?? '');
    _initDescriptionController();
    _reportDateController = TextEditingController(
      text: widget.report.reportDate ?? '',
    );
    _startTimeController = TextEditingController(
      text: widget.report.startTime ?? '',
    );
    _endTimeController = TextEditingController(
      text: widget.report.endTime ?? '',
    );
    _initToolsController();
    _initPersonnelController();
    _initMaterialsController();
    _initSuggestionsController();
    _employeeIdController = TextEditingController(
      text: widget.report.employee?.id.toString() ?? '',
    );
    _projectIdController = TextEditingController(
      text: widget.report.project?.id.toString() ?? '',
    );

    if (widget.report.employee != null) {
      _selectedEmployee = EmployeeQuick(
        id: widget.report.employee!.id,
        fullName: widget.report.employee!.fullName,
        documentNumber: widget.report.employee!.documentNumber,
        position: widget.report.employee!.position?.name,
      );
    }

    if (widget.report.project != null) {
      _selectedProject = ProjectQuick(
        id: widget.report.project!.id,
        name: widget.report.project!.name,
      );
    }

    if (widget.report.photos != null) {
      for (var photo in widget.report.photos!) {
        _photos.add({
          'id': photo.id,
          'descripcion': photo.afterWork.description,
          'before_work_descripcion': photo.beforeWork.description,
          'photo': null,
          'before_work_photo': null,
          'photo_bytes': null,
          'before_work_photo_bytes': null,
        });
      }
    }

    // Initialize signatures - handle both URLs and base64
    final supervisorSig = widget.report.signatures?.supervisor;
    final managerSig = widget.report.signatures?.manager;

    // Store original signatures (could be URLs or base64)
    _supervisorSignature = supervisorSig;
    _managerSignature = managerSig;

    // For display, use the same values (SignatureBox now handles both URLs and base64)
    _supervisorSignatureBytes = supervisorSig;
    _managerSignatureBytes = managerSig;

    print('🔍 [INIT] Initialized signatures from report:');
    print(
      '🔍 [INIT] supervisor: ${_supervisorSignature != null ? "${_supervisorSignature!.substring(0, 50)}..." : "null"}',
    );
    print(
      '🔍 [INIT] manager: ${_managerSignature != null ? "${_managerSignature!.substring(0, 50)}..." : "null"}',
    );
  }

  Future<void> _initDescriptionController() async {
    try {
      final text = widget.report.description ?? '';
      if (text.isEmpty) {
        _descriptionController = FleatherController();
      } else {
        // Try to convert HTML to Quill Delta
        final convertHtmlToQuill = ref.read(convertHtmlToQuillProvider);
        final result = await convertHtmlToQuill(text);

        result.fold(
          (failure) {
            print(
              '❌ [EDIT] HTML conversion failed for description: ${failure.message}',
            );
            // If conversion fails, try as JSON or plain text
            try {
              final delta = jsonDecode(text);
              if (delta is Map && delta['ops'] != null) {
                _descriptionController = FleatherController(
                  document: ParchmentDocument.fromJson(delta['ops']),
                );
              } else if (delta is List) {
                _descriptionController = FleatherController(
                  document: ParchmentDocument.fromJson(delta),
                );
              } else {
                throw const FormatException('Not a valid format');
              }
            } catch (_) {
              _descriptionController = FleatherController(
                document: ParchmentDocument.fromDelta(Delta()..insert(text)),
              );
            }
          },
          (conversionResult) {
            // Successfully converted HTML to Quill
            print(
              '✅ [EDIT] HTML converted for description: ${conversionResult.content.substring(0, conversionResult.content.length > 100 ? 100 : conversionResult.content.length)}',
            );
            try {
              final delta = jsonDecode(conversionResult.content);
              if (delta is Map && delta['ops'] != null) {
                print(
                  '✅ [EDIT] Creating FleatherController with ops: ${delta['ops']}',
                );
                _descriptionController = FleatherController(
                  document: ParchmentDocument.fromJson(delta['ops']),
                );
              } else {
                throw const FormatException('Invalid format');
              }
            } catch (e) {
              print(
                '❌ [EDIT] Error parsing converted Quill for description: $e',
              );
              _descriptionController = FleatherController(
                document: ParchmentDocument.fromDelta(Delta()..insert(text)),
              );
            }
          },
        );
      }
    } catch (err, st) {
      print('❌ [EDIT] Error initializing description controller: $err\n$st');
      _descriptionController = FleatherController();
    }
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _initToolsController() async {
    try {
      final text = widget.report.resources?.tools ?? '';
      print(
        '🔧 [EDIT] Tools text received: "${text.substring(0, text.length > 100 ? 100 : text.length)}"',
      );
      if (text.isEmpty) {
        _toolsController = FleatherController();
      } else {
        // Try to convert HTML to Quill Delta
        final convertHtmlToQuill = ref.read(convertHtmlToQuillProvider);
        final result = await convertHtmlToQuill(text);

        result.fold(
          (failure) {
            print(
              '❌ [EDIT] HTML conversion failed for tools: ${failure.message}',
            );
            // If conversion fails, try as JSON or plain text
            try {
              final delta = jsonDecode(text);
              if (delta is Map && delta['ops'] != null) {
                _toolsController = FleatherController(
                  document: ParchmentDocument.fromJson(delta['ops']),
                );
              } else if (delta is List) {
                _toolsController = FleatherController(
                  document: ParchmentDocument.fromJson(delta),
                );
              } else {
                throw const FormatException('Not a valid format');
              }
            } catch (_) {
              _toolsController = FleatherController(
                document: ParchmentDocument.fromDelta(Delta()..insert(text)),
              );
            }
          },
          (conversionResult) {
            // Successfully converted HTML to Quill
            print(
              '✅ [EDIT] HTML converted for tools: ${conversionResult.content.substring(0, conversionResult.content.length > 100 ? 100 : conversionResult.content.length)}',
            );
            try {
              final delta = jsonDecode(conversionResult.content);
              if (delta is Map && delta['ops'] != null) {
                print(
                  '✅ [EDIT] Creating FleatherController with ops: ${delta['ops']}',
                );
                _toolsController = FleatherController(
                  document: ParchmentDocument.fromJson(delta['ops']),
                );
              } else {
                throw const FormatException('Invalid format');
              }
            } catch (e) {
              print('❌ [EDIT] Error parsing converted Quill for tools: $e');
              _toolsController = FleatherController(
                document: ParchmentDocument.fromDelta(Delta()..insert(text)),
              );
            }
          },
        );
      }
    } catch (err, st) {
      print('❌ [EDIT] Error initializing tools controller: $err\n$st');
      _toolsController = FleatherController();
    }
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _initPersonnelController() async {
    try {
      final text = widget.report.resources?.personnel ?? '';
      if (text.isEmpty) {
        _personnelController = FleatherController();
      } else {
        // Try to convert HTML to Quill Delta
        final convertHtmlToQuill = ref.read(convertHtmlToQuillProvider);
        final result = await convertHtmlToQuill(text);

        result.fold(
          (failure) {
            // If conversion fails, try as JSON or plain text
            try {
              final delta = jsonDecode(text);
              if (delta is Map && delta['ops'] != null) {
                _personnelController = FleatherController(
                  document: ParchmentDocument.fromJson(delta['ops']),
                );
              } else if (delta is List) {
                _personnelController = FleatherController(
                  document: ParchmentDocument.fromJson(delta),
                );
              } else {
                throw const FormatException('Not a valid format');
              }
            } catch (_) {
              _personnelController = FleatherController(
                document: ParchmentDocument.fromDelta(Delta()..insert(text)),
              );
            }
          },
          (conversionResult) {
            // Successfully converted HTML to Quill
            try {
              final delta = jsonDecode(conversionResult.content);
              if (delta is Map && delta['ops'] != null) {
                _personnelController = FleatherController(
                  document: ParchmentDocument.fromJson(delta['ops']),
                );
              } else {
                throw const FormatException('Invalid format');
              }
            } catch (e) {
              print('Error parsing converted Quill: $e');
              _personnelController = FleatherController(
                document: ParchmentDocument.fromDelta(Delta()..insert(text)),
              );
            }
          },
        );
      }
    } catch (err, st) {
      print('Error initializing personnel controller: $err\n$st');
      _personnelController = FleatherController();
    }
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _initMaterialsController() async {
    try {
      final text = widget.report.resources?.materials ?? '';
      if (text.isEmpty) {
        _materialsController = FleatherController();
      } else {
        // Try to convert HTML to Quill Delta
        final convertHtmlToQuill = ref.read(convertHtmlToQuillProvider);
        final result = await convertHtmlToQuill(text);

        result.fold(
          (failure) {
            // If conversion fails, try as JSON or plain text
            try {
              final delta = jsonDecode(text);
              if (delta is Map && delta['ops'] != null) {
                _materialsController = FleatherController(
                  document: ParchmentDocument.fromJson(delta['ops']),
                );
              } else if (delta is List) {
                _materialsController = FleatherController(
                  document: ParchmentDocument.fromJson(delta),
                );
              } else {
                throw const FormatException('Not a valid format');
              }
            } catch (_) {
              _materialsController = FleatherController(
                document: ParchmentDocument.fromDelta(Delta()..insert(text)),
              );
            }
          },
          (conversionResult) {
            // Successfully converted HTML to Quill
            try {
              final delta = jsonDecode(conversionResult.content);
              if (delta is Map && delta['ops'] != null) {
                _materialsController = FleatherController(
                  document: ParchmentDocument.fromJson(delta['ops']),
                );
              } else {
                throw const FormatException('Invalid format');
              }
            } catch (e) {
              print('Error parsing converted Quill: $e');
              _materialsController = FleatherController(
                document: ParchmentDocument.fromDelta(Delta()..insert(text)),
              );
            }
          },
        );
      }
    } catch (err, st) {
      print('Error initializing materials controller: $err\n$st');
      _materialsController = FleatherController();
    }
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _initSuggestionsController() async {
    try {
      final text = widget.report.suggestions ?? '';
      try {
        final delta = jsonDecode(text);
        if (delta is List) {
          _suggestionsController = FleatherController(
            document: ParchmentDocument.fromJson(delta),
          );
        } else {
          throw const FormatException('Not a list');
        }
      } catch (_) {
        _suggestionsController = FleatherController(
          document: ParchmentDocument.fromDelta(Delta()..insert(text)),
        );
      }
    } catch (err, st) {
      print('Error initializing suggestions controller: $err\n$st');
      _suggestionsController = FleatherController();
    }
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController?.dispose();
    _reportDateController.dispose();
    _startTimeController.dispose();
    _endTimeController.dispose();
    _toolsController?.dispose();
    _personnelController?.dispose();
    _materialsController?.dispose();
    _suggestionsController?.dispose();
    _employeeIdController.dispose();
    _projectIdController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(bool isSupervisor) async {
    // Llamada limpia usando el método estático del Sheet
    final String? signatureBase64 = await IndustrialSignatureSheet.show(
      context,
      title: isSupervisor ? 'FIRMA DEL SUPERVISOR' : 'FIRMA GERENCIA / CLIENTE',
    );

    // Lógica de negocio (Guardado)
    if (signatureBase64 != null) {
      setState(() {
        if (isSupervisor) {
          _supervisorSignature = signatureBase64;
          _supervisorSignatureBytes = signatureBase64;
        } else {
          _managerSignature = signatureBase64;
          _managerSignatureBytes = signatureBase64;
        }
      });
    }
  }

  void _addPhoto() {
    setState(() {
      _photos.add({
        'descripcion': '',
        'before_work_descripcion': '',
        'photo': null,
        'before_work_photo': null,
        'photo_bytes': null,
        'before_work_photo_bytes': null,
      });
    });
  }

  Future<void> _pickPhotoImage(int index, bool isAfterWork) async {
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
          _photos[index]['photo'] = multipartFile;
          _photos[index]['photo_bytes'] = bytes;
        } else {
          _photos[index]['before_work_photo'] = multipartFile;
          _photos[index]['before_work_photo_bytes'] = bytes;
        }
      });
    }
  }

  Future<void> _savePhoto(int index) async {
    final photo = _photos[index];

    // Convert descriptions from Delta to HTML before saving
    final descripcionHtml = await _convertDeltaToHtml(photo['descripcion']);
    final beforeWorkDescripcionHtml = await _convertDeltaToHtml(
      photo['before_work_descripcion'],
    );

    if (photo['id'] == null) {
      // Create new photo
      if (photo['photo'] != null && (descripcionHtml?.isNotEmpty ?? false)) {
        try {
          final createUseCase = CreatePhotoUseCase(
            ref.read(workReportsPhotosRepositoryProvider),
          );
          await createUseCase(
            widget.report.id!,
            photo['photo'],
            descripcionHtml!,
            photo['before_work_photo'],
            beforeWorkDescripcionHtml,
          );
          // Invalidate to reload
          ref.invalidate(workReportProvider(widget.report.id!));
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Foto creada exitosamente')),
            );
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text('Error creando foto: $e')));
          }
        }
      }
    } else {
      // Update existing photo
      try {
        final updateUseCase = UpdatePhotoUseCase(
          ref.read(workReportsPhotosRepositoryProvider),
        );
        await updateUseCase(
          photo['id'],
          photo['photo_bytes'] != null
              ? MultipartFile.fromBytes(
                  photo['photo_bytes'],
                  filename: 'photo.jpg',
                )
              : null,
          descripcionHtml ?? '',
          photo['before_work_photo_bytes'] != null
              ? MultipartFile.fromBytes(
                  photo['before_work_photo_bytes'],
                  filename: 'before.jpg',
                )
              : null,
          beforeWorkDescripcionHtml,
        );
        // Invalidate to reload
        ref.invalidate(workReportProvider(widget.report.id!));
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Foto actualizada exitosamente')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error actualizando foto: $e')),
          );
        }
      }
    }
  }

  Future<void> _deletePhoto(int index) async {
    final photo = _photos[index];
    if (photo['id'] != null) {
      try {
        final deleteUseCase = DeletePhotoUseCase(
          ref.read(workReportsPhotosRepositoryProvider),
        );
        await deleteUseCase(photo['id']);
        if (mounted) {
          setState(() {
            _photos.removeAt(index);
          });
        }
        // Invalidate to reload
        ref.invalidate(workReportProvider(widget.report.id!));
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Foto eliminada exitosamente')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error eliminando foto: $e')));
        }
      }
    } else {
      // Remove unsaved photo
      if (mounted) {
        setState(() {
          _photos.removeAt(index);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(
        brightness: Brightness.dark,
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: kIndSurface,
          labelStyle: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(kIndRadius),
            borderSide: const BorderSide(color: kIndBorder),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(kIndRadius),
            borderSide: const BorderSide(color: kIndAccent, width: 1.5),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(kIndRadius),
            borderSide: BorderSide(color: AppTheme.error),
          ),
        ),
      ),
      child: Container(
        color: kIndBg,
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              _buildSectionHeader(
                Theme.of(context),
                title: 'CONTEXTO OPERATIVO',
                icon: Icons.location_on,
              ),
              const SizedBox(height: 12),

              IndustrialSelector(
                label: 'PROYECTO ASIGNADO',
                value: _selectedProject != null
                    ? '${_selectedProject!.name} (ID: ${_selectedProject!.id})'
                    : null,
                icon: Icons.business,
                onTap: () async {
                  final result = await ModernBottomModal.show<ProjectQuick>(
                    context,
                    title: 'Seleccionar Proyecto',
                    content: const projects_modal.QuickSearchModal(),
                  );
                  if (result != null) {
                    setState(() {
                      _selectedProject = result;
                      _projectIdController.text = result.id.toString();
                    });
                  }
                },
              ),
              const SizedBox(height: 12),

              IndustrialSelector(
                label: 'RESPONSABLE TÉCNICO',
                value: _selectedEmployee != null
                    ? '${_selectedEmployee!.fullName}'
                    : null,
                subValue: _selectedEmployee != null
                    ? 'DOC: ${_selectedEmployee!.documentNumber}'
                    : null,
                icon: Icons.badge,
                onTap: () async {
                  final result = await ModernBottomModal.show<EmployeeQuick>(
                    context,
                    title: 'Seleccionar Empleado',
                    content: const QuickSearchModal(),
                  );
                  if (result != null) {
                    setState(() {
                      _selectedEmployee = result;
                      _employeeIdController.text = result.id.toString();
                    });
                  }
                },
              ),

              const SizedBox(height: 24),
              const Divider(color: Colors.white10),
              const SizedBox(height: 24),

              _buildSectionHeader(
                Theme.of(context),
                title: 'DETALLES DEL REPORTE',
                icon: Icons.description,
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'NOMBRE DEL REPORTE',
                  prefixIcon: Icon(Icons.title, color: AppTheme.textSecondary),
                ),
                validator: (value) =>
                    value?.isEmpty ?? true ? 'Requerido' : null,
              ),
              const SizedBox(height: 12),

              Column(
                // <--- 1. CONTENEDOR PRINCIPAL: Vertical
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- 1. CAMPO FECHA (Full Width) ---
                  TextFormField(
                    controller: _reportDateController,
                    readOnly: true,
                    decoration: const InputDecoration(labelText: 'FECHA'),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2101),
                      );
                      if (picked != null) {
                        _reportDateController.text = picked
                            .toIso8601String()
                            .split('T')[0];
                      }
                    },
                    validator: (value) =>
                        value?.isEmpty ?? true ? 'Requerido' : null,
                  ),

                  const SizedBox(height: 16), // Espacio entre Fecha y Horas
                  // --- 2. HORA INICIO Y HORA FIN (Row Anidada) ---
                  Row(
                    // <--- 2. Fila para las Horas
                    children: [
                      Expanded(
                        // 50%
                        child: TextFormField(
                          controller: _startTimeController,
                          readOnly: true,
                          decoration: const InputDecoration(
                            labelText: 'INICIO (HH:mm)',
                          ),
                          onTap: () async {
                            final picked = await showTimePicker(
                              context: context,
                              initialTime: TimeOfDay.now(),
                            );
                            if (picked != null) {
                              _startTimeController.text =
                                  '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
                            }
                          },
                        ),
                      ),
                      const SizedBox(
                        width: 8,
                      ), // Espacio entre los campos de hora
                      Expanded(
                        // 50%
                        child: TextFormField(
                          controller: _endTimeController,
                          readOnly: true,
                          decoration: const InputDecoration(
                            labelText: 'FIN (HH:mm)',
                          ),
                          onTap: () async {
                            final picked = await showTimePicker(
                              context: context,
                              initialTime: TimeOfDay.now(),
                            );
                            if (picked != null) {
                              _endTimeController.text =
                                  '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  color: kIndSurface,
                  border: Border.all(color: kIndBorder),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(kIndRadius),
                    topRight: Radius.circular(kIndRadius),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 16, top: 8),
                      child: Row(
                        children: [
                          Icon(Icons.description, color: Colors.grey, size: 18),
                          const SizedBox(width: 8),
                          Text(
                            'DESCRIPCIÓN GENERAL',
                            style: TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (_descriptionController == null)
                      const Padding(
                        padding: EdgeInsets.all(16),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    else ...[
                      FleatherToolbar.basic(
                        controller: _descriptionController!,
                        editorKey: _descriptionEditorKey,
                      ),
                      Container(
                        height: 200,
                        decoration: BoxDecoration(
                          border: Border.all(color: kIndBorder),
                          borderRadius: BorderRadius.only(
                            bottomLeft: Radius.circular(kIndRadius),
                            bottomRight: Radius.circular(kIndRadius),
                          ),
                        ),
                        child: FleatherEditor(
                          controller: _descriptionController!,
                          padding: const EdgeInsets.all(16),
                          focusNode: FocusNode(),
                          editorKey: _descriptionEditorKey,
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 24),
              const Divider(color: Colors.white10),
              const SizedBox(height: 24),

              _buildSectionHeader(
                Theme.of(context),
                title: 'RECURSOS UTILIZADOS',
                icon: Icons.build,
              ),
              const SizedBox(height: 12),

              Container(
                decoration: BoxDecoration(
                  color: kIndSurface,
                  border: Border.all(color: kIndBorder),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(kIndRadius),
                    topRight: Radius.circular(kIndRadius),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 16, top: 8),
                      child: Row(
                        children: [
                          Icon(Icons.build, color: Colors.grey, size: 18),
                          const SizedBox(width: 8),
                          Text(
                            'HERRAMIENTAS / EQUIPOS',
                            style: TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (_toolsController == null)
                      const Padding(
                        padding: EdgeInsets.all(16),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    else ...[
                      FleatherToolbar.basic(
                        controller: _toolsController!,
                        editorKey: _editorKey,
                      ),
                      Container(
                        height: 200,
                        decoration: BoxDecoration(
                          border: Border.all(color: kIndBorder),
                          borderRadius: BorderRadius.only(
                            bottomLeft: Radius.circular(kIndRadius),
                            bottomRight: Radius.circular(kIndRadius),
                          ),
                        ),
                        child: FleatherEditor(
                          controller: _toolsController!,
                          padding: const EdgeInsets.all(16),
                          focusNode: FocusNode(),
                          editorKey: _editorKey,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  color: kIndSurface,
                  border: Border.all(color: kIndBorder),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(kIndRadius),
                    topRight: Radius.circular(kIndRadius),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 16, top: 8),
                      child: Row(
                        children: [
                          Icon(Icons.group, color: Colors.grey, size: 18),
                          const SizedBox(width: 8),
                          Text(
                            'PERSONAL ADICIONAL',
                            style: TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (_personnelController == null)
                      const Padding(
                        padding: EdgeInsets.all(16),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    else ...[
                      FleatherToolbar.basic(
                        controller: _personnelController!,
                        editorKey: _personnelEditorKey,
                      ),
                      Container(
                        height: 200,
                        decoration: BoxDecoration(
                          border: Border.all(color: kIndBorder),
                          borderRadius: BorderRadius.only(
                            bottomLeft: Radius.circular(kIndRadius),
                            bottomRight: Radius.circular(kIndRadius),
                          ),
                        ),
                        child: FleatherEditor(
                          controller: _personnelController!,
                          padding: const EdgeInsets.all(16),
                          focusNode: FocusNode(),
                          editorKey: _personnelEditorKey,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  color: kIndSurface,
                  border: Border.all(color: kIndBorder),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(kIndRadius),
                    topRight: Radius.circular(kIndRadius),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 16, top: 8),
                      child: Row(
                        children: [
                          Icon(Icons.inventory_2, color: Colors.grey, size: 18),
                          const SizedBox(width: 8),
                          Text(
                            'MATERIALES / INSUMOS',
                            style: TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (_materialsController == null)
                      const Padding(
                        padding: EdgeInsets.all(16),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    else ...[
                      FleatherToolbar.basic(
                        controller: _materialsController!,
                        editorKey: _materialsEditorKey,
                      ),
                      Container(
                        height: 200,
                        decoration: BoxDecoration(
                          border: Border.all(color: kIndBorder),
                          borderRadius: BorderRadius.only(
                            bottomLeft: Radius.circular(kIndRadius),
                            bottomRight: Radius.circular(kIndRadius),
                          ),
                        ),
                        child: FleatherEditor(
                          controller: _materialsController!,
                          padding: const EdgeInsets.all(16),
                          focusNode: FocusNode(),
                          editorKey: _materialsEditorKey,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  color: kIndSurface,
                  border: Border.all(color: kIndBorder),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(kIndRadius),
                    topRight: Radius.circular(kIndRadius),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 16, top: 8),
                      child: Row(
                        children: [
                          Icon(Icons.lightbulb, color: Colors.grey, size: 18),
                          const SizedBox(width: 8),
                          Text(
                            'OBSERVACIONES / SUGERENCIAS',
                            style: TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (_suggestionsController == null)
                      const Padding(
                        padding: EdgeInsets.all(16),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    else ...[
                      FleatherToolbar.basic(
                        controller: _suggestionsController!,
                        editorKey: _suggestionsEditorKey,
                      ),
                      Container(
                        height: 200,
                        decoration: BoxDecoration(
                          border: Border.all(color: kIndBorder),
                          borderRadius: BorderRadius.only(
                            bottomLeft: Radius.circular(kIndRadius),
                            bottomRight: Radius.circular(kIndRadius),
                          ),
                        ),
                        child: FleatherEditor(
                          controller: _suggestionsController!,
                          padding: const EdgeInsets.all(16),
                          focusNode: FocusNode(),
                          editorKey: _suggestionsEditorKey,
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 24),
              const Divider(color: Colors.white10),
              const SizedBox(height: 24),

              SizedBox(
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kIndAccent,
                    foregroundColor: Colors.black,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(kIndRadius),
                    ),
                  ),
                  child: _isLoading
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.black,
                                ),
                              ),
                            ),
                            SizedBox(width: 8),
                            Text(
                              'CARGANDO...',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.0,
                              ),
                            ),
                          ],
                        )
                      : const Text(
                          'ACTUALIZAR REPORTE',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.0,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 24),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildSectionHeader(
                    Theme.of(context),
                    title: 'EVIDENCIA FOTOGRÁFICA',
                    icon: Icons.photo,
                  ),
                  TextButton.icon(
                    onPressed: _addPhoto,
                    icon: const Icon(Icons.add, size: 16, color: kIndAccent),
                    label: const Text(
                      'AGREGAR',
                      style: TextStyle(color: kIndAccent),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              if (_photos.isEmpty)
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Colors.white10,
                      style: BorderStyle.solid,
                    ),
                    borderRadius: BorderRadius.circular(kIndRadius),
                  ),
                  child: const Center(
                    child: Text(
                      'No hay evidencia adjunta',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                ),

              ..._photos.asMap().entries.map((entry) {
                return _IndustrialPhotoEntry(
                  index: entry.key,
                  data: entry.value,
                  report: widget.report,
                  onPickAfter: () => _pickPhotoImage(entry.key, true),
                  onPickBefore: () => _pickPhotoImage(entry.key, false),
                  onRemove: () => _deletePhoto(entry.key),
                  onSave: () => _savePhoto(entry.key),
                  onAfterDescChanged: (v) => entry.value['descripcion'] = v,
                  onBeforeDescChanged: (v) =>
                      entry.value['before_work_descripcion'] = v,
                  isEditMode: true,
                );
              }),

              const SizedBox(height: 24),
              const Divider(color: Colors.white10),
              const SizedBox(height: 24),

              _buildSectionHeader(
                Theme.of(context),
                title: 'VALIDACIÓN Y FIRMAS',
                icon: Icons.edit,
              ),
              const SizedBox(height: 12),

              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: IndustrialSignatureBox(
                      title: 'SUPERVISOR',
                      base64: _supervisorSignatureBytes,
                      onTap: () => _pickImage(true),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: IndustrialSignatureBox(
                      title: 'GERENCIA / CLIENTE',
                      base64: _managerSignatureBytes,
                      onTap: () => _pickImage(false),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(
    ThemeData theme, {
    required String title,
    IconData? icon,
  }) {
    return Row(
      children: [
        if (icon != null) Icon(icon, color: kIndAccent, size: 16),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            color: kIndAccent,
            fontSize: 12,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
          ),
        ),
      ],
    );
  }

  void _submit() async {
    if (_formKey.currentState?.validate() ?? false) {
      if (_selectedEmployee == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Debe seleccionar un empleado')),
        );
        return;
      }
      if (_selectedProject == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Debe seleccionar un proyecto')),
        );
        return;
      }

      print('🔍 [SUBMIT] Starting submit with signatures:');
      print(
        '🔍 [SUBMIT] _supervisorSignature: ${_supervisorSignature != null ? "present (${_supervisorSignature!.length} chars)" : "null"}',
      );
      print(
        '🔍 [SUBMIT] _managerSignature: ${_managerSignature != null ? "present (${_managerSignature!.length} chars)" : "null"}',
      );

      setState(() => _isLoading = true);
      try {
        print('🔍 [SUBMIT] Calling updateWorkReport...');

        // Convert Quill Delta to HTML for description
        final convertQuillToHtml = ref.read(convertQuillToHtmlProvider);

        String? descriptionHtml;
        if (_descriptionController != null &&
            _descriptionController!.document.toPlainText().trim().isNotEmpty) {
          final descriptionDelta = jsonEncode({
            'ops': _descriptionController!.document.toDelta().toJson(),
          });
          final result = await convertQuillToHtml(descriptionDelta);
          result.fold(
            (failure) {
              print(
                '⚠️ [SUBMIT] Failed to convert description to HTML: ${failure.message}',
              );
              descriptionHtml = jsonEncode(
                _descriptionController!.document.toDelta().toJson(),
              );
            },
            (conversionResult) {
              descriptionHtml = conversionResult.content;
              print('✅ [SUBMIT] Description converted to HTML');
            },
          );
        }

        String? toolsHtml;
        if (_toolsController != null &&
            _toolsController!.document.toPlainText().trim().isNotEmpty) {
          final toolsDelta = jsonEncode({
            'ops': _toolsController!.document.toDelta().toJson(),
          });
          final result = await convertQuillToHtml(toolsDelta);
          result.fold(
            (failure) {
              print(
                '⚠️ [SUBMIT] Failed to convert tools to HTML: ${failure.message}',
              );
              toolsHtml = jsonEncode(
                _toolsController!.document.toDelta().toJson(),
              );
            },
            (conversionResult) {
              toolsHtml = conversionResult.content;
              print('✅ [SUBMIT] Tools converted to HTML');
            },
          );
        }

        String? personnelHtml;
        if (_personnelController != null &&
            _personnelController!.document.toPlainText().trim().isNotEmpty) {
          final personnelDelta = jsonEncode({
            'ops': _personnelController!.document.toDelta().toJson(),
          });
          final result = await convertQuillToHtml(personnelDelta);
          result.fold(
            (failure) {
              print(
                '⚠️ [SUBMIT] Failed to convert personnel to HTML: ${failure.message}',
              );
              personnelHtml = jsonEncode(
                _personnelController!.document.toDelta().toJson(),
              );
            },
            (conversionResult) {
              personnelHtml = conversionResult.content;
              print('✅ [SUBMIT] Personnel converted to HTML');
            },
          );
        }

        String? materialsHtml;
        if (_materialsController != null &&
            _materialsController!.document.toPlainText().trim().isNotEmpty) {
          final materialsDelta = jsonEncode({
            'ops': _materialsController!.document.toDelta().toJson(),
          });
          final result = await convertQuillToHtml(materialsDelta);
          result.fold(
            (failure) {
              print(
                '⚠️ [SUBMIT] Failed to convert materials to HTML: ${failure.message}',
              );
              materialsHtml = jsonEncode(
                _materialsController!.document.toDelta().toJson(),
              );
            },
            (conversionResult) {
              materialsHtml = conversionResult.content;
              print('✅ [SUBMIT] Materials converted to HTML');
            },
          );
        }

        String? suggestionsHtml;
        if (_suggestionsController != null &&
            _suggestionsController!.document.toPlainText().trim().isNotEmpty) {
          final suggestionsDelta = jsonEncode({
            'ops': _suggestionsController!.document.toDelta().toJson(),
          });
          final result = await convertQuillToHtml(suggestionsDelta);
          result.fold(
            (failure) {
              print(
                '⚠️ [SUBMIT] Failed to convert suggestions to HTML: ${failure.message}',
              );
              suggestionsHtml = jsonEncode(
                _suggestionsController!.document.toDelta().toJson(),
              );
            },
            (conversionResult) {
              suggestionsHtml = conversionResult.content;
              print('✅ [SUBMIT] Suggestions converted to HTML');
            },
          );
        }

        await ref
            .read(workReportsProvider.notifier)
            .updateWorkReport(
              widget.report.id!,
              _selectedProject!.id!,
              int.parse(_employeeIdController.text),
              _nameController.text,
              _reportDateController.text,
              _startTimeController.text.isEmpty
                  ? null
                  : _startTimeController.text,
              _endTimeController.text.isEmpty ? null : _endTimeController.text,
              descriptionHtml,
              toolsHtml,
              personnelHtml,
              materialsHtml,
              suggestionsHtml,
              _supervisorSignature,
              _managerSignature,
            );

        print('✅ [SUBMIT] Update successful');
        ref.invalidate(workReportProvider(widget.report.id!));
        ref.invalidate(workReportsProvider);

        if (mounted) {
          context.go('/work-reports/${widget.report.id}');
        }
      } on DioException catch (e) {
        print('❌ [SUBMIT] DioException: ${e.message}');
        String errorMessage = 'Error updating work report';
        if (e.response?.data != null && e.response!.data['errors'] != null) {
          final errors = e.response!.data['errors'] as Map<String, dynamic>;
          errorMessage += ': ${errors.values.join(', ')}';
        } else {
          errorMessage += ': ${e.message}';
        }
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(errorMessage)));
        }
      } catch (e) {
        print('❌ [SUBMIT] Exception: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error updating work report: $e')),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  /// Converts a Delta JSON string to HTML using the quill converter.
  /// Returns the original string if conversion fails or if it's empty.
  Future<String?> _convertDeltaToHtml(String? deltaJson) async {
    if (deltaJson == null || deltaJson.isEmpty) return null;

    try {
      // Try to parse as Delta JSON
      final decoded = jsonDecode(deltaJson);
      if (decoded is! List) return deltaJson;

      // Format for the converter: { "ops": [...] }
      final formattedDelta = jsonEncode({'ops': decoded});

      final convertQuillToHtml = ref.read(convertQuillToHtmlProvider);
      final result = await convertQuillToHtml(formattedDelta);

      return result.fold(
        (failure) {
          print(
            '⚠️ [CONVERT] Failed to convert Delta to HTML: ${failure.message}',
          );
          return deltaJson; // Return original on failure
        },
        (conversionResult) {
          print('✅ [CONVERT] Delta converted to HTML');
          return conversionResult.content;
        },
      );
    } catch (e) {
      print('⚠️ [CONVERT] Error parsing Delta JSON: $e');
      return deltaJson; // Return original on error
    }
  }
}

class _IndustrialPhotoEntry extends ConsumerStatefulWidget {
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

  const _IndustrialPhotoEntry({
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
    required this.isEditMode,
  });

  @override
  ConsumerState<_IndustrialPhotoEntry> createState() =>
      _IndustrialPhotoEntryState();
}

class _IndustrialPhotoEntryState extends ConsumerState<_IndustrialPhotoEntry> {
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
            // Verify structure returned by converter (usually {ops: [...]})
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

  void _showPreview(
    BuildContext context,
    Uint8List? bytes,
    String? url,
    String title,
  ) {
    String? imageUrl;
    if (bytes != null) {
      imageUrl = 'data:image/jpeg;base64,${base64Encode(bytes)}';
    } else if (url != null) {
      imageUrl = url.startsWith('data:')
          ? url
          : (url.startsWith('http') ? url : 'data:image/jpeg;base64,$url');
    }

    if (imageUrl == null) return;

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: EdgeInsets.zero,
        child: Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            title: Text(
              title,
              style: const TextStyle(color: Colors.white, fontSize: 14),
            ),
            leading: IconButton(
              icon: const Icon(Icons.close, color: Colors.white),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
          body: Center(
            child: InteractiveViewer(
              minScale: 0.5,
              maxScale: 8.0,
              child: ImageViewer(
                url: imageUrl!,
                width: MediaQuery.of(context).size.width,
                fit: BoxFit.contain,
              ),
            ),
          ),
        ),
      ),
    );
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
                    if (widget.isEditMode)
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
                  '',
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
                  'ANTES DEL TRABAJO',
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
        InkWell(
          onTap: hasPhoto
              ? () => _showPreview(context, bytes, url, title)
              : onPick,
          child: Container(
            height: 200,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.black26,
              border: Border.all(color: kIndBorder),
              borderRadius: BorderRadius.circular(kIndRadius),
            ),
            child: bytes != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(kIndRadius - 1),
                    child: Image.memory(bytes, fit: BoxFit.cover),
                  )
                : (url != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(kIndRadius - 1),
                          child: ImageViewer(url: url, height: 200),
                        )
                      : const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.camera_alt,
                                color: Colors.grey,
                                size: 40,
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Tocar para agregar foto',
                                style: TextStyle(color: Colors.grey),
                              ),
                            ],
                          ),
                        )),
          ),
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
