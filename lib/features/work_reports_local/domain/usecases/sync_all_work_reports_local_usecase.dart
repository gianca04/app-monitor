import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../repositories/work_reports_local_repository.dart';

class SyncAllWorkReportsLocalUseCase {
  final WorkReportsLocalRepository repository;

  SyncAllWorkReportsLocalUseCase(this.repository);

  Future<Either<Failure, Map<String, dynamic>>> call() async {
    return await repository.syncAllWorkReports();
  }
}
