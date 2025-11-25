import '../../data/models/work_report.dart';

abstract class WorkReportsRepository {
  Future<List<WorkReport>> getWorkReports();
  Future<WorkReport> getWorkReport(int id);
  Future<WorkReport> createWorkReport(WorkReport report);
  Future<WorkReport> updateWorkReport(int id, WorkReport report);
  Future<void> deleteWorkReport(int id);
}