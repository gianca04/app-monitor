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

  dynamic _replaceUrls(dynamic data) {
    if (data is String) {
      return data.replaceAll('127.0.0.1', '10.0.2.2');
    } else if (data is Map) {
      return data.map<String, dynamic>((key, value) => MapEntry(key as String, _replaceUrls(value)));
    } else if (data is List) {
      return data.map(_replaceUrls).toList();
    } else {
      return data;
    }
  }

  @override
  Future<List<Photo>> getPhotos() async {
    final response = await dio.get('${ApiConstants.baseUrl}${ApiConstants.photosEndpoint}');
    final replacedData = _replaceUrls(response.data);
    return (replacedData['data'] as List).map((json) => Photo.fromJson(json)).toList();
  }

  @override
  Future<Photo> getPhoto(int id) async {
    final response = await dio.get('${ApiConstants.baseUrl}${ApiConstants.photosEndpoint}/$id');
    final replacedData = _replaceUrls(response.data);
    return Photo.fromJson(replacedData['data']);
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
    final replacedData = _replaceUrls(response.data);
    return Photo.fromJson(replacedData['data']);
  }

  @override
  Future<Photo> updatePhoto(int id, Photo photo) async {
    final response = await dio.put(
      '${ApiConstants.baseUrl}${ApiConstants.photosEndpoint}/$id',
      data: photo.toJson(),
    );
    final replacedData = _replaceUrls(response.data);
    return Photo.fromJson(replacedData['data']);
  }

  @override
  Future<void> deletePhoto(int id) async {
    await dio.delete('${ApiConstants.baseUrl}${ApiConstants.photosEndpoint}/$id');
  }
}