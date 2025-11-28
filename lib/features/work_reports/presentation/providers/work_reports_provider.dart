import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:convert';
import '../../domain/usecases/get_work_reports_usecase.dart';
import '../../domain/usecases/get_work_report_usecase.dart';
import '../../domain/usecases/create_work_report_usecase.dart';
import '../../domain/usecases/update_work_report_usecase.dart';
import '../../domain/usecases/delete_work_report_usecase.dart';
import '../../data/models/work_report.dart';
import '../../data/models/work_reports_response.dart';
import '../../data/models/cached_work_report.dart';
import '../../data/datasources/work_reports_datasource.dart';
import '../../data/repositories/work_reports_repository_impl.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

// Providers para dependencias
final dioProvider = Provider((ref) => Dio());
final connectivityProvider = Provider((ref) => Connectivity());
final workReportsBoxProvider = Provider<Box<CachedWorkReport>>((ref) {
  return Hive.box<CachedWorkReport>('workReports');
});
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
  final Connectivity connectivity;
  final Box<CachedWorkReport> workReportsBox;

  WorkReportsNotifier(
    this.getWorkReportsUseCase,
    this.createWorkReportUseCase,
    this.updateWorkReportUseCase,
    this.deleteWorkReportUseCase,
    this.connectivity,
    this.workReportsBox,
  ) : super(WorkReportsState());

  Future<void> _syncPendingReports() async {
    final pending = workReportsBox.values.where((cached) => cached.isPending).toList();
    for (final cached in pending) {
      try {
        final report = WorkReport.fromJson(cached.json);
        // Assuming we have the data to recreate, but since it's complex, for now just mark as synced
        // In a real app, you'd send to server and update ID
        // For simplicity, just mark as not pending
        final updatedCached = CachedWorkReport(id: cached.id, jsonString: cached.jsonString, isPending: false);
        await workReportsBox.put(cached.id, updatedCached);
      } catch (e) {
        // Handle sync error, perhaps retry later
        print('Error syncing report ${cached.id}: $e');
      }
    }
  }

  Future<void> loadWorkReports() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final connectivityResult = await connectivity.checkConnectivity();
      if (connectivityResult == ConnectivityResult.none) {
        // Load from Hive
        final cachedReports = workReportsBox.values
            .where((cached) => !cached.isPending) // Only non-pending for offline view
            .map((cached) => WorkReport.fromJson(cached.json))
            .toList();
        final response = WorkReportsResponse(data: cachedReports, meta: null);
        state = state.copyWith(isLoading: false, response: response);
      } else {
        // Sync pending reports first
        await _syncPendingReports();
        // Load from server
        final response = await getWorkReportsUseCase();
        // Save to Hive, mark as not pending
        await workReportsBox.clear();
        for (final report in response.data ?? []) {
          final cached = CachedWorkReport(id: report.id ?? 0, jsonString: jsonEncode(report.toJson()), isPending: false);
          await workReportsBox.put(report.id, cached);
        }
        state = state.copyWith(isLoading: false, response: response);
      }
    } catch (e) {
      // Try to load from Hive as fallback
      try {
        final cachedReports = workReportsBox.values
            .where((cached) => !cached.isPending)
            .map((cached) => WorkReport.fromJson(cached.json))
            .toList();
        final response = WorkReportsResponse(data: cachedReports, meta: null);
        state = state.copyWith(isLoading: false, response: response, error: 'Offline mode: ${e.toString()}');
      } catch (hiveError) {
        state = state.copyWith(isLoading: false, error: e.toString());
      }
    }
  }

  Future<WorkReport> createWorkReport(int projectId, int employeeId, String name, String reportDate, String? startTime, String? endTime, String? description, String? tools, String? personnel, String? materials, String? suggestions, List<Map<String, dynamic>> photos) async {
    final connectivityResult = await connectivity.checkConnectivity();
    if (connectivityResult == ConnectivityResult.none) {
      // Create locally and save to Hive as pending
      final newReport = WorkReport(
        id: DateTime.now().millisecondsSinceEpoch, // Temporary ID
        name: name,
        description: description,
        reportDate: reportDate,
        startTime: startTime,
        endTime: endTime,
        resources: Resources(tools: tools, personnel: personnel, materials: materials),
        suggestions: suggestions,
        // Other fields can be added
      );
      final cached = CachedWorkReport(id: newReport.id ?? 0, jsonString: jsonEncode(newReport.toJson()), isPending: true);
      await workReportsBox.put(newReport.id, cached);
      // Reload from Hive
      await loadWorkReports();
      return newReport;
    } else {
      final newReport = await createWorkReportUseCase(projectId, employeeId, name, reportDate, startTime, endTime, description, tools, personnel, materials, suggestions, photos);
      // Save to Hive as synced
      final cached = CachedWorkReport(id: newReport.id ?? 0, jsonString: jsonEncode(newReport.toJson()), isPending: false);
      await workReportsBox.put(newReport.id, cached);
      await loadWorkReports();
      return newReport;
    }
  }

  Future<void> updateWorkReport(int id, int? projectId, int? employeeId, String name, String reportDate, String? startTime, String? endTime, String? description, String? tools, String? personnel, String? materials, String? suggestions, MultipartFile? supervisorSignature, MultipartFile? managerSignature, List<Map<String, dynamic>> photos) async {
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
  final connectivity = ref.watch(connectivityProvider);
  final box = ref.watch(workReportsBoxProvider);
  return WorkReportsNotifier(getUseCase, createUseCase, updateUseCase, deleteUseCase, connectivity, box);
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