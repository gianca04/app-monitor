import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../repositories/work_reports_local_repository.dart';

class DeleteWorkReportLocalUseCase {
  final WorkReportsLocalRepository repository;

  DeleteWorkReportLocalUseCase(this.repository);

  Future<Either<Failure, void>> call(int id) async {
    return await repository.deleteWorkReport(id);
  }
}
