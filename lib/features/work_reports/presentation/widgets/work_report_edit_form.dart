import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
import 'package:go_router/go_router.dart';
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
import 'sgnature_box.dart';
import 'industrial_signature_dialog.dart';
import '../../../../core/theme_config.dart';

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
    _descriptionController = TextEditingController(text: widget.report.description ?? '');
    _reportDateController = TextEditingController(text: widget.report.reportDate ?? '');
    _startTimeController = TextEditingController(text: widget.report.startTime ?? '');
    _endTimeController = TextEditingController(text: widget.report.endTime ?? '');
    _toolsController = TextEditingController(text: widget.report.resources?.tools ?? '');
    _personnelController = TextEditingController(text: widget.report.resources?.personnel ?? '');
    _materialsController = TextEditingController(text: widget.report.resources?.materials ?? '');
    _suggestionsController = TextEditingController(text: widget.report.suggestions ?? '');
    _employeeIdController = TextEditingController(text: widget.report.employee?.id.toString() ?? '');
    _projectIdController = TextEditingController(text: widget.report.project?.id.toString() ?? '');

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
    print('🔍 [INIT] supervisor: ${_supervisorSignature != null ? "${_supervisorSignature!.substring(0, 50)}..." : "null"}');
    print('🔍 [INIT] manager: ${_managerSignature != null ? "${_managerSignature!.substring(0, 50)}..." : "null"}');
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
    print('🔍 [FORM] Starting _pickImage for ${isSupervisor ? "supervisor" : "manager"}');
    // Llamada limpia usando el método estático del Sheet
    final String? signatureBase64 = await IndustrialSignatureSheet.show(
      context,
      title: isSupervisor ? 'FIRMA DEL SUPERVISOR' : 'FIRMA GERENCIA / CLIENTE',
    );

    print('🔍 [FORM] Await completed, signatureBase64: ${signatureBase64 != null ? "present (${signatureBase64.length} chars)" : "null"}');

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
      final multipartFile = MultipartFile.fromBytes(bytes, filename: pickedFile.name);

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
    if (photo['id'] == null) {
      // Create new photo
      if (photo['photo'] != null && photo['descripcion'].isNotEmpty) {
        try {
          final createUseCase = CreatePhotoUseCase(ref.read(workReportsPhotosRepositoryProvider));
          await createUseCase(widget.report.id!, photo['photo'], photo['descripcion'], photo['before_work_photo'], photo['before_work_descripcion']);
          // Invalidate to reload
          ref.invalidate(workReportProvider(widget.report.id!));
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Foto creada exitosamente')));
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error creando foto: $e')));
        }
      }
    } else {
      // Update existing photo
      try {
        final updateUseCase = UpdatePhotoUseCase(ref.read(workReportsPhotosRepositoryProvider));
        await updateUseCase(
          photo['id'],
          photo['photo_bytes'] != null ? MultipartFile.fromBytes(photo['photo_bytes'], filename: 'photo.jpg') : null,
          photo['descripcion'],
          photo['before_work_photo_bytes'] != null ? MultipartFile.fromBytes(photo['before_work_photo_bytes'], filename: 'before.jpg') : null,
          photo['before_work_descripcion'],
        );
        // Invalidate to reload
        ref.invalidate(workReportProvider(widget.report.id!));
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Foto actualizada exitosamente')));
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error actualizando foto: $e')));
      }
    }
  }

  Future<void> _deletePhoto(int index) async {
    final photo = _photos[index];
    if (photo['id'] != null) {
      try {
        final deleteUseCase = DeletePhotoUseCase(ref.read(workReportsPhotosRepositoryProvider));
        await deleteUseCase(photo['id']);
        setState(() {
          _photos.removeAt(index);
        });
        // Invalidate to reload
        ref.invalidate(workReportProvider(widget.report.id!));
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Foto eliminada exitosamente')));
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error eliminando foto: $e')));
      }
    } else {
      // Remove unsaved photo
      setState(() {
        _photos.removeAt(index);
      });
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
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
                value: _selectedProject != null ? '${_selectedProject!.name} (ID: ${_selectedProject!.id})' : null,
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
                value: _selectedEmployee != null ? '${_selectedEmployee!.fullName}' : null,
                subValue: _selectedEmployee != null ? 'DOC: ${_selectedEmployee!.documentNumber}' : null,
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
                decoration: const InputDecoration(labelText: 'NOMBRE DEL REPORTE', prefixIcon: Icon(Icons.title, color: AppTheme.textSecondary)),
                validator: (value) => value?.isEmpty ?? true ? 'Requerido' : null,
              ),
              const SizedBox(height: 12),

              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 2,
                    child: TextFormField(
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
                          _reportDateController.text = picked.toIso8601String().split('T')[0];
                        }
                      },
                      validator: (value) => value?.isEmpty ?? true ? 'Requerido' : null,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      controller: _startTimeController,
                      readOnly: true,
                      decoration: const InputDecoration(labelText: 'INICIO (HH:mm)'),
                      onTap: () async {
                        final picked = await showTimePicker(context: context, initialTime: TimeOfDay.now());
                        if (picked != null) {
                          _startTimeController.text = '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
                        }
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
                        final picked = await showTimePicker(context: context, initialTime: TimeOfDay.now());
                        if (picked != null) {
                          _endTimeController.text = '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
                        }
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'DESCRIPCIÓN GENERAL', alignLabelWithHint: true),
                maxLines: 3,
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

              TextFormField(
                controller: _toolsController,
                decoration: const InputDecoration(labelText: 'HERRAMIENTAS / EQUIPOS', prefixIcon: Icon(Icons.build, color: Colors.grey)),
                maxLines: 2,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _personnelController,
                decoration: const InputDecoration(labelText: 'PERSONAL ADICIONAL', prefixIcon: Icon(Icons.group, color: Colors.grey)),
                maxLines: 2,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _materialsController,
                decoration: const InputDecoration(labelText: 'MATERIALES / INSUMOS', prefixIcon: Icon(Icons.inventory_2, color: Colors.grey)),
                maxLines: 2,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _suggestionsController,
                decoration: const InputDecoration(labelText: 'OBSERVACIONES / SUGERENCIAS', prefixIcon: Icon(Icons.lightbulb, color: Colors.grey)),
                maxLines: 2,
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
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(kIndRadius)),
                  ),
                  child: _isLoading
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.black))),
                            SizedBox(width: 8),
                            Text('CARGANDO...', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.0)),
                          ],
                        )
                      : const Text('ACTUALIZAR REPORTE', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.0)),
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
                    label: const Text('AGREGAR FOTO', style: TextStyle(color: kIndAccent)),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              if (_photos.isEmpty)
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.white10, style: BorderStyle.solid),
                    borderRadius: BorderRadius.circular(kIndRadius),
                  ),
                  child: const Center(child: Text('No hay evidencia adjunta', style: TextStyle(color: Colors.grey))),
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
                  onBeforeDescChanged: (v) => entry.value['before_work_descripcion'] = v,
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
                    child: SignatureBox(
                      title: 'SUPERVISOR',
                      base64: _supervisorSignatureBytes,
                      onTap: () => _pickImage(true),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SignatureBox(
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

  Widget _buildSectionHeader(ThemeData theme, {required String title, IconData? icon}) {
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
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Debe seleccionar un empleado')));
        return;
      }
      if (_selectedProject == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Debe seleccionar un proyecto')));
        return;
      }

      print('🔍 [SUBMIT] Starting submit with signatures:');
      print('🔍 [SUBMIT] _supervisorSignature: ${_supervisorSignature != null ? "present (${_supervisorSignature!.length} chars)" : "null"}');
      print('🔍 [SUBMIT] _managerSignature: ${_managerSignature != null ? "present (${_managerSignature!.length} chars)" : "null"}');

      setState(() => _isLoading = true);
      try {
        print('🔍 [SUBMIT] Calling updateWorkReport...');
        await ref.read(workReportsProvider.notifier).updateWorkReport(
          widget.report.id!,
          _selectedProject!.id!,
          int.parse(_employeeIdController.text),
          _nameController.text,
          _reportDateController.text,
          _startTimeController.text.isEmpty ? null : _startTimeController.text,
          _endTimeController.text.isEmpty ? null : _endTimeController.text,
          _descriptionController.text.isEmpty ? null : _descriptionController.text,
          _toolsController.text.isEmpty ? null : _toolsController.text,
          _personnelController.text.isEmpty ? null : _personnelController.text,
          _materialsController.text.isEmpty ? null : _materialsController.text,
          _suggestionsController.text.isEmpty ? null : _suggestionsController.text,
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
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(errorMessage)));
        }
      } catch (e) {
        print('❌ [SUBMIT] Exception: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error updating work report: $e')));
        }
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }
}

