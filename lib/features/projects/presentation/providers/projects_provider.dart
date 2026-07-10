import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/usecases/get_projects_usecase.dart';
import '../../domain/usecases/quick_search_projects_usecase.dart';
import '../../data/models/project.dart';
import '../../data/models/quick_search_response.dart';
import '../../data/datasources/projects_datasource_impl.dart';
import '../../data/repositories/projects_repository_impl.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import 'package:monitor/core/error/dio_error_handler.dart';

// Providers para dependencias
final projectsDataSourceProvider = Provider((ref) => ProjectsDatasourceImpl(ref.watch(authenticatedDioProvider)));
final projectsRepositoryProvider = Provider((ref) => ProjectsRepositoryImpl(ref.watch(projectsDataSourceProvider)));
final getProjectsUseCaseProvider = Provider((ref) => GetProjectsUsecase(ref.watch(projectsRepositoryProvider)));
final quickSearchProjectsUseCaseProvider = Provider((ref) => QuickSearchProjectsUsecase(ref.watch(projectsRepositoryProvider)));

// Estado para la lista
class ProjectsState {
  final List<Project> projects;
  final bool isLoading;
  final bool isLoadingMore;
  final String? error;
  final int currentPage;
  final bool hasMorePages;

  ProjectsState({
    this.projects = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.error,
    this.currentPage = 1,
    this.hasMorePages = true,
  });

  ProjectsState copyWith({
    List<Project>? projects,
    bool? isLoading,
    bool? isLoadingMore,
    String? error,
    int? currentPage,
    bool? hasMorePages,
    bool clearError = false,
  }) {
    return ProjectsState(
      projects: projects ?? this.projects,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      error: clearError ? null : (error ?? this.error),
      currentPage: currentPage ?? this.currentPage,
      hasMorePages: hasMorePages ?? this.hasMorePages,
    );
  }
}

class ProjectsNotifier extends StateNotifier<ProjectsState> {
  final GetProjectsUsecase getProjectsUseCase;

  ProjectsNotifier(this.getProjectsUseCase) : super(ProjectsState()) {
    loadProjects();
  }

  Future<void> loadProjects() async {
    state = state.copyWith(
      isLoading: true,
      clearError: true,
      projects: const [],
      currentPage: 1,
      hasMorePages: true,
    );
    try {
      final response = await getProjectsUseCase(page: 1);
      state = state.copyWith(
        isLoading: false,
        projects: response.data ?? [],
        currentPage: 2,
        hasMorePages: response.pagination?.hasMorePages ?? false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: DioErrorHandler.getErrorMessage(
          e,
          defaultMessage: 'Error al cargar los proyectos. Por favor, intenta nuevamente.',
        ),
      );
    }
  }

  Future<void> loadMoreProjects() async {
    if (state.isLoading || state.isLoadingMore || !state.hasMorePages) return;

    state = state.copyWith(isLoadingMore: true, clearError: true);
    try {
      final nextPage = state.currentPage;
      final response = await getProjectsUseCase(page: nextPage);
      state = state.copyWith(
        isLoadingMore: false,
        projects: [...state.projects, ...?response.data],
        currentPage: nextPage + 1,
        hasMorePages: response.pagination?.hasMorePages ?? false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoadingMore: false,
        error: DioErrorHandler.getErrorMessage(
          e,
          defaultMessage: 'Error al cargar más proyectos. Por favor, intenta nuevamente.',
        ),
      );
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
    bool clearError = false,
  }) {
    return QuickSearchState(
      results: results ?? this.results,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class QuickSearchNotifier extends StateNotifier<QuickSearchState> {
  final QuickSearchProjectsUsecase quickSearchUseCase;

  QuickSearchNotifier(this.quickSearchUseCase) : super(QuickSearchState());

  Future<void> search(String query) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final response = await quickSearchUseCase(query);
      state = state.copyWith(isLoading: false, results: response.data);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: DioErrorHandler.getErrorMessage(
          e,
          defaultMessage: 'Error al buscar proyectos. Por favor, intenta nuevamente.',
        ),
      );
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