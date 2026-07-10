import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:monitor/core/widgets/industrial_feedback.dart';
import 'package:monitor/core/widgets/industrial_error_state.dart';
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
  final ScrollController _scrollController = ScrollController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
    _scrollController.addListener(_onScroll);
    // Ensure projects are loaded
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(projectsProvider.notifier).loadProjects();
    });
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      ref.read(projectsProvider.notifier).loadMoreProjects();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<ProjectsState>(projectsProvider, (previous, next) {
      if (previous != null) {
        if (previous.isLoading && !next.isLoading && next.error == null) {
          final count = next.projects.length;
          IndustrialFeedback.showSuccess(
            context,
            message: 'Se cargaron $count proyectos',
          );
        } else if (previous.isLoadingMore && !next.isLoadingMore && next.error == null) {
          final loadedMoreCount = next.projects.length - previous.projects.length;
          if (loadedMoreCount > 0) {
            IndustrialFeedback.showSuccess(
              context,
              message: 'Se cargaron $loadedMoreCount proyectos más',
            );
          }
        }
      }
    });

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
              ? IndustrialErrorState(
                  error: projectsState.error!,
                  onRetry: () => ref.read(projectsProvider.notifier).loadProjects(),
                )
              : filteredProjects.isEmpty
                  ? const Center(child: Text('No se encontraron proyectos.'))
                  : ListView.separated(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(16.0),
                      itemCount: filteredProjects.length + (projectsState.isLoadingMore ? 1 : 0),
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        if (index == filteredProjects.length) {
                          return const Padding(
                            padding: EdgeInsets.symmetric(vertical: 16.0),
                            child: Center(child: CircularProgressIndicator()),
                          );
                        }
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