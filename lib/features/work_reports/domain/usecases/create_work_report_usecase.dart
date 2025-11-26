import 'package:dio/dio.dart';
import '../repositories/work_reports_repository.dart';
import '../../data/models/work_report.dart';

class CreateWorkReportUseCase {
  final WorkReportsRepository repository;

  CreateWorkReportUseCase(this.repository);

  Future<WorkReport> call(int projectId, int employeeId, String name, String reportDate, String? startTime, String? endTime, String? description, String? tools, String? personnel, String? materials, String? suggestions, MultipartFile? supervisorSignature, MultipartFile? managerSignature, List<Map<String, dynamic>> photos) async {
    return await repository.createWorkReport(projectId, employeeId, name, reportDate, startTime, endTime, description, tools, personnel, materials, suggestions, supervisorSignature, managerSignature, photos);
  }
}