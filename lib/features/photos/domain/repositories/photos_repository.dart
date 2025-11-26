import 'package:dio/dio.dart';
import '../../data/models/photo.dart';

abstract class PhotosRepository {
  Future<List<Photo>> getPhotos();
  Future<Photo> getPhoto(int id);
  Future<Photo> createPhoto(int workReportId, MultipartFile photo, String descripcion, MultipartFile? beforeWorkPhoto, String? beforeWorkDescripcion);
  Future<Photo> updatePhoto(int id, Photo photo);
  Future<void> deletePhoto(int id);
}