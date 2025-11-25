import '../repositories/photos_repository.dart';
import '../../data/models/photo.dart';

class GetPhotoUseCase {
  final PhotosRepository repository;

  GetPhotoUseCase(this.repository);

  Future<Photo> call(int id) async {
    return await repository.getPhoto(id);
  }
}