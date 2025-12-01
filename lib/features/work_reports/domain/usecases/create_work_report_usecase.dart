import '../repositories/work_reports_repository.dart';
import '../../data/models/work_report.dart';

class CreateWorkReportUseCase {
  final WorkReportsRepository repository;

  CreateWorkReportUseCase(this.repository);

  Future<WorkReport> call(int projectId, int employeeId, String name, String reportDate, String? startTime, String? endTime, String? description, String? tools, String? personnel, String? materials, String? suggestions, List<Map<String, dynamic>> photos, String? supervisorSignature, String? managerSignature) async {
    return await repository.createWorkReport(projectId, employeeId, name, reportDate, startTime, endTime, description, tools, personnel, materials, suggestions, photos, supervisorSignature, managerSignature);
  }
}