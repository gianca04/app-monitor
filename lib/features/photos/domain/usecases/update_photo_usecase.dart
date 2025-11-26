import 'package:dio/dio.dart';
import '../repositories/photos_repository.dart';
import '../../data/models/photo.dart';

class UpdatePhotoUseCase {
  final PhotosRepository repository;

  UpdatePhotoUseCase(this.repository);

  Future<Photo> call(int id, MultipartFile? photo, String descripcion, MultipartFile? beforeWorkPhoto, String? beforeWorkDescripcion) async {
    return await repository.updatePhoto(id, photo, descripcion, beforeWorkPhoto, beforeWorkDescripcion);
  }
}