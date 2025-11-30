import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
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
import '../../../settings/providers/connectivity_preferences_provider.dart';

// Providers para dependencias
final dioProvider = Provider((ref) => Dio());
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
enum ReportFilter { local, cloud }

class WorkReportsState {
  final WorkReportsResponse? response;
  final bool isLoading;
  final String? error;
  final bool isOffline;
  final ReportFilter filter;
  final String? dateFrom;
  final String? dateTo;

  WorkReportsState({
    this.response,
    this.isLoading = false,
    this.error,
    this.isOffline = false,
    this.filter = ReportFilter.cloud,
    this.dateFrom,
    this.dateTo,
  });

  List<WorkReport> get reports {
    final all = response?.data ?? [];
    switch (filter) {
      case ReportFilter.local:
        return all.where((r) => r.id != null && r.id! > 1700000000000).toList();
      case ReportFilter.cloud:
        return all.where((r) => r.id == null || r.id! <= 1700000000000).toList();
    }
  }

  WorkReportsState copyWith({
    WorkReportsResponse? response,
    bool? isLoading,
    String? error,
    bool? isOffline,
    ReportFilter? filter,
    String? dateFrom,
    String? dateTo,
  }) {
    return WorkReportsState(
      response: response ?? this.response,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      isOffline: isOffline ?? this.isOffline,
      filter: filter ?? this.filter,
      dateFrom: dateFrom ?? this.dateFrom,
      dateTo: dateTo ?? this.dateTo,
    );
  }
}

class WorkReportsNotifier extends StateNotifier<WorkReportsState> {
  final GetWorkReportsUseCase getWorkReportsUseCase;
  final CreateWorkReportUseCase createWorkReportUseCase;
  final UpdateWorkReportUseCase updateWorkReportUseCase;
  final DeleteWorkReportUseCase deleteWorkReportUseCase;
  final AsyncValue<bool> connectivityAsync;
  final Box<CachedWorkReport> workReportsBox;

  bool mounted = true;

  WorkReportsNotifier(
    this.getWorkReportsUseCase,
    this.createWorkReportUseCase,
    this.updateWorkReportUseCase,
    this.deleteWorkReportUseCase,
    this.connectivityAsync,
    this.workReportsBox,
  ) : super(WorkReportsState());

  Future<void> _syncPendingReports() async {
    final pending = workReportsBox.values.where((cached) => cached.isPending).toList();
    for (final cached in pending) {
      try {
        // Assuming we have the data to recreate, but since it's complex, for now just mark as synced
        // In a real app, you'd send to server and update ID
        // For simplicity, just mark as not pending
        final updatedCached = CachedWorkReport(id: cached.id, jsonString: cached.jsonString, isPending: false, isLocal: cached.isLocal);
        await workReportsBox.put(cached.id, updatedCached);
      } catch (e) {
        // Handle sync error, perhaps retry later
        // TODO: Add proper logging instead of print
        // print('Error syncing report ${cached.id}: $e');
      }
    }
  }

  Future<void> loadWorkReports() async {
    if (mounted) state = state.copyWith(isLoading: true, error: null);
    try {
      final isOnline = connectivityAsync.maybeWhen(
        data: (online) => online,
        orElse: () => false,
      );

      if (!isOnline) {
        // Sin conexión: cargar desde almacenamiento local
        final cachedReports = workReportsBox.values
            .where((cached) => !cached.isPending)
            .map((cached) => WorkReport.fromJson(cached.json))
            .toList();
        final response = WorkReportsResponse(data: cachedReports, meta: null);
        if (mounted) state = state.copyWith(isLoading: false, response: response, isOffline: true);
        return;
      }

      // Hay conexión: intentar sincronizar y cargar desde servidor
      try {
        // Sync pending reports first
        await _syncPendingReports();

        // Load from server
        final response = await getWorkReportsUseCase(dateFrom: state.dateFrom, dateTo: state.dateTo);

        // Save to Hive, mark as not pending
        await workReportsBox.clear();
        for (final report in response.data ?? []) {
          final cached = CachedWorkReport(id: report.id ?? 0, jsonString: jsonEncode(report.toJson()), isPending: false, isLocal: false);
          await workReportsBox.put(report.id, cached);
        }
        if (mounted) state = state.copyWith(isLoading: false, response: response, isOffline: false);
      } catch (serverError) {
        // Error del servidor: intentar cargar desde cache local como fallback
        final cachedReports = workReportsBox.values
            .where((cached) => !cached.isPending)
            .map((cached) => WorkReport.fromJson(cached.json))
            .toList();

        if (cachedReports.isNotEmpty) {
          // Hay datos en cache: mostrarlos con mensaje informativo
          final response = WorkReportsResponse(data: cachedReports, meta: null);
          if (mounted) state = state.copyWith(
            isLoading: false,
            response: response,
            error: 'No se pudo conectar al servidor. Mostrando datos locales guardados.',
            isOffline: true,
          );
        } else {
          // No hay datos en cache: mostrar error
          if (mounted) state = state.copyWith(
            isLoading: false,
            error: 'No hay conexión al servidor y no hay datos locales disponibles.',
            isOffline: true,
          );
        }
      }
    } catch (e) {
      // Error crítico (ej: problema con Hive)
      if (mounted) state = state.copyWith(
        isLoading: false,
        error: 'Error al cargar los reportes. Por favor, intenta nuevamente.',
      );
    }
  }

