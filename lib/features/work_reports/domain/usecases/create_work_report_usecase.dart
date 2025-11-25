import '../repositories/work_reports_repository.dart';
import '../../data/models/work_report.dart';

class CreateWorkReportUseCase {
  final WorkReportsRepository repository;

  CreateWorkReportUseCase(this.repository);

  Future<WorkReport> call(WorkReport report) async {
    return await repository.createWorkReport(report);
  }
}