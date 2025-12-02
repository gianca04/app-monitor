import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/work_report_local_entity.dart';
import '../repositories/work_reports_local_repository.dart';

class CreateWorkReportLocalUseCase {
  final WorkReportsLocalRepository repository;

  CreateWorkReportLocalUseCase(this.repository);

  Future<Either<Failure, int>> call(WorkReportLocalEntity report) async {
    return await repository.saveWorkReport(report);
  }
}