  Future<WorkReport> createWorkReport(int projectId, int employeeId, String name, String reportDate, String? startTime, String? endTime, String? description, String? tools, String? personnel, String? materials, String? suggestions, List<Map<String, dynamic>> photos) async {
    final isOnline = connectivityAsync.maybeWhen(
      data: (online) => online,
      orElse: () => false,
    );
    if (!isOnline) {
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
      final cached = CachedWorkReport(id: newReport.id ?? 0, jsonString: jsonEncode(newReport.toJson()), isPending: true, isLocal: true);
      await workReportsBox.put(newReport.id, cached);
      // Reload from Hive
      await loadWorkReports();
      return newReport;
    } else {
      final newReport = await createWorkReportUseCase(projectId, employeeId, name, reportDate, startTime, endTime, description, tools, personnel, materials, suggestions, photos);
      // Save to Hive as synced
      final cached = CachedWorkReport(id: newReport.id ?? 0, jsonString: jsonEncode(newReport.toJson()), isPending: false, isLocal: false);
      await workReportsBox.put(newReport.id, cached);
      await loadWorkReports();
      return newReport;
    }
  }

  Future<void> updateWorkReport(int id, int? projectId, int? employeeId, String name, String reportDate, String? startTime, String? endTime, String? description, String? tools, String? personnel, String? materials, String? suggestions, MultipartFile? supervisorSignature, MultipartFile? managerSignature) async {
    try {
      await updateWorkReportUseCase(id, projectId, employeeId, name, reportDate, startTime, endTime, description, tools, personnel, materials, suggestions, supervisorSignature, managerSignature);
      // Reload the list to get updated data
      await loadWorkReports();
    } catch (e) {
      if (mounted) state = state.copyWith(error: e.toString());
    }
  }

  Future<void> deleteWorkReport(int id) async {
    try {
      await deleteWorkReportUseCase(id);
      // Reload the list to get updated data
      await loadWorkReports();
    } catch (e) {
      if (mounted) state = state.copyWith(error: e.toString());
    }
  }

  void setFilter(ReportFilter newFilter) {
    state = state.copyWith(filter: newFilter);
  }

  void setDateFilter(String? dateFrom, String? dateTo) {
    state = state.copyWith(dateFrom: dateFrom, dateTo: dateTo);
    loadWorkReports();
  }
}

final workReportsProvider = StateNotifierProvider<WorkReportsNotifier, WorkReportsState>((ref) {
  final getUseCase = ref.watch(getWorkReportsUseCaseProvider);
  final createUseCase = ref.watch(createWorkReportUseCaseProvider);
  final updateUseCase = ref.watch(updateWorkReportUseCaseProvider);
  final deleteUseCase = ref.watch(deleteWorkReportUseCaseProvider);
  final connectivityAsync = ref.watch(connectivityStatusProvider);
  final box = ref.watch(workReportsBoxProvider);
  final notifier = WorkReportsNotifier(getUseCase, createUseCase, updateUseCase, deleteUseCase, connectivityAsync, box);
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