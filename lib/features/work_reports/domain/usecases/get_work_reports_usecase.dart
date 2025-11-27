import '../repositories/work_reports_repository.dart';
import '../../data/models/work_reports_response.dart';

class GetWorkReportsUseCase {
  final WorkReportsRepository repository;

  GetWorkReportsUseCase(this.repository);

  Future<WorkReportsResponse> call() async {
    return await repository.getWorkReports();
  }
}