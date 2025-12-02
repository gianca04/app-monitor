import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/work_report_local_entity.dart';
import '../repositories/work_reports_local_repository.dart';

class UpdateWorkReportLocalUseCase {
  final WorkReportsLocalRepository repository;

  UpdateWorkReportLocalUseCase(this.repository);

  Future<Either<Failure, void>> call(WorkReportLocalEntity report) async {
    return await repository.updateWorkReport(report);
  }
}
