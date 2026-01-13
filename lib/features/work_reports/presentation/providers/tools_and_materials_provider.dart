// lib/features/work_reports/presentation/providers/tools_and_materials_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/tool_and_material.dart';

// --- PROVIDER DE HERRAMIENTAS ---
final toolsProvider = StateNotifierProvider<ToolsNotifier, List<MaterialItem>>((
  ref,
) {
  return ToolsNotifier();
});

class ToolsNotifier extends StateNotifier<List<MaterialItem>> {
  ToolsNotifier() : super([]);

  // Agregar una nueva herramienta
  void addTool(MaterialItem tool) {
    state = [...state, tool];
  }

  // Eliminar herramienta por su ID único
  void removeTool(String id) {
    state = state.where((item) => item.id != id).toList();
  }

  // Actualizar una herramienta existente
  void updateTool(String id, MaterialItem updatedTool) {
    state = [
      for (final item in state)
        if (item.id == id) updatedTool else item,
    ];
  }

  void clearTools() {
    state = [];
  }
}

// --- PROVIDER DE MATERIALES ---
final materialsProvider =
    StateNotifierProvider<MaterialsNotifier, List<MaterialItem>>((ref) {
      return MaterialsNotifier();
    });

class MaterialsNotifier extends StateNotifier<List<MaterialItem>> {
  MaterialsNotifier() : super([]);

  // Agregar un nuevo material
  void addMaterial(MaterialItem material) {
    state = [...state, material];
  }

  // Eliminar material por ID
  void removeMaterial(String id) {
    state = state.where((item) => item.id != id).toList();
  }

  // Actualizar un material existente
  void updateMaterial(String id, MaterialItem updatedMaterial) {
    state = [
      for (final item in state)
        if (item.id == id) updatedMaterial else item,
    ];
  }

  void clearMaterials() {
    state = [];
  }

  final workReportJsonProvider = Provider((ref) {
    final tools = ref.watch(toolsProvider);
    final materials = ref.watch(materialsProvider);

    return {
      "materials": materials.map((m) => m.toJson(false)).toList(),
      "tools": tools.map((t) => t.toJson(true)).toList(),
    };
  });
}
