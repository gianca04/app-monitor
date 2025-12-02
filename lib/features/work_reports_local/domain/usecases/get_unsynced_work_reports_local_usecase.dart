import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/work_report_local_entity.dart';
import '../repositories/work_reports_local_repository.dart';

class GetUnsyncedWorkReportsLocalUseCase {
  final WorkReportsLocalRepository repository;

  GetUnsyncedWorkReportsLocalUseCase(this.repository);

  Future<Either<Failure, List<WorkReportLocalEntity>>> call() async {
    return await repository.getUnsyncedWorkReports();
  }
}
