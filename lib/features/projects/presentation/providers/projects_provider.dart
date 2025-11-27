import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/usecases/get_projects_usecase.dart';
import '../../domain/usecases/quick_search_projects_usecase.dart';
import '../../data/models/project.dart';
import '../../data/models/quick_search_response.dart';
import '../../data/datasources/projects_datasource_impl.dart';
import '../../data/repositories/projects_repository_impl.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

// Providers para dependencias
final projectsDataSourceProvider = Provider((ref) => ProjectsDatasourceImpl(ref.watch(authenticatedDioProvider)));
final projectsRepositoryProvider = Provider((ref) => ProjectsRepositoryImpl(ref.watch(projectsDataSourceProvider)));
final getProjectsUseCaseProvider = Provider((ref) => GetProjectsUsecase(ref.watch(projectsRepositoryProvider)));
final quickSearchProjectsUseCaseProvider = Provider((ref) => QuickSearchProjectsUsecase(ref.watch(projectsRepositoryProvider)));

// Estado para la lista
class ProjectsState {
  final List<Project> projects;
  final bool isLoading;
  final String? error;

  ProjectsState({
    this.projects = const [],
    this.isLoading = false,
    this.error,
  });

  ProjectsState copyWith({
    List<Project>? projects,
    bool? isLoading,
    String? error,
  }) {
    return ProjectsState(
      projects: projects ?? this.projects,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

class ProjectsNotifier extends StateNotifier<ProjectsState> {
  final GetProjectsUsecase getProjectsUseCase;

  ProjectsNotifier(this.getProjectsUseCase) : super(ProjectsState()) {
    loadProjects();
  }

  Future<void> loadProjects() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final projects = await getProjectsUseCase();
      state = state.copyWith(isLoading: false, projects: projects);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}

// Estado para la búsqueda rápida
class QuickSearchState {
  final List<ProjectQuick> results;
  final bool isLoading;
  final String? error;

  QuickSearchState({
    this.results = const [],
    this.isLoading = false,
    this.error,
  });

  QuickSearchState copyWith({
    List<ProjectQuick>? results,
    bool? isLoading,
    String? error,
  }) {
    return QuickSearchState(
      results: results ?? this.results,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

class QuickSearchNotifier extends StateNotifier<QuickSearchState> {
  final QuickSearchProjectsUsecase quickSearchUseCase;

  QuickSearchNotifier(this.quickSearchUseCase) : super(QuickSearchState());

  Future<void> search(String query) async {
    if (query.isEmpty) {
      state = QuickSearchState();
      return;
    }
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await quickSearchUseCase(query);
      state = state.copyWith(isLoading: false, results: response.data);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}

final projectsProvider = StateNotifierProvider<ProjectsNotifier, ProjectsState>((ref) {
  final getUseCase = ref.watch(getProjectsUseCaseProvider);
  return ProjectsNotifier(getUseCase);
});

final quickSearchProvider = StateNotifierProvider<QuickSearchNotifier, QuickSearchState>((ref) {
  final useCase = ref.watch(quickSearchProjectsUseCaseProvider);
  return QuickSearchNotifier(useCase);
});