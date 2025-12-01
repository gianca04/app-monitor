import '../repositories/work_reports_repository.dart';
import '../../data/models/work_report.dart';

class UpdateWorkReportUseCase {
  final WorkReportsRepository repository;

  UpdateWorkReportUseCase(this.repository);

  Future<WorkReport> call(int id, int projectId, int employeeId, String name, String reportDate, String? startTime, String? endTime, String? description, String? tools, String? personnel, String? materials, String? suggestions, String? supervisorSignature, String? managerSignature) async {
    return await repository.updateWorkReport(id, projectId, employeeId, name, reportDate, startTime, endTime, description, tools, personnel, materials, suggestions, supervisorSignature, managerSignature);
  }
}