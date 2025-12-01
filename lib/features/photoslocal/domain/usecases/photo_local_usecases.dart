import '../repositories/photo_local_repository.dart';
import '../entities/photo_local.dart';

class GetPhotoLocals {
  final PhotoLocalRepository repository;

  GetPhotoLocals(this.repository);

  Future<List<PhotoLocal>> call() => repository.getPhotoLocals();
}

class SavePhotoLocal {
  final PhotoLocalRepository repository;

  SavePhotoLocal(this.repository);

  Future<void> call(PhotoLocal photoLocal) => repository.savePhotoLocal(photoLocal);
}

class DeletePhotoLocal {
  final PhotoLocalRepository repository;

  DeletePhotoLocal(this.repository);

  Future<void> call(int id) => repository.deletePhotoLocal(id);
}