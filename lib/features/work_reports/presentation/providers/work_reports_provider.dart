import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/usecases/get_work_reports_usecase.dart';
import '../../domain/usecases/get_work_report_usecase.dart';
import '../../domain/usecases/create_work_report_usecase.dart';
import '../../domain/usecases/update_work_report_usecase.dart';
import '../../domain/usecases/delete_work_report_usecase.dart';
import '../../data/models/work_report.dart';
import '../../data/models/work_reports_response.dart';
import '../../data/datasources/work_reports_datasource.dart';
import '../../data/repositories/work_reports_repository_impl.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../photos/domain/usecases/create_photo_usecase.dart';
import '../../../photos/domain/usecases/update_photo_usecase.dart';
import '../../../photos/domain/usecases/delete_photo_usecase.dart';
import '../../../photos/data/repositories/photos_repository_impl.dart';
import '../../../photos/data/datasources/photos_datasource.dart';

// Providers para dependencias
final dioProvider = Provider((ref) => Dio());
final workReportsDataSourceProvider = Provider((ref) => WorkReportsDataSourceImpl(ref.watch(authenticatedDioProvider)));
final workReportsRepositoryProvider = Provider((ref) => WorkReportsRepositoryImpl(ref.watch(workReportsDataSourceProvider)));
final getWorkReportsUseCaseProvider = Provider((ref) => GetWorkReportsUseCase(ref.watch(workReportsRepositoryProvider)));
final getWorkReportUseCaseProvider = Provider((ref) => GetWorkReportUseCase(ref.watch(workReportsRepositoryProvider)));
final createWorkReportUseCaseProvider = Provider((ref) => CreateWorkReportUseCase(ref.watch(workReportsRepositoryProvider)));
final updateWorkReportUseCaseProvider = Provider((ref) => UpdateWorkReportUseCase(ref.watch(workReportsRepositoryProvider)));
final deleteWorkReportUseCaseProvider = Provider((ref) => DeleteWorkReportUseCase(ref.watch(workReportsRepositoryProvider)));

// Providers para fotos
final photosDataSourceProvider = Provider((ref) => PhotosDataSourceImpl(ref.watch(authenticatedDioProvider)));
final workReportsPhotosRepositoryProvider = Provider((ref) => PhotosRepositoryImpl(ref.watch(photosDataSourceProvider)));
final createPhotoUseCaseProvider = Provider((ref) => CreatePhotoUseCase(ref.watch(workReportsPhotosRepositoryProvider)));
final updatePhotoUseCaseProvider = Provider((ref) => UpdatePhotoUseCase(ref.watch(workReportsPhotosRepositoryProvider)));
final deletePhotoUseCaseProvider = Provider((ref) => DeletePhotoUseCase(ref.watch(workReportsPhotosRepositoryProvider)));

class WorkReportsState {
  final List<WorkReport> reports;
  final bool isLoading;
  final bool isLoadingMore;
  final String? error;
  final String? search;
  final String? dateFrom;
  final String? dateTo;
  final String? sortBy;
  final String? sortOrder;
  final int? perPage;
  final int currentPage;
  final bool hasMorePages;
  final int? total;

  WorkReportsState({
    this.reports = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.error,
    this.search,
    this.dateFrom,
    this.dateTo,
    this.sortBy = 'report_date',
    this.sortOrder = 'asc',
    this.perPage = 10,
    this.currentPage = 1,
    this.hasMorePages = true,
    this.total,
  });

  WorkReportsState copyWith({
    List<WorkReport>? reports,
    bool? isLoading,
    bool? isLoadingMore,
    String? error,
    String? search,
    String? dateFrom,
    String? dateTo,
    String? sortBy,
    String? sortOrder,
    int? perPage,
    int? currentPage,
    bool? hasMorePages,
    int? total,
  }) {
    return WorkReportsState(
      reports: reports ?? this.reports,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      error: error ?? this.error,
      search: search ?? this.search,
      dateFrom: dateFrom ?? this.dateFrom,
      dateTo: dateTo ?? this.dateTo,
      sortBy: sortBy ?? this.sortBy,
      sortOrder: sortOrder ?? this.sortOrder,
      perPage: perPage ?? this.perPage,
      currentPage: currentPage ?? this.currentPage,
      hasMorePages: hasMorePages ?? this.hasMorePages,
      total: total ?? this.total,
    );
  }
}

class WorkReportsNotifier extends StateNotifier<WorkReportsState> {
  final GetWorkReportsUseCase getWorkReportsUseCase;
  final CreateWorkReportUseCase createWorkReportUseCase;
  final UpdateWorkReportUseCase updateWorkReportUseCase;
  final DeleteWorkReportUseCase deleteWorkReportUseCase;

  @override
  bool mounted = true;

