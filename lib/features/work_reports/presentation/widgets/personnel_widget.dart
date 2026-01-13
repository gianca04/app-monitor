import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/personnel_provider.dart';
import '../../domain/models/personnel.dart';
import '../../../../core/theme_config.dart';
import '../../../../core/widgets/modern_bottom_modal.dart';
import '../../../employees/presentation/widgets/quick_search_modal.dart';
import '../../../employees/data/models/quick_search_response.dart';

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
          // Usamos el nuevo Widget Deslizable
          ...personnel.map(
            (p) => _SlidablePersonnelTile(
              key: ValueKey(p.id), // Importante para el rendimiento de la lista
              person: p,
              onTap: () => _showPersonnelForm(context, ref, existing: p),
              onDelete: () =>
                  ref.read(personnelProvider.notifier).removePersonnel(p.id),
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

class _SlidablePersonnelTile extends StatefulWidget {
  final PersonnelItem person;
  final VoidCallback onDelete;
  final VoidCallback onTap;

  const _SlidablePersonnelTile({
    super.key,
    required this.person,
    required this.onDelete,
    required this.onTap,
  });

  @override
  State<_SlidablePersonnelTile> createState() => _SlidablePersonnelTileState();
}

class _SlidablePersonnelTileState extends State<_SlidablePersonnelTile> {
  double _dragExtent = 0;
  bool _isOpen = false;
  static const double _kActionWidth = 80.0;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Stack(
        children: [
          // --- CAPA TRASERA (BOTÓN ELIMINAR) ---
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                color: AppTheme.error.withOpacity(0.9), // Rojo
                borderRadius: BorderRadius.circular(AppTheme.kRadius),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end, // A la derecha
                children: [
                  InkWell(
                    onTap: widget.onDelete,
                    child: SizedBox(
                      width: _kActionWidth,
                      height: double.infinity,
                      child: const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.delete_outline,
                            color: Colors.white,
                            size: 24,
                          ),
                          SizedBox(height: 2),
                          Text(
                            "Borrar",
                            style: TextStyle(color: Colors.white, fontSize: 10),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // --- CAPA FRONTAL (LA TARJETA VISIBLE) ---
          GestureDetector(
            onHorizontalDragUpdate: (details) {
              setState(() {
                _dragExtent += details.delta.dx;
                if (_dragExtent > 0) _dragExtent = 0;
                if (_dragExtent < -_kActionWidth) _dragExtent = -_kActionWidth;
              });
            },
            onHorizontalDragEnd: (details) {
              setState(() {
                if (_dragExtent < -_kActionWidth / 2) {
                  _dragExtent = -_kActionWidth;
                  _isOpen = true;
                } else {
                  _dragExtent = 0;
                  _isOpen = false;
                }
              });
            },
            child: Transform.translate(
              offset: Offset(_dragExtent, 0),
              child: _PersonnelListTile(
                person: widget.person,
                onTap: _isOpen
                    ? () => setState(() {
                        _dragExtent = 0;
                        _isOpen = false;
                      })
                    : widget.onTap,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PersonnelListTile extends StatelessWidget {
  final PersonnelItem person;
  final VoidCallback onTap;

  const _PersonnelListTile({required this.person, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(AppTheme.kRadius),
          border: Border.all(color: AppTheme.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Icono / Avatar
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF1B2B28),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.person,
                color: AppTheme.success,
                size: 18,
              ),
            ),
            const SizedBox(width: 8),

            // Textos
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          person.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12.0,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (person.employeeId != null) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white10,
                            borderRadius: BorderRadius.circular(3),
                          ),
                          child: Text(
                            "ID ${person.employeeId}",
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 8.5,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    "${person.positionName} • ${person.hh} HH",
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 10.0,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            // Badge "Registrado"
            if (!person.isNotRegistered)
              Container(
                margin: const EdgeInsets.only(right: 4),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  border: Border.all(color: AppTheme.success.withOpacity(0.5)),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  "REG",
                  style: TextStyle(
                    color: AppTheme.success,
                    fontSize: 7.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

            // Indicador visual
            const Icon(Icons.chevron_left, color: Colors.white12, size: 16),
          ],
        ),
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

  // Controladores
  final _nameController = TextEditingController();
  final _roleController = TextEditingController();
  final _hoursController = TextEditingController();

  double _hours = 4;

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
    _hoursController.text = _hours.toString();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _roleController.dispose();
    _hoursController.dispose();
    super.dispose();
  }

  void _updateHoursBy(double amount) {
    double current = double.tryParse(_hoursController.text) ?? 0.0;
    double newValue = current + amount;
    if (newValue < 0) newValue = 0;
    newValue = double.parse(newValue.toStringAsFixed(1));

    setState(() {
      _hours = newValue;
      _hoursController.text = _hours.toString();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: AppTheme.border),
          ),
          child: Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "REGISTRADO EN EL SISTEMA",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      "Desactivar para ingreso manual",
                      style: TextStyle(color: Colors.grey, fontSize: 10),
                    ),
                  ],
                ),
              ),
              Switch(
                value: !_isNotRegistered, // true = registrado
                onChanged: (value) {
                  setState(() {
                    _isNotRegistered = !value;

                    // --- LÓGICA DE LIMPIEZA SOLICITADA ---
                    // Al cambiar el switch, limpiamos todos los campos para evitar mezcla de datos
                    _employeeId = null;
                    _positionId = null;
                    _nameController.clear();
                    _roleController.clear();

                    // Reseteamos las horas al estándar (8.0)
                    _hours = 8.0;
                    _hoursController.text = "8.0";
                  });
                },
                activeColor: AppTheme.success,
                activeTrackColor: AppTheme.success.withOpacity(0.3),
                inactiveThumbColor: AppTheme.textSecondary,
                inactiveTrackColor: AppTheme.inputFill,
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // --- CAMPO NOMBRE ---
        const Text(
          "NOMBRE COMPLETO",
          style: TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _nameController,
          readOnly: !_isNotRegistered,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: _isNotRegistered
                ? 'Escribir nombre completo'
                : 'Seleccionar empleado...',
            hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
            filled: true,
            fillColor: AppTheme.inputFill,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4),
              borderSide: BorderSide.none,
            ),
            suffixIcon: _isNotRegistered
                ? null
                : const Icon(
                    Icons.arrow_drop_down_circle_outlined,
                    size: 20,
                    color: AppTheme.primaryAccent,
                  ),
          ),
          onTap: !_isNotRegistered
              ? () async {
                  // Tu lógica de modal de búsqueda aquí
                  final result = await ModernBottomModal.show<EmployeeQuick>(
                    context,
                    title: 'Seleccionar Empleado',
                    content:
                        const QuickSearchModal(), // O EmployeeSelectModal según lo que decidiste usar
                  );
                  if (result != null) {
                    setState(() {
                      _employeeId = result.id;
                      _nameController.text = result.fullName ?? "";
                      _roleController.text = result.position ?? "";
                      _positionId = null;
                    });
                  }
                }
              : null,
        ),

        const SizedBox(height: 20),

        // --- CAMPO CARGO ---
        const Text(
          "CARGO INDUSTRIAL",
          style: TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _roleController,
          readOnly: !_isNotRegistered,
          style: TextStyle(
            color: !_isNotRegistered ? Colors.white70 : Colors.white,
          ),
          decoration: InputDecoration(
            hintText: 'Cargo del personal',
            hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
            filled: true,
            fillColor: !_isNotRegistered
                ? Colors.black.withOpacity(0.2)
                : AppTheme.inputFill,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4),
              borderSide: BorderSide.none,
            ),
          ),
        ),

        const SizedBox(height: 24),

        // --- SECCIÓN HORAS HOMBRE MEJORADA ---
        const Row(
          children: [
            Icon(
              Icons.access_time_filled,
              color: AppTheme.primaryAccent,
              size: 16,
            ),
            SizedBox(width: 8),
            Text(
              "DISTRIBUCIÓN DE HORAS",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: AppTheme.inputFill,
            border: Border.all(color: AppTheme.border),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              // Etiqueta y descripción
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Jornada Diaria",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      "Horas efectivas (HH)",
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),

              // Botón Menos
              _qtyBtn(Icons.remove, () => _updateHoursBy(-0.5)),

              const SizedBox(width: 12),

              // --- TEXTFIELD EDITABLE ---
              Container(
                width: 70,
                padding: const EdgeInsets.symmetric(vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(
                    0xFF162133,
                  ), // Fondo más oscuro para el input
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: AppTheme.border),
                ),
                child: TextField(
                  controller: _hoursController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppTheme.info, // Color cyan para resaltar
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(vertical: 8),
                  ),
                  onChanged: (value) {
                    // Actualizamos la variable _hours al escribir
                    final parsed = double.tryParse(value);
                    if (parsed != null) {
                      setState(() {
                        _hours = parsed;
                      });
                    }
                  },
                ),
              ),

              const SizedBox(width: 12),

              // Botón Más
              _qtyBtn(Icons.add, () => _updateHoursBy(0.5), isPrimary: true),
            ],
          ),
        ),

        const SizedBox(height: 32),

        // --- BOTÓN CONFIRMAR ---
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryAccent,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () {
              // Validación final antes de guardar
              if (_nameController.text.isEmpty) return;

              // Asegurar que las horas sean el valor del input text
              final finalHours = double.tryParse(_hoursController.text) ?? 0.0;

              final newItem = PersonnelItem(
                id: widget.existingItem?.id ?? DateTime.now().toString(),
                employeeId: _employeeId,
                name: _nameController.text,
                hh: finalHours, // Usamos el valor validado
                positionId: _positionId,
                positionName: _roleController.text.isEmpty
                    ? "No especificado"
                    : _roleController.text,
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
            child: const Text(
              "CONFIRMAR PERSONAL",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
  }

  // Widget auxiliar para botones
  Widget _qtyBtn(IconData icon, VoidCallback onTap, {bool isPrimary = false}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: isPrimary ? AppTheme.info : const Color(0xFF30363D),
          borderRadius: BorderRadius.circular(4),
          border: isPrimary ? null : Border.all(color: Colors.white10),
        ),
        child: Icon(icon, size: 18, color: Colors.white),
      ),
    );
  }
}
