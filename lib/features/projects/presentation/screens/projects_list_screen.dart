import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme_config.dart';
import '../providers/projects_provider.dart';
import '../widgets/project_list_item.dart';

class ProjectsListScreen extends ConsumerStatefulWidget {
  const ProjectsListScreen({super.key});

  @override
  ConsumerState<ProjectsListScreen> createState() => _ProjectsListScreenState();
}

class _ProjectsListScreenState extends ConsumerState<ProjectsListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
    // Ensure projects are loaded
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(projectsProvider.notifier).loadProjects();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final projectsState = ref.watch(projectsProvider);
    final theme = Theme.of(context);

    final filteredProjects = projectsState.projects.where((project) {
      final name = project.name?.toLowerCase() ?? '';
      final location = project.location?.toLowerCase() ?? '';
      return name.contains(_searchQuery) || location.contains(_searchQuery);
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: 'Buscar proyectos...',
            hintStyle: TextStyle(
              color: theme.textTheme.bodyMedium?.color?.withOpacity(0.5),
            ),
            filled: true,
            fillColor: theme.inputDecorationTheme.fillColor ?? AppTheme.inputFill,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.kRadius),
              borderSide: BorderSide(color: theme.colorScheme.outline),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.kRadius),
              borderSide: BorderSide(color: theme.colorScheme.primary, width: 1.5),
            ),
            prefixIcon: Icon(Icons.search, color: theme.colorScheme.primary),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear, size: 18),
                    onPressed: () => _searchController.clear(),
                  )
                : null,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
          style: TextStyle(color: theme.textTheme.bodyMedium?.color),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: projectsState.isLoading
                ? null
                : () => ref.read(projectsProvider.notifier).loadProjects(),
            tooltip: 'RECARGAR',
          ),
        ],
      ),
      body: projectsState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : projectsState.error != null
              ? Center(child: Text('Error: ${projectsState.error}'))
              : filteredProjects.isEmpty
                  ? const Center(child: Text('No se encontraron proyectos.'))
                  : ListView.separated(
                      padding: const EdgeInsets.all(16.0),
                      itemCount: filteredProjects.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final project = filteredProjects[index];
                        return ProjectListItem(
                          project: project,
                          onTap: () {
                            if (project.id != null) {
                              context.push('/work-reports/project/${project.id}');
                            }
                          },
                        );
                      },
                    ),
    );
  }
}