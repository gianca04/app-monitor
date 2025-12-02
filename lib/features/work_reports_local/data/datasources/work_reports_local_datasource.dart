import 'package:hive/hive.dart';
import '../models/work_report_local_model.dart';

abstract class WorkReportsLocalDataSource {
  Future<int> saveWorkReport(WorkReportLocalModel report);
  Future<WorkReportLocalModel?> getWorkReport(int id);
  Future<List<WorkReportLocalModel>> getAllWorkReports();
  Future<int> updateWorkReport(WorkReportLocalModel report);
  Future<void> deleteWorkReport(int id);
  Future<List<WorkReportLocalModel>> getUnsyncedWorkReports();
  Future<void> markAsSynced(int localId, int serverId);
  Future<void> markSyncError(int localId, String error);
}

class WorkReportsLocalDataSourceImpl implements WorkReportsLocalDataSource {
  final Box<WorkReportLocalModel> workReportsBox;

  WorkReportsLocalDataSourceImpl({required this.workReportsBox});

  @override
  Future<int> saveWorkReport(WorkReportLocalModel report) async {
    // Generate an ID if not provided
    if (report.id == null) {
      // Get the highest ID in the box and increment it
      final ids = workReportsBox.keys.cast<int>().toList();
      final maxId = ids.isEmpty ? 0 : ids.reduce((a, b) => a > b ? a : b);
      report.id = maxId + 1;
    }
    await workReportsBox.put(report.id, report);
    return report.id!;
  }

  @override
  Future<WorkReportLocalModel?> getWorkReport(int id) async {
    return workReportsBox.get(id);
  }

  @override
  Future<List<WorkReportLocalModel>> getAllWorkReports() async {
    return workReportsBox.values.toList();
  }

  @override
  Future<int> updateWorkReport(WorkReportLocalModel report) async {
    if (report.id == null) {
      throw Exception('Cannot update work report without an ID');
    }
    await workReportsBox.put(report.id, report);
    return report.id!;
  }

  @override
  Future<void> deleteWorkReport(int id) async {
    await workReportsBox.delete(id);
  }

  @override
  Future<List<WorkReportLocalModel>> getUnsyncedWorkReports() async {
    return workReportsBox.values
        .where((report) => !(report.isSynced ?? false))
        .toList();
  }

  @override
  Future<void> markAsSynced(int localId, int serverId) async {
    final report = workReportsBox.get(localId);
    if (report != null) {
      final updatedReport = WorkReportLocalModel(
        id: report.id,
        employeeId: report.employeeId,
        projectId: report.projectId,
        name: report.name,
        description: report.description,
        resources: report.resources,
        signatures: report.signatures,
        suggestions: report.suggestions,
        timestamps: report.timestamps,
        startTime: report.startTime,
        endTime: report.endTime,
        isSynced: true,
        syncedServerId: serverId,
        syncError: null,
        lastSyncAttempt: DateTime.now().toIso8601String(),
      );
      await workReportsBox.put(localId, updatedReport);
    }
  }

  @override
  Future<void> markSyncError(int localId, String error) async {
    final report = workReportsBox.get(localId);
    if (report != null) {
      final updatedReport = WorkReportLocalModel(
        id: report.id,
        employeeId: report.employeeId,
        projectId: report.projectId,
        name: report.name,
        description: report.description,
        resources: report.resources,
        signatures: report.signatures,
        suggestions: report.suggestions,
        timestamps: report.timestamps,
        startTime: report.startTime,
        endTime: report.endTime,
        isSynced: false,
        syncedServerId: report.syncedServerId,
        syncError: error,
        lastSyncAttempt: DateTime.now().toIso8601String(),
      );
      await workReportsBox.put(localId, updatedReport);
    }
  }
}
