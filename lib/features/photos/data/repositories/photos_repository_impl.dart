import 'package:dio/dio.dart';
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
  Future<Photo> createPhoto(int workReportId, MultipartFile photo, String descripcion, MultipartFile? beforeWorkPhoto, String? beforeWorkDescripcion) async {
    return await dataSource.createPhoto(workReportId, photo, descripcion, beforeWorkPhoto, beforeWorkDescripcion);
  }

  @override
  Future<Photo> updatePhoto(int id, MultipartFile? photo, String descripcion, MultipartFile? beforeWorkPhoto, String? beforeWorkDescripcion) async {
    return await dataSource.updatePhoto(id, photo, descripcion, beforeWorkPhoto, beforeWorkDescripcion);
  }

  @override
  Future<void> deletePhoto(int id) async {
    return await dataSource.deletePhoto(id);
  }
}