import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/work_report_photo_local_entity.dart';
import '../repositories/work_report_photos_local_repository.dart';

class UpdateWorkReportPhotoLocalUseCase {
  final WorkReportPhotosLocalRepository repository;

  UpdateWorkReportPhotoLocalUseCase(this.repository);

  Future<Either<Failure, void>> call(WorkReportPhotoLocalEntity photo) {
    return repository.updatePhoto(photo);
  }
}
