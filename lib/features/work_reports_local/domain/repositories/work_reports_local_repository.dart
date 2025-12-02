import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/work_report_local_entity.dart';

abstract class WorkReportsLocalRepository {
  Future<Either<Failure, int>> saveWorkReport(WorkReportLocalEntity report);
  Future<Either<Failure, WorkReportLocalEntity>> getWorkReport(int id);
  Future<Either<Failure, List<WorkReportLocalEntity>>> getAllWorkReports();
  Future<Either<Failure, int>> updateWorkReport(WorkReportLocalEntity report);
  Future<Either<Failure, void>> deleteWorkReport(int id);
}
