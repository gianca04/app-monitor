import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
import 'package:go_router/go_router.dart';
import 'dart:convert';
import 'package:fleather/fleather.dart';
import '../../../../core/widgets/industrial_signature.dart';
import '../../data/models/work_report.dart';
import '../providers/work_reports_provider.dart';
import '../../../../core/widgets/modern_bottom_modal.dart';
import '../../../employees/presentation/widgets/quick_search_modal.dart';
import '../../../employees/data/models/quick_search_response.dart';
import '../../../projects/presentation/widgets/quick_search_modal.dart'
    as projects_modal;
import '../../../projects/data/models/quick_search_response.dart';
import '../../../settings/providers/connectivity_preferences_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import 'industrial_selector.dart';
import '../../../../core/theme_config.dart';
import '../../../../core/services/quill_converter_providers.dart';
import '../../../../core/services/image_compression_service.dart';
import 'industrial_photo_entry.dart';
import 'package:monitor/features/work_reports/presentation/widgets/work_report_progress_overlay.dart';
import 'personnel_widget.dart';
import '../widgets/tools_and_materials_widget.dart';

// --- CONSTANTES DE DISEÑO INDUSTRIAL ---
const Color kIndBg = AppTheme.background;
const Color kIndSurface = AppTheme.surface;
const Color kIndBorder = AppTheme.border;
const Color kIndAccent = AppTheme.primaryAccent;
const double kIndRadius = 4.0;

class WorkReportForm extends ConsumerStatefulWidget {
  final WorkReport? report;
  final String? saveType;

  const WorkReportForm({super.key, this.report, this.saveType});

  @override
  ConsumerState<WorkReportForm> createState() => _WorkReportFormState();
}

class _WorkReportFormState extends ConsumerState<WorkReportForm> {
  // ... (Toda tu lógica de estado se mantiene INTACTA) ...
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  FleatherController? _descriptionController;
  late TextEditingController _reportDateController;
  late TextEditingController _startTimeController;
  late TextEditingController _endTimeController;
  FleatherController? _toolsController;

  FleatherController? _materialsController;
  FleatherController? _suggestionsController;
  late TextEditingController _employeeIdController;
  late TextEditingController _projectIdController;

  final GlobalKey<EditorState> _editorKey = GlobalKey();
  final GlobalKey<EditorState> _descriptionEditorKey = GlobalKey();

  final GlobalKey<EditorState> _suggestionsEditorKey = GlobalKey();

  EmployeeQuick? _selectedEmployee;
  ProjectQuick? _selectedProject;

  String? _supervisorSignature;
  String? _managerSignature;
  String? _supervisorSignatureBytes;
  String? _managerSignatureBytes;

  List<Map<String, dynamic>> _photos = [];

