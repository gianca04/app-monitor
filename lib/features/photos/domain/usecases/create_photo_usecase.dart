import '../repositories/photos_repository.dart';
import '../../data/models/photo.dart';

class CreatePhotoUseCase {
  final PhotosRepository repository;

  CreatePhotoUseCase(this.repository);

  Future<Photo> call(Photo photo) async {
    return await repository.createPhoto(photo);
  }
}