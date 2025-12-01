import '../entities/photo_local.dart';

abstract class PhotoLocalRepository {
  Future<List<PhotoLocal>> getPhotoLocals();
  Future<void> savePhotoLocal(PhotoLocal photoLocal);
  Future<void> deletePhotoLocal(int id);
}