  bool _isLoading = false;
  WorkReportSubmissionStage _submissionStage = WorkReportSubmissionStage.idle;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.report?.name ?? '');
    _initDescriptionController();
    _reportDateController = TextEditingController(
      text: widget.report?.reportDate ?? '',
    );
    _startTimeController = TextEditingController(
      text: widget.report?.startTime ?? '',
    );
    _endTimeController = TextEditingController(
      text: widget.report?.endTime ?? '',
    );
    _initToolsController();
    _initMaterialsController();
    _initSuggestionsController();
    _employeeIdController = TextEditingController(
      text: widget.report?.employee?.id.toString() ?? '',
    );
    _projectIdController = TextEditingController(
      text: widget.report?.project?.id.toString() ?? '',
    );

    if (widget.report?.employee != null) {
      _selectedEmployee = EmployeeQuick(
        id: widget.report!.employee!.id,
        fullName: widget.report!.employee!.fullName,
        documentNumber: widget.report!.employee!.documentNumber,
        position: widget.report!.employee!.position?.name,
      );
    }

    if (widget.report?.project != null) {
      _selectedProject = ProjectQuick(
        id: widget.report!.project!.id,
        name: widget.report!.project!.name,
      );
    }

    if (widget.report != null) {
      for (var photo in widget.report!.photos ?? []) {
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

    // Load current user employee if creating new report
    if (widget.report == null) {
      Future.microtask(() async {
        final authNotifier = ref.read(authProvider.notifier);
        final sharedPreferences = authNotifier.sharedPreferences;
        final employeeId = sharedPreferences.getInt('employee_id');
        if (employeeId != null) {
          final firstName =
              sharedPreferences.getString('employee_first_name') ?? '';
          final lastName =
              sharedPreferences.getString('employee_last_name') ?? '';
          final documentNumber =
              sharedPreferences.getString('employee_document_number') ?? '';
          final position =
              sharedPreferences.getString('employee_position') ?? '';
          if (mounted) {
            setState(() {
              _selectedEmployee = EmployeeQuick(
                id: employeeId,
                fullName: '$firstName $lastName'.trim(),
                documentNumber: documentNumber,
                position: position,
              );
              _employeeIdController.text = employeeId.toString();
            });
          }
        }
      });
    }
    if (widget.report == null) {
      Future.microtask(() async {
        final authNotifier = ref.read(authProvider.notifier);
        final sharedPreferences = authNotifier.sharedPreferences;
        final employeeId = sharedPreferences.getInt('employee_id');
        print(
          'DEBUG: employeeId from SharedPreferences: $employeeId',
        ); // Agrega esto
        if (employeeId != null) {
          final firstName =
              sharedPreferences.getString('employee_first_name') ?? '';
          final lastName =
              sharedPreferences.getString('employee_last_name') ?? '';
          final documentNumber =
              sharedPreferences.getString('employee_document_number') ?? '';
          final position =
              sharedPreferences.getString('employee_position') ?? '';
          print(
            'DEBUG: Loaded employee data - firstName: $firstName, lastName: $lastName, documentNumber: $documentNumber',
          ); // Agrega esto
          if (mounted) {
            setState(() {
              _selectedEmployee = EmployeeQuick(
                id: employeeId,
                fullName: '$firstName $lastName'.trim(),
                documentNumber: documentNumber,
                position: position,
              );
              _employeeIdController.text = employeeId.toString();
              print(
                'DEBUG: _selectedEmployee set to: ${_selectedEmployee?.fullName}',
              ); // Agrega esto
            });
          }
        } else {
          print(
            'DEBUG: No employeeId found in SharedPreferences',
          ); // Agrega esto
        }
      });
    }
  }

  Future<void> _initDescriptionController() async {
    try {
      final text = widget.report?.description ?? '';
      if (text.isEmpty) {
        _descriptionController = FleatherController();
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
            try {
              final delta = jsonDecode(conversionResult.content);
              if (delta is Map && delta['ops'] != null) {
                _descriptionController = FleatherController(
                  document: ParchmentDocument.fromJson(delta['ops']),
                );
              } else {
                throw const FormatException('Invalid format');
              }
            } catch (e) {
              print('Error parsing converted Quill: $e');
              _descriptionController = FleatherController(
                document: ParchmentDocument.fromDelta(Delta()..insert(text)),
              );
            }
          },
        );
      }
    } catch (err, st) {
      print('Error initializing description controller: $err\n$st');
      _descriptionController = FleatherController();
    }
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _initToolsController() async {
    try {
      final text = widget.report?.resources?.tools ?? '';
      if (text.isEmpty) {
        _toolsController = FleatherController();
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
            try {
              final delta = jsonDecode(conversionResult.content);
              if (delta is Map && delta['ops'] != null) {
                _toolsController = FleatherController(
                  document: ParchmentDocument.fromJson(delta['ops']),
                );
              } else {
                throw const FormatException('Invalid format');
              }
            } catch (e) {
              print('Error parsing converted Quill: $e');
              _toolsController = FleatherController(
                document: ParchmentDocument.fromDelta(Delta()..insert(text)),
              );
            }
          },
        );
      }
    } catch (err, st) {
      print('Error initializing tools controller: $err\n$st');
      _toolsController = FleatherController();
    }
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _initMaterialsController() async {
    try {
      final text = widget.report?.resources?.materials ?? '';
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
      final text = widget.report?.suggestions ?? '';
      if (text.isEmpty) {
        _suggestionsController = FleatherController();
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
                _suggestionsController = FleatherController(
                  document: ParchmentDocument.fromJson(delta['ops']),
                );
              } else if (delta is List) {
                _suggestionsController = FleatherController(
                  document: ParchmentDocument.fromJson(delta),
                );
              } else {
                throw const FormatException('Not a valid format');
              }
            } catch (_) {
              _suggestionsController = FleatherController(
                document: ParchmentDocument.fromDelta(Delta()..insert(text)),
              );
            }
          },
          (conversionResult) {
            // Successfully converted HTML to Quill
            try {
              final delta = jsonDecode(conversionResult.content);
              if (delta is Map && delta['ops'] != null) {
                _suggestionsController = FleatherController(
                  document: ParchmentDocument.fromJson(delta['ops']),
                );
              } else {
                throw const FormatException('Invalid format');
              }
            } catch (e) {
              print('Error parsing converted Quill: $e');
              _suggestionsController = FleatherController(
                document: ParchmentDocument.fromDelta(Delta()..insert(text)),
              );
            }
          },
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

  void _removePhoto(int index) {
    setState(() {
      _photos.removeAt(index);
    });
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

  /// Converts photo descriptions from Delta to HTML format.
  /// Converts photo descriptions from Delta to HTML format concurrently.
  Future<List<Map<String, dynamic>>> _convertPhotoDescriptionsToHtml(
    List<Map<String, dynamic>> photos,
  ) async {
    final futures = photos.map((photo) async {
      final convertedPhoto = Map<String, dynamic>.from(photo);

      // Launch both conversions in parallel
      final descFuture =
          (photo['descripcion'] != null &&
              photo['descripcion'].toString().isNotEmpty)
          ? _convertDeltaToHtml(photo['descripcion'])
          : Future.value(null);

      final beforeDescFuture =
          (photo['before_work_descripcion'] != null &&
              photo['before_work_descripcion'].toString().isNotEmpty)
          ? _convertDeltaToHtml(photo['before_work_descripcion'])
          : Future.value(null);

      final results = await Future.wait([descFuture, beforeDescFuture]);

      if (results[0] != null) convertedPhoto['descripcion'] = results[0];
      if (results[1] != null)
        convertedPhoto['before_work_descripcion'] = results[1];

      return convertedPhoto;
    });

    return Future.wait(futures);
  }

  Future<void> _updatePhoto(
    int index,
    bool isAfterWork, {
    XFile? file,
    Uint8List? bytes,
    required String description,
  }) async {
    // Update description always
    final descKey = isAfterWork ? 'descripcion' : 'before_work_descripcion';
    _photos[index][descKey] = description;

    // Handle Image Update if present
    if (file != null && bytes != null) {
      final compressionService = ref.read(imageCompressionServiceProvider);
      final compressedBytes = await compressionService.compressToWebp(bytes);

      final filename = file.name;
      final nameWithoutExt = filename.contains('.')
          ? filename.substring(0, filename.lastIndexOf('.'))
          : filename;
      final newFilename = '$nameWithoutExt.webp';

      final multipartFile = MultipartFile.fromBytes(
        compressedBytes,
        filename: newFilename,
        contentType: DioMediaType.parse('image/webp'),
      );

      setState(() {
        if (isAfterWork) {
          _photos[index]['photo'] = multipartFile;
          _photos[index]['photo_bytes'] = compressedBytes;
        } else {
          _photos[index]['before_work_photo'] = multipartFile;
          _photos[index]['before_work_photo_bytes'] = compressedBytes;
        }
      });
    } else {
      // Just refresh UI for description change
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    // Inject Theme for Inputs to reduce boilerplate
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
      child: Stack(
        children: [
          Container(
            color: kIndBg,
            child: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16.0),
                children: [
                  // --- SECTION 1: CONTEXT ---
                  _buildSectionHeader(
                    Theme.of(context),
                    title: 'CONTEXTO OPERATIVO',
                    icon: Icons.location_on,
                  ),
                  const SizedBox(height: 12),

                  // Project Selector
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

                  // Employee Selector
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
                      final result =
                          await ModernBottomModal.show<EmployeeQuick>(
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

                  // --- SECTION 2: REPORT DETAILS ---
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
                      prefixIcon: Icon(
                        Icons.title,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    validator: (value) =>
                        value?.isEmpty ?? true ? 'Requerido' : null,
                  ),
                  const SizedBox(height: 12),

                  // Date & Time Row
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
                              Icon(
                                Icons.description,
                                color: Colors.grey,
                                size: 18,
                              ),
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

                  // --- SECTION 3: RESOURCES ---
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

                  const SizedBox(height: 12),
                  const ToolsAndMaterialsWidget(), const SizedBox(height: 12),
                  const PersonnelWidget(),
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
                              Icon(
                                Icons.lightbulb,
                                color: Colors.grey,
                                size: 18,
                              ),
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

                  // --- SECTION 4: EVIDENCE ---
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
                        icon: const Icon(
                          Icons.add,
                          size: 16,
                          color: kIndAccent,
                        ),
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
                    return IndustrialPhotoEntry(
                      key: ObjectKey(entry.value),
                      index: entry.key,
                      data: entry.value,
                      report: widget.report,
                      onUpdateAfter: (file, bytes, desc) => _updatePhoto(
                        entry.key,
                        true,
                        file: file,
                        bytes: bytes,
                        description: desc,
                      ),
                      onUpdateBefore: (file, bytes, desc) => _updatePhoto(
                        entry.key,
                        false,
                        file: file,
                        bytes: bytes,
                        description: desc,
                      ),
                      onRemove: () => _removePhoto(entry.key),
                      // onSave no es necesario en creación (WorkReportForm), pero lo dejamos null o implementamos si queremos guardar individualmente (no soportado aquí)
                      onSave: null,
                    );
                  }),

                  const SizedBox(height: 24),
                  const Divider(color: Colors.white10),
                  const SizedBox(height: 24),

                  // ... dentro de tu build ...
                  _buildSectionHeader(
                    Theme.of(context),
                    title: 'VALIDACIÓN Y FIRMAS',
                    icon: Icons.edit,
                  ), // Asumo que este widget ya lo tienes estilizado
                  const SizedBox(height: 12),

                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: IndustrialSignatureBox(
                          title: 'SUPERVISOR',
                          base64:
                              _supervisorSignatureBytes, // Variable de estado String?
                          onTap: () => _pickImage(true), // true = es supervisor
                        ),
                      ),

                      const SizedBox(width: 12), // Separación industrial
                      // Slot Gerencia
                      Expanded(
                        child: IndustrialSignatureBox(
                          title: 'GERENCIA / CLIENTE',
                          base64:
                              _managerSignatureBytes, // Variable de estado String?
                          onTap: () =>
                              _pickImage(false), // false = es gerente/cliente
                        ),
                      ),
                    ],
                  ), // --- SECTION 5: VALIDATION ---

                  const SizedBox(height: 32),

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
                          : Text(
                              widget.report == null
                                  ? (widget.saveType == 'local'
                                        ? 'GUARDAR LOCALMENTE'
                                        : 'GENERAR REPORTE')
                                  : 'ACTUALIZAR REPORTE',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.0,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
          WorkReportProgressOverlay(
            stage: _submissionStage,
            isVisible: _isLoading,
          ),
        ],
      ),
    );
  }

  // --- Helper: Títulos de Sección ---
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

      // Check connectivity
      final connectivityAsync = ref.watch(connectivityStatusProvider);
      final actualOnline = connectivityAsync.maybeWhen(
        data: (online) => online,
        orElse: () => false,
      );

      if (widget.saveType == 'cloud' && !actualOnline) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No hay conexión para guardar en la nube'),
          ),
        );
        return;
      }

      // Validate photos
      List<Map<String, dynamic>> validPhotos = _photos
          .where(
            (photo) =>
                photo['id'] != null ||
                photo['photo'] != null ||
                photo['before_work_photo'] != null,
          )
          .toList();

      setState(() {
        _isLoading = true;
        _submissionStage = WorkReportSubmissionStage.converting;
      });

      try {
        // Convert Delta to HTML for tools, personnel, materials, suggestions
        final convertQuillToHtml = ref.read(convertQuillToHtmlProvider);

        // Helper function for parallel conversion
        Future<String?> convertField(
          FleatherController? controller,
          String name,
        ) async {
          if (controller != null &&
              controller.document.toPlainText().trim().isNotEmpty) {
            final delta = jsonEncode({
              'ops': controller.document.toDelta().toJson(),
            });
            final result = await convertQuillToHtml(delta);
            return result.fold(
              (failure) {
                print(
                  '⚠️ [SUBMIT] Failed to convert $name to HTML: ${failure.message}',
                );
                return jsonEncode(controller.document.toDelta().toJson());
              },
              (conversionResult) {
                print('✅ [SUBMIT] $name converted to HTML');
                return conversionResult.content;
              },
            );
          }
          return null;
        }

        // Execute all conversions in parallel
        final results = await Future.wait([
          // 0: Photos
          _convertPhotoDescriptionsToHtml(validPhotos),
          // 1: Description
          convertField(_descriptionController, 'Description'),
          // 2: Tools
          convertField(_toolsController, 'Tools'),
          // 3: Materials
          convertField(_materialsController, 'Materials'),
          // 4: Suggestions
          convertField(_suggestionsController, 'Suggestions'),
        ]);

        final photosWithHtmlDescriptions =
            results[0] as List<Map<String, dynamic>>;
        final descriptionHtml = results[1] as String?;
        final toolsHtml = results[2] as String?;
        final materialsHtml = results[3] as String?;
        final suggestionsHtml = results[4] as String?;

        if (mounted) {
          setState(() {
            _submissionStage = WorkReportSubmissionStage.uploading;
          });
        }

        if (widget.report == null) {
          try {
            print('📝 [FORM] Starting create work report with signatures:');
            print(
              '📝 [FORM] _supervisorSignature: ${_supervisorSignature != null ? 'present (${_supervisorSignature!.length} chars)' : 'null'}',
            );
            print(
              '📝 [FORM] _managerSignature: ${_managerSignature != null ? 'present (${_managerSignature!.length} chars)' : 'null'}',
            );

            final newReport = await ref
                .read(workReportsProvider.notifier)
                .createWorkReport(
                  _selectedProject!.id!,
                  int.parse(_employeeIdController.text),
                  _nameController.text,
                  _reportDateController.text,
                  _startTimeController.text.isEmpty
                      ? null
                      : _startTimeController.text,
                  _endTimeController.text.isEmpty
                      ? null
                      : _endTimeController.text,
                  descriptionHtml,
                  toolsHtml,
                  null, // personnel
                  materialsHtml,
                  suggestionsHtml,
                  photosWithHtmlDescriptions,
                  _supervisorSignature,
                  _managerSignature,
                );

            if (mounted) {
              setState(() {
                _submissionStage = WorkReportSubmissionStage.finalizing;
              });
            }

            // Invalidate the individual report provider to force reload
            ref.invalidate(workReportProvider(newReport.id!));

            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Reporte creado exitosamente')),
              );
              // Navigate to the detail screen of the newly created report
              context.go('/work-reports/${newReport.id}');
            }
          } on DioException catch (e) {
            String errorMessage = 'Error creating work report';
            if (e.response?.data != null &&
                e.response!.data['errors'] != null) {
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
            if (mounted) {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text('Error inesperado: $e')));
            }
          }
        } else {
          // Update logic - Only calling update logic if report is not null
          await ref
              .read(workReportsProvider.notifier)
              .updateWorkReport(
                widget.report!.id!,
                _selectedProject!.id!,
                _selectedEmployee!.id!,
                _nameController.text,
                _reportDateController.text,
                _startTimeController.text.isEmpty
                    ? null
                    : _startTimeController.text,
                _endTimeController.text.isEmpty
                    ? null
                    : _endTimeController.text,
                descriptionHtml,
                toolsHtml,
                null, // personnel
                materialsHtml,
                suggestionsHtml,
                _supervisorSignature,
                _managerSignature,
              );

          // Navigate back to the detail screen
          if (mounted) {
            context.go('/work-reports/${widget.report!.id}');
          }
        }
      } catch (e) {
        // Handle global errors in the process (e.g. initial HTML conversion failed brutally)
        if (mounted && widget.report != null) {
          // If it's an update, simple error message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error updating work report: $e')),
          );
        } else if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error preparing work report: $e')),
          );
        }
      } finally {
        if (mounted &&
            _isLoading &&
            _submissionStage != WorkReportSubmissionStage.success &&
            _submissionStage != WorkReportSubmissionStage.finalizing) {
          // Only stop loading if we represent a failure or cancellation,
          // not success (which navigates away) or finalizing.
          // Actually, finalize happens before navigation.
          // We can reset if we are not navigating effectively.
          // But navigation happens in try block.
          if (mounted) {
            // If we are here, it means we finished or errored.
            // If we errored, we should hide overlay.
            // If success, we navigated away?
            // Safest is to hide if still mounted and not navigated?
            // But navigation is async.
            // Let's just check if we are still mounted.
            setState(() {
              _isLoading = false;
              _submissionStage = WorkReportSubmissionStage.idle;
            });
          }
        }
      }
    }
  }
}