  WorkReportsNotifier(
    this.getWorkReportsUseCase,
    this.createWorkReportUseCase,
    this.updateWorkReportUseCase,
    this.deleteWorkReportUseCase,
  ) : super(WorkReportsState());

  Future<void> loadWorkReports() async {
    if (mounted) {
      state = state.copyWith(
        isLoading: true,
        error: null,
        reports: [],
        currentPage: 1,
        hasMorePages: true,
      );
    }
    try {
      final response = await getWorkReportsUseCase(
        search: state.search,
        dateFrom: state.dateFrom,
        dateTo: state.dateTo,
        sortBy: state.sortBy,
        sortOrder: state.sortOrder,
        perPage: state.perPage,
        page: 1,
      );
      if (mounted) {
        state = state.copyWith(
          isLoading: false,
          reports: response.data ?? [],
          currentPage: 2,
          hasMorePages: response.pagination?.hasMorePages ?? false,
          total: response.pagination?.total,
        );
      }
    } on DioException catch (e) {
      String errorMessage;
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.sendTimeout ||
          e.type == DioExceptionType.connectionError) {
        errorMessage = 'Error de conexión. Verifica tu conexión a internet e intenta nuevamente.';
      } else if (e.type == DioExceptionType.badResponse) {
        errorMessage = 'Error del servidor. Inténtalo más tarde.';
      } else {
        errorMessage = 'Error al cargar los reportes. Por favor, intenta nuevamente.';
      }
      if (mounted) {
        state = state.copyWith(
          isLoading: false,
          error: errorMessage,
        );
      }
    } catch (e) {
      if (mounted) {
        state = state.copyWith(
          isLoading: false,
          error: 'Error al cargar los reportes. Por favor, intenta nuevamente.',
        );
      }
    }
  }

  Future<void> loadMoreWorkReports() async {
    if (!mounted || state.isLoadingMore || !state.hasMorePages) return;

    state = state.copyWith(isLoadingMore: true, error: null);
    try {
      final response = await getWorkReportsUseCase(
        search: state.search,
        dateFrom: state.dateFrom,
        dateTo: state.dateTo,
        sortBy: state.sortBy,
        sortOrder: state.sortOrder,
        perPage: state.perPage,
        page: state.currentPage,
      );
      if (mounted) {
        final newReports = List<WorkReport>.from(state.reports)
          ..addAll(response.data ?? []);
        state = state.copyWith(
          isLoadingMore: false,
          reports: newReports,
          currentPage: state.currentPage + 1,
          hasMorePages: response.pagination?.hasMorePages ?? false,
          total: response.pagination?.total,
        );
      }
    } on DioException catch (e) {
      String errorMessage;
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.sendTimeout ||
          e.type == DioExceptionType.connectionError) {
        errorMessage = 'Error de conexión. Verifica tu conexión a internet e intenta nuevamente.';
      } else if (e.type == DioExceptionType.badResponse) {
        errorMessage = 'Error del servidor. Inténtalo más tarde.';
      } else {
        errorMessage = 'Error al cargar más reportes. Por favor, intenta nuevamente.';
      }
      if (mounted) {
        state = state.copyWith(
          isLoadingMore: false,
          error: errorMessage,
        );
      }
    } catch (e) {
      if (mounted) {
        state = state.copyWith(
          isLoadingMore: false,
          error: 'Error al cargar más reportes. Por favor, intenta nuevamente.',
        );
      }
    }
  }

  Future<WorkReport> createWorkReport(int projectId, int employeeId, String name, String reportDate, String? startTime, String? endTime, String? description, String? tools, String? personnel, String? materials, String? suggestions, List<Map<String, dynamic>> photos) async {
    try {
      final newReport = await createWorkReportUseCase(projectId, employeeId, name, reportDate, startTime, endTime, description, tools, personnel, materials, suggestions, photos);
      await loadWorkReports();
      return newReport;
    } on DioException catch (e) {
      String errorMessage;
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.sendTimeout ||
          e.type == DioExceptionType.connectionError) {
        errorMessage = 'Error de conexión. Verifica tu conexión a internet e intenta nuevamente.';
      } else if (e.type == DioExceptionType.badResponse) {
        errorMessage = 'Error del servidor. Inténtalo más tarde.';
      } else {
        errorMessage = 'Error al crear el reporte. Por favor, intenta nuevamente.';
      }
      if (mounted) state = state.copyWith(error: errorMessage);
      rethrow;
    } catch (e) {
      if (mounted) state = state.copyWith(error: 'Error al crear el reporte. Por favor, intenta nuevamente.');
      rethrow;
    }
  }

  Future<void> updateWorkReport(int id, int projectId, int employeeId, String name, String reportDate, String? startTime, String? endTime, String? description, String? tools, String? personnel, String? materials, String? suggestions, MultipartFile? supervisorSignature, MultipartFile? managerSignature) async {
    try {
      await updateWorkReportUseCase(id, projectId, employeeId, name, reportDate, startTime, endTime, description, tools, personnel, materials, suggestions, supervisorSignature, managerSignature);
      await loadWorkReports();
    } on DioException catch (e) {
      String errorMessage;
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.sendTimeout ||
          e.type == DioExceptionType.connectionError) {
        errorMessage = 'Error de conexión. Verifica tu conexión a internet e intenta nuevamente.';
      } else if (e.type == DioExceptionType.badResponse) {
        errorMessage = 'Error del servidor. Inténtalo más tarde.';
      } else {
        errorMessage = 'Error al actualizar el reporte. Por favor, intenta nuevamente.';
      }
      if (mounted) state = state.copyWith(error: errorMessage);
      rethrow; // Para que el formulario pueda manejar el error
    } catch (e) {
      if (mounted) state = state.copyWith(error: 'Error al actualizar el reporte. Por favor, intenta nuevamente.');
      rethrow;
    }
  }

  Future<void> deleteWorkReport(int id) async {
    try {
      await deleteWorkReportUseCase(id);
      await loadWorkReports();
    } on DioException catch (e) {
      String errorMessage;
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.sendTimeout ||
          e.type == DioExceptionType.connectionError) {
        errorMessage = 'Error de conexión. Verifica tu conexión a internet e intenta nuevamente.';
      } else if (e.type == DioExceptionType.badResponse) {
        errorMessage = 'Error del servidor. Inténtalo más tarde.';
      } else {
        errorMessage = 'Error al eliminar el reporte. Por favor, intenta nuevamente.';
      }
      if (mounted) state = state.copyWith(error: errorMessage);
      rethrow; // Para que la UI pueda manejar el error
    } catch (e) {
      if (mounted) state = state.copyWith(error: 'Error al eliminar el reporte. Por favor, intenta nuevamente.');
      rethrow;
    }
  }

  void setFilters({
    String? search,
    String? dateFrom,
    String? dateTo,
    String? sortBy,
    String? sortOrder,
    int? perPage,
  }) {
    state = state.copyWith(
      search: search,
      dateFrom: dateFrom,
      dateTo: dateTo,
      sortBy: sortBy,
      sortOrder: sortOrder,
      perPage: perPage,
      reports: [],
      currentPage: 1,
      hasMorePages: true,
    );
    loadWorkReports();
  }

  void setDateFilter(String? dateFrom, String? dateTo) {
    setFilters(dateFrom: dateFrom, dateTo: dateTo);
  }
}

