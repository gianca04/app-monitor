import '../../domain/repositories/photos_repository.dart';
import '../datasources/photos_datasource.dart';
import '../models/photo.dart';

class PhotosRepositoryImpl implements PhotosRepository {
  final PhotosDataSource dataSource;

  PhotosRepositoryImpl(this.dataSource);

  @override
  Future<List<Photo>> getPhotos() async {
    return await dataSource.getPhotos();
  }

  @override
  Future<Photo> getPhoto(int id) async {
    return await dataSource.getPhoto(id);
  }

  @override
  Future<Photo> createPhoto(Photo photo) async {
    return await dataSource.createPhoto(photo);
  }

  @override
  Future<Photo> updatePhoto(int id, Photo photo) async {
    return await dataSource.updatePhoto(id, photo);
  }

  @override
  Future<void> deletePhoto(int id) async {
    return await dataSource.deletePhoto(id);
  }
}