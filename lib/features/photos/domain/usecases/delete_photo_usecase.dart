import '../repositories/photos_repository.dart';

class DeletePhotoUseCase {
  final PhotosRepository repository;

  DeletePhotoUseCase(this.repository);

  Future<void> call(int id) async {
    return await repository.deletePhoto(id);
  }
}