import 'package:hive/hive.dart';
import '../models/work_report_photo_local_model.dart';

abstract class WorkReportPhotosLocalDataSource {
  Future<WorkReportPhotoLocalModel> createPhoto(
    WorkReportPhotoLocalModel photo,
  );

  Future<WorkReportPhotoLocalModel?> getPhoto(int id);

  Future<List<WorkReportPhotoLocalModel>> getPhotosByWorkReport(
    int workReportId,
  );

  Future<void> updatePhoto(WorkReportPhotoLocalModel photo);

  Future<void> deletePhoto(int id);

  Future<void> deletePhotosByWorkReport(int workReportId);
}

class WorkReportPhotosLocalDataSourceImpl
    implements WorkReportPhotosLocalDataSource {
  final Box<WorkReportPhotoLocalModel> photosBox;

  WorkReportPhotosLocalDataSourceImpl({required this.photosBox});

  int _generateId() {
    if (photosBox.isEmpty) {
      return 1;
    }
    final maxId = photosBox.values
        .map((photo) => photo.id ?? 0)
        .reduce((a, b) => a > b ? a : b);
    return maxId + 1;
  }

  @override
  Future<WorkReportPhotoLocalModel> createPhoto(
    WorkReportPhotoLocalModel photo,
  ) async {
    final newId = _generateId();
    photo.id = newId;
    await photosBox.put(newId, photo);
    return photo;
  }

  @override
  Future<WorkReportPhotoLocalModel?> getPhoto(int id) async {
    return photosBox.get(id);
  }

  @override
  Future<List<WorkReportPhotoLocalModel>> getPhotosByWorkReport(
    int workReportId,
  ) async {
    return photosBox.values
        .where((photo) => photo.workReportId == workReportId)
        .toList();
  }

  @override
  Future<void> updatePhoto(WorkReportPhotoLocalModel photo) async {
    if (photo.id == null) {
      throw Exception('Photo ID cannot be null for update');
    }
    await photosBox.put(photo.id!, photo);
  }

  @override
  Future<void> deletePhoto(int id) async {
    await photosBox.delete(id);
  }

  @override
  Future<void> deletePhotosByWorkReport(int workReportId) async {
    final photosToDelete = photosBox.values
        .where((photo) => photo.workReportId == workReportId)
        .toList();

    for (var photo in photosToDelete) {
      if (photo.id != null) {
        await photosBox.delete(photo.id!);
      }
    }
  }
}