final workReportsProvider = StateNotifierProvider<WorkReportsNotifier, WorkReportsState>((ref) {
  final getUseCase = ref.watch(getWorkReportsUseCaseProvider);
  final createUseCase = ref.watch(createWorkReportUseCaseProvider);
  final updateUseCase = ref.watch(updateWorkReportUseCaseProvider);
  final deleteUseCase = ref.watch(deleteWorkReportUseCaseProvider);
  final notifier = WorkReportsNotifier(getUseCase, createUseCase, updateUseCase, deleteUseCase);
  ref.onDispose(() => notifier.mounted = false);
  return notifier;
});

// Provider para un reporte individual
class WorkReportState {
  final WorkReport? report;
  final bool isLoading;
  final String? error;

  WorkReportState({
    this.report,
    this.isLoading = false,
    this.error,
  });

  WorkReportState copyWith({
    WorkReport? report,
    bool? isLoading,
    String? error,
  }) {
    return WorkReportState(
      report: report ?? this.report,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

class WorkReportNotifier extends StateNotifier<WorkReportState> {
  final GetWorkReportUseCase getWorkReportUseCase;

  WorkReportNotifier(this.getWorkReportUseCase) : super(WorkReportState());

  Future<void> loadWorkReport(int id) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final report = await getWorkReportUseCase(id);
      state = state.copyWith(isLoading: false, report: report);
    } on DioException catch (e) {
      String errorMessage;
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.sendTimeout ||
          e.type == DioExceptionType.connectionError) {
        errorMessage = 'Error de conexión. Verifica tu conexión a internet e intenta nuevamente.';
      } else if (e.type == DioExceptionType.badResponse) {
        errorMessage = 'Error del servidor. Inténtalo más tarde.';
      } else {
        errorMessage = 'Error al cargar el reporte. Por favor, intenta nuevamente.';
      }
      state = state.copyWith(isLoading: false, error: errorMessage);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Error al cargar el reporte. Por favor, intenta nuevamente.');
    }
  }
}

final workReportProvider = StateNotifierProvider.family<WorkReportNotifier, WorkReportState, int>((ref, id) {
  final getUseCase = ref.watch(getWorkReportUseCaseProvider);
  final notifier = WorkReportNotifier(getUseCase);
  notifier.loadWorkReport(id);
  return notifier;
});