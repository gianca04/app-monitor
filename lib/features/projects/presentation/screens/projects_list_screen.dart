import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/widgets/modern_bottom_modal.dart';
import '../providers/projects_provider.dart';
import '../widgets/quick_search_modal.dart';
import '../../data/models/quick_search_response.dart';

class ProjectsListScreen extends ConsumerWidget {
  const ProjectsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projectsState = ref.watch(projectsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Projects'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () async {
              final result = await ModernBottomModal.show<ProjectQuick>(
                context,
                title: 'Búsqueda Rápida de Proyectos',
                content: const QuickSearchModal(),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancelar'),
                  ),
                ],
              );
              if (result != null) {
                // Manejar el resultado seleccionado
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Seleccionado: ${result.name}')),
                );
              }
            },
          ),
        ],
      ),
      body: projectsState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : projectsState.error != null
              ? Center(child: Text('Error: ${projectsState.error}'))
              : ListView.builder(
                  itemCount: projectsState.projects.length,
                  itemBuilder: (context, index) {
                    final project = projectsState.projects[index];
                    return ListTile(
                      title: Text(project.name ?? 'Sin nombre'),
                      subtitle: Text('${project.location ?? ''}'),
                      trailing: Text('${project.startDate ?? ''} - ${project.endDate ?? ''}'),
                    );
                  },
                ),
    );
  }
}