import 'package:dio/dio.dart';
import '../../data/models/work_report.dart';

abstract class WorkReportsRepository {
  Future<List<WorkReport>> getWorkReports();
  Future<WorkReport> getWorkReport(int id);
  Future<WorkReport> createWorkReport(int projectId, int employeeId, String name, String reportDate, String? startTime, String? endTime, String? description, String? tools, String? personnel, String? materials, String? suggestions, List<Map<String, dynamic>> photos);
  Future<WorkReport> updateWorkReport(int id, int projectId, int employeeId, String name, String reportDate, String? startTime, String? endTime, String? description, String? tools, String? personnel, String? materials, String? suggestions, MultipartFile? supervisorSignature, MultipartFile? managerSignature, List<Map<String, dynamic>> photos);
  Future<void> deleteWorkReport(int id);
}