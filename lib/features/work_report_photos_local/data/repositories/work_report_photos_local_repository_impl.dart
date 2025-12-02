import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/work_report_photo_local_entity.dart';
import '../../domain/repositories/work_report_photos_local_repository.dart';
import '../datasources/work_report_photos_local_datasource.dart';
import '../models/work_report_photo_local_model.dart';

class WorkReportPhotosLocalRepositoryImpl
    implements WorkReportPhotosLocalRepository {
  final WorkReportPhotosLocalDataSource localDataSource;

  WorkReportPhotosLocalRepositoryImpl({required this.localDataSource});

  @override
  Future<Either<Failure, WorkReportPhotoLocalEntity>> createPhoto(
    WorkReportPhotoLocalEntity photo,
  ) async {
    try {
      final model = WorkReportPhotoLocalModel.fromEntity(photo);
      final createdModel = await localDataSource.createPhoto(model);
      return Right(createdModel.toEntity());
    } catch (e) {
      return Left(CacheFailure('Error al crear foto: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, WorkReportPhotoLocalEntity>> getPhoto(int id) async {
    try {
      final model = await localDataSource.getPhoto(id);
      if (model == null) {
        return Left(CacheFailure('Foto no encontrada'));
      }
      return Right(model.toEntity());
    } catch (e) {
      return Left(CacheFailure('Error al obtener foto: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, List<WorkReportPhotoLocalEntity>>>
  getPhotosByWorkReport(int workReportId) async {
    try {
      final models = await localDataSource.getPhotosByWorkReport(workReportId);
      final entities = models.map((model) => model.toEntity()).toList();
      return Right(entities);
    } catch (e) {
      return Left(CacheFailure('Error al obtener fotos: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, void>> updatePhoto(
    WorkReportPhotoLocalEntity photo,
  ) async {
    try {
      final model = WorkReportPhotoLocalModel.fromEntity(photo);
      await localDataSource.updatePhoto(model);
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure('Error al actualizar foto: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, void>> deletePhoto(int id) async {
    try {
      await localDataSource.deletePhoto(id);
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure('Error al eliminar foto: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, void>> deletePhotosByWorkReport(
    int workReportId,
  ) async {
    try {
      await localDataSource.deletePhotosByWorkReport(workReportId);
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure('Error al eliminar fotos: ${e.toString()}'));
    }
  }
}
