import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import '../../../../core/theme_config.dart';
import '../../../../core/widgets/modern_bottom_modal.dart';
import '../../../work_reports/presentation/widgets/industrial_selector.dart';
import '../../../work_reports/presentation/widgets/signature_box.dart';
import '../../../work_reports/presentation/widgets/industrial_signature_dialog.dart';
import '../../domain/entities/work_report_local_entity.dart';
import '../providers/work_reports_local_provider.dart';
import '../../../projectslocal/presentation/providers/project_providers.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../work_report_photos_local/domain/entities/work_report_photo_local_entity.dart';
import '../../../work_report_photos_local/presentation/providers/work_report_photos_local_provider.dart';
import '../../../employees/data/models/quick_search_response.dart';
import '../../../employees/presentation/widgets/quick_search_modal.dart';

class WorkReportLocalFormScreen extends ConsumerStatefulWidget {
  final int? reportId;

  const WorkReportLocalFormScreen({super.key, this.reportId});

  @override
  ConsumerState<WorkReportLocalFormScreen> createState() =>
      _WorkReportLocalFormScreenState();
}

class _WorkReportLocalFormScreenState
    extends ConsumerState<WorkReportLocalFormScreen> with WidgetsBindingObserver {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _startTimeController = TextEditingController();
  final _endTimeController = TextEditingController();
  final _toolsController = TextEditingController();
  final _personnelController = TextEditingController();
  final _materialsController = TextEditingController();
  final _suggestionsController = TextEditingController();
  final _projectController = TextEditingController();

  int? _selectedProjectId;
  EmployeeQuick? _selectedEmployee;

  bool _isLoading = false;
  WorkReportLocalEntity? _existingReport;

  // Signatures management
  String? _supervisorSignature;
  String? _managerSignature;

  // Photos management
  final List<Map<String, dynamic>> _photos = [];
  int? _savedReportId; // Para guardar el ID del reporte después de crearlo

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadCurrentUser();
    if (widget.reportId != null) {
      _loadExistingReport();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // No hacer nada aquí, solo mantener el método vacío
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // Recargar cuando la app vuelve a estar en primer plano
    if (state == AppLifecycleState.resumed && widget.reportId != null) {
      _loadExistingReport();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _nameController.dispose();
    _descriptionController.dispose();
    _startTimeController.dispose();
    _endTimeController.dispose();
    _toolsController.dispose();
    _personnelController.dispose();
    _materialsController.dispose();
    _suggestionsController.dispose();
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
      final documentNumber = sharedPreferences.getString('employee_document_number');
      final position = sharedPreferences.getString('employee_position');
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
          context.pop();
        }
      },
      (report) async {
        if (mounted) {
          setState(() {
            _existingReport = report;
            _savedReportId = report.id;
            _nameController.text = report.name;
            _descriptionController.text = report.description ?? '';
            _startTimeController.text = report.startTime ?? '';
            _endTimeController.text = report.endTime ?? '';
            _toolsController.text = report.tools ?? '';
            _personnelController.text = report.personnel ?? '';
            _materialsController.text = report.materials ?? '';
            _suggestionsController.text = report.suggestions ?? '';
            _selectedProjectId = report.projectId;
            // Create EmployeeQuick from report data - will be replaced if user selects different employee
            _selectedEmployee = EmployeeQuick(
              id: report.employeeId,
              fullName: 'Empleado #${report.employeeId}', // Placeholder name
            );
            // Cargar firmas existentes
            _supervisorSignature = report.supervisorSignature;
            _managerSignature = report.managerSignature;
          });

          // Load existing photos
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
        print('No photos found for report: ${failure.message}');
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

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedProjectId == null) {
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

    final now = DateTime.now().toIso8601String();
    final entity = WorkReportLocalEntity(
      id: _existingReport?.id,
      employeeId: _selectedEmployee!.id!,
      projectId: _selectedProjectId!,
      name: _nameController.text,
      description: _descriptionController.text.isEmpty
          ? null
          : _descriptionController.text,
      supervisorSignature: _supervisorSignature,
      managerSignature: _managerSignature,
      suggestions: _suggestionsController.text.isEmpty
          ? null
          : _suggestionsController.text,
      createdAt: _existingReport?.createdAt ?? now,
      updatedAt: now,
      tools: _toolsController.text.isEmpty ? null : _toolsController.text,
      personnel: _personnelController.text.isEmpty
          ? null
          : _personnelController.text,
      materials: _materialsController.text.isEmpty
          ? null
          : _materialsController.text,
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
        // Save photos after report is saved
        _savedReportId = savedReportId;
        await _savePhotos(savedReportId);

        setState(() => _isLoading = false);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                widget.reportId == null
                    ? 'Reporte guardado exitosamente'
                    : 'Reporte actualizado exitosamente',
              ),
              backgroundColor: AppTheme.primaryAccent,
            ),
          );
          // Refresh the list after successful save
          ref.read(workReportsLocalListProvider.notifier).refresh();
          context.go('/work-reports-local');
        }
      },
    );
  }

  Future<void> _savePhotos(int reportId) async {
    for (var photo in _photos) {
      try {
        String? photoPath;
        String? beforeWorkPhotoPath;

        // Use the already saved local paths
        if (photo['photo_path'] != null) {
          photoPath = photo['photo_path'];
        }

        if (photo['before_work_photo_path'] != null) {
          beforeWorkPhotoPath = photo['before_work_photo_path'];
        }

        final photoEntity = WorkReportPhotoLocalEntity(
          id: photo['id'],
          workReportId: reportId,
          photoPath: photoPath,
          beforeWorkPhotoPath: beforeWorkPhotoPath,
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
          // Create new photo
          await ref.read(createWorkReportPhotoLocalUseCaseProvider)(
            photoEntity,
          );
        } else {
          // Update existing photo
          await ref.read(updateWorkReportPhotoLocalUseCaseProvider)(
            photoEntity,
          );
        }
      } catch (e) {
        print('Error saving photo: $e');
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
      print('Error saving image: $e');
      rethrow;
    }
  }

  Future<void> _delete() async {
    if (widget.reportId == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surface,
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
        // Refresh the list after successful deletion
        ref.read(workReportsLocalListProvider.notifier).refresh();
        context.go('/work-reports-local');
      },
    );
  }

  void _addPhoto() {
    setState(() {
      _photos.add({
        'id': null,
        'descripcion': '',
        'before_work_descripcion': '',
        'photo_path': null,
        'before_work_photo_path': null,
        'photo_bytes': null,
        'before_work_photo_bytes': null,
      });
    });
  }

  void _removePhoto(int index) {
    setState(() {
      final photo = _photos[index];

      // If photo has an ID, we should delete it from database
      if (photo['id'] != null && _savedReportId != null) {
        ref.read(deleteWorkReportPhotoLocalUseCaseProvider)(photo['id']);
      }

      _photos.removeAt(index);
    });
  }

  Future<void> _pickSignature(bool isSupervisor) async {
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

  Future<void> _pickPhotoImage(int index, bool isAfterWork) async {
    final picker = ImagePicker();

    // Show dialog to choose camera or gallery
    final source = await showDialog<ImageSource>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: const Text(
          'Seleccionar fuente',
          style: TextStyle(color: AppTheme.textPrimary),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(
                Icons.camera_alt,
                color: AppTheme.primaryAccent,
              ),
              title: const Text(
                'Cámara',
                style: TextStyle(color: AppTheme.textPrimary),
              ),
              onTap: () => Navigator.of(context).pop(ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(
                Icons.photo_library,
                color: AppTheme.primaryAccent,
              ),
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

        // Save image locally immediately when selected
        final localPath = await _saveImageToLocal(bytes);

        setState(() {
          if (isAfterWork) {
            _photos[index]['photo_bytes'] = bytes;
            _photos[index]['photo_path'] = localPath; // Use local path instead of original
          } else {
            _photos[index]['before_work_photo_bytes'] = bytes;
            _photos[index]['before_work_photo_path'] = localPath; // Use local path instead of original
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

  Future<void> _selectEmployee() async {
    final result = await ModernBottomModal.show<EmployeeQuick>(
      context,
      title: 'Seleccionar Empleado',
      content: const QuickSearchModal(),
    );
    if (result != null) {
      setState(() {
        _selectedEmployee = result;
      });
    }
  }

  Future<void> _selectProject(List<dynamic> projects) async {
    String searchQuery = '';

    final selectedId = await ModernBottomModal.show<int>(
      context,
      title: 'Seleccionar Proyecto',
      content: StatefulBuilder(
        builder: (context, setState) {
          final filteredProjects = searchQuery.isEmpty
              ? projects
              : projects.where((project) =>
                  project.name.toLowerCase().contains(searchQuery.toLowerCase())).toList();

          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Search field
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Buscar proyecto...',
                    prefixIcon: const Icon(Icons.search, color: AppTheme.textSecondary),
                    filled: true,
                    fillColor: AppTheme.surface,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(4),
                      borderSide: const BorderSide(color: AppTheme.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(4),
                      borderSide: const BorderSide(color: AppTheme.primaryAccent, width: 1.5),
                    ),
                  ),
                  style: const TextStyle(color: AppTheme.textPrimary),
                  onChanged: (value) {
                    setState(() {
                      searchQuery = value;
                    });
                  },
                ),
              ),
              // Projects list
              SizedBox(
                height: 300,
                child: ListView(
                  shrinkWrap: true,
                  children: filteredProjects.map((project) {
                    return ListTile(
                      title: Text(
                        project.name,
                        style: const TextStyle(color: AppTheme.textPrimary),
                      ),
                      onTap: () => Navigator.of(context).pop(project.id),
                    );
                  }).toList(),
                ),
              ),
            ],
          );
        },
      ),
    );

    if (selectedId != null) {
      setState(() {
        _selectedProjectId = selectedId;
        final selectedProject = projects.firstWhere((p) => p.id == selectedId);
        _projectController.text = selectedProject.name;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final projectsBoxAsync = ref.watch(projectBoxProvider);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/work-reports-local'),
        ),
        title: Text(
          widget.reportId == null
              ? 'Crear Reporte Local'
              : 'Editar Reporte Local',
        ),
        iconTheme: const IconThemeData(color: AppTheme.textPrimary),
        actions: [
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

          // Set project name if selected and not set
          if (_selectedProjectId != null && _projectController.text.isEmpty) {
            final project = projects.firstWhere((p) => p.id == _selectedProjectId);
            _projectController.text = project.name;
          }

          return Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Project Selection
                _buildSectionHeader('PROYECTO'),
                const SizedBox(height: 8),
                IndustrialSelector(
                  label: 'Seleccionar proyecto',
                  value: _projectController.text.isEmpty ? null : _projectController.text,
                  icon: Icons.business,
                  onTap: () => _selectProject(projects),
                ),

                const SizedBox(height: 16),

                // Employee Selection
                _buildSectionHeader('EMPLEADO'),
                const SizedBox(height: 8),
                IndustrialSelector(
                  label: 'Seleccionar empleado',
                  value: _selectedEmployee?.fullName,
                  subValue: _selectedEmployee != null
                      ? 'DOC: ${_selectedEmployee!.documentNumber ?? 'N/A'}'
                      : null,
                  icon: Icons.person,
                  onTap: _selectEmployee,
                ),

                const SizedBox(height: 24),
                const Divider(color: Colors.white10),
                const SizedBox(height: 24),

                // Report Details
                _buildSectionHeader('DETALLES DEL REPORTE'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _nameController,
                  decoration: _inputDecoration(
                    label: 'Nombre del reporte',
                    icon: Icons.title,
                  ),
                  validator: (value) =>
                      value?.isEmpty ?? true ? 'Requerido' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _descriptionController,
                  decoration: _inputDecoration(
                    label: 'Descripción',
                    icon: Icons.description,
                  ),
                  maxLines: 3,
                ),

                const SizedBox(height: 16),

                // Date and Times
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _startTimeController,
                        decoration: _inputDecoration(
                          label: 'Hora inicio',
                          icon: Icons.access_time,
                        ),
                        readOnly: true,
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
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _endTimeController,
                        decoration: _inputDecoration(
                          label: 'Hora fin',
                          icon: Icons.access_time_filled,
                        ),
                        readOnly: true,
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

                const SizedBox(height: 24),
                const Divider(color: Colors.white10),
                const SizedBox(height: 24),

                // Resources
                _buildSectionHeader('RECURSOS'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _toolsController,
                  decoration: _inputDecoration(
                    label: 'Herramientas',
                    icon: Icons.build,
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _personnelController,
                  decoration: _inputDecoration(
                    label: 'Personal',
                    icon: Icons.group,
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _materialsController,
                  decoration: _inputDecoration(
                    label: 'Materiales',
                    icon: Icons.inventory_2,
                  ),
                  maxLines: 2,
                ),

                const SizedBox(height: 24),
                const Divider(color: Colors.white10),
                const SizedBox(height: 24),

                // Photo Evidence Section
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildSectionHeader('EVIDENCIA FOTOGRÁFICA'),
                    TextButton.icon(
                      onPressed: _addPhoto,
                      icon: const Icon(
                        Icons.add,
                        size: 16,
                        color: AppTheme.primaryAccent,
                      ),
                      label: const Text(
                        'AGREGAR',
                        style: TextStyle(color: AppTheme.primaryAccent),
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
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Center(
                      child: Text(
                        'No hay evidencia adjunta',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  ),

                ..._photos.asMap().entries.map((entry) {
                  return _buildPhotoEntry(entry.key, entry.value);
                }),

                const SizedBox(height: 24),
                const Divider(color: Colors.white10),
                const SizedBox(height: 24),

                // Suggestions
                _buildSectionHeader('OBSERVACIONES'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _suggestionsController,
                  decoration: _inputDecoration(
                    label: 'Sugerencias',
                    icon: Icons.lightbulb_outline,
                  ),
                  maxLines: 3,
                ),

                const SizedBox(height: 24),
                const Divider(color: Colors.white10),
                const SizedBox(height: 24),

                // Signatures Section
                _buildSectionHeader('VALIDACIÓN Y FIRMAS'),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: SignatureBox(
                        title: 'SUPERVISOR',
                        base64: _supervisorSignature,
                        onTap: () => _pickSignature(true),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: SignatureBox(
                        title: 'GERENCIA / CLIENTE',
                        base64: _managerSignature,
                        onTap: () => _pickSignature(false),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 32),

                // Save Button
                SizedBox(
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryAccent,
                      foregroundColor: Colors.black,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.black,
                              ),
                            ),
                          )
                        : Text(
                            widget.reportId == null
                                ? 'GUARDAR REPORTE'
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
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryAccent),
          ),
        ),
        error: (error, stack) => Center(
          child: Text(
            'Error al cargar proyectos',
            style: const TextStyle(color: AppTheme.textSecondary),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Row(
      children: [
        Container(width: 3, height: 16, color: AppTheme.primaryAccent),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            color: AppTheme.primaryAccent,
            fontSize: 12,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
          ),
        ),
      ],
    );
  }

  InputDecoration _inputDecoration({
    required String label,
    required IconData icon,
  }) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: AppTheme.textSecondary, size: 20),
      filled: true,
      fillColor: AppTheme.surface,
      labelStyle: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(4),
        borderSide: const BorderSide(color: AppTheme.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(4),
        borderSide: const BorderSide(color: AppTheme.primaryAccent, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(4),
        borderSide: const BorderSide(color: Colors.redAccent),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(4),
        borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
      ),
      disabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(4),
        borderSide: const BorderSide(color: AppTheme.border),
      ),
    );
  }

  Widget _buildPhotoEntry(int index, Map<String, dynamic> photo) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        border: Border.all(color: AppTheme.border),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with photo number and remove button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'FOTO #${index + 1}',
                style: const TextStyle(
                  color: AppTheme.primaryAccent,
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
                onPressed: () => _removePhoto(index),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // After Work Photo Section
          const Text(
            'DESPUÉS DEL TRABAJO',
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 8),

          // After work photo preview/button
          GestureDetector(
            onTap: () => _pickPhotoImage(index, true),
            child: Container(
              height: 150,
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppTheme.background,
                border: Border.all(color: AppTheme.border),
                borderRadius: BorderRadius.circular(4),
              ),
              child: _buildPhotoPreview(
                photo['photo_bytes'],
                photo['photo_path'],
                'Agregar foto después',
              ),
            ),
          ),
          const SizedBox(height: 8),

          // After work description
          TextFormField(
            initialValue: photo['descripcion'] ?? '',
            decoration: _inputDecoration(
              label: 'Descripción',
              icon: Icons.description,
            ),
            maxLines: 2,
            onChanged: (value) => photo['descripcion'] = value,
          ),

          const SizedBox(height: 16),

          // Before Work Photo Section
          const Text(
            'ANTES DEL TRABAJO',
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 8),

          // Before work photo preview/button
          GestureDetector(
            onTap: () => _pickPhotoImage(index, false),
            child: Container(
              height: 150,
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppTheme.background,
                border: Border.all(color: AppTheme.border),
                borderRadius: BorderRadius.circular(4),
              ),
              child: _buildPhotoPreview(
                photo['before_work_photo_bytes'],
                photo['before_work_photo_path'],
                'Agregar foto antes',
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Before work description
          TextFormField(
            initialValue: photo['before_work_descripcion'] ?? '',
            decoration: _inputDecoration(
              label: 'Descripción',
              icon: Icons.description,
            ),
            maxLines: 2,
            onChanged: (value) => photo['before_work_descripcion'] = value,
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoPreview(
    Uint8List? bytes,
    String? path,
    String placeholder,
  ) {
    if (bytes != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: Image.memory(bytes, fit: BoxFit.cover),
      );
    } else if (path != null && path.isNotEmpty) {
      final file = File(path);
      if (file.existsSync()) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: Image.file(file, fit: BoxFit.cover),
        );
      }
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.add_photo_alternate,
            color: AppTheme.textSecondary,
            size: 40,
          ),
          const SizedBox(height: 8),
          Text(
            placeholder,
            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
