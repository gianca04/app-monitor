import '../repositories/work_reports_repository.dart';
import '../../data/models/work_report.dart';

class GetWorkReportUseCase {
  final WorkReportsRepository repository;

  GetWorkReportUseCase(this.repository);

  Future<WorkReport> call(int id) async {
    return await repository.getWorkReport(id);
  }
}