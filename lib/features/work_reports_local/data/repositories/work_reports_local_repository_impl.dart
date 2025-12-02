import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/work_report_local_entity.dart';
import '../../domain/repositories/work_reports_local_repository.dart';
import '../datasources/work_reports_local_datasource.dart';
import '../models/work_report_local_model.dart';

class WorkReportsLocalRepositoryImpl implements WorkReportsLocalRepository {
  final WorkReportsLocalDataSource localDataSource;

  WorkReportsLocalRepositoryImpl({required this.localDataSource});

  @override
  Future<Either<Failure, int>> saveWorkReport(
    WorkReportLocalEntity report,
  ) async {
    try {
      final model = WorkReportLocalModel.fromEntity(report);
      final id = await localDataSource.saveWorkReport(model);
      return Right(id);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, WorkReportLocalEntity>> getWorkReport(int id) async {
    try {
      final model = await localDataSource.getWorkReport(id);
      if (model == null) {
        return Left(CacheFailure('Work report with id $id not found'));
      }
      return Right(model.toEntity());
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<WorkReportLocalEntity>>>
  getAllWorkReports() async {
    try {
      final models = await localDataSource.getAllWorkReports();
      final entities = models.map((model) => model.toEntity()).toList();
      return Right(entities);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, int>> updateWorkReport(
    WorkReportLocalEntity report,
  ) async {
    try {
      final model = WorkReportLocalModel.fromEntity(report);
      final id = await localDataSource.updateWorkReport(model);
      return Right(id);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteWorkReport(int id) async {
    try {
      await localDataSource.deleteWorkReport(id);
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }
}
