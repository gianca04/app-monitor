import '../repositories/work_reports_repository.dart';
import '../../data/models/work_report.dart';

class UpdateWorkReportUseCase {
  final WorkReportsRepository repository;

  UpdateWorkReportUseCase(this.repository);

  Future<WorkReport> call(int id, WorkReport report) async {
    return await repository.updateWorkReport(id, report);
  }
}