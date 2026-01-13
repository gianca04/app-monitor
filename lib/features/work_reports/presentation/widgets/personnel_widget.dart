import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/personnel_provider.dart';
import '../../domain/models/personnel.dart';
import '../../../../core/theme_config.dart';
import '../../../../core/widgets/modern_bottom_modal.dart';
import '../../../employees/presentation/widgets/quick_search_modal.dart';

class PersonnelWidget extends ConsumerWidget {
  const PersonnelWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final personnel = ref.watch(personnelProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(context, 'PERSONAL', Icons.people_outline),
        const SizedBox(height: 12),
        if (personnel.isEmpty)
          _buildEmptyState("No hay personal asignado")
        else
          ...personnel.map(
            (p) => _PersonnelListTile(
              person: p,
              onTap: () => _showPersonnelForm(context, ref, existing: p),
            ),
          ),
        _buildAddButton(
          label: 'Agregar personal',
          onPressed: () => _showPersonnelForm(context, ref),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(
    BuildContext context,
    String title,
    IconData icon,
  ) {
    return Row(
      children: [
        Icon(icon, color: AppTheme.textSecondary, size: 16),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 11,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        text,
        style: TextStyle(
          color: AppTheme.textSecondary.withOpacity(0.4),
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildAddButton({
    required String label,
    required VoidCallback onPressed,
  }) {
    return TextButton.icon(
      onPressed: onPressed,
      icon: const Icon(
        Icons.person_add_alt_1,
        color: AppTheme.primaryAccent,
        size: 18,
      ),
      label: Text(
        label,
        style: const TextStyle(
          color: AppTheme.primaryAccent,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  void _showPersonnelForm(
    BuildContext context,
    WidgetRef ref, {
    PersonnelItem? existing,
  }) {
    ModernBottomModal.show(
      context,
      title: existing == null ? "Añadir Personal" : "Editar Personal",
      content: PersonnelFormContent(existingItem: existing),
    );
  }
}

// --- TARJETA DE CADA EMPLEADO EN LA LISTA ---
class _PersonnelListTile extends StatelessWidget {
  final PersonnelItem person;
  final VoidCallback onTap;

  const _PersonnelListTile({required this.person, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.kRadius),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF1B2B28),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.check_circle,
              color: AppTheme.success,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (person.employeeId != null)
                  Text(
                    "ID: ${person.employeeId}",
                    style: const TextStyle(
                      color: AppTheme.info,
                      fontSize: 10,
                      fontFamily: 'monospace',
                    ),
                  ),
                Text(
                  person.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13.5,
                  ),
                ),
                Text(
                  "${person.positionName} • ${person.hh} HH",
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          if (!person.isNotRegistered)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                border: Border.all(color: AppTheme.success.withOpacity(0.5)),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                "REGISTERED",
                style: TextStyle(
                  color: AppTheme.success,
                  fontSize: 8,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          IconButton(
            icon: const Icon(Icons.more_vert, color: AppTheme.textSecondary),
            onPressed: onTap,
          ),
        ],
      ),
    );
  }
}

// --- CONTENIDO DEL MODAL ---
class PersonnelFormContent extends ConsumerStatefulWidget {
  final PersonnelItem? existingItem;
  const PersonnelFormContent({super.key, this.existingItem});

  @override
  ConsumerState<PersonnelFormContent> createState() =>
      _PersonnelFormContentState();
}

class _PersonnelFormContentState extends ConsumerState<PersonnelFormContent> {
  bool _isNotRegistered = false;
  int? _employeeId;
  int? _positionId;
  final _nameController = TextEditingController();
  final _roleController = TextEditingController();
  double _hours = 8.0;

  @override
  void initState() {
    super.initState();
    if (widget.existingItem != null) {
      _isNotRegistered = widget.existingItem!.isNotRegistered;
      _employeeId = widget.existingItem!.employeeId;
      _positionId = widget.existingItem!.positionId;
      _nameController.text = widget.existingItem!.name;
      _roleController.text = widget.existingItem!.positionName;
      _hours = widget.existingItem!.hh;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _roleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // --- TOGGLE DE REGISTRO ---
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.inputFill,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "No Registrado",
                      style: TextStyle(color: Colors.white, fontSize: 13),
                    ),
                    Text(
                      "Ingresar datos manualmente",
                      style: TextStyle(color: Colors.grey, fontSize: 11),
                    ),
                  ],
                ),
              ),
              Switch(
                value: _isNotRegistered,
                activeColor: AppTheme.primaryAccent,
                onChanged: (v) {
                  setState(() {
                    _isNotRegistered = v;
                    // Limpiamos los campos al cambiar el modo
                    _nameController.clear();
                    _roleController.clear();
                    _employeeId = null;
                    _positionId = null;
                  });
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // --- CAMPO NOMBRE ---
        const Text(
          "NOMBRE COMPLETO",
          style: TextStyle(
            color: Colors.grey,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _nameController,
          // Si NO está registrado, se puede escribir. Si SÍ está, es solo lectura (abre buscador)
          readOnly: !_isNotRegistered,
          decoration: InputDecoration(
            hintText: _isNotRegistered
                ? 'Escribir nombre completo'
                : 'Seleccionar del personal registrado',
            suffixIcon: _isNotRegistered
                ? null
                : const Icon(Icons.search, size: 20),
          ),
          onTap: _isNotRegistered
              ? null
              : () async {
                  // Reutiliza tu modal de búsqueda de empleados
                  final dynamic result = await ModernBottomModal.show(
                    context,
                    content: const QuickSearchModal(),
                  );

                  if (result != null) {
                    setState(() {
                      // 'result' debe ser de tipo Employee
                      _employeeId = result.id;
                      _nameController.text = result.fullName ?? "";

                      // Obtenemos el nombre del cargo si viene en el objeto (ajustar según tu QuickSearchResponse)
                      _roleController.text = result.positionName ?? "";
                      _positionId = result.positionId;
                    });
                  }
                },
        ),

        const SizedBox(height: 20),

        // --- CAMPO CARGO INDUSTRIAL ---
        const Text(
          "CARGO INDUSTRIAL",
          style: TextStyle(
            color: Colors.grey,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _roleController,
          // Si está registrado, este campo se bloquea porque viene del sistema
          readOnly: !_isNotRegistered,
          decoration: InputDecoration(
            hintText: _isNotRegistered
                ? 'Escribir cargo'
                : 'Cargo automático del sistema',
            fillColor: !_isNotRegistered
                ? AppTheme.inputFill.withOpacity(0.5)
                : AppTheme.inputFill,
          ),
        ),

        const SizedBox(height: 24),
        const Text(
          "Distribución de Horas-Hombre",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),

        // --- CONTADOR DE HORAS ---
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.inputFill,
            border: Border.all(color: AppTheme.border),
          ),
          child: Row(
            children: [
              const Expanded(
                child: Text(
                  "Horas Diarias",
                  style: TextStyle(color: Colors.grey),
                ),
              ),
              _qtyBtn(
                Icons.remove,
                () => setState(() => _hours = _hours > 0 ? _hours - 0.5 : 0),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  "$_hours",
                  style: const TextStyle(
                    color: AppTheme.info,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              _qtyBtn(
                Icons.add,
                () => setState(() => _hours += 0.5),
                isPrimary: true,
              ),
            ],
          ),
        ),

        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () {
              if (_nameController.text.isEmpty) return; // Validación simple

              final newItem = PersonnelItem(
                id: widget.existingItem?.id ?? DateTime.now().toString(),
                employeeId: _employeeId,
                name: _nameController.text,
                hh: _hours,
                positionId: _positionId,
                positionName: _roleController.text,
                isNotRegistered: _isNotRegistered,
              );

              if (widget.existingItem == null) {
                ref.read(personnelProvider.notifier).addPersonnel(newItem);
              } else {
                ref
                    .read(personnelProvider.notifier)
                    .updatePersonnel(newItem.id, newItem);
              }
              Navigator.pop(context);
            },
            child: const Text("Confirmar Personal"),
          ),
        ),
      ],
    );
  }

  Widget _qtyBtn(IconData icon, VoidCallback onTap, {bool isPrimary = false}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isPrimary ? AppTheme.info : AppTheme.border,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Icon(icon, size: 16, color: Colors.white),
      ),
    );
  }
}
