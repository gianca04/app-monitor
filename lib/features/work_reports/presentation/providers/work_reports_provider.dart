import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/usecases/get_work_reports_usecase.dart';
import '../../domain/usecases/get_work_report_usecase.dart';
import '../../domain/usecases/create_work_report_usecase.dart';
import '../../domain/usecases/update_work_report_usecase.dart';
import '../../domain/usecases/delete_work_report_usecase.dart';
import '../../data/models/work_report.dart';
import '../../data/datasources/work_reports_datasource.dart';
import '../../data/repositories/work_reports_repository_impl.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../photos/domain/usecases/create_photo_usecase.dart';
import '../../../photos/domain/usecases/update_photo_usecase.dart';
import '../../../photos/domain/usecases/delete_photo_usecase.dart';
import '../../../photos/data/repositories/photos_repository_impl.dart';
import 'package:monitor/core/error/dio_error_handler.dart';
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
  final int? projectId;
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
    this.projectId,
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
    int? projectId,
    String? dateFrom,
    String? dateTo,
    String? sortBy,
    String? sortOrder,
    int? perPage,
    int? currentPage,
    bool? hasMorePages,
    int? total,
    bool clearError = false,
  }) {
    return WorkReportsState(
      reports: reports ?? this.reports,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      error: clearError ? null : (error ?? this.error),
      search: search ?? this.search,
      projectId: projectId ?? this.projectId,
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
        clearError: true,
        reports: [],
        currentPage: 1,
        hasMorePages: true,
      );
    }
    try {
      final response = await getWorkReportsUseCase(
        projectId: state.projectId,
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
    } catch (e) {
      if (mounted) {
        state = state.copyWith(
          isLoading: false,
          error: DioErrorHandler.getErrorMessage(
            e,
            defaultMessage: 'Error al cargar los reportes. Por favor, intenta nuevamente.',
          ),
        );
      }
    }
  }

  Future<void> loadMoreWorkReports() async {
    if (!mounted || state.isLoadingMore || !state.hasMorePages) return;

    state = state.copyWith(isLoadingMore: true, clearError: true);
    try {
      final response = await getWorkReportsUseCase(
        projectId: state.projectId,
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
    } catch (e) {
      if (mounted) {
        state = state.copyWith(
          isLoadingMore: false,
          error: DioErrorHandler.getErrorMessage(
            e,
            defaultMessage: 'Error al cargar más reportes. Por favor, intenta nuevamente.',
          ),
        );
      }
    }
  }

  Future<WorkReport> createWorkReport(int projectId, int employeeId, String name, String reportDate, String? startTime, String? endTime, String? description, String? tools, String? personnel, String? materials, String? suggestions, List<Map<String, dynamic>> photos, String? supervisorSignature, String? managerSignature) async {
    try {
      final newReport = await createWorkReportUseCase(projectId, employeeId, name, reportDate, startTime, endTime, description, tools, personnel, materials, suggestions, photos, supervisorSignature, managerSignature);

      await loadWorkReports();
      return newReport;
    } catch (e) {
      if (mounted) {
        state = state.copyWith(
          error: DioErrorHandler.getErrorMessage(
            e,
            defaultMessage: 'Error al crear el reporte. Por favor, intenta nuevamente.',
          ),
        );
      }
      rethrow;
    }
  }

  Future<void> updateWorkReport(int id, int projectId, int employeeId, String name, String reportDate, String? startTime, String? endTime, String? description, String? tools, String? personnel, String? materials, String? suggestions, String? supervisorSignature, String? managerSignature) async {
    try {
      await updateWorkReportUseCase(id, projectId, employeeId, name, reportDate, startTime, endTime, description, tools, personnel, materials, suggestions, supervisorSignature, managerSignature);
      await loadWorkReports();
    } catch (e) {
      if (mounted) {
        state = state.copyWith(
          error: DioErrorHandler.getErrorMessage(
            e,
            defaultMessage: 'Error al actualizar el reporte. Por favor, intenta nuevamente.',
          ),
        );
      }
      rethrow;
    }
  }

  Future<Map<String, dynamic>> deleteWorkReport(int id) async {
    try {
      final response = await deleteWorkReportUseCase(id);
      await loadWorkReports();
      return response;
    } catch (e) {
      if (mounted) {
        state = state.copyWith(
          error: DioErrorHandler.getErrorMessage(
            e,
            defaultMessage: 'Error al eliminar el reporte. Por favor, intenta nuevamente.',
          ),
        );
      }
      rethrow;
    }
  }

  void setFilters({
    String? search,
    int? projectId,
    String? dateFrom,
    String? dateTo,
    String? sortBy,
    String? sortOrder,
    int? perPage,
  }) {
    state = state.copyWith(
      search: search,
      projectId: projectId,
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
    bool clearError = false,
  }) {
    return WorkReportState(
      report: report ?? this.report,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class WorkReportNotifier extends StateNotifier<WorkReportState> {
  final GetWorkReportUseCase getWorkReportUseCase;

  WorkReportNotifier(this.getWorkReportUseCase) : super(WorkReportState());

  Future<void> loadWorkReport(int id) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final report = await getWorkReportUseCase(id);
      state = state.copyWith(isLoading: false, report: report);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: DioErrorHandler.getErrorMessage(
          e,
          defaultMessage: 'Error al cargar el reporte. Por favor, intenta nuevamente.',
        ),
      );
    }
  }
}

final workReportProvider = StateNotifierProvider.family<WorkReportNotifier, WorkReportState, int>((ref, id) {
  final getUseCase = ref.watch(getWorkReportUseCaseProvider);
  final notifier = WorkReportNotifier(getUseCase);
  notifier.loadWorkReport(id);
  return notifier;
});