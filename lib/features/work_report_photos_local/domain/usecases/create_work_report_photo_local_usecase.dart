import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/work_report_photo_local_entity.dart';
import '../repositories/work_report_photos_local_repository.dart';

class CreateWorkReportPhotoLocalUseCase {
  final WorkReportPhotosLocalRepository repository;

  CreateWorkReportPhotoLocalUseCase(this.repository);

  Future<Either<Failure, WorkReportPhotoLocalEntity>> call(
    WorkReportPhotoLocalEntity photo,
  ) {
    return repository.createPhoto(photo);
  }
}
