import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/work_report_photo_local_entity.dart';

abstract class WorkReportPhotosLocalRepository {
  Future<Either<Failure, WorkReportPhotoLocalEntity>> createPhoto(
    WorkReportPhotoLocalEntity photo,
  );

  Future<Either<Failure, WorkReportPhotoLocalEntity>> getPhoto(int id);

  Future<Either<Failure, List<WorkReportPhotoLocalEntity>>>
  getPhotosByWorkReport(int workReportId);

  Future<Either<Failure, void>> updatePhoto(WorkReportPhotoLocalEntity photo);

  Future<Either<Failure, void>> deletePhoto(int id);

  Future<Either<Failure, void>> deletePhotosByWorkReport(int workReportId);
}
