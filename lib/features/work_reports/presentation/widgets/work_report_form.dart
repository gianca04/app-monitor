import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
import 'package:go_router/go_router.dart';
import 'dart:typed_data';
import '../../data/models/work_report.dart';
import '../providers/work_reports_provider.dart';
import '../../../photos/presentation/providers/photos_provider.dart';
import '../../../photos/presentation/widgets/image_viewer.dart';
import '../../../../core/widgets/modern_bottom_modal.dart';
import '../../../employees/presentation/widgets/quick_search_modal.dart';
import '../../../employees/data/models/quick_search_response.dart';
import '../../../projects/presentation/widgets/quick_search_modal.dart'
    as projects_modal;
import '../../../projects/data/models/quick_search_response.dart';
import '../../../settings/providers/connectivity_preferences_provider.dart';
import 'industrial_selector.dart';
import 'sgnature_box.dart';
import '../../../../core/theme_config.dart';

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
  late TextEditingController _descriptionController;
  late TextEditingController _reportDateController;
  late TextEditingController _startTimeController;
  late TextEditingController _endTimeController;
  late TextEditingController _toolsController;
  late TextEditingController _personnelController;
  late TextEditingController _materialsController;
  late TextEditingController _suggestionsController;
  late TextEditingController _employeeIdController;
  late TextEditingController _projectIdController;

  EmployeeQuick? _selectedEmployee;
  ProjectQuick? _selectedProject;

  MultipartFile? _supervisorSignature;
  MultipartFile? _managerSignature;
  Uint8List? _supervisorSignatureBytes;
  Uint8List? _managerSignatureBytes;

  List<Map<String, dynamic>> _photos = [];

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.report?.name ?? '');
    _descriptionController = TextEditingController(
      text: widget.report?.description ?? '',
    );
    _reportDateController = TextEditingController(
      text: widget.report?.reportDate ?? '',
    );
    _startTimeController = TextEditingController(
      text: widget.report?.startTime ?? '',
    );
    _endTimeController = TextEditingController(
      text: widget.report?.endTime ?? '',
    );
    _toolsController = TextEditingController(
      text: widget.report?.resources?.tools ?? '',
    );
    _personnelController = TextEditingController(
      text: widget.report?.resources?.personnel ?? '',
    );
    _materialsController = TextEditingController(
      text: widget.report?.resources?.materials ?? '',
    );
    _suggestionsController = TextEditingController(
      text: widget.report?.suggestions ?? '',
    );
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
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _reportDateController.dispose();
    _startTimeController.dispose();
    _endTimeController.dispose();
    _toolsController.dispose();
    _personnelController.dispose();
    _materialsController.dispose();
    _suggestionsController.dispose();
    _employeeIdController.dispose();
    _projectIdController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(bool isSupervisor) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes();
      final multipartFile = MultipartFile.fromBytes(
        bytes,
        filename: pickedFile.name,
      );

      setState(() {
        if (isSupervisor) {
          _supervisorSignature = multipartFile;
          _supervisorSignatureBytes = bytes;
        } else {
          _managerSignature = multipartFile;
          _managerSignatureBytes = bytes;
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
      child: Container(
        color: kIndBg,
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              // --- SECTION 1: CONTEXT ---
              _buildSectionHeader('CONTEXTO OPERATIVO'),
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

              // --- SECTION 2: REPORT DETAILS ---
              _buildSectionHeader('DETALLES DEL REPORTE'),
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

              // Date & Time Row
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 2,
                    child: TextFormField(
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
                          _reportDateController.text = picked.toIso8601String().split('T')[0];
                        }
                      },
                      validator: (value) {
                        if (value?.isEmpty ?? true) return 'Requerido';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      controller: _startTimeController,
                      readOnly: true,
                      decoration: const InputDecoration(labelText: 'INICIO (HH:mm)'),
                      onTap: () async {
                        final picked = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay.now(),
                        );
                        if (picked != null) {
                          _startTimeController.text = '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
                        }
                      },
                      validator: (value) {
                        if (value?.isEmpty ?? true) return null;
                        final regex = RegExp(r'^\d{2}:\d{2}$');
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      controller: _endTimeController,
                      readOnly: true,
                      decoration: const InputDecoration(labelText: 'FIN (HH:mm)'),
                      onTap: () async {
                        final picked = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay.now(),
                        );
                        if (picked != null) {
                          _endTimeController.text = '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
                        }
                      },
                      validator: (value) {
                        if (value?.isEmpty ?? true) return null;
                        final regex = RegExp(r'^\d{2}:\d{2}$');
                        if (!regex.hasMatch(value!)) return 'Formato inválido';
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'DESCRIPCIÓN GENERAL',
                  alignLabelWithHint: true,
                ),
                maxLines: 3,
              ),

              const SizedBox(height: 24),
              const Divider(color: Colors.white10),
              const SizedBox(height: 24),

              // --- SECTION 3: RESOURCES ---
              _buildSectionHeader('RECURSOS UTILIZADOS'),
              const SizedBox(height: 12),

              TextFormField(
                controller: _toolsController,
                decoration: const InputDecoration(
                  labelText: 'HERRAMIENTAS / EQUIPOS',
                  prefixIcon: Icon(Icons.build, color: Colors.grey),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _personnelController,
                decoration: const InputDecoration(
                  labelText: 'PERSONAL ADICIONAL',
                  prefixIcon: Icon(Icons.group, color: Colors.grey),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _materialsController,
                decoration: const InputDecoration(
                  labelText: 'MATERIALES / INSUMOS',
                  prefixIcon: Icon(Icons.inventory_2, color: Colors.grey),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _suggestionsController,
                decoration: const InputDecoration(
                  labelText: 'OBSERVACIONES / SUGERENCIAS',
                  prefixIcon: Icon(Icons.lightbulb, color: Colors.grey),
                ),
                maxLines: 2,
              ),

              const SizedBox(height: 24),
              const Divider(color: Colors.white10),
              const SizedBox(height: 24),

              // --- SECTION 4: EVIDENCE ---
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildSectionHeader('EVIDENCIA FOTOGRÁFICA'),
                  TextButton.icon(
                    onPressed: _addPhoto,
                    icon: const Icon(Icons.add, size: 16, color: kIndAccent),
                    label: const Text(
                      'AGREGAR FOTO',
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
                  onRemove: () => _removePhoto(entry.key),
                  onAfterDescChanged: (v) => entry.value['descripcion'] = v,
                  onBeforeDescChanged: (v) =>
                      entry.value['before_work_descripcion'] = v,
                );
              }),

              const SizedBox(height: 24),
              const Divider(color: Colors.white10),
              const SizedBox(height: 24),

              // --- SECTION 5: VALIDATION ---
              _buildSectionHeader('VALIDACIÓN Y FIRMAS'),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: SignatureBox(
                      title: 'SUPERVISOR',
                      bytes: _supervisorSignatureBytes,
                      onTap: () => _pickImage(true),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SignatureBox(
                      title: 'GERENCIA / CLIENTE',
                      bytes: _managerSignatureBytes,
                      onTap: () => _pickImage(false),
                    ),
                  ),
                ],
              ),

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
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
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
                              ? (widget.saveType == 'local' ? 'GUARDAR LOCALMENTE' : 'GENERAR REPORTE')
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
  }

  // --- Helper: Títulos de Sección ---
  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: kIndAccent,
        fontSize: 12,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.5,
      ),
    );
  }

  // ... (Tu método _submit se mantiene INTACTO) ...
  void _submit() async {
    // ... el código de _submit original ...
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

      bool isOnline;
      if (widget.saveType == 'cloud') {
        if (!actualOnline) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No hay conexión para guardar en la nube')),
          );
          return;
        }
        isOnline = true;
      } else if (widget.saveType == 'local') {
        isOnline = false;
      } else {
        isOnline = actualOnline;
      }

      // Validate photos - descriptions are not required
      // Removed validation for photo descriptions

      List<Map<String, dynamic>> validPhotos = _photos
          .where(
            (photo) =>
                photo['id'] != null ||
                photo['photo'] != null ||
                photo['before_work_photo'] != null,
          )
          .toList();
      print(
        'Sending data: projectId: ${_selectedProject!.id}, employeeId: ${int.parse(_employeeIdController.text)}, name: ${_nameController.text}, reportDate: ${_reportDateController.text}, startTime: ${_startTimeController.text.isEmpty ? null : _startTimeController.text}, endTime: ${_endTimeController.text.isEmpty ? null : _endTimeController.text}, description: ${_descriptionController.text.isEmpty ? null : _descriptionController.text}, tools: ${_toolsController.text.isEmpty ? null : _toolsController.text}, personnel: ${_personnelController.text.isEmpty ? null : _personnelController.text}, materials: ${_materialsController.text.isEmpty ? null : _materialsController.text}, suggestions: ${_suggestionsController.text.isEmpty ? null : _suggestionsController.text}, photos: $validPhotos',
      );
      setState(() => _isLoading = true);
      if (widget.report == null) {
        try {
          final newReport = await ref
              .read(workReportsProvider.notifier)
              .createWorkReport(
                _selectedProject!.id as int,
                int.parse(_employeeIdController.text),
                _nameController.text,
                _reportDateController.text,
                _startTimeController.text.isEmpty
                    ? null
                    : _startTimeController.text,
                _endTimeController.text.isEmpty
                    ? null
                    : _endTimeController.text,
                _descriptionController.text.isEmpty
                    ? null
                    : _descriptionController.text,
                _toolsController.text.isEmpty ? null : _toolsController.text,
                _personnelController.text.isEmpty
                    ? null
                    : _personnelController.text,
                _materialsController.text.isEmpty
                    ? null
                    : _materialsController.text,
                _suggestionsController.text.isEmpty
                    ? null
                    : _suggestionsController.text,
                validPhotos,
              );

          if (isOnline) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Reporte creado exitosamente')),
            );
            // Navigate to the detail screen of the newly created report
            if (mounted) {
              context.go('/work-reports/${newReport.id}');
            }
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Reporte guardado localmente. Se sincronizará cuando haya conexión.',
                ),
              ),
            );
            // Navigate to the list since the ID is temporary
            if (mounted) {
              context.go('/work-reports');
            }
          }
        } on DioException catch (e) {
          String errorMessage = 'Error creating work report';
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
          // Handle error, maybe show a snackbar
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error creating work report: $e')),
            );
          }
        } finally {
          setState(() => _isLoading = false);
        }
      } else {
        try {
          await ref
              .read(workReportsProvider.notifier)
              .updateWorkReport(
                widget.report!.id!,
                _selectedProject!.id as int,
                int.parse(_employeeIdController.text),
                _nameController.text,
                _reportDateController.text,
                _startTimeController.text.isEmpty
                    ? null
                    : _startTimeController.text,
                _endTimeController.text.isEmpty
                    ? null
                    : _endTimeController.text,
                _descriptionController.text.isEmpty
                    ? null
                    : _descriptionController.text,
                _toolsController.text.isEmpty ? null : _toolsController.text,
                _personnelController.text.isEmpty
                    ? null
                    : _personnelController.text,
                _materialsController.text.isEmpty
                    ? null
                    : _materialsController.text,
                _suggestionsController.text.isEmpty
                    ? null
                    : _suggestionsController.text,
                _supervisorSignature,
                _managerSignature,
              );

          // Navigate back to the detail screen
          if (mounted) {
            context.go('/work-reports/${widget.report!.id}');
          }
        } on DioException catch (e) {
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
          // Handle error, maybe show a snackbar
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error updating work report: $e')),
            );
          }
        } finally {
          setState(() => _isLoading = false);
        }
      }
    }
  }
}

