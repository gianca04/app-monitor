import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/work_report_photo_local_entity.dart';
import '../repositories/work_report_photos_local_repository.dart';

class GetPhotosByWorkReportLocalUseCase {
  final WorkReportPhotosLocalRepository repository;

  GetPhotosByWorkReportLocalUseCase(this.repository);

  Future<Either<Failure, List<WorkReportPhotoLocalEntity>>> call(
    int workReportId,
  ) {
    return repository.getPhotosByWorkReport(workReportId);
  }
}
