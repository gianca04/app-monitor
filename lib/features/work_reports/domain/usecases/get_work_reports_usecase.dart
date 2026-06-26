import '../repositories/work_reports_repository.dart';
import '../../data/models/work_reports_response.dart';

class GetWorkReportsUseCase {
  final WorkReportsRepository repository;

  GetWorkReportsUseCase(this.repository);

  Future<WorkReportsResponse> call({
    int? projectId,
    String? search,
    String? dateFrom,
    String? dateTo,
    String? sortBy,
    String? sortOrder,
    int? perPage,
    int? page,
  }) async {
    return await repository.getWorkReports(
      projectId: projectId,
      search: search,
      dateFrom: dateFrom,
      dateTo: dateTo,
      sortBy: sortBy,
      sortOrder: sortOrder,
      perPage: perPage,
      page: page,
    );
  }
}