class _IndustrialPhotoEntry extends StatelessWidget {
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
                  'EVIDENCIA #${index + 1}',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white70),
                ),
                Row(
                  children: [
                    if (isEditMode)
                      IconButton(
                        icon: const Icon(Icons.save, color: kIndAccent, size: 20),
                        onPressed: onSave,
                        tooltip: 'Guardar',
                      ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.redAccent, size: 20),
                      onPressed: onRemove,
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
                  'AFTER WORK',
                  'FOTO FINAL',
                  data['photo_bytes'],
                  data['id'] != null ? report?.photos?.firstWhere((p) => p.id == data['id']).afterWork.photoPath : null,
                  data['descripcion'],
                  onPickAfter,
                  onAfterDescChanged,
                ),

                const Divider(color: Colors.white10, height: 24),

                _buildPhotoBlock(
                  context,
                  'BEFORE WORK',
                  'FOTO INICIAL',
                  data['before_work_photo_bytes'],
                  data['id'] != null ? report?.photos?.firstWhere((p) => p.id == data['id']).beforeWork.photoPath : null,
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
                      : const Center(child: Icon(Icons.camera_alt, color: Colors.grey))),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: kIndAccent),
              ),
              const SizedBox(height: 4),
              TextFormField(
                initialValue: desc,
                style: const TextStyle(fontSize: 13),
                decoration: const InputDecoration(
                  hintText: 'Descripción...',
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                ),
                onChanged: onChanged,
                maxLines: 2,
              ),
              const SizedBox(height: 4),
              InkWell(
                onTap: onPick,
                child: Text(
                  btnLabel,
                  style: const TextStyle(fontSize: 11, decoration: TextDecoration.underline, color: Colors.grey),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}