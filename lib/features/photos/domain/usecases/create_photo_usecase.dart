import 'package:dio/dio.dart';
import '../repositories/photos_repository.dart';
import '../../data/models/photo.dart';

class CreatePhotoUseCase {
  final PhotosRepository repository;

  CreatePhotoUseCase(this.repository);

  Future<Photo> call(int workReportId, MultipartFile photo, String descripcion, MultipartFile? beforeWorkPhoto, String? beforeWorkDescripcion) async {
    return await repository.createPhoto(workReportId, photo, descripcion, beforeWorkPhoto, beforeWorkDescripcion);
  }
}