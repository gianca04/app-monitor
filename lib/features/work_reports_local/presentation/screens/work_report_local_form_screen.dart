import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:fleather/fleather.dart';
import '../../../../core/theme_config.dart';
import '../../../../core/widgets/modern_bottom_modal.dart';
import '../../../../core/widgets/industrial_quill_editor.dart';
import '../../../../core/widgets/industrial_signature.dart';
import '../../../work_reports/presentation/widgets/industrial_selector.dart';
import '../../domain/entities/work_report_local_entity.dart';
import '../providers/work_reports_local_provider.dart';
import '../../../projectslocal/presentation/providers/project_providers.dart';
import '../../../projectslocal/data/models/project_hive_model.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../work_report_photos_local/domain/entities/work_report_photo_local_entity.dart';
import '../../../work_report_photos_local/presentation/providers/work_report_photos_local_provider.dart';
import '../../../employees/data/models/quick_search_response.dart';
import '../../../employees/presentation/widgets/quick_search_modal.dart';

// --- CONSTANTES DE DISEÑO INDUSTRIAL ---
const Color kIndBg = AppTheme.background;
const Color kIndSurface = AppTheme.surface;
const Color kIndBorder = AppTheme.border;
const Color kIndAccent = AppTheme.primaryAccent;
const double kIndRadius = 4.0;

class WorkReportLocalFormScreen extends ConsumerStatefulWidget {
  final int? reportId;

  const WorkReportLocalFormScreen({super.key, this.reportId});

  @override
  ConsumerState<WorkReportLocalFormScreen> createState() =>
      _WorkReportLocalFormScreenState();
}

