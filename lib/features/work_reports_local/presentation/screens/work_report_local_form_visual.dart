import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:go_router/go_router.dart';
import 'dart:typed_data';
import '../../../../core/theme_config.dart';
import '../../../../core/widgets/industrial_signature.dart';
import '../widgets/industrial_selector.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../projectslocal/presentation/providers/project_providers.dart';

// --- CONSTANTES DE DISEÑO INDUSTRIAL ---
const Color kIndBg = AppTheme.background;
const Color kIndSurface = AppTheme.surface;
const Color kIndBorder = AppTheme.border;
const Color kIndAccent = AppTheme.primaryAccent;
const double kIndRadius = 4.0;

class WorkReportLocalFormVisual extends ConsumerStatefulWidget {
  final int? reportId;

  const WorkReportLocalFormVisual({super.key, this.reportId});

  @override
  ConsumerState<WorkReportLocalFormVisual> createState() =>
      _WorkReportLocalFormVisualState();
}

class _WorkReportLocalFormVisualState
    extends ConsumerState<WorkReportLocalFormVisual> {
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
  int? _selectedEmployeeId;
  String? _selectedEmployeeName;

  bool _isLoading = false;

  // Signatures management
  String? _supervisorSignature;
  String? _managerSignature;

  // Photos management
  final List<Map<String, dynamic>> _photos = [];

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
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
    _projectController.dispose();
    super.dispose();
  }

  void _goBack() {
    context.go('/work-reports-local');
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
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes();

      setState(() {
        if (isAfterWork) {
          _photos[index]['photo_bytes'] = bytes;
          _photos[index]['photo_path'] = pickedFile.path;
        } else {
          _photos[index]['before_work_photo_bytes'] = bytes;
          _photos[index]['before_work_photo_path'] = pickedFile.path;
        }
      });
    }
  }

  Future<void> _selectProject(List<dynamic> projects) async {
    // TODO: Implement project selection
    if (projects.isNotEmpty) {
      setState(() {
        _selectedProjectId = projects.first.id;
        _projectController.text = projects.first.name;
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
          onPressed: _goBack,
        ),
        title: Text(
          widget.reportId == null
              ? 'Crear Reporte Local'
              : 'Editar Reporte Local',
        ),
        iconTheme: const IconThemeData(color: AppTheme.textPrimary),
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
                  value: _projectController.text.isEmpty ? null : _projectController.text,
                  icon: Icons.business,
                  onTap: () => _selectProject(projects),
                ),
                const SizedBox(height: 12),

                // Employee Selector
                TextFormField(
                  initialValue: _selectedEmployeeName ?? 'Cargando...',
                  decoration: _inputDecoration(
                    label: 'RESPONSABLE TÉCNICO',
                    icon: Icons.person,
                  ),
                  enabled: false,
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
                  decoration: _inputDecoration(
                    label: 'NOMBRE DEL REPORTE',
                    icon: Icons.title,
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
                        controller: TextEditingController(text: '2025-12-02'), // Example date
                        readOnly: true,
                        decoration: _inputDecoration(
                          label: 'FECHA',
                          icon: Icons.calendar_today,
                        ),
                        onTap: () async {
                          // TODO: Implement date picker
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextFormField(
                        controller: _startTimeController,
                        readOnly: true,
                        decoration: _inputDecoration(
                          label: 'INICIO (HH:mm)',
                          icon: Icons.access_time,
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
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextFormField(
                        controller: _endTimeController,
                        readOnly: true,
                        decoration: _inputDecoration(
                          label: 'FIN (HH:mm)',
                          icon: Icons.access_time_filled,
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
                const SizedBox(height: 12),

                // Description with industrial styling
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
                      TextFormField(
                        controller: _descriptionController,
                        maxLines: 4,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.only(
                              bottomLeft: Radius.circular(kIndRadius),
                              bottomRight: Radius.circular(kIndRadius),
                            ),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: kIndSurface,
                          contentPadding: const EdgeInsets.all(16),
                        ),
                      ),
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

                // Tools
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
                      TextFormField(
                        controller: _toolsController,
                        maxLines: 3,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.only(
                              bottomLeft: Radius.circular(kIndRadius),
                              bottomRight: Radius.circular(kIndRadius),
                            ),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: kIndSurface,
                          contentPadding: const EdgeInsets.all(16),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Personnel
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
                      TextFormField(
                        controller: _personnelController,
                        maxLines: 3,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.only(
                              bottomLeft: Radius.circular(kIndRadius),
                              bottomRight: Radius.circular(kIndRadius),
                            ),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: kIndSurface,
                          contentPadding: const EdgeInsets.all(16),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Materials
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
                      TextFormField(
                        controller: _materialsController,
                        maxLines: 3,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.only(
                              bottomLeft: Radius.circular(kIndRadius),
                              bottomRight: Radius.circular(kIndRadius),
                            ),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: kIndSurface,
                          contentPadding: const EdgeInsets.all(16),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Suggestions
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
                      TextFormField(
                        controller: _suggestionsController,
                        maxLines: 3,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.only(
                              bottomLeft: Radius.circular(kIndRadius),
                              bottomRight: Radius.circular(kIndRadius),
                            ),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: kIndSurface,
                          contentPadding: const EdgeInsets.all(16),
                        ),
                      ),
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
                    key: ObjectKey(entry.value),
                    index: entry.key,
                    data: entry.value,
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
                        onTap: () => _pickSignature(true),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: IndustrialSignatureBox(
                        title: 'GERENCIA / CLIENTE',
                        base64: _managerSignature,
                        onTap: () => _pickSignature(false),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 32),

                SizedBox(
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : () {},
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

// ============================================
// COMPONENTES VISUALES INDUSTRIALES AUXILIARES
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
                  'EVIDENCIA #${widget.index + 1}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white70,
                  ),
                ),
                InkWell(
                  onTap: widget.onRemove,
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
                  widget.data['photo_bytes'],
                  widget.onPickAfter,
                  widget.data['descripcion'],
                  widget.onAfterDescChanged,
                ),

                const Divider(color: Colors.white10, height: 24),

                // BEFORE WORK BLOCK
                _buildPhotoBlock(
                  context,
                  'BEFORE WORK',
                  'FOTO INICIAL',
                  widget.data['before_work_photo_bytes'],
                  widget.onPickBefore,
                  widget.data['before_work_descripcion'],
                  widget.onBeforeDescChanged,
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
    VoidCallback onPick,
    String description,
    ValueChanged<String> onDescChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Título de la sección de foto
        Text(
          title,
          style: const TextStyle(
            color: kIndAccent,
            fontSize: 12,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 8),

        // Área de la foto (Grande)
        InkWell(
          onTap: onPick,
          child: Container(
            width: double.infinity,
            height: 200,
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
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.camera_alt,
                        color: Colors.grey,
                        size: 40,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        btnLabel,
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
        const SizedBox(height: 12),

        // Área de descripción
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
                      'DESCRIPCIÓN',
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              TextFormField(
                initialValue: description,
                maxLines: 3,
                onChanged: onDescChanged,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(kIndRadius),
                      bottomRight: Radius.circular(kIndRadius),
                    ),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: kIndSurface,
                  contentPadding: const EdgeInsets.all(16),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}