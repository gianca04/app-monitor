import 'package:dio/dio.dart';
import '../../domain/repositories/work_reports_repository.dart';
import '../datasources/work_reports_datasource.dart';
import '../models/work_report.dart';

class WorkReportsRepositoryImpl implements WorkReportsRepository {
  final WorkReportsDataSource dataSource;

  WorkReportsRepositoryImpl(this.dataSource);

  @override
  Future<List<WorkReport>> getWorkReports() async {
    return await dataSource.getWorkReports();
  }

  @override
  Future<WorkReport> getWorkReport(int id) async {
    return await dataSource.getWorkReport(id);
  }

  @override
  Future<WorkReport> createWorkReport(int projectId, int employeeId, String name, String reportDate, String? startTime, String? endTime, String? description, String? tools, String? personnel, String? materials, String? suggestions, MultipartFile? supervisorSignature, MultipartFile? managerSignature, List<Map<String, dynamic>> photos) async {
    return await dataSource.createWorkReport(projectId, employeeId, name, reportDate, startTime, endTime, description, tools, personnel, materials, suggestions, supervisorSignature, managerSignature, photos);
  }

  @override
  Future<WorkReport> updateWorkReport(int id, WorkReport report) async {
    return await dataSource.updateWorkReport(id, report);
  }

  @override
  Future<void> deleteWorkReport(int id) async {
    return await dataSource.deleteWorkReport(id);
  }
}