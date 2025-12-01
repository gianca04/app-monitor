import '../models/photo_local_model.dart';

abstract class PhotoLocalLocalDataSource {
  Future<List<PhotoLocalModel>> getPhotoLocals();
  Future<void> savePhotoLocal(PhotoLocalModel model);
  Future<void> deletePhotoLocal(int id);
}