// ============================================
// COMPONENTES VISUALES INDUSTRIALES AUXILIARES
// ============================================

class _IndustrialPhotoEntry extends StatelessWidget {
  final int index;
  final Map<String, dynamic> data;
  final WorkReport? report;
  final VoidCallback onPickAfter;
  final VoidCallback onPickBefore;
  final VoidCallback onRemove;
  final ValueChanged<String> onAfterDescChanged;
  final ValueChanged<String> onBeforeDescChanged;

  const _IndustrialPhotoEntry({
    required this.index,
    required this.data,
    this.report,
    required this.onPickAfter,
    required this.onPickBefore,
    required this.onRemove,
    required this.onAfterDescChanged,
    required this.onBeforeDescChanged,
  });

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
          // Header del item
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: kIndBorder)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'EVIDENCIA #${index + 1}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white70,
                  ),
                ),
                InkWell(
                  onTap: onRemove,
                  child: const Icon(
                    Icons.close,
                    color: Colors.redAccent,
                    size: 20,
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                // AFTER WORK BLOCK
                _buildPhotoBlock(
                  context,
                  'AFTER WORK',
                  'FOTO FINAL',
                  data['photo_bytes'],
                  data['id'] != null
                      ? report?.photos
                            ?.firstWhere((p) => p.id == data['id'])
                            .afterWork
                            .photoPath
                      : null,
                  data['descripcion'],
                  onPickAfter,
                  onAfterDescChanged,
                ),

                const Divider(color: Colors.white10, height: 24),

                // BEFORE WORK BLOCK
                _buildPhotoBlock(
                  context,
                  'BEFORE WORK',
                  'FOTO INICIAL',
                  data['before_work_photo_bytes'],
                  data['id'] != null
                      ? report?.photos
                            ?.firstWhere((p) => p.id == data['id'])
                            .beforeWork
                            .photoPath
                      : null,
                  data['before_work_descripcion'],
                  onPickBefore,
                  onBeforeDescChanged,
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
    String? desc,
    VoidCallback onPick,
    ValueChanged<String> onChanged,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Thumbnail
        InkWell(
          onTap: onPick,
          child: Container(
            width: 80,
            height: 80,
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
                          child: ImageViewer(url: url),
                        )
                      : const Center(
                          child: Icon(Icons.camera_alt, color: Colors.grey),
                        )),
          ),
        ),
        const SizedBox(width: 12),
        // Input
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: kIndAccent,
                ),
              ),
              const SizedBox(height: 4),
              TextFormField(
                initialValue: desc,
                style: const TextStyle(fontSize: 13),
                decoration: const InputDecoration(
                  hintText: 'Descripción...',
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(
                    vertical: 8,
                    horizontal: 8,
                  ),
                ),
                onChanged: onChanged,
                maxLines: 2,
              ),
              const SizedBox(height: 4),
              InkWell(
                onTap: onPick,
                child: Text(
                  btnLabel,
                  style: const TextStyle(
                    fontSize: 11,
                    decoration: TextDecoration.underline,
                    color: Colors.grey,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
