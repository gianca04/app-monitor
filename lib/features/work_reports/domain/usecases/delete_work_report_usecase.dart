import '../repositories/work_reports_repository.dart';

class DeleteWorkReportUseCase {
  final WorkReportsRepository repository;

  DeleteWorkReportUseCase(this.repository);

  Future<Map<String, dynamic>> call(int id) async {
    return await repository.deleteWorkReport(id);
  }
}