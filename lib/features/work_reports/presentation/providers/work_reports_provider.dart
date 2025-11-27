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

// Providers para dependencias
final dioProvider = Provider((ref) => Dio());
final workReportsDataSourceProvider = Provider((ref) => WorkReportsDataSourceImpl(ref.watch(authenticatedDioProvider)));
final workReportsRepositoryProvider = Provider((ref) => WorkReportsRepositoryImpl(ref.watch(workReportsDataSourceProvider)));
final getWorkReportsUseCaseProvider = Provider((ref) => GetWorkReportsUseCase(ref.watch(workReportsRepositoryProvider)));
final getWorkReportUseCaseProvider = Provider((ref) => GetWorkReportUseCase(ref.watch(workReportsRepositoryProvider)));
final createWorkReportUseCaseProvider = Provider((ref) => CreateWorkReportUseCase(ref.watch(workReportsRepositoryProvider)));
final updateWorkReportUseCaseProvider = Provider((ref) => UpdateWorkReportUseCase(ref.watch(workReportsRepositoryProvider)));
final deleteWorkReportUseCaseProvider = Provider((ref) => DeleteWorkReportUseCase(ref.watch(workReportsRepositoryProvider)));

// Estado para la lista
class WorkReportsState {
  final WorkReportsResponse? response;
  final bool isLoading;
  final String? error;

  WorkReportsState({
    this.response,
    this.isLoading = false,
    this.error,
  });

  List<WorkReport> get reports => response?.data ?? [];

  WorkReportsState copyWith({
    WorkReportsResponse? response,
    bool? isLoading,
    String? error,
  }) {
    return WorkReportsState(
      response: response ?? this.response,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

class WorkReportsNotifier extends StateNotifier<WorkReportsState> {
  final GetWorkReportsUseCase getWorkReportsUseCase;
  final CreateWorkReportUseCase createWorkReportUseCase;
  final UpdateWorkReportUseCase updateWorkReportUseCase;
  final DeleteWorkReportUseCase deleteWorkReportUseCase;

  WorkReportsNotifier(
    this.getWorkReportsUseCase,
    this.createWorkReportUseCase,
    this.updateWorkReportUseCase,
    this.deleteWorkReportUseCase,
  ) : super(WorkReportsState());

  Future<void> loadWorkReports() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await getWorkReportsUseCase();
      // Log loaded reports for debugging
      try {
        print('Loaded work reports response: $response');
        print('Loaded work reports data: ${response.data?.map((r) => r.toJson()).toList() ?? []}');
      } catch (_) {}
      state = state.copyWith(isLoading: false, response: response);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<WorkReport> createWorkReport(int projectId, int employeeId, String name, String reportDate, String? startTime, String? endTime, String? description, String? tools, String? personnel, String? materials, String? suggestions, List<Map<String, dynamic>> photos) async {
    final newReport = await createWorkReportUseCase(projectId, employeeId, name, reportDate, startTime, endTime, description, tools, personnel, materials, suggestions, photos);
    // Log the created report returned by the server
    try {
      print('Created work report (model): $newReport');
      print('Created work report (as json): ${newReport.toJson()}');
    } catch (_) {}

    // Reload the list to get updated pagination
    await loadWorkReports();

    return newReport;
  }

  Future<void> updateWorkReport(int id, int projectId, int employeeId, String name, String reportDate, String? startTime, String? endTime, String? description, String? tools, String? personnel, String? materials, String? suggestions, MultipartFile? supervisorSignature, MultipartFile? managerSignature, List<Map<String, dynamic>> photos) async {
    try {
      await updateWorkReportUseCase(id, projectId, employeeId, name, reportDate, startTime, endTime, description, tools, personnel, materials, suggestions, supervisorSignature, managerSignature, photos);
      // Reload the list to get updated data
      await loadWorkReports();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> deleteWorkReport(int id) async {
    try {
      await deleteWorkReportUseCase(id);
      // Reload the list to get updated data
      await loadWorkReports();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }
}

final workReportsProvider = StateNotifierProvider<WorkReportsNotifier, WorkReportsState>((ref) {
  final getUseCase = ref.watch(getWorkReportsUseCaseProvider);
  final createUseCase = ref.watch(createWorkReportUseCaseProvider);
  final updateUseCase = ref.watch(updateWorkReportUseCaseProvider);
  final deleteUseCase = ref.watch(deleteWorkReportUseCaseProvider);
  return WorkReportsNotifier(getUseCase, createUseCase, updateUseCase, deleteUseCase);
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
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}

final workReportProvider = StateNotifierProvider.family<WorkReportNotifier, WorkReportState, int>((ref, id) {
  final getUseCase = ref.watch(getWorkReportUseCaseProvider);
  final notifier = WorkReportNotifier(getUseCase);
  notifier.loadWorkReport(id);
  return notifier;
});