class _WorkReportLocalFormScreenState
    extends ConsumerState<WorkReportLocalFormScreen> {
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
  late TextEditingController _projectController;

  final GlobalKey<EditorState> _editorKey = GlobalKey();
  final GlobalKey<EditorState> _descriptionEditorKey = GlobalKey();
  final GlobalKey<EditorState> _personnelEditorKey = GlobalKey();
  final GlobalKey<EditorState> _materialsEditorKey = GlobalKey();
  final GlobalKey<EditorState> _suggestionsEditorKey = GlobalKey();

  EmployeeQuick? _selectedEmployee;
  ProjectHiveModel? _selectedProject;

  String? _supervisorSignature;
  String? _managerSignature;

  List<Map<String, dynamic>> _photos = [];

  bool _isLoading = false;
  WorkReportLocalEntity? _existingReport;
  int? _savedReportId;

  /// Navega hacia atrás de forma segura
  void _goBack() {
    context.go('/work-reports-local');
  }

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _reportDateController = TextEditingController();
    _startTimeController = TextEditingController();
    _endTimeController = TextEditingController();
    _projectController = TextEditingController();

    // Inicializar controladores Fleather vacíos
    _descriptionController = FleatherController();
    _toolsController = FleatherController();
    _personnelController = FleatherController();
    _materialsController = FleatherController();
    _suggestionsController = FleatherController();

    // Load current user employee
    _loadCurrentUser();

    // Load existing report if editing
    if (widget.reportId != null) {
      _loadExistingReport();
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
    _projectController.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentUser() async {
    final authNotifier = ref.read(authProvider.notifier);
    final sharedPreferences = authNotifier.sharedPreferences;
    final employeeId = sharedPreferences.getInt('employee_id');
    if (employeeId != null) {
      final firstName =
          sharedPreferences.getString('employee_first_name') ?? '';
      final lastName = sharedPreferences.getString('employee_last_name') ?? '';
      final documentNumber =
          sharedPreferences.getString('employee_document_number') ?? '';
      final position = sharedPreferences.getString('employee_position') ?? '';
      if (mounted) {
        setState(() {
          _selectedEmployee = EmployeeQuick(
            id: employeeId,
            fullName: '$firstName $lastName'.trim(),
            documentNumber: documentNumber,
            position: position,
          );
        });
      }
    }
  }

  Future<void> _loadExistingReport() async {
    final getUseCase = ref.read(getWorkReportLocalUseCaseProvider);
    final result = await getUseCase(widget.reportId!);

    result.fold(
      (failure) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${failure.message}'),
              backgroundColor: Colors.redAccent,
            ),
          );
          _goBack();
        }
      },
      (report) async {
        // Cargar proyecto local
        final projectBox = await ref.read(projectBoxProvider.future);
        final project = projectBox.values.cast<ProjectHiveModel?>().firstWhere(
          (p) => p?.id == report.projectId,
          orElse: () => null,
        );

        if (mounted) {
          setState(() {
            _existingReport = report;
            _savedReportId = report.id;
            _nameController.text = report.name;
            _descriptionController = IndustrialQuillEditor.createFromJson(
              report.description ?? '',
            );
            _startTimeController.text = report.startTime ?? '';
            _endTimeController.text = report.endTime ?? '';
            _toolsController = IndustrialQuillEditor.createFromJson(
              report.tools ?? '',
            );
            _personnelController = IndustrialQuillEditor.createFromJson(
              report.personnel ?? '',
            );
            _materialsController = IndustrialQuillEditor.createFromJson(
              report.materials ?? '',
            );
            _suggestionsController = IndustrialQuillEditor.createFromJson(
              report.suggestions ?? '',
            );
            _selectedProject = project;
            if (project != null) {
              _projectController.text = project.name;
            }
            _selectedEmployee = EmployeeQuick(
              id: report.employeeId,
              fullName: 'Empleado #${report.employeeId}',
            );
            _supervisorSignature = report.supervisorSignature;
            _managerSignature = report.managerSignature;
          });

          await _loadPhotos(report.id!);
        }
      },
    );
  }

  Future<void> _loadPhotos(int reportId) async {
    final getPhotosUseCase = ref.read(
      getPhotosByWorkReportLocalUseCaseProvider,
    );
    final result = await getPhotosUseCase(reportId);

    result.fold(
      (failure) {
        // Silently fail if no photos exist
      },
      (photos) {
        if (mounted) {
          setState(() {
            _photos.clear();
            for (var photo in photos) {
              _photos.add({
                'id': photo.id,
                'descripcion': photo.descripcion ?? '',
                'before_work_descripcion': photo.beforeWorkDescripcion ?? '',
                'photo_path': photo.photoPath,
                'before_work_photo_path': photo.beforeWorkPhotoPath,
                'photo_bytes': null,
                'before_work_photo_bytes': null,
              });
            }
          });
        }
      },
    );
  }

  Future<void> _pickImage(bool isSupervisor) async {
    final String? signatureBase64 = await IndustrialSignatureSheet.show(
      context,
      title: isSupervisor ? 'FIRMA DEL SUPERVISOR' : 'FIRMA GERENCIA / CLIENTE',
    );

    if (signatureBase64 != null) {
      setState(() {
        if (isSupervisor) {
          _supervisorSignature = signatureBase64;
        } else {
          _managerSignature = signatureBase64;
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
        'photo_path': null,
        'before_work_photo_path': null,
      });
    });
  }

  void _removePhoto(int index) {
    setState(() {
      final photo = _photos[index];
      if (photo['id'] != null && _savedReportId != null) {
        ref.read(deleteWorkReportPhotoLocalUseCaseProvider)(photo['id']);
      }
      _photos.removeAt(index);
    });
  }

  Future<void> _pickPhotoImage(int index, bool isAfterWork) async {
    final picker = ImagePicker();

    final source = await showDialog<ImageSource>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: kIndSurface,
        title: const Text(
          'Seleccionar fuente',
          style: TextStyle(color: AppTheme.textPrimary),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt, color: kIndAccent),
              title: const Text(
                'Cámara',
                style: TextStyle(color: AppTheme.textPrimary),
              ),
              onTap: () => Navigator.of(context).pop(ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: kIndAccent),
              title: const Text(
                'Galería',
                style: TextStyle(color: AppTheme.textPrimary),
              ),
              onTap: () => Navigator.of(context).pop(ImageSource.gallery),
            ),
          ],
        ),
      ),
    );

    if (source == null) return;

    try {
      final pickedFile = await picker.pickImage(source: source);
      if (pickedFile != null) {
        final bytes = await pickedFile.readAsBytes();
        final localPath = await _saveImageToLocal(bytes);

        setState(() {
          if (isAfterWork) {
            _photos[index]['photo_bytes'] = bytes;
            _photos[index]['photo_path'] = localPath;
          } else {
            _photos[index]['before_work_photo_bytes'] = bytes;
            _photos[index]['before_work_photo_path'] = localPath;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al seleccionar imagen: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  Future<String> _saveImageToLocal(Uint8List imageBytes) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final imagesDir = Directory('${directory.path}/work_report_photos');

      if (!await imagesDir.exists()) {
        await imagesDir.create(recursive: true);
      }

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'photo_$timestamp.jpg';
      final filePath = '${imagesDir.path}/$fileName';

      final file = File(filePath);
      await file.writeAsBytes(imageBytes);

      return filePath;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedProject == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Debe seleccionar un proyecto')),
      );
      return;
    }

    if (_selectedEmployee == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Debe seleccionar un empleado')),
      );
      return;
    }

    setState(() => _isLoading = true);

    // Extraer contenido de los editores Fleather como JSON
    final descriptionJson =
        _descriptionController != null &&
            !IndustrialQuillEditor.isEmpty(_descriptionController!)
        ? IndustrialQuillEditor.getContentAsJson(_descriptionController!)
        : null;
    final toolsJson =
        _toolsController != null &&
            !IndustrialQuillEditor.isEmpty(_toolsController!)
        ? IndustrialQuillEditor.getContentAsJson(_toolsController!)
        : null;
    final personnelJson =
        _personnelController != null &&
            !IndustrialQuillEditor.isEmpty(_personnelController!)
        ? IndustrialQuillEditor.getContentAsJson(_personnelController!)
        : null;
    final materialsJson =
        _materialsController != null &&
            !IndustrialQuillEditor.isEmpty(_materialsController!)
        ? IndustrialQuillEditor.getContentAsJson(_materialsController!)
        : null;
    final suggestionsJson =
        _suggestionsController != null &&
            !IndustrialQuillEditor.isEmpty(_suggestionsController!)
        ? IndustrialQuillEditor.getContentAsJson(_suggestionsController!)
        : null;

    final now = DateTime.now().toIso8601String();
    final entity = WorkReportLocalEntity(
      id: _existingReport?.id,
      employeeId: _selectedEmployee!.id!,
      projectId: _selectedProject!.id,
      name: _nameController.text,
      description: descriptionJson,
      supervisorSignature: _supervisorSignature,
      managerSignature: _managerSignature,
      suggestions: suggestionsJson,
      createdAt: _existingReport?.createdAt ?? now,
      updatedAt: now,
      tools: toolsJson,
      personnel: personnelJson,
      materials: materialsJson,
      startTime: _startTimeController.text.isEmpty
          ? null
          : _startTimeController.text,
      endTime: _endTimeController.text.isEmpty ? null : _endTimeController.text,
    );

    final result = widget.reportId == null
        ? await ref.read(createWorkReportLocalUseCaseProvider)(entity)
        : await ref.read(updateWorkReportLocalUseCaseProvider)(entity);

    result.fold(
      (failure) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${failure.message}'),
            backgroundColor: Colors.redAccent,
          ),
        );
      },
      (savedReportId) async {
        _savedReportId = savedReportId;
        await _savePhotos(savedReportId);

        setState(() => _isLoading = false);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                widget.reportId == null
                    ? 'Reporte guardado localmente'
                    : 'Reporte actualizado exitosamente',
              ),
              backgroundColor: kIndAccent,
            ),
          );
          ref.read(workReportsLocalListProvider.notifier).refresh();
          context.go('/work-reports-local');
        }
      },
    );
  }

  Future<void> _savePhotos(int reportId) async {
    for (var photo in _photos) {
      try {
        final photoEntity = WorkReportPhotoLocalEntity(
          id: photo['id'],
          workReportId: reportId,
          photoPath: photo['photo_path'],
          beforeWorkPhotoPath: photo['before_work_photo_path'],
          descripcion: photo['descripcion']?.isEmpty ?? true
              ? null
              : photo['descripcion'],
          beforeWorkDescripcion:
              photo['before_work_descripcion']?.isEmpty ?? true
              ? null
              : photo['before_work_descripcion'],
          createdAt: photo['id'] == null
              ? DateTime.now().toIso8601String()
              : null,
          updatedAt: DateTime.now().toIso8601String(),
        );

        if (photo['id'] == null) {
          await ref.read(createWorkReportPhotoLocalUseCaseProvider)(
            photoEntity,
          );
        } else {
          await ref.read(updateWorkReportPhotoLocalUseCaseProvider)(
            photoEntity,
          );
        }
      } catch (e) {
        debugPrint('Error saving photo: $e');
      }
    }
  }

  Future<void> _delete() async {
    if (widget.reportId == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: kIndSurface,
        title: const Text(
          'Confirmar eliminación',
          style: TextStyle(color: AppTheme.textPrimary),
        ),
        content: const Text(
          '¿Está seguro de eliminar este reporte local?',
          style: TextStyle(color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(
              'Eliminar',
              style: TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isLoading = true);

    final result = await ref.read(deleteWorkReportLocalUseCaseProvider)(
      widget.reportId!,
    );

    setState(() => _isLoading = false);

    result.fold(
      (failure) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${failure.message}'),
            backgroundColor: Colors.redAccent,
          ),
        );
      },
      (_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Reporte eliminado exitosamente'),
            backgroundColor: Colors.redAccent,
          ),
        );
        ref.read(workReportsLocalListProvider.notifier).refresh();
        context.go('/work-reports-local');
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final projectsBoxAsync = ref.watch(projectBoxProvider);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          context.go('/work-reports-local');
        }
      },
      child: Scaffold(
        backgroundColor: kIndBg,
        appBar: AppBar(
          backgroundColor: kIndSurface,
          leading: IconButton(
            icon: const Icon(Icons.close, color: AppTheme.textPrimary),
            onPressed: _goBack,
          ),
          title: Text(
            widget.reportId == null
                ? 'NUEVO REPORTE LOCAL'
                : 'EDITAR REPORTE LOCAL',
            style: const TextStyle(
              color: kIndAccent,
              fontSize: 14,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
            ),
          ),
          centerTitle: true,
          elevation: 0,
          actions: [
            // Indicador de modo offline
            Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.2),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.orange.withOpacity(0.5)),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.offline_bolt, color: Colors.orange, size: 14),
                  SizedBox(width: 4),
                  Text(
                    'LOCAL',
                    style: TextStyle(
                      color: Colors.orange,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            if (widget.reportId != null)
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                onPressed: _isLoading ? null : _delete,
              ),
          ],
        ),
        body: projectsBoxAsync.when(
          data: (projectsBox) {
            final projects = projectsBox.values.toList();

            return Theme(
              data: Theme.of(context).copyWith(
                brightness: Brightness.dark,
                inputDecorationTheme: InputDecorationTheme(
                  filled: true,
                  fillColor: kIndSurface,
                  labelStyle: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 13,
                  ),
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
                    borderSide: const BorderSide(color: Colors.redAccent),
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
                      // --- SECTION 1: CONTEXT ---
                      _buildSectionHeader(
                        Theme.of(context),
                        title: 'CONTEXTO OPERATIVO',
                        icon: Icons.location_on,
                      ),
                      const SizedBox(height: 12),

                      // Project Selector (Local)
                      IndustrialSelector(
                        label: 'PROYECTO ASIGNADO',
                        value: _selectedProject != null
                            ? '${_selectedProject!.name} (ID: ${_selectedProject!.id})'
                            : null,
                        icon: Icons.business,
                        onTap: () async {
                          if (projects.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'No hay proyectos descargados. Sincronice primero.',
                                ),
                                backgroundColor: Colors.orange,
                              ),
                            );
                            return;
                          }

                          final result =
                              await ModernBottomModal.show<ProjectHiveModel>(
                                context,
                                title: 'Seleccionar Proyecto Local',
                                content: _LocalProjectSelector(
                                  projects: projects,
                                ),
                              );
                          if (result != null) {
                            setState(() {
                              _selectedProject = result;
                              _projectController.text = result.name;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 12),

                      // Employee Selector
                      IndustrialSelector(
                        label: 'RESPONSABLE TÉCNICO',
                        value: _selectedEmployee != null
                            ? _selectedEmployee!.fullName
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

                      Column(
                        // <--- 1. CONTENEDOR PRINCIPAL: Vertical
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // --- 1. CAMPO FECHA (Full Width) ---
                          TextFormField(
                            controller: _reportDateController,
                            readOnly: true,
                            decoration: const InputDecoration(
                              labelText: 'FECHA',
                            ),
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

                          const SizedBox(
                            height: 16,
                          ), // Espacio entre Fecha y Horas
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

                      // Description Editor
                      Container(
                        decoration: BoxDecoration(
                          color: kIndSurface,
                          border: Border.all(color: kIndBorder),
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(kIndRadius),
                            topRight: Radius.circular(kIndRadius),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Padding(
                              padding: EdgeInsets.only(left: 16, top: 8),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.description,
                                    color: Colors.grey,
                                    size: 18,
                                  ),
                                  SizedBox(width: 8),
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
                                child: Center(
                                  child: CircularProgressIndicator(),
                                ),
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
                                  borderRadius: const BorderRadius.only(
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

                      // Tools Editor
                      Container(
                        decoration: BoxDecoration(
                          color: kIndSurface,
                          border: Border.all(color: kIndBorder),
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(kIndRadius),
                            topRight: Radius.circular(kIndRadius),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Padding(
                              padding: EdgeInsets.only(left: 16, top: 8),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.build,
                                    color: Colors.grey,
                                    size: 18,
                                  ),
                                  SizedBox(width: 8),
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
                                child: Center(
                                  child: CircularProgressIndicator(),
                                ),
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
                                  borderRadius: const BorderRadius.only(
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

                      // Personnel Editor
                      Container(
                        decoration: BoxDecoration(
                          color: kIndSurface,
                          border: Border.all(color: kIndBorder),
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(kIndRadius),
                            topRight: Radius.circular(kIndRadius),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Padding(
                              padding: EdgeInsets.only(left: 16, top: 8),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.group,
                                    color: Colors.grey,
                                    size: 18,
                                  ),
                                  SizedBox(width: 8),
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
                                child: Center(
                                  child: CircularProgressIndicator(),
                                ),
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
                                  borderRadius: const BorderRadius.only(
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

                      // Materials Editor
                      Container(
                        decoration: BoxDecoration(
                          color: kIndSurface,
                          border: Border.all(color: kIndBorder),
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(kIndRadius),
                            topRight: Radius.circular(kIndRadius),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Padding(
                              padding: EdgeInsets.only(left: 16, top: 8),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.inventory_2,
                                    color: Colors.grey,
                                    size: 18,
                                  ),
                                  SizedBox(width: 8),
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
                                child: Center(
                                  child: CircularProgressIndicator(),
                                ),
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
                                  borderRadius: const BorderRadius.only(
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

                      // Suggestions Editor
                      Container(
                        decoration: BoxDecoration(
                          color: kIndSurface,
                          border: Border.all(color: kIndBorder),
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(kIndRadius),
                            topRight: Radius.circular(kIndRadius),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Padding(
                              padding: EdgeInsets.only(left: 16, top: 8),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.lightbulb,
                                    color: Colors.grey,
                                    size: 18,
                                  ),
                                  SizedBox(width: 8),
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
                                child: Center(
                                  child: CircularProgressIndicator(),
                                ),
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
                                  borderRadius: const BorderRadius.only(
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
                        return _IndustrialPhotoEntry(
                          key: ObjectKey(entry.value),
                          index: entry.key,
                          data: entry.value,
                          onPickAfter: () => _pickPhotoImage(entry.key, true),
                          onPickBefore: () => _pickPhotoImage(entry.key, false),
                          onRemove: () => _removePhoto(entry.key),
                          onAfterDescChanged: (v) =>
                              entry.value['descripcion'] = v,
                          onBeforeDescChanged: (v) =>
                              entry.value['before_work_descripcion'] = v,
                        );
                      }),

                      const SizedBox(height: 24),
                      const Divider(color: Colors.white10),
                      const SizedBox(height: 24),

                      // --- SECTION 5: SIGNATURES ---
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
                              base64: _supervisorSignature,
                              onTap: () => _pickImage(true),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: IndustrialSignatureBox(
                              title: 'GERENCIA / CLIENTE',
                              base64: _managerSignature,
                              onTap: () => _pickImage(false),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 32),

                      // Submit Button
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
                              ? const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              Colors.black,
                                            ),
                                      ),
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      'GUARDANDO...',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 1.0,
                                      ),
                                    ),
                                  ],
                                )
                              : Text(
                                  widget.reportId == null
                                      ? 'GUARDAR LOCALMENTE'
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
            );
          },
          loading: () => const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(kIndAccent),
            ),
          ),
          error: (error, stack) => const Center(
            child: Text(
              'Error al cargar proyectos',
              style: TextStyle(color: AppTheme.textSecondary),
            ),
          ),
        ),
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
}

// ============================================
// SELECTOR DE PROYECTOS LOCALES
// ============================================

class _LocalProjectSelector extends StatefulWidget {
  final List<ProjectHiveModel> projects;

  const _LocalProjectSelector({required this.projects});

  @override
  State<_LocalProjectSelector> createState() => _LocalProjectSelectorState();
}

class _LocalProjectSelectorState extends State<_LocalProjectSelector> {
  final _searchController = TextEditingController();
  List<ProjectHiveModel> _filteredProjects = [];

  @override
  void initState() {
    super.initState();
    _filteredProjects = widget.projects;
  }

  void _filterProjects(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredProjects = widget.projects;
      } else {
        _filteredProjects = widget.projects
            .where((p) => p.name.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Buscar proyecto...',
              prefixIcon: const Icon(
                Icons.search,
                color: AppTheme.textSecondary,
              ),
              filled: true,
              fillColor: kIndSurface,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(kIndRadius),
                borderSide: const BorderSide(color: kIndBorder),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(kIndRadius),
                borderSide: const BorderSide(color: kIndAccent, width: 1.5),
              ),
            ),
            style: const TextStyle(color: AppTheme.textPrimary),
            onChanged: _filterProjects,
          ),
        ),
        SizedBox(
          height: 300,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: _filteredProjects.length,
            itemBuilder: (context, index) {
              final project = _filteredProjects[index];
              return ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: kIndAccent.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Icon(
                    Icons.folder_outlined,
                    color: kIndAccent,
                    size: 20,
                  ),
                ),
                title: Text(
                  project.name,
                  style: const TextStyle(color: AppTheme.textPrimary),
                ),
                subtitle: Text(
                  'ID: ${project.id}',
                  style: const TextStyle(color: AppTheme.textSecondary),
                ),
                onTap: () => Navigator.of(context).pop(project),
              );
            },
          ),
        ),
      ],
    );
  }
}

// ============================================
// WIDGET DE ENTRADA DE FOTO (CLONE DE _IndustrialPhotoEntry)
// ============================================

class _IndustrialPhotoEntry extends StatefulWidget {
  final int index;
  final Map<String, dynamic> data;
  final VoidCallback onPickAfter;
  final VoidCallback onPickBefore;
  final VoidCallback onRemove;
  final ValueChanged<String> onAfterDescChanged;
  final ValueChanged<String> onBeforeDescChanged;

  const _IndustrialPhotoEntry({
    super.key,
    required this.index,
    required this.data,
    required this.onPickAfter,
    required this.onPickBefore,
    required this.onRemove,
    required this.onAfterDescChanged,
    required this.onBeforeDescChanged,
  });

  @override
  State<_IndustrialPhotoEntry> createState() => _IndustrialPhotoEntryState();
}

class _IndustrialPhotoEntryState extends State<_IndustrialPhotoEntry> {
  FleatherController? _afterDescController;
  FleatherController? _beforeDescController;
  final GlobalKey<EditorState> _afterEditorKey = GlobalKey();
  final GlobalKey<EditorState> _beforeEditorKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _afterDescController = IndustrialQuillEditor.createFromJson(
      widget.data['descripcion'] ?? '',
    );
    _beforeDescController = IndustrialQuillEditor.createFromJson(
      widget.data['before_work_descripcion'] ?? '',
    );
  }

  @override
  void dispose() {
    _afterDescController?.dispose();
    _beforeDescController?.dispose();
    super.dispose();
  }

  void _syncAfterDesc() {
    if (_afterDescController != null) {
      final json = IndustrialQuillEditor.getContentAsJson(
        _afterDescController!,
      );
      widget.onAfterDescChanged(json);
    }
  }

  void _syncBeforeDesc() {
    if (_beforeDescController != null) {
      final json = IndustrialQuillEditor.getContentAsJson(
        _beforeDescController!,
      );
      widget.onBeforeDescChanged(json);
    }
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
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: kIndBorder)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'FOTO #${widget.index + 1}',
                  style: const TextStyle(
                    color: kIndAccent,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.delete_outline,
                    color: Colors.redAccent,
                    size: 20,
                  ),
                  onPressed: widget.onRemove,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                // AFTER WORK
                _buildPhotoBlock(
                  title: 'DESPUÉS DEL TRABAJO',
                  bytes: widget.data['photo_bytes'],
                  localPath: widget.data['photo_path'],
                  onPick: widget.onPickAfter,
                  controller: _afterDescController,
                  editorKey: _afterEditorKey,
                  onFocusLost: _syncAfterDesc,
                ),

                const Divider(color: Colors.white10, height: 24),

                // BEFORE WORK
                _buildPhotoBlock(
                  title: 'ANTES DEL TRABAJO',
                  bytes: widget.data['before_work_photo_bytes'],
                  localPath: widget.data['before_work_photo_path'],
                  onPick: widget.onPickBefore,
                  controller: _beforeDescController,
                  editorKey: _beforeEditorKey,
                  onFocusLost: _syncBeforeDesc,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoBlock({
    required String title,
    Uint8List? bytes,
    String? localPath,
    required VoidCallback onPick,
    FleatherController? controller,
    required GlobalKey<EditorState> editorKey,
    required VoidCallback onFocusLost,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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

        // Photo area
        GestureDetector(
          onTap: onPick,
          child: Container(
            height: 180,
            width: double.infinity,
            decoration: BoxDecoration(
              color: kIndBg,
              border: Border.all(color: kIndBorder),
              borderRadius: BorderRadius.circular(kIndRadius),
            ),
            child: _buildPhotoPreview(bytes, localPath),
          ),
        ),
        const SizedBox(height: 8),

        // Description Editor
        Container(
          decoration: BoxDecoration(
            color: kIndBg,
            border: Border.all(color: kIndBorder),
            borderRadius: BorderRadius.circular(kIndRadius),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(left: 12, top: 8),
                child: Text(
                  'DESCRIPCIÓN',
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 11),
                ),
              ),
              if (controller != null) ...[
                FleatherToolbar.basic(
                  controller: controller,
                  editorKey: editorKey,
                ),
                Container(
                  height: 120,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Focus(
                    onFocusChange: (hasFocus) {
                      if (!hasFocus) onFocusLost();
                    },
                    child: FleatherEditor(
                      controller: controller,
                      padding: const EdgeInsets.all(8),
                      focusNode: FocusNode(),
                      editorKey: editorKey,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPhotoPreview(Uint8List? bytes, String? localPath) {
    if (bytes != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(kIndRadius),
        child: GestureDetector(
          onTap: () => _showLocalImageViewer(bytes: bytes),
          child: Image.memory(bytes, fit: BoxFit.cover),
        ),
      );
    } else if (localPath != null && localPath.isNotEmpty) {
      final file = File(localPath);
      if (file.existsSync()) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(kIndRadius),
          child: GestureDetector(
            onTap: () => _showLocalImageViewer(filePath: localPath),
            child: Image.file(file, fit: BoxFit.cover),
          ),
        );
      }
    }

    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.add_photo_alternate, color: Colors.grey, size: 40),
          SizedBox(height: 8),
          Text(
            'Tocar para agregar foto',
            style: TextStyle(color: Colors.grey, fontSize: 12),
          ),
        ],
      ),
    );
  }

  void _showLocalImageViewer({Uint8List? bytes, String? filePath}) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) =>
            _LocalImageViewerScreen(bytes: bytes, filePath: filePath),
      ),
    );
  }
}

// ============================================
// VISOR DE IMAGEN LOCAL
// ============================================

class _LocalImageViewerScreen extends StatelessWidget {
  final Uint8List? bytes;
  final String? filePath;

  const _LocalImageViewerScreen({this.bytes, this.filePath});

  @override
  Widget build(BuildContext context) {
    Widget imageWidget;

    if (bytes != null) {
      imageWidget = Image.memory(bytes!, fit: BoxFit.contain);
    } else if (filePath != null && filePath!.isNotEmpty) {
      final file = File(filePath!);
      if (file.existsSync()) {
        imageWidget = Image.file(file, fit: BoxFit.contain);
      } else {
        imageWidget = const Center(
          child: Text(
            'Imagen no encontrada',
            style: TextStyle(color: Colors.white),
          ),
        );
      }
    } else {
      imageWidget = const Center(
        child: Text(
          'Sin imagen disponible',
          style: TextStyle(color: Colors.white),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Vista previa',
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: InteractiveViewer(
        minScale: 0.5,
        maxScale: 4.0,
        child: Center(child: imageWidget),
      ),
    );
  }
}
