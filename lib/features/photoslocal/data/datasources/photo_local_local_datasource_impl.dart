import 'package:hive/hive.dart';
import '../models/photo_local_model.dart';
import 'photo_local_local_datasource.dart';

class PhotoLocalLocalDataSourceImpl implements PhotoLocalLocalDataSource {
  final Box<PhotoLocalModel> box;

  PhotoLocalLocalDataSourceImpl(this.box);

  @override
  Future<List<PhotoLocalModel>> getPhotoLocals() async {
    return box.values.toList();
  }

  @override
  Future<void> savePhotoLocal(PhotoLocalModel model) async {
    if (model.id == null) {
      final id = await box.add(model);
      model.id = id;
    } else {
      await box.put(model.id, model);
    }
  }

  @override
  Future<void> deletePhotoLocal(int id) async {
    await box.delete(id);
  }
}