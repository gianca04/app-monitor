import '../repositories/photos_repository.dart';
import '../../data/models/photo.dart';

class UpdatePhotoUseCase {
  final PhotosRepository repository;

  UpdatePhotoUseCase(this.repository);

  Future<Photo> call(int id, Photo photo) async {
    return await repository.updatePhoto(id, photo);
  }
}