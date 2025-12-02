import 'package:hive/hive.dart';
import '../models/work_report_local_model.dart';

abstract class WorkReportsLocalDataSource {
  Future<int> saveWorkReport(WorkReportLocalModel report);
  Future<WorkReportLocalModel?> getWorkReport(int id);
  Future<List<WorkReportLocalModel>> getAllWorkReports();
  Future<int> updateWorkReport(WorkReportLocalModel report);
  Future<void> deleteWorkReport(int id);
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
}
