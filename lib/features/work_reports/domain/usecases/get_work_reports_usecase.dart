import '../repositories/work_reports_repository.dart';
import '../../data/models/work_report.dart';

class GetWorkReportsUseCase {
  final WorkReportsRepository repository;

  GetWorkReportsUseCase(this.repository);

  Future<List<WorkReport>> call() async {
    return await repository.getWorkReports();
  }
}