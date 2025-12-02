import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/work_report_local_entity.dart';
import '../repositories/work_reports_local_repository.dart';

class GetWorkReportLocalUseCase {
  final WorkReportsLocalRepository repository;

  GetWorkReportLocalUseCase(this.repository);

  Future<Either<Failure, WorkReportLocalEntity>> call(int id) async {
    return await repository.getWorkReport(id);
  }
}
