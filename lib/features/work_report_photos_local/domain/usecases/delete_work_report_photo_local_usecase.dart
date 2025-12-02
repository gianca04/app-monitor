import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../repositories/work_report_photos_local_repository.dart';

class DeleteWorkReportPhotoLocalUseCase {
  final WorkReportPhotosLocalRepository repository;

  DeleteWorkReportPhotoLocalUseCase(this.repository);

  Future<Either<Failure, void>> call(int id) {
    return repository.deletePhoto(id);
  }
}
