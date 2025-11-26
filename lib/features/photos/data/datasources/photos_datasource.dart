import 'package:dio/dio.dart';
import '../models/photo.dart';
import 'package:monitor/core/constants/api_constants.dart';

abstract class PhotosDataSource {
  Future<List<Photo>> getPhotos();
  Future<Photo> getPhoto(int id);
  Future<Photo> createPhoto(int workReportId, MultipartFile photo, String descripcion, MultipartFile? beforeWorkPhoto, String? beforeWorkDescripcion);
  Future<Photo> updatePhoto(int id, Photo photo);
  Future<void> deletePhoto(int id);
}

class PhotosDataSourceImpl implements PhotosDataSource {
  final Dio dio;

  PhotosDataSourceImpl(this.dio);

  @override
  Future<List<Photo>> getPhotos() async {
    final response = await dio.get('${ApiConstants.baseUrl}${ApiConstants.photosEndpoint}');
    return (response.data['data'] as List).map((json) => Photo.fromJson(json)).toList();
  }

  @override
  Future<Photo> getPhoto(int id) async {
    final response = await dio.get('${ApiConstants.baseUrl}${ApiConstants.photosEndpoint}/$id');
    return Photo.fromJson(response.data['data']);
  }

  @override
  Future<Photo> createPhoto(int workReportId, MultipartFile photo, String descripcion, MultipartFile? beforeWorkPhoto, String? beforeWorkDescripcion) async {
    final formData = FormData.fromMap({
      'work_report_id': workReportId,
      'photo': photo,
      'descripcion': descripcion,
      if (beforeWorkPhoto != null) 'before_work_photo': beforeWorkPhoto,
      if (beforeWorkDescripcion != null) 'before_work_descripcion': beforeWorkDescripcion,
    });

    final response = await dio.post(
      '${ApiConstants.baseUrl}${ApiConstants.photosEndpoint}',
      data: formData,
    );
    return Photo.fromJson(response.data['data']);
  }

  @override
  Future<Photo> updatePhoto(int id, Photo photo) async {
    final response = await dio.put(
      '${ApiConstants.baseUrl}${ApiConstants.photosEndpoint}/$id',
      data: photo.toJson(),
    );
    return Photo.fromJson(response.data['data']);
  }

  @override
  Future<void> deletePhoto(int id) async {
    await dio.delete('${ApiConstants.baseUrl}${ApiConstants.photosEndpoint}/$id');
  }
}