import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/work_report_local_entity.dart';
import '../repositories/work_reports_local_repository.dart';

class SyncWorkReportLocalUseCase {
  final WorkReportsLocalRepository repository;

  SyncWorkReportLocalUseCase(this.repository);

  Future<Either<Failure, WorkReportLocalEntity>> call(int localId) async {
    return await repository.syncWorkReport(localId);
  }
}
