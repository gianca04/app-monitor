import 'dart:convert'; // Importante para jsonEncode
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/tool_and_material.dart';
import '../providers/tools_and_materials_provider.dart';
import '../../../../core/theme_config.dart';
import '../../../../core/widgets/modern_bottom_modal.dart';

class ToolsAndMaterialsWidget extends ConsumerWidget {
  const ToolsAndMaterialsWidget({super.key});

  void _saveAndPrintJson(BuildContext context, WidgetRef ref) {
    final tools = ref.read(toolsProvider);
    final materials = ref.read(materialsProvider);

    // 1. Construimos la lista de materiales puramente como Lista
    final List<Map<String, String>> materialsList = materials
        .map(
          (m) => {
            "material": m.name,
            "unidad": m.unit,
            "cantidad": m.quantity.toString(),
          },
        )
        .toList();

    // 2. Construimos la lista de herramientas puramente como Lista
    final List<Map<String, String>> toolsList = tools
        .map(
          (t) => {
            "herramienta": t.name,
            "unidad": t.unit,
            "cantidad": t.quantity.toString(),
          },
        )
        .toList();

    // Convertimos a JSON String
    final String materialsJson = jsonEncode(materialsList);
    final String toolsJson = jsonEncode(toolsList);

    // --- IMPRESIÓN EN CONSOLA ---
    debugPrint("--- JSON MATERIALES ---");
    debugPrint(materialsJson);
    debugPrint("--- JSON HERRAMIENTAS ---");
    debugPrint(toolsJson);

    // --- MOSTRAR EN PANTALLA ---
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: const Text(
          "JSON Formateado",
          style: TextStyle(color: Colors.white, fontSize: 16),
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "MATERIALES:",
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                materialsJson,
                style: const TextStyle(
                  color: AppTheme.secondaryAccent,
                  fontFamily: 'monospace',
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                "HERRAMIENTAS:",
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                toolsJson,
                style: const TextStyle(
                  color: AppTheme.secondaryAccent,
                  fontFamily: 'monospace',
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("CERRAR"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tools = ref.watch(toolsProvider);
    final materials = ref.watch(materialsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(context, 'HERRAMIENTAS', Icons.build_outlined),
        const SizedBox(height: 12),
        if (tools.isEmpty) _buildEmptyState("No hay herramientas agregadas"),
        ...tools.map(
          (tool) => _SlidableDeleteTile(
            key: ValueKey(tool.id),
            item: tool,
            isTool: true,
            onDelete: () =>
                ref.read(toolsProvider.notifier).removeTool(tool.id),
            onTap: () =>
                _showFormModal(context, ref, isTool: true, existingItem: tool),
          ),
        ),
        _buildAddButton(
          label: 'Agregar herramienta',
          onPressed: () => _showFormModal(context, ref, isTool: true),
        ),

        const SizedBox(height: 32),

        _buildSectionHeader(context, 'MATERIALES', Icons.inventory_2_outlined),
        const SizedBox(height: 12),
        if (materials.isEmpty) _buildEmptyState("No hay materiales agregados"),
        ...materials.map(
          (material) => _SlidableDeleteTile(
            key: ValueKey(material.id),
            item: material,
            isTool: false,
            onDelete: () => ref
                .read(materialsProvider.notifier)
                .removeMaterial(material.id),
            onTap: () => _showFormModal(
              context,
              ref,
              isTool: false,
              existingItem: material,
            ),
          ),
        ),
        _buildAddButton(
          label: 'Agregar material',
          onPressed: () => _showFormModal(context, ref, isTool: false),
        ),

        const SizedBox(height: 40),

        // --- BOTÓN DE GUARDAR / GENERAR JSON ---
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppTheme.primaryAccent),
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            onPressed: () => _saveAndPrintJson(context, ref),
            icon: const Icon(Icons.code, color: AppTheme.primaryAccent),
            label: const Text(
              "GENERAR Y VER JSON",
              style: TextStyle(
                color: AppTheme.primaryAccent,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  // --- MÉTODOS DE APOYO (HEADERS Y BOTONES) ---
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
        Icons.add_circle_outline,
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

  void _showFormModal(
    BuildContext context,
    WidgetRef ref, {
    required bool isTool,
    MaterialItem? existingItem,
  }) {
    ModernBottomModal.show(
      context,
      title: existingItem == null
          ? (isTool ? "Añadir Herramienta" : "Añadir Material")
          : (isTool ? "Editar Herramienta" : "Editar Material"),
      content: _MaterialForm(
        isTool: isTool,
        existingItem: existingItem,
        onSave: (name, unit, qty) {
          final item = MaterialItem(
            id:
                existingItem?.id ??
                DateTime.now().millisecondsSinceEpoch.toString(),
            name: name,
            unit: unit,
            quantity: qty,
          );
          if (isTool) {
            existingItem == null
                ? ref.read(toolsProvider.notifier).addTool(item)
                : ref.read(toolsProvider.notifier).updateTool(item.id, item);
          } else {
            existingItem == null
                ? ref.read(materialsProvider.notifier).addMaterial(item)
                : ref
                      .read(materialsProvider.notifier)
                      .updateMaterial(item.id, item);
          }
          Navigator.pop(context);
        },
      ),
    );
  }
}

// --- WIDGET PERSONALIZADO: SLIDABLE PERSISTENTE ---
class _SlidableDeleteTile extends StatefulWidget {
  final MaterialItem item;
  final bool isTool;
  final VoidCallback onDelete;
  final VoidCallback onTap;

  const _SlidableDeleteTile({
    super.key,
    required this.item,
    required this.isTool,
    required this.onDelete,
    required this.onTap,
  });

  @override
  State<_SlidableDeleteTile> createState() => _SlidableDeleteTileState();
}

class _SlidableDeleteTileState extends State<_SlidableDeleteTile> {
  double _dragExtent = 0;
  bool _isOpen = false;
  static const double _kActionWidth = 80.0;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Stack(
        children: [
          // FONDO: Botón de borrar (Fijo detrás)
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                color: AppTheme.error,
                borderRadius: BorderRadius.circular(AppTheme.kRadius),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  InkWell(
                    onTap: widget.onDelete,
                    child: SizedBox(
                      width: _kActionWidth,
                      height: double.infinity,
                      child: const Icon(
                        Icons.delete_outline,
                        color: Colors.white,
                        size: 26,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // FRENTE: La tarjeta que se desliza
          GestureDetector(
            onHorizontalDragUpdate: (details) {
              setState(() {
                _dragExtent += details.delta.dx;
                // Limitamos el arrastre (solo hacia la izquierda para abrir)
                if (_dragExtent > 0) _dragExtent = 0;
                if (_dragExtent < -_kActionWidth) _dragExtent = -_kActionWidth;
              });
            },
            onHorizontalDragEnd: (details) {
              setState(() {
                // Si arrastró más de la mitad del botón, se queda abierto
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
              child: _MaterialListTile(
                item: widget.item,
                isTool: widget.isTool,
                onTap: _isOpen
                    ? () => setState(() => _dragExtent = 0)
                    : widget.onTap,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// --- TARJETA DE CADA ITEM ---
class _MaterialListTile extends StatelessWidget {
  final MaterialItem item;
  final bool isTool;
  final VoidCallback onTap;

  const _MaterialListTile({
    required this.item,
    required this.isTool,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(AppTheme.kRadius),
          border: Border.all(color: AppTheme.border),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF162133),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                isTool ? Icons.handyman_outlined : Icons.layers_outlined,
                color: const Color(0xFF38BDF8),
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                item.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 13.0,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  "${item.quantity}",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  item.unit.toUpperCase(),
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 9,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MaterialForm extends StatefulWidget {
  final bool isTool;
  final MaterialItem? existingItem;
  final Function(String, String, int) onSave;
  const _MaterialForm({
    required this.onSave,
    required this.isTool,
    this.existingItem,
  });

  @override
  State<_MaterialForm> createState() => _MaterialFormState();
}

class _MaterialFormState extends State<_MaterialForm> {
  late TextEditingController _nameController;
  late TextEditingController _unitController;
  late TextEditingController _qtyController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: widget.existingItem?.name ?? "",
    );
    _unitController = TextEditingController(
      text: widget.existingItem?.unit ?? "",
    );
    _qtyController = TextEditingController(
      text: widget.existingItem?.quantity.toString() ?? "1",
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _unitController.dispose();
    _qtyController.dispose();
    super.dispose();
  }

  void _updateQty(int delta) {
    int current = int.tryParse(_qtyController.text) ?? 0;
    int next = current + delta;
    if (next < 0) next = 0;
    _qtyController.text = next.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.isTool ? "NOMBRE DE LA HERRAMIENTA" : "NOMBRE DEL MATERIAL",
          style: const TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _nameController,
          style: const TextStyle(fontSize: 14),
          decoration: InputDecoration(
            hintText: widget.isTool ? 'Ej: Taladro' : 'Ej: Acero',
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          "UNIDAD DE MEDIDA",
          style: TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _unitController,
          style: const TextStyle(fontSize: 14),
          decoration: const InputDecoration(hintText: 'Ej: Unidades'),
        ),
        const SizedBox(height: 20),
        const Text(
          "CANTIDAD",
          style: TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
          decoration: BoxDecoration(
            color: AppTheme.inputFill,
            borderRadius: BorderRadius.circular(AppTheme.kRadius),
            border: Border.all(color: AppTheme.border),
          ),
          child: Row(
            children: [
              Icon(
                widget.isTool ? Icons.construction : Icons.inventory_2_outlined,
                color: AppTheme.info,
                size: 18,
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  "Cantidad",
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                ),
              ),
              _qtyActionBtn(Icons.remove, () => _updateQty(-1)),
              SizedBox(
                width: 50,
                child: TextField(
                  controller: _qtyController,
                  textAlign: TextAlign.center,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),
              _qtyActionBtn(Icons.add, () => _updateQty(1), isPrimary: true),
            ],
          ),
        ),
        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () {
              if (_nameController.text.isNotEmpty &&
                  _unitController.text.isNotEmpty) {
                widget.onSave(
                  _nameController.text,
                  _unitController.text,
                  int.tryParse(_qtyController.text) ?? 0,
                );
              }
            },
            icon: const Icon(Icons.save_outlined, size: 18),
            label: Text(widget.existingItem == null ? "GUARDAR" : "ACTUALIZAR"),
          ),
        ),
      ],
    );
  }

  Widget _qtyActionBtn(
    IconData icon,
    VoidCallback onTap, {
    bool isPrimary = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: isPrimary ? AppTheme.info : const Color(0xFF30363D),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Icon(icon, size: 14, color: Colors.white),
      ),
    );
  }
}
