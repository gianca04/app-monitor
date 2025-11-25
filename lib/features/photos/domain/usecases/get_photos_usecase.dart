import '../repositories/photos_repository.dart';
import '../../data/models/photo.dart';

class GetPhotosUseCase {
  final PhotosRepository repository;

  GetPhotosUseCase(this.repository);

  Future<List<Photo>> call() async {
    return await repository.getPhotos();
  }
}