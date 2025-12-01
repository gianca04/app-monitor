import '../../domain/repositories/photo_local_repository.dart';
import '../../domain/entities/photo_local.dart';
import '../../domain/entities/after_work.dart';
import '../../domain/entities/before_work.dart';
import '../../domain/entities/timestamps.dart';
import '../models/photo_local_model.dart';
import '../models/after_work_model.dart';
import '../models/before_work_model.dart';
import '../models/timestamps_model.dart';
import '../datasources/photo_local_local_datasource.dart';

class PhotoLocalRepositoryImpl implements PhotoLocalRepository {
  final PhotoLocalLocalDataSource dataSource;

  PhotoLocalRepositoryImpl(this.dataSource);

  @override
  Future<List<PhotoLocal>> getPhotoLocals() async {
    final models = await dataSource.getPhotoLocals();
    return models.map((model) => _modelToEntity(model)).toList();
  }

  @override
  Future<void> savePhotoLocal(PhotoLocal photoLocal) async {
    final model = _entityToModel(photoLocal);
    await dataSource.savePhotoLocal(model);
  }

  @override
  Future<void> deletePhotoLocal(int id) async {
    await dataSource.deletePhotoLocal(id);
  }

  PhotoLocal _modelToEntity(PhotoLocalModel model) {
    return PhotoLocal(
      id: model.id,
      workReportId: model.workReportId,
      afterWork: _modelToEntityAfterWork(model.afterWork),
      beforeWork: _modelToEntityBeforeWork(model.beforeWork),
      timestamps: _modelToEntityTimestamps(model.timestamps),
    );
  }

  PhotoLocalModel _entityToModel(PhotoLocal entity) {
    return PhotoLocalModel(
      id: entity.id,
      workReportId: entity.workReportId,
      afterWork: _entityToModelAfterWork(entity.afterWork),
      beforeWork: _entityToModelBeforeWork(entity.beforeWork),
      timestamps: _entityToModelTimestamps(entity.timestamps),
    );
  }

  AfterWork _modelToEntityAfterWork(AfterWorkModel model) {
    switch (model) {
      case AfterWorkModel.yes:
        return AfterWork.yes;
      case AfterWorkModel.no:
        return AfterWork.no;
    }
  }

  AfterWorkModel _entityToModelAfterWork(AfterWork entity) {
    switch (entity) {
      case AfterWork.yes:
        return AfterWorkModel.yes;
      case AfterWork.no:
        return AfterWorkModel.no;
    }
  }

  BeforeWork _modelToEntityBeforeWork(BeforeWorkModel model) {
    switch (model) {
      case BeforeWorkModel.yes:
        return BeforeWork.yes;
      case BeforeWorkModel.no:
        return BeforeWork.no;
    }
  }

  BeforeWorkModel _entityToModelBeforeWork(BeforeWork entity) {
    switch (entity) {
      case BeforeWork.yes:
        return BeforeWorkModel.yes;
      case BeforeWork.no:
        return BeforeWorkModel.no;
    }
  }

  Timestamps _modelToEntityTimestamps(TimestampsModel model) {
    return Timestamps(
      createdAt: model.createdAt,
      updatedAt: model.updatedAt,
    );
  }

  TimestampsModel _entityToModelTimestamps(Timestamps entity) {
    return TimestampsModel(
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }
}