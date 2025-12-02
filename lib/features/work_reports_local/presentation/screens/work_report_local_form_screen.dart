import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import '../../../../core/theme_config.dart';
import '../../domain/entities/work_report_local_entity.dart';
import '../providers/work_reports_local_provider.dart';
import '../../../projectslocal/presentation/providers/project_providers.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../work_report_photos_local/domain/entities/work_report_photo_local_entity.dart';
import '../../../work_report_photos_local/presentation/providers/work_report_photos_local_provider.dart';

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
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _startTimeController = TextEditingController();
  final _endTimeController = TextEditingController();
  final _toolsController = TextEditingController();
  final _personnelController = TextEditingController();
  final _materialsController = TextEditingController();
  final _suggestionsController = TextEditingController();

  int? _selectedProjectId;
  int? _selectedEmployeeId;
  String? _selectedEmployeeName;

  bool _isLoading = false;
  WorkReportLocalEntity? _existingReport;

  // Photos management
  final List<Map<String, dynamic>> _photos = [];

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
    if (widget.reportId != null) {
      _loadExistingReport();
    }
  }

  Future<void> _loadCurrentUser() async {
    final authNotifier = ref.read(authProvider.notifier);
    final sharedPreferences = authNotifier.sharedPreferences;
    final employeeId = sharedPreferences.getInt('employee_id');
    if (employeeId != null) {
      final firstName =
          sharedPreferences.getString('employee_first_name') ?? '';
      final lastName = sharedPreferences.getString('employee_last_name') ?? '';
      if (mounted) {
        setState(() {
          _selectedEmployeeId = employeeId;
          _selectedEmployeeName = '$firstName $lastName'.trim();
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
      (report) {
        if (mounted) {
          setState(() {
            _existingReport = report;
            _nameController.text = report.name;
            _descriptionController.text = report.description ?? '';
            _startTimeController.text = report.startTime ?? '';
            _endTimeController.text = report.endTime ?? '';
            _toolsController.text = report.tools ?? '';
            _personnelController.text = report.personnel ?? '';
            _materialsController.text = report.materials ?? '';
            _suggestionsController.text = report.suggestions ?? '';
            _selectedProjectId = report.projectId;
            _selectedEmployeeId = report.employeeId;
          });
        }
      },
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _startTimeController.dispose();
    _endTimeController.dispose();
    _toolsController.dispose();
    _personnelController.dispose();
    _materialsController.dispose();
    _suggestionsController.dispose();
    super.dispose();
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

    if (_selectedEmployeeId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Debe seleccionar un empleado')),
      );
      return;
    }

    setState(() => _isLoading = true);

    final now = DateTime.now().toIso8601String();
    final entity = WorkReportLocalEntity(
      id: _existingReport?.id,
      employeeId: _selectedEmployeeId!,
      projectId: _selectedProjectId!,
      name: _nameController.text,
      description: _descriptionController.text.isEmpty
          ? null
          : _descriptionController.text,
      supervisorSignature: _existingReport?.supervisorSignature,
      managerSignature: _existingReport?.managerSignature,
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
          SnackBar(
            content: Text(
              widget.reportId == null
                  ? 'Reporte guardado exitosamente'
                  : 'Reporte actualizado exitosamente',
            ),
            backgroundColor: AppTheme.primaryAccent,
          ),
        );
        context.go('/work-reports-local');
      },
    );
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
        context.go('/work-reports-local');
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final projectsBoxAsync = ref.watch(projectBoxProvider);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        title: Text(
          widget.reportId == null
              ? 'CREAR REPORTE LOCAL'
              : 'EDITAR REPORTE LOCAL',
          style: const TextStyle(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
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

          return Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Project Selection
                _buildSectionHeader('PROYECTO'),
                const SizedBox(height: 8),
                DropdownButtonFormField<int>(
                  value: _selectedProjectId,
                  decoration: _inputDecoration(
                    label: 'Seleccionar proyecto',
                    icon: Icons.business,
                  ),
                  dropdownColor: AppTheme.surface,
                  items: projects.map((project) {
                    return DropdownMenuItem<int>(
                      value: project.id,
                      child: Text(
                        project.name,
                        style: const TextStyle(color: AppTheme.textPrimary),
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() => _selectedProjectId = value);
                  },
                  validator: (value) => value == null ? 'Requerido' : null,
                ),

                const SizedBox(height: 16),

                // Employee (read-only)
                _buildSectionHeader('EMPLEADO'),
                const SizedBox(height: 8),
                TextFormField(
                  initialValue: _selectedEmployeeName ?? 'Cargando...',
                  decoration: _inputDecoration(
                    label: 'Responsable',
                    icon: Icons.person,
                  ),
                  enabled: false,
